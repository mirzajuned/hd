class OrganisationsController < ApplicationController
  before_action :authorize
  before_action :find_organisation, only: [:edit, :update]
  before_action :count_ip_address, only: [:edit, :save_ip_whitelisting]

  def manage
    @organisation_id = current_organisation['_id']
  end

  def edit
    @disable_region = (count_sequences('counter_level', 'region') > 0)
    @disable_entity_group = (count_sequences('counter_level', 'entity_group') > 0)
    @communication_numbers = CommunicationNumber.where.in(
      organisation_id: [current_organisation['_id'].to_s, nil], is_disable: false
    )
  end

  def update
    params[:organisation][:currency_ids] = params[:organisation][:currency_ids].delete_if(&:blank?)

    if @organisation.update(organisation_params)
      # update_whatsapp_number(params[:organisation]) if params[:organisation].present?
      # @organisations_setting.update(organisations_setting_params)
      @country = Country.find_by(id: @organisation.country_id)
      @currencies = Currency.where(:id.in => @organisation.currency_ids)
      render 'show'
      object_config = {}
      object_config["class_name"] = "organisations"
      object_config["method_name"] = "update"
      mandatory = {}
      mandatory["organisation_id"] = @organisation.id.to_s
      optional = {}
      others = {}
      ProcessInBackgroundJob.set(queue: :urgent, wait_until: 0).perform_later(object_config, mandatory, optional, others)
      RegionMasters::CreateRegionService.call(@organisation.id.to_s, logger) if @organisation.enable_region && RegionMaster.where(organisation_id: @organisation.id).count == 0
    else
      render 'edit'
    end
  end

  def update_whatsapp_number params
    @communication_template = CommunicationTemplate.find_or_initialize_by(display_name: "default", communication_number: params[:whatsapp_number] )
    @communication_template.organisation_id = @organisation.id.to_s
    @communication_template.save
  end

  def edit_ip_whitelisting
    @ip_status = params[:ip_status]
    @organisation_id = params[:id]
    count_ip_address
  end

  def save_ip_whitelisting
    organisation = Organisation.find_by(id: params[:id])
    organisation.update(is_ip_whitelisted: params[:is_ip_whitelisted])
    Redis::Master.new.set("organisation:#{params[:id]}:ip-whitelisting-enabled", params[:is_ip_whitelisted])
    update_log_history(organisation)
    find_organisation

    render :edit
  end

  # # Move these Methods to OnboardingController in Future
  # # Onboarding --> Needs Work when onboarding Starts
  # def onboarding
  #   @appointment_types = AppointmentType.where(user_id: current_user.id, is_active: true)
  #   @organisation = current_user.organisation
  #   @organisation.identifier_prefix = current_user.email.gsub(/[^a-zA-Z ]/i, '').upcase[0, 3]
  #   @organisation.footer_text = 'Thank You!'
  #   facility_ids = Facility.where(organisation_id: current_user.organisation.id, is_active: true).map(&:id)
  #   @inventory_facility_ids = facility_ids # added by Ra
  #   @wards = Ward.where(:facility_id.in => facility_ids)
  #   if @organisation.type == 'individual'
  #     @user_settings = UsersSetting.find_by(organisation_id: current_user.organisation_id,
  #                                           facility_id: current_user.facilities.first.id,
  #                                           user_id: current_user.id)
  #     if @user_settings.nil?
  #       @user_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
  #     end
  #   elsif @organisation.type == 'hospital'
  #     @user_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
  #   end
  #   @medication_kits = MedicationKit.where(user_id: current_user.id)
  #   if @organisation.onboarding_completed
  #     # redirect_to "/outpatients/appointment_management"
  #     current_user.update_attributes(user_selected_url: '/dashboard')
  #     redirect_to '/dashboard'
  #     return
  #   end
  #   respond_to do |format|
  #     format.html { render layout: 'loggedout' }
  #   end
  # end

  # # Onboarding --> Needs Work when onboarding Starts
  # def onboarding_save
  #   params[:organisation][:letter_head_customisations] = {}

  #   if params[:organisation][:customised_letter_head] == 'true'
  #     params[:organisation][:letter_head_customisations][:logo_location] = params[:header_logo_location]
  #     params[:organisation][:letter_head_customisations][:header_location] = params[:header_location]
  #     if params[:header_logo_location] == 'left'
  #       params[:organisation][:letter_head_customisations][:right] = params[:right_header_text]
  #     elsif params[:header_logo_location] == 'right'
  #       params[:organisation][:letter_head_customisations][:left] = params[:left_header_text]
  #     elsif params[:header_logo_location] == 'none'
  #       params[:organisation][:letter_head_customisations][:left] = params[:left_header_text]
  #       params[:organisation][:letter_head_customisations][:right] = params[:right_header_text]
  #     end
  #     if params[:header_location] == 'left'
  #       params[:organisation][:letter_head_customisations][:header] = params[:header_text]
  #     elsif params[:header_location] == 'right'
  #       params[:organisation][:letter_head_customisations][:header] = params[:header_text]
  #     elsif params[:header_location] == 'center'
  #       params[:organisation][:letter_head_customisations][:header] = params[:header_text]
  #     end
  #   end
  #   params[:organisation][:letter_head_customisations][:header_height] = params[:letter_head_height]

  #   params[:organisation][:onboarding_completed] = true
  #   organisation = Organisation.find_by(id: params[:organisation][:id])
  #   organisation.update(org_onboarding_params)

  #   redirect_to '/outpatients/appointment_management'
  # end

  # # Onboarding --> Needs Work when onboarding Starts
  # Used by Inventory Departments Setting in Organisation Setting
  def add_inventory_button
    @facilities = current_user.organisation.facilities.where(is_active: true)
    respond_to do |format|
      format.js {}
    end
  end

  # # Onboarding --> Needs Work when onboarding Starts
  # Used by Inventory Departments Setting in Organisation Setting
  def facility_dropdown_inventory
    @facility_id = params['id']
    @inventory_department = Inventory::Department.where(facility_id: @facility_id)
    @all_inventory_department = @inventory_department.pluck(:department_id)
    respond_to do |format|
      format.js {}
    end
  end

  # # Onboarding --> Needs Work when onboarding Starts
  # def save_org_basic_details
  #   organisation = Organisation.find_by(id: params[:organisation][:id])
  #   organisation.update(save_org_basic_details_params)
  #   @facility = current_user.facilities[0]
  #   @facility.update_attributes(facility_update_params)
  #   address_new = []
  #   address_new.push(params[:organisation][:address1])
  #   address_new.push(params[:organisation][:address2])
  #   address_new = address_new.join(' ')
  #   @facility.update_attributes(address: address_new)
  #   respond_to do |format|
  #     format.js { render nothing: true }
  #   end
  # end

  # # Onboarding --> Needs Work when onboarding Starts
  # def save_org_general_settings
  #   params[:organisation][:letter_head_customisations] = {}

  #   if params[:organisation][:customised_letter_head] == 'true'
  #     params[:organisation][:letter_head_customisations][:logo_location] = params[:header_logo_location]
  #     params[:organisation][:letter_head_customisations][:header_location] = params[:header_location]
  #     if params[:header_logo_location] == 'left'
  #       params[:organisation][:letter_head_customisations][:right] = params[:right_header_text]
  #     elsif params[:header_logo_location] == 'right'
  #       params[:organisation][:letter_head_customisations][:left] = params[:left_header_text]
  #     elsif params[:header_logo_location] == 'none'
  #       params[:organisation][:letter_head_customisations][:left] = params[:left_header_text]
  #       params[:organisation][:letter_head_customisations][:right] = params[:right_header_text]
  #     end
  #     if params[:header_location] == 'left'
  #       params[:organisation][:letter_head_customisations][:header] = params[:header_text]
  #     elsif params[:header_location] == 'right'
  #       params[:organisation][:letter_head_customisations][:header] = params[:header_text]
  #     elsif params[:header_location] == 'center'
  #       params[:organisation][:letter_head_customisations][:header] = params[:header_text]
  #     end
  #   end
  #   params[:organisation][:letter_head_customisations][:header_height] = params[:letter_head_height]
  #   params[:organisation][:letter_head_customisations][:footer_height] = params[:footer_height]
  #   params[:organisation][:letter_head_customisations][:left_margin] = params[:left_margin]
  #   params[:organisation][:letter_head_customisations][:right_margin] = params[:right_margin]

  #   params[:organisation][:account_no] = CommonHelper.gen_org_account_identifier(
  #     params[:organisation][:identifier_prefix], current_user
  #   )

  #   organisation = Organisation.find_by(id: params[:organisation][:id])
  #   organisation.update(save_org_general_settings_params)

  #   respond_to do |format|
  #     format.js {}
  #   end
  # end

  # # Onboarding --> Needs Work when onboarding Starts
  # def onboarding_complete
  #   params[:organisation][:onboarding_completed] = true
  #   @organisation = Organisation.find_by(id: params[:organisation][:id])
  #   @organisation.update(onboarding_complete_params)

  #   ActivateUserJob.perform_later(@organisation.id.to_s)
  #   if current_user.organisation.type == 'individual'
  #     current_user.update_attributes(user_selected_url: '/dashboard')
  #     redirect_to '/dashboard'
  #   elsif current_user.organisation.type == 'hospital'
  #     current_user.update_attributes(user_selected_url: '/dashboard')
  #     redirect_to '/dashboard'
  #   end
  # end

  # Move these Methods to Facility/OrganisationSettings in Future
  # Used by Manage Invoice Passcode in Organisation Settings
  def set_password_internal
    passcode = params[:passcode]
    invoice_accessible = params[:invoice_accessible]
    organisation = Organisation.find_by(id: current_user.organisation_id)
    organisation.update_attributes(invoice_access_code: passcode, invoice_accessible: invoice_accessible)

    render json: { "success": true }
  end

  # Used by Manage Facility Settings in Organisation Settings
  def finance_facility_change
    @facility = Facility.find_by(id: params[:facility])

    # TokenSetting
    @token_setting = TokenSetting.find_by(facility_id: @facility.try(:id))
    @token_settings = TokenSetting.where(:facility_id.in => current_user.facilities.pluck(:id))

    respond_to do |format|
      format.js { render '/organisations/finance_facility_change', layout: false }
    end
  end

  # Used by Manage Facility Settings in Organisation Settings
  def show_finances
    show_finances = params[:show_finances]
    if params[:facility].to_i == 0 # All Facilities
      organisation_facilities.each do |facility|
        facility.update!(show_finances: show_finances)
      end
    else
      @facility = Facility.find_by(id: params[:facility])
      @facility.update_attributes(show_finances: show_finances)
    end

    render json: { "success": true }
  end

  # Used by Manage Facility Settings in Organisation Settings
  def show_user_state
    show_user_state = params[:show_user_state]
    if params[:facility].to_i == 0 # All Facilities
      organisation_facilities.each do |facility|
        facility.update!(show_user_state: show_user_state)
      end
    else
      @facility = Facility.find_by(id: params[:facility])
      @facility.update_attributes(show_user_state: show_user_state)
    end
    render json: { "success": true }
  end

  def show_language_support
    show_language_support = params[:show_language_support]
    if params[:facility].to_i == 0 # All Facilities
      organisation_facilities.each do |facility|
        facility.update!(show_language_support: show_language_support)
      end
    else
      @facility = Facility.find_by(id: params[:facility])
      @facility.update_attributes(show_language_support: show_language_support)
    end
    render json: { "success": true }
  end

  # Used by Manage Facility Settings in Organisation Settings
  def open_payment_taken
    open_payment_taken = params[:counsellor_counsels_investigation]
    if params[:facility].to_i == 0 # All Facilities
      organisation_facilities.each do |facility|
        facility.update!(counsellor_counsels_investigation: open_payment_taken)
      end
    else
      @facility = Facility.find_by(id: params[:facility])
      @facility.update_attributes(counsellor_counsels_investigation: open_payment_taken)
    end
    render json: { "success": true }
  end

  # Used by Manage Facility Settings in Organisation Settings
  def show_consultancy_type
    show_consultancy_type = params[:consultancy_type_enabled]
    if params[:facility].to_i == 0 # All Facilities
      organisation_facilities.each do |facility|
        facility.update!(consultancy_type_enabled: show_consultancy_type)
      end
    else
      @facility = Facility.find_by(id: params[:facility])
      @facility.update_attributes(consultancy_type_enabled: show_consultancy_type)
    end
    render json: { "success": true }
  end

  # Used by Manage Facility Settings in Organisation Settings
  def invoice_compulsory
    invoice_compulsory = params[:invoice_compulsory]
    if params[:facility] == '0' # All Facility
      organisation_facilities.each do |facility|
        facility.update!(invoice_compulsory: invoice_compulsory)
      end
    else
      @facility = Facility.find_by(id: params[:facility])
      @facility.update_attributes(invoice_compulsory: invoice_compulsory)
    end

    render json: { "success": true }
  end

  # Used by Manage Scheduled Admission List in Organisation Settings
  def scheduled_list_settings
    if params[:facility].to_i == 0 # All Facilities
      @count = current_facility.admission_schedule_list_length.to_i
    else
      @facility = Facility.find_by(id: params[:facility])
      @count = @facility.admission_schedule_list_length.to_i
    end
    respond_to do |format|
      format.js { render '/organisations/scheduled_list_settings', layout: false }
    end
  end

  # Used by Manage Scheduled Admission List in Organisation Settings
  def scheduled_list_count
    @count = params[:count]
    if params[:facility].to_i == 0 # All Facilities
      organisation_facilities.each do |facility|
        facility.update!(admission_schedule_list_length: @count)
      end
    else
      @facility = Facility.find_by(id: params[:facility])
      @facility.update_attributes(admission_schedule_list_length: @count)
    end
    render json: { "success": true }
  end

  # Used by Manage Inventory Department in Organisation Settings
  def edit_inventory
    @facility_id = params[:fac_id]
    @inventory_department = Inventory::Department.where(facility_id: @facility_id)
    @all_inventory_department = @inventory_department.pluck(:department_id)
    respond_to do |format|
      format.js {}
    end
  end

  # Used by Manage Inventory Department in Organisation Settings
  def inventory_save
    inventories = params[:inventories]
    facility_id = params[:facility_id]
    Inventory::Department.where(facility_id: facility_id).destroy

    inventories.each do |key, value|
      inventory = Inventory::Department.where(department_id: key, facility_id: facility_id).first
      next if inventory

      new_inventory = Inventory::Department.new
      new_inventory.facility_id = facility_id
      new_inventory.department_id = key
      new_inventory.display_name = value
      new_inventory.name = value

      new_inventory.save!
    end
    @facilities = current_user.organisation.facilities.where(is_active: true)
  end

  # Used in Facility Settings SMS
  def save_query_number
    phone_number = params[:number]
    @organisation = Organisation.find_by(id: current_user.organisation_id)
    @organisation.update!(query_contact: phone_number)
  end

  # Used in Facility Settings SMS
  def edit_query_number
    @phone_number = params[:number]
  end

  # Used somewhere in SMS
  def set_facility_settings
    @sms_type = {
      'visit' => 'Visit Ack', 'followup' => 'Followup', 'birthday' => 'Birthday', 'long_overdue' => 'Long Overdue',
      'appointment' => 'Appointment', 'missed' => 'Missed', 'discharge' => 'Discharge', 'campaign' => 'Campaign'
    }

    user_id = params[:user_id]
    facility_id = params[:facility_id]

    if facility_id.present?
      status = params[:sms_active_inactive] == 'true'
      type = params[:type]
      @facility = Facility.includes(:users).find_by(id: facility_id)
      @facility_doctors = @facility.users.where(:role_ids.in => [158965000], is_active: true)

      @facility_setting = save_facility_setting(@facility, user_id, status, type)
    else
      head :ok
    end
  end

  # Used by Manage Facility Settings in Organisation Settings
  def hide_referral_note
    hide_referral_note = params[:hide_referral_note]
    if params[:facility] == '0' # All Facility
      organisation_facilities.each do |facility|
        facility.update!(hide_referral_note: hide_referral_note)
      end
    else
      @facility = Facility.find_by(id: params[:facility])
      @facility.update_attributes(hide_referral_note: hide_referral_note)
    end

    render json: { "success": true }
  end

  private

  def organisation_params
    params.require(:organisation).permit(
      :name, :tagline, :address1, :address2, :city, :state, :pincode, :country_id, :telephone, :fax, :website, :email, :enable_region, :enable_entity_group,
      :pan_no, :st_no, :logo, :district, :commune, :sms_contact_number, :whatsapp_number, :number_format, :mandatory_opd_templates, :auto_offline_on_logout, :assign_patients_to_offline_user, :clear_my_queue_before_offline, :assign_patients_to_ot_user, :clear_my_queue_before_ot, currency_ids: []
    )
  end

  def find_organisation
    @organisation = Organisation.includes(:organisations_setting).find_by(id: params[:id])
    @organisations_setting = @organisation.organisations_setting
    @countries = Country.all
    @available_specialties = Specialty.where(:id.in => @organisation.specialty_ids).pluck(:name)
    @ip_status_val = Redis::Master.new.get("organisation:#{@organisation.id}:ip-whitelisting-enabled")
  end

  def count_ip_address
    facilities = Facility.where(organisation_id: current_user.organisation_id, is_active: true)
    @has_ip_addres_count = 0
    @has_not_ip_addres_count = 0
    @restrcited_user_count = 0
    @non_restrcited_user_count = 0
    facilities.each do |facility|
      if facility.ip_address.present?
        @has_ip_addres_count += 1
      else
        @has_not_ip_addres_count += 1
      end
    end
    admin_users = ['158965000,6868009', '158965000', '158965000,160943002', '6868009', '160943002']
    users = User.where(organisation_id: current_user.organisation_id, is_active: true)
    users.each do |user|
      unless admin_users.include? user.role_ids.join(',')
        if user.is_open_access_enabled
          @non_restrcited_user_count += 1
        else
          @restrcited_user_count += 1
        end
      end
    end
  end

  def organisation_facilities
    organisation_facilities = Facility.where(organisation_id: current_facility.organisation_id)

    organisation_facilities
  end

  # Onboarding Stuff
  def org_onboarding_params
    params.require(:organisation).permit(
      :id, :name, :logo, :tagline, :identifier_prefix, :type, :type_id, :website, :email, :customised_letter_head,
      :customised_footer, :address, :telephone, :fax, :footer_text, :onboarding_completed,
      letter_head_customisations: [
        :header_height, :footer_height, :left_margin, :right_margin, :logo_location, :header_location,
        :left, :right, :header
      ]
    )
  end

  def save_org_basic_details_params
    params.require(:organisation).permit(
      :id, :name, :logo, :tagline, :address1, :address2, :city, :state, :pincode, :website, :email, :telephone, :fax, :district, :commune,
      :pan_no, :st_no, :identifier_prefix, :type, :type_id
    )
  end

  def save_org_general_settings_params
    params.require(:organisation).permit(
      :id, :customised_letter_head, :customised_footer, :footer_text, :identifier_prefix, :account_no,
      letter_head_customisations: [
        :header_height, :footer_height, :left_margin, :right_margin, :logo_location, :header_location,
        :left, :right, :header
      ]
    )
  end

  def onboarding_complete_params
    params.require(:organisation).permit(:id, :onboarding_completed)
  end

  def missing_nested_hash_variables
    Hash.new do |hash, key|
      hash[key] = missing_nested_hash_variables
    end
  end

  def facility_update_params
    params.require(:organisation).permit(:name, :city, :state, :pincode, :telephone, :fax, :email, :district, :commune)
  end

  def save_facility_setting(facility, user_id, type, status)
    facility_setting = facility.facility_setting
    case type
    when 'facility'
      facility_setting.sms_feature = status
    when 'user'
      facility_setting.user_sms_feature[user_id]['sms_feature'] = status
    when 'user_personal'
      facility_setting.user_sms_feature[user_id]['personilized_sms'] = status
    when 'visit'
      facility_setting.visit_sms_active_inactive = status
    when 'followup'
      facility_setting.followup_sms_active_inactive = status
    when 'long_overdue'
      facility_setting.long_overdue_sms_active_inactive = status
    when 'missed'
      facility_setting.missed_sms_active_inactive = status
    when 'appointment'
      facility_setting.appointment_sms_active_inactive = status
    when 'discharge'
      facility_setting.discharge_sms_active_inactive = status
    when 'birthday'
      facility_setting.birthday_sms_active_inactive = status
    end
    facility_setting.save!

    facility_setting
  end

  def update_log_history(organisation)
    action = params[:is_ip_whitelisted] == 'true' ? 'Enabled' : 'Disabled'
    all_roles = Global.send('user_roles')
    role_arr = []
    current_user.role_ids.each do |role_id|
      role = all_roles[role_id.to_s]
      role_arr << all_roles[role_id.to_s]['label'] if role.present?
    end
    organisation.organisation_log_trail.create!(action_taken: action, user_id: current_user.id,
                                                user_name: current_user.fullname, user_role: role_arr.join(' & '))
  end
end
