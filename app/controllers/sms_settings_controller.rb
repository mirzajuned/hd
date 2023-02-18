class SmsSettingsController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"
  after_action :update_audit_trail, only: [:visit_sms_setting, :followup_sms_setting, :birthday_sms_setting,
                                           :appointment_sms_setting, :campaign_sms_setting, :long_overdue_sms_setting, :missed_sms_setting, :discharge_sms_setting]

  def manage_sms
    @current_user_facility_settings = sms_current_configuration
    sms_types
    @level = "facility"
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def organisation_manage_sms
    @current_user_facility_settings = sms_current_configuration("organisation")
    @level = "organisation"
    sms_types
  end

  def override_facility_sms_setting
    SmsSettingJobs::OverrideFacilitySmsJob.perform_later(current_user.id.to_s)
  end

  def change_organisation_level_sms
    organisation_setting = current_user.organisation.organisations_setting
    organisation_setting.update_attributes(sms_contact_enabled: params[:sms_contact_enabled])

    # if eval(params[:sms_contact_enabled])
    if ActiveModel::Type::Boolean.new.cast(params[:sms_contact_enabled].to_s.downcase)
      @msg = "Organisation level sms settings is turned on"
    else
      @msg = "Organisation level sms settings is turned off"
    end
  end

  def set_facility_settings
    @level = params[:level]
    sms_types
    user_id = params[:user_id]
    @facility_id = params[:facility_id]
    if @facility_id.present?
      if params[:sms_active_inactive] == "true"
        status = true
      else
        status = false
      end

      type = params[:type]
      if @level == "organisation"
        @facility_setting = OrganisationsSetting.find_by(id: params[:facility_id])
      else
        @facility = Facility.includes(:users).find_by(id: @facility_id)
        # @facility_doctors = @facility.users.where(:role_ids.in => [158965000],is_active: true)
        @facility_setting = @facility.facility_setting
      end
      if type == "facility"
        @facility_setting.update(sms_feature: status, sms_feature_last_update: current_user.try(:fullname))
        identifier = "sms_feature_last_update"
      elsif type == "user"
        @facility_setting.user_sms_feature[user_id]['sms_feature'] = status
        @facility_setting.save
        identifier = "sms_feature_user"
      elsif type == "user_personal"
        @facility_setting.user_sms_feature[user_id]['personilized_sms'] = status
        @facility_setting.save
        identifier = "personilized_sms"
      elsif type == "visit"
        @facility_setting.update(visit_sms_active_inactive: status, visit_sms_last_update: current_user.try(:fullname))
        identifier = "visit_sms_setting"
      elsif type == "followup"
        @facility_setting.update(followup_sms_active_inactive: status, followup_sms_last_update: current_user.try(:fullname))
        identifier = "followup_sms_setting"
      elsif type == "long_overdue"
        @facility_setting.update(long_overdue_sms_active_inactive: status, long_overdue_sms_last_update: current_user.try(:fullname))
        identifier = "long_overdue_sms_setting"
      elsif type == "missed"
        @facility_setting.update(missed_sms_active_inactive: status, missed_sms_last_update: current_user.try(:fullname))
        identifier = "missed_sms_setting"
      elsif type == "appointment"
        @facility_setting.update(appointment_sms_active_inactive: status, appointment_sms_last_update: current_user.try(:fullname))
        identifier = "appointment_sms_setting"
      elsif type == "discharge"
        @facility_setting.update(discharge_sms_active_inactive: status, discharge_sms_last_update: current_user.try(:fullname))
        identifier = "discharge_sms_setting"
      elsif type == "birthday"
        @facility_setting.update(birthday_sms_active_inactive: status, birthday_sms_last_update: current_user.try(:fullname))
        identifier = "birthday_sms_setting"
        # elsif type == "campaign"
        #   @facility_setting.update(campaign_sms_active_inactive: status)
      end
      params.merge!(identifier: identifier)
      SettingsAudit::SmsSettingsAudit.new(params, current_user.id.to_s, current_user.organisation_id.to_s).create_audit
      @current_user_facility_settings = sms_current_configuration(@level, @facility_id)
    else
      head :ok
    end
  end

  def sms_visit_modal
    email_sms_modal_common
  end

  def sms_followup_modal
    email_sms_modal_common
  end

  def sms_birthday_modal
    email_sms_modal_common
  end

  def sms_long_overdue_modal
    email_sms_modal_common
  end

  def sms_appointment_modal
    email_sms_modal_common
  end

  def sms_missed_modal
    email_sms_modal_common
  end

  def sms_discharge_modal
    email_sms_modal_common
  end

  # saving data in db

  def visit_sms_setting
    if params[:facility_setting_id].present? && params[:level].present? && params[:level] == "facility"
      @facility_setting = FacilitySetting.find_by(id: params[:facility_setting_id])
      @facility_setting.update_attributes(visit_sms_setting_params)
      refresh_facility_sms_setting_page
    else
      @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
      @org_message_setting.update_attributes(visit_sms_setting_params)
      sms_setting_refresh
    end
  end

  def followup_sms_setting
    if params[:facility_setting_id].present? && params[:level] == "facility"
      @facility_setting = FacilitySetting.find_by(id: params[:facility_setting_id])
      @facility_setting.update_attributes(followup_sms_setting_params)
      refresh_facility_sms_setting_page
    else
      @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
      @org_message_setting.update_attributes(followup_sms_setting_params)
      sms_setting_refresh
    end
  end

  def birthday_sms_setting
    if params[:facility_setting_id].present? && params[:level] == "facility"
      @facility_setting = FacilitySetting.find_by(id: params[:facility_setting_id])
      @facility_setting.update_attributes(birthday_sms_setting_params)
      refresh_facility_sms_setting_page
    else
      @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
      @org_message_setting.update_attributes(birthday_sms_setting_params)
      sms_setting_refresh
    end
  end

  def appointment_sms_setting
    if params[:facility_setting_id].present? && params[:level] == "facility"
      @facility_setting = FacilitySetting.find_by(id: params[:facility_setting_id])
      @facility_setting.update_attributes(appointment_sms_setting_params)
      refresh_facility_sms_setting_page
    else
      @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
      @org_message_setting.update_attributes(appointment_sms_setting_params)
      sms_setting_refresh
    end
  end

  # def campaign_sms_setting
  #   if params[:facility_setting_id].present? && params[:level] == "facility"
  #     @facility_setting  = FacilitySetting.find_by(id: params[:facility_setting_id])
  #     @facility_setting.update_attributes(campaign_sms_setting_params)
  #     refresh_facility_sms_setting_page
  #   else
  #     @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
  #     @org_message_setting.update_attributes(campaign_sms_setting_params)
  #     sms_setting_refresh
  #   end
  # end

  def long_overdue_sms_setting
    if params[:facility_setting_id].present? && params[:level] == "facility"
      @facility_setting = FacilitySetting.find_by(id: params[:facility_setting_id])
      @facility_setting.update_attributes(long_overdue_sms_setting_params)
      refresh_facility_sms_setting_page
    else
      @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
      @org_message_setting.update_attributes(long_overdue_sms_setting_params)
      sms_setting_refresh
    end
  end

  def missed_sms_setting
    if params[:facility_setting_id].present? && params[:level] == "facility"
      @facility_setting = FacilitySetting.find_by(id: params[:facility_setting_id])
      @facility_setting.update_attributes(missed_sms_setting_params)
      refresh_facility_sms_setting_page
    else
      @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
      @org_message_setting.update_attributes(missed_sms_setting_params)
      sms_setting_refresh
    end
  end

  def discharge_sms_setting
    if params[:facility_setting_id].present? && params[:level] == "facility"
      @facility_setting = FacilitySetting.find_by(id: params[:facility_setting_id])
      @facility_setting.update_attributes(discharge_sms_setting_params)
      refresh_facility_sms_setting_page
    else
      @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
      @org_message_setting.update_attributes(discharge_sms_setting_params)
      sms_setting_refresh
    end
  end

  def get_facility_setting
    @level = params[:level]
    @facility_setting = FacilitySetting.find(params[:facility_setting_id])
    sms_types
  end

  def get_audit_trail
    limit = 10
    if params[:level] == "organisation"
      @audit_trail = SettingsAudit.where(organisation_id: current_user.organisation_id, level: params[:level], identifier: params[:identifier]).limit(limit).order(created_at: :desc)
    else
      @audit_trail = SettingsAudit.where(organisation_id: current_user.organisation_id, level: params[:level], identifier: params[:identifier], facility_id: params[:facilityid]).limit(limit).order(created_at: :desc)
    end
  end

  private

  def sms_types
    @sms_type = { "visit" => "Visit Ack", "followup" => "Followup", "birthday" => "Birthday", "long_overdue" => "Long Overdue", "appointment" => "Appointment", "missed" => "Missed", "discharge" => "Discharge", "campaign" => "Campaign" }
  end

  def sms_current_configuration(level = "facility", facility_id = current_facility.id)
    if level == "organisation"
      OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    else
      current_user_facility_settings = FacilitySetting.where(:facility_id => facility_id).first
    end
  end

  def email_sms_modal_common
    @level = params[:level]

    if params[:facility_id].present? && @level == "facility"
      @facility_id = params[:facility_id]
      @facility_setting = Facility.find(@facility_id).facility_setting
      @setting_source = @facility_setting
    else
      # @facility_id = current_user.facilities.first.id.to_s
      @facility_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
      @setting_source = @facility_setting
    end
    @organisation = current_user.organisation

    respond_to do |format|
      format.js {}
    end
  end

  def sms_setting_refresh
    respond_to do |format|
      format.js { render 'refresh_facility_sms_setting_page' }
    end
  end

  def refresh_facility_sms_setting_page
    respond_to do |format|
      format.js { render 'refresh_facility_sms_setting_page' }
    end
  end

  def update_audit_trail
    params.merge!(identifier: params[:action])
    SettingsAudit::SmsSettingsAudit.new(params, current_user.id.to_s, current_user.organisation_id.to_s).create_audit
  end

  # form params

  def visit_sms_setting_params
    params.permit(:visit_sms_text, :visit_sms_time, :visit_sms_schedule, :visit_sms_last_update)
  end

  def long_overdue_sms_setting_params
    params.permit(:long_overdue_sms_text, :long_overdue_sms_time, :long_overdue_sms_schedule, :long_overdue_sms_last_update)
  end

  def followup_sms_setting_params
    params.permit(:followup_sms_text, :followup_sms_time, :followup_sms_schedule, :followup_sms_last_update)
  end

  def birthday_sms_setting_params
    params.permit(:birthday_sms_text, :birthday_sms_time, :birthday_sms_schedule, :birthday_sms_last_update)
  end

  def appointment_sms_setting_params
    params.permit(:appointment_sms_text, :appointment_sms_time, :appointment_sms_schedule, :appointment_sms_last_update)
  end

  def missed_sms_setting_params
    params.permit(:missed_sms_text, :missed_sms_time, :missed_sms_schedule, :missed_sms_last_update)
  end

  def discharge_sms_setting_params
    params.permit(:discharge_sms_text, :discharge_sms_time, :discharge_sms_schedule, :discharge_sms_last_update)
  end

  # def campaign_sms_setting_params
  #   params.permit(:campaign_sms_text,:campaign_sms_time,:campaign_start_date, :campaign_end_date)
  # end
end # class end here
