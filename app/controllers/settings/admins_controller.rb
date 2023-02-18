class Settings::AdminsController < ApplicationController
  before_action :authorize
  before_action :authenticate_admin_user, only: [:organisation_settings]
  respond_to :js, :json, :html
  layout "loggedin"

  def account_settings
    respond_to do |format|
      format.js { render "settings/admins/account_settings", layout: false }
      format.html {}
    end
  end

  def organisation_settings
    # @inventory_dept =  Inventory::Department.where(:facility_id.in => current_user.facilities.pluck(:id))
    @organisation = current_user.organisation
    @facilities = current_user_facilities
    @current_user_facility_settings = current_user_facility_settings
    @sms_type = { "visit" => "Visit Ack", "followup" => "Followup", "birthday" => "Birthday", "long_overdue" => "Long Overdue", "appointment" => "Appointment", "missed" => "Missed", "discharge" => "Discharge", "campaign" => "Campaign" }
    @organisation_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @org_identifier_prefix = @organisation.identifier_prefix
    @org_cin = @organisation_settings.cin
    @org_emails = @organisation_settings.emails
    @organisation = Organisation.find_by(id: current_user.organisation_id)
    # nabh setting
    @nabh_setting = NabhSetting.find_by(facility_id: current_facility.id)
    # appointment types organisation level
    # removed rendering of appointment types for organisation level. now that rendering is different
    respond_to do |format|
      format.js { render "settings/admins/organisation_settings", :layout => false }
      format.html {}
    end
  end

  def facility_settings
    @organisation = current_user.organisation
    @facilities = current_user_facilities
    @current_user_facility_settings = current_user_facility_settings
    @sms_type = { "visit" => "Visit Ack", "followup" => "Followup", "birthday" => "Birthday", "long_overdue" => "Long Overdue", "appointment" => "Appointment", "missed" => "Missed", "discharge" => "Discharge", "campaign" => "Campaign" }
    @organisation_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @org_cin = @organisation_settings.cin
    # Inventory Store Setup
    @inventory_stores = Inventory::Store.where(facility_id: current_facility.id.to_s)
                                        .order_by(is_disable: :asc).group_by(&:facility_id)
    @facilities_data = Facility.where(:id.in => @inventory_stores.keys).pluck(:name, :id)
    # appointment types organisation level
    # removed rendering of appointment types for organisation level. now that rendering is different
    respond_to do |format|
      format.js { render "settings/admins/facility_settings", :layout => false }
      format.html {}
    end
  end

  def manage_sms
    @current_user_facility_settings = facility_users
    @sms_type = { "visit" => "Visit Ack", "followup" => "Followup", "birthday" => "Birthday", "long_overdue" => "Long Overdue", "appointment" => "Appointment", "missed" => "Missed", "discharge" => "Discharge", "campaign" => "Campaign" }
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def refresh_users
    @facility = Facility.find_by(id: params[:facility_id])
    @facility.update! if @facility.present?
  end

  def get_facility_setting
    @facility_setting = FacilitySetting.find(params[:facility_setting_id])
    @sms_type = { "visit" => "Visit Ack", "followup" => "Followup", "birthday" => "Birthday", "long_overdue" => "Long Overdue", "appointment" => "Appointment", "missed" => "Missed", "discharge" => "Discharge", "campaign" => "Campaign" }
  end

  def update_id_prefix
    organisation = Organisation.find_by(id: current_user.organisation_id)
    organisation.update_attributes!(:identifier_prefix => params[:org_id_prefix])
    SequenceManagerJobs::UpdateOrganisationJob.perform_later(organisation.id.to_s)
  end

  def update_cin
    organisation_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    organisation_settings.update_attributes(:cin => params[:org_cin])
  end

  def update_org_email
    org_emails = params[:org_emails].reject{|email| email.blank?}
    if org_emails.present?
      organisation_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
      organisation_settings.update_attributes(:emails => org_emails)
    end
  end

  private

  def authenticate_admin_user
    department_ids = current_user.department_ids
    if department_ids.present?
      if department_ids.include?("224608005")
        custom_check_for_lockup
      else
        redirect_to user_department_url(current_user)
      end
    else
      redirect_to '/'
    end
  end

  def custom_check_for_lockup
    multi_auth = OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id)).try(:multi_auth)
    return unless multi_auth
    return unless respond_to?(:lockup) && lockup_codeword
    return if cookies[:lockup].present? && cookies[:lockup] == lockup_codeword.to_s.downcase

    if request.xhr?
      respond_to do |format|
        format.js { render inline: "location.reload();" }
      end
    else
      redirect_to lockup.unlock_path(
        return_to: request.fullpath.split('?lockup_codeword')[0],
        lockup_codeword: params[:lockup_codeword],
      )
    end
  end

  def facility_users
    current_user_facility_ids = User.find(current_user.id).facility_ids
    current_user_facility_settings = FacilitySetting.where(:facility_id.in => current_user_facility_ids)
  end
end
