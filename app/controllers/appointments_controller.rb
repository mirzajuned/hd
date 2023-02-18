# rubocop:disable all
class AppointmentsController < ApplicationController
  before_action :authorize
  before_action :find_appointment, only: [:edit, :update, :update_appointment_type]
  before_action :find_patient, only: [:new]
  before_action :get_appointment_form_values, only: [:edit]
  before_action :occupation_name, only: [:new]
  after_action :prepare_sms, only: [:create]
  after_action :prepare_mis_job, only: [:create, :update, :update_appointment_type]

  def new
    @patient_type = PatientType.where(is_active: true, organisation_id: current_user.organisation_id).pluck(:label, :id)

    @past_appointment = AppointmentListView.where(patient_id: @patient.try(:id), :appointment_date.lt => Date.current, :current_state.nin => ['Deleted', 'Scheduled']).order(appointment_date: :desc)
    @existing_appointment = AppointmentListView.find_by(patient_id: @patient.try(:id), appointment_date: Date.current, facility_id: current_facility.id, current_state: 'Scheduled')

    @appointment = Appointment.new
    get_appointment_form_values

    @type = params[:type]
    if @type == "walkin"
      @appointment_label = 'OP'
    else
      @appointment_label = 'Appointment'
    end
    @referral_types = ReferralType.where(is_active: true, :id.nin => ['FS-RT-0009'])
    @patient_referral_type = PatientReferralType.find_by(appointment_id: @appointment.try(:id))
    if params[:patient_origin] == 'camp'
      @camp_referral_type_id = params[:patient_referral_type][:referral_type_id]
      camp_unique_id = CampPatient.find_by(id: params[:camp_patient_id]).camp_username
      @sub_referral = SubReferralType.where(camp_unique_id: camp_unique_id).pluck(:id, :name).flatten
    end
    @initial_referral_type = PatientReferralType.where(patient_id: @patient.try(:id), is_deleted: false).order(created_at: :asc)[0]

    @organisation_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)

    @case_sheets = CaseSheet.where(patient_id: params[:patient_id], is_active: true)
    @case_sheet = @case_sheets.find_by(specialty_id: @selected_specialty)
    @occupation_list = Global.send('occupation_list').send('sets').pluck(:name, :snomedcode)
  end

  def create
    # Create/Update Patient
    if params[:appointment][:patient_id].present?
      @patient = Patients::UpdateService.call(params[:appointment][:patient_id], params, current_user) # Call Patient UpdateService
    else
      @patient = Patients::CreateService.call(params, current_user, current_facility) # Call Patient CreateService
    end
    # Create New Appointment
    if @patient
      @appointment = Appointment::CreateService.call(params[:appointment], current_user, @patient, current_facility)

      if @appointment
        communication_notification_trigger
        # Patient Referral
        if params[:patient_referral_type].present? && params[:patient_referral_type][:referral_type_id].present?
          create_patient_referral

          analytics_params = {}
          analytics_params['appointment_id'] = @appointment.id.to_s
          analytics_params['patient_referral_id'] = @patient_referral_type.id.to_s
          Analytics::CreateService.call(analytics_params.to_json, nil, @appointment.facility_id.to_s, 'patient_referral_type')
        end

        facility_setting = FacilitySetting.find_by(facility_id: current_facility.id)
        @queue_management_present = facility_setting.try(:queue_management)

        if current_facility.clinical_workflow # Workflow
          @url = '/opd_clinical_workflow/patient_arrived'
          # redirect_to opd_clinical_workflow_patient_arrived_path(appointment_id: @appointment.id)
        else # Non-Workflow
          @url = '/opd_clinical_workflow/mark_as_arrived'
          # redirect_to opd_clinical_workflow_mark_as_arrived_path(id: @appointment.id.to_s, appointment_id: @appointment.id.to_s, patient_arrived: true)
        end

        respond_to do |format|
          format.js { render 'appointments/create' }
        end
        CaseSheet::CreateAppointmentService.call(@patient, @appointment, current_user, params[:case_sheet])
        # Procedure Data Job
        MisJobs::Clinical::PatientProcedureJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@appointment.case_sheet_id.to_s, @appointment.id.to_s, "appointment")
      else
        render 'new'
      end
    end
  end

  def edit
    params[:patient_id] = @appointment.patient_id
    @case_sheets = CaseSheet.where(patient_id: params[:patient_id], is_active: true)
    @case_sheet = @case_sheets.find_by(specialty_id: @selected_specialty)
    @organisation_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @type = @appointment.try(:appointmenttype)
    @past_appointment = AppointmentListView.where(patient_id: params[:patient_id], :appointment_date.lt => Date.current, :current_state.nin => ['Deleted', 'Scheduled']).order(appointment_date: :desc)
    if @type == "walkin"
      @appointment_label = 'OP'
    else
      @appointment_label = 'Appointment'
    end
  end

  def update
    params[:appointment][:patient_id] = @appointment.patient_id.to_s
    @patient = @appointment.patient
    @past_appointment = @appointment

    past_facility_id = @past_appointment.facility_id
    past_specialty_id = @past_appointment.specialty_id
    past_appointmentdate = @past_appointment.appointmentdate
    past_appointment_type_id = @past_appointment.appointment_type_id
    past_appointment_category_id = @past_appointment.appointment_category_id
    past_appointmenttype = @past_appointment.appointmenttype

    # params set for update job
    set_update_analytics_params

    params[:appointment][:scheduling_time] = params[:appointment][:start_time]
    params[:appointment][:scheduling_date] = params[:appointment][:start_time]
    if @appointment.update_attributes(appointment_params)
      update_extra_workflows

      respond_to do |format|
        format.js { render 'appointments/update' }
      end
      # create/update daily report through service
      # Reports::Opd::Appointment.call(@appointment)

      # case when appointment_type changes
      if past_appointment_type_id != @appointment.appointment_type_id
        Analytics::Appointment::UpdateService.update_appointment_type_count(@appointment.id, past_appointment_type_id, past_facility_id, past_specialty_id, past_appointmentdate)
      end
      if past_appointment_category_id != @appointment.appointment_category_id
        Analytics::Appointment::UpdateService.update_appointment_category_type_count(@appointment.id, past_appointment_category_id, past_facility_id, past_specialty_id, past_appointmentdate)
      end

      if past_appointmenttype != @appointment.appointmenttype
        Analytics::Appointment::UpdateService.update_walkin_appointment_type_count(@appointment.id, past_facility_id, past_specialty_id, past_appointmentdate, past_appointmenttype)
      end

      if (past_facility_id != @appointment.facility_id) || (past_appointmentdate != @appointment.appointmentdate)
        Analytics::UpdateService.call(@analytics_params.to_json, nil, @appointment.facility_id.to_s, 'patient_referral_type')
        Analytics::Appointment::UpdateService.update_appointment_created_count(@appointment.id, past_facility_id, past_appointmentdate, past_specialty_id)
      end
      CaseSheet::CreateAppointmentService.call(@patient, @appointment, current_user, params[:case_sheet])

      Patients::Summary::TimelineWorker.call({ event_name: 'OPD_APPOINTMENT', sub_event_name: 'EDITED', appointment_id: @appointment.id, user_id: current_user.id, user_name: current_user.fullname, workflow: current_facility.clinical_workflow })
      # Procedure Data Job
      MisJobs::Clinical::PatientProcedureJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@appointment.case_sheet_id.to_s, @appointment.id.to_s, "appointment")
    else
      redirect_to 'edit'
    end
  end

  def get_facility_specialties
    facility = Facility.find_by(id: params[:facility_id])
    specialties = Specialty.where(:id.in => facility.specialty_ids & current_user.specialty_ids)

    render json: specialties.to_json
  end

  def get_users_from_specialty
    facility = Facility.find_by(id: params[:facility_id])
    @available_consultant = User.where(facility_ids: params[:facility_id], :role_ids.in => facility['consultant_role_ids'], specialty_ids: params[:specialty_id], is_active: true).pluck('fullname', 'id')
    @facility_country_id = facility.country_id
    @available_consultant.map do |u|
      u << UserTimeSlot.find_by(user_id: u[1])&.calendar_duration
      u << UserState.find_by(facility_id: params[:facility_id], user_id: u[1]).active_state if facility.show_user_state
    end
    render json: @available_consultant.to_json
  end

  def get_appointment_types_from_facility
    # changed now appointment types are based on facility instead of user
    facility_id = params.present? && params[:facility_id].present? ? params[:facility_id] : current_facility.id
    @appointment_types = AppointmentType.where(facility_id: facility_id, specialty_ids: params[:specialty_id], is_active: true).pluck('label', 'id', 'is_default', 'comment')

    render json: @appointment_types.to_json
  end

  def get_organisation_sub_appointment_types

    selected_org_app_type_id = AppointmentType.find_by(id: params[:appointment_type_id].to_s).try(:organisation_appointment_type).try(:id).to_s
    appointment_types = OrganisationAppointmentCategoryType.where(organisation_id: current_user.organisation_id,
                                                                  specialty_ids: params[:specialty_id], is_active: true,
                                                                  organisation_appointment_type_ids: selected_org_app_type_id).pluck(:label, :id)
    render json: appointment_types.to_json
  end

  def get_available_slots
    @selected_facility = params[:facility_id]
    @selected_doctor = params[:doctor_id]
    @current_date = if params[:current_date].present?
                      Date.parse(params[:current_date])
                    else
                      Date.current
                    end

    @holiday = HolidayPlan.where(user_id: @selected_doctor)
    @appointments = Appointment.where(appointmentdate: @current_date, consultant_id: @selected_doctor, facility_id: @selected_facility, specialty_id: params[:specialty_id], appointmentstatus: 416774000)
  end

  def update_appointment_type
    appointment_type_id = params[:appointment_type_id]
    appointmenttype     = params[:appointmenttype]
    if appointmenttype.blank?
      appointmenttype = @appointment.try(:appointmenttype)
    end
    appointment_category_id = params[:appointment_category_id]
    if appointment_type_id.present?
      # for analytics data
      @appointment.update(appointment_type_id: appointment_type_id, appointmenttype: appointmenttype, appointment_category_id: appointment_category_id)
    end

    if params[:mark_arrived] == 'true'
      @clinical_workflow_present = current_facility.clinical_workflow

      if @clinical_workflow_present
        facility_id = current_facility.id
        if current_facility_setting.queue_management
          sub_station_options = if current_facility_setting&.user_set_station
                                  { active_user_id: current_user.id, facility_id: facility_id, is_deleted: false }
                                else
                                  { user_id: current_user.id, facility_id: facility_id, is_deleted: false }
                                end
          @user_station = QueueManagement::SubStation.find_by(sub_station_options)

          if @user_station.present?
            redirect_to opd_clinical_workflow_patient_arrived_path(appointment_id: @appointment.id.to_s,
                                                                   to_station: @user_station.id, format: :js)
          else
            head :ok
          end
        else
          redirect_to opd_clinical_workflow_patient_arrived_path(appointment_id: @appointment.id.to_s, format: :js)
        end
      else # for non-workflow
        redirect_to opd_clinical_workflow_mark_as_arrived_path(id: @appointment.id, appointment_id: @appointment.id, patient_arrived: true, format: :js)
      end
    else
      head :ok
    end
  end

  def consultancy_types
    @appointment = Appointment.find_by(id: params[:appointment_id])

    @past_appointments = params[:past_appointment_ids].present? ? AppointmentListView.where(:id.in => params[:past_appointment_ids].split(',')).order(appointment_date: :desc).limit(5) : []

    @past_appointment_fields = @past_appointments.map do |appt|
      { appointment_date: appt.appointment_date, consulting_doctor: appt.consulting_doctor,
        appointment_type: appt.appointment_type, appointment_type_color: appt.appointment_type_color,
        consultancy_type: appt.consultancy_type, consultancy_type_reason: appt.consultancy_type_reason }
    end
  end

  def save_consultancy_type
    @appointment = Appointment.find_by(id: params[:appointment_id])

    @appointment.set(consultancy_type: params[:consultancy_type], consultancy_type_reason: params[:consultancy_type_reason], consultancy_type_by: params[:consultancy_type_by])

    if params[:token_setting_enabled] == 'true'
      @token_setting = TokenSetting.find_by(facility_id: current_facility.id.to_s)
      redirect_to token_settings_show_tokens_path(token_setting_id: @token_setting.id.to_s,
                                                  appointment_id: @appointment.id, to_station: params[:to_station])
    else
      if current_facility.clinical_workflow # Workflow
        redirect_to opd_clinical_workflow_patient_arrived_path(appointment_id: @appointment.id,
                                                               to_station: params[:to_station])
      else # Non-Workflow
        redirect_to opd_clinical_workflow_mark_as_arrived_path(id: @appointment.id.to_s, appointment_id: @appointment.id.to_s, patient_arrived: true)
      end
    end
  end

  def print
    @organisation = current_facility.organisation
    @facility = current_facility
    @datepicker_date = Date.parse(params[:appointmentdate])
    @appointment = Appointment.where(appointmentdate: @datepicker_date, appointmentstatus: '416774000', facility_id: @facility.id, current_state: params[:list_type]).order('start_time ASC')
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render template: 'appointments/print', pdf: 'AdmissionList', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', orientation: 'landscape', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def call_patient
    patient = Patient.find_by(id: params[:id])

    url = 'https://fcm.googleapis.com/fcm/send'
    if patient.mobilenumber == '9742332503'
      device_token = 'cG-DqlLTrh8:APA91bGKkXTdMrjJiKxZErM4xrlTfoGFcSgO373z1gtInz5IDjm3nOatR95u_b30wAnrAvZyvCNJ441QBTYDGQazv62FGO9HziMthW7NursKB3Dna7lIuvZoQacRQryjxIavIjAfL__c'
    elsif patient.mobilenumber == '7975989664'
      device_token = 'fpJj9j5BHaQ:APA91bElxNsu0KcIlFpyY5eIrv6gQIudC_PvaryzRhRFaSwd88a-lZDoeILjCMEtZoJ6y_BmBtW7I8rjILyN2E_Uorv8QUKvZsGdhYSeNyhHyDg2WpHVvKGGytMmiVKGJS1HfaaRUEa4'
    else
      device_token = ['cG-DqlLTrh8:APA91bGKkXTdMrjJiKxZErM4xrlTfoGFcSgO373z1gtInz5IDjm3nOatR95u_b30wAnrAvZyvCNJ441QBTYDGQazv62FGO9HziMthW7NursKB3Dna7lIuvZoQacRQryjxIavIjAfL__c', 'fpJj9j5BHaQ:APA91bElxNsu0KcIlFpyY5eIrv6gQIudC_PvaryzRhRFaSwd88a-lZDoeILjCMEtZoJ6y_BmBtW7I8rjILyN2E_Uorv8QUKvZsGdhYSeNyhHyDg2WpHVvKGGytMmiVKGJS1HfaaRUEa4'].sample
    end
    title = patient.fullname.to_s
    message = 'Please come to Room 101'
    image = 'http://www.eye7.in/wp-content/uploads/eye7logo-nabh.png' # "https://images1-fabric.practo.com/practices/1147987/centre-for-sight-hyderabad-5947b0c01b168.jpg"
    authorize_key = 'key=AAAAEHjcFpw:APA91bEqvBExspRF_-wyC_MqsE8jZrxLhPYsW8GjcQpkLnvJUKBUPHn_ThBD1JF5G-vjR-bR1bAjvUQLmvA8jwak_V2n13XQQC0bYVVGbK_PWQ4JTiggFlqbDCmEWEEkPWyYjoBV13zR'
    payload = '{
                "to": "' + device_token + '",
                "sound": "default",
                "data": {
                  "title": "' + title + '",
                  "message": "' + message + '",
                  "image-url": "' + image + '"
                }
              }'

    request = RestClient::Request.execute(method: :post, url: url, payload: payload, headers: { 'Content-Type' => 'application/json', 'Authorization' => authorize_key })

    @response = JSON.parse(request)
    puts @response.to_a
    head :ok
  end

  def prepare_mis_job
    Mis::ClinicalReportsHelper.prepare_mis_job(@appointment.id.to_s) if @appointment.present?
  end

  private

  def set_update_analytics_params
    @analytics_params = {}
    @patient_referral_type = PatientReferralType.find_by(appointment_id: @appointment.id)
    @analytics_params['appointment_id'] = @appointment.id
    @analytics_params['patient_referral_id'] = @patient_referral_type.try(:id)
    @analytics_params['before_referral_type_id'] = (if @patient_referral_type.try(:is_deleted) == false
                                                      @patient_referral_type.try(:referral_type_id)
                                                    end) || nil
    @analytics_params['before_appointment_date'] = @appointment.appointmentdate
    @analytics_params['before_facility_id'] = @appointment.facility_id
  end

  def appointment_params
    params.require(:appointment).permit(:facility_id, :case_sheet_id, :consultant_id, :consultant_frozen, :appointment_type_id, :appointmentdate, :start_time, :patient_id, :specialty_id, :organisation_id, :user_id, :display_id, :created_from, :opd_referral_id, :referral, :referral_created_on, :referring_doctor, :referee_doctor, :to_facility_name, :from_facility_name, :referral_note, :facility_appointment_type_id, :appointment_category_id, :appointmenttype, :scheduling_time)
  end

  def find_appointment
    @appointment = Appointment.find(params[:id])
    @appointment_list_view = AppointmentListView.find_by(appointment_id: params[:id])
  end

  def find_patient
    @camp_patient = CampPatient.find_by(id: params[:camp_patient_id])

    if params[:patient_origin].present?
      if @camp_patient.converted == true
        @patient = Patient.find_by(id: @camp_patient.patient_id)
      else
        make_patient_from_camp_patient
      end
    else
      @patient = Patient.find_by(id: params[:patient_id]) || Patient.new
    end
    @patient_location = Location.find_by(id: @patient.try(:location_id))
    @area_details = ['', '']
    if @patient_location.present?
      @area_details = @patient_location.area_managers.pluck(:area_name, :_id)
    end
  end

  def make_patient_from_camp_patient
    camp_patient = @camp_patient
    get_age_data
    @patient = Patient.new(
      address_1: camp_patient.address1,
      address_2: camp_patient.address2,
      age: camp_patient.age.to_i,
      dob: camp_patient.dob,
      dob_day: @dob_day,
      dob_month: @dob_month,
      dob_year: @dob_year,
      is_approx_dob: @is_approx_dob,
      fullname: camp_patient.fullname,
      firstname: camp_patient.fullname,
      gender: camp_patient.gender,
      mobilenumber: camp_patient.phone_number,
      city: camp_patient.city,
      district: camp_patient.district,
      commune: camp_patient.commune,
      camp_patient_identifier: camp_patient.camp_patient_identifier,
      camp_patient_id: camp_patient.id
    ) || Patient.new
  end

  def get_age_data
    @camp_patient.age.present? && @camp_patient.dob.blank?
    @dob_day = Date.current.day
    @dob_year = Date.current.year - @camp_patient.age.to_i
    @dob_month = Date.current.month
    @is_approx_dob = true
  end

  def occupation_name
    if @patient.occupation.present?
      occupation_list = Global.send('occupation_list').send('sets')
      occupation_hash = occupation_list.find { |x| x[:snomedcode] == @patient&.occupation }
      @occupation_name = occupation_hash.present? ? occupation_hash[:name] : @patient.occupation
    end
  end

  def get_appointment_form_values
    @current_user = current_user
    @current_date = @appointment.appointmentdate || Date.parse(params[:date]) || Date.current
    @current_time = @appointment.start_time || Time.zone.parse(params[:time]) || Time.current
    @selected_facility = @appointment.facility_id || params[:facility_id] || current_facility.id
    @selected_doctor = @appointment.consultant_id || params[:doctor_id] || (if (@current_user.role_ids.include?(158965000) || @current_user.role_ids.include?(28229004)) && @current_user.facility_ids.map(&:to_s).include?(@selected_facility.to_s) then @current_user.id end) || User.where(:role_ids.in => current_facility['consultant_role_ids'], facility_ids: @selected_facility, is_active: true)[0].id
    facility = Facility.find_by(id: @selected_facility)
    @facility_country_id = facility.country_id
    @available_specialties = Specialty.where(:id.in => facility.specialty_ids & @current_user.specialty_ids).pluck(:name, :id).sort
    @selected_specialty = @appointment.specialty_id || if @available_specialties.present? then @available_specialties.first[1] end || ''
    @available_consultant = User.where(facility_ids: @selected_facility, :role_ids.in => current_facility['consultant_role_ids'], specialty_ids: @selected_specialty, is_active: true).pluck('fullname', 'id')

    @available_consultant.map do |u|
      u << UserTimeSlot.find_by(user_id: u[1])&.calendar_duration
    end
    @available_appointment_types = AppointmentType.where(facility_id: @selected_facility.to_s, specialty_ids: @selected_specialty, is_active: true)
    @available_sub_appointment_types = OrganisationAppointmentCategoryType.where(organisation_id: current_user.organisation_id, specialty_ids: @selected_specialty, is_active: true)

    # @previous_opd_records = PatientTimeline.where(encountertype: "OPD", appointment_id: @appointment.id.to_s, specalityid: @appointment.specialty_id)
  end

  def update_extra_workflows
    @clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
    if @clinical_workflow
      consultant_id = @clinical_workflow.consultant_ids
      consultant_id[0] = @appointment.consultant_id.to_s
      @clinical_workflow.update(facility_id: @appointment.facility_id, appointmentdate: @appointment.appointmentdate, consultant_ids: consultant_id)
    end
    @case_sheet = CaseSheet.find_by(id: @appointment.case_sheet_id)
    @case_sheet.update(specialty_id: @appointment.specialty_id) if @case_sheet.present?
  end

  def remove_assigned_token
    key = "used_tokens:#{@appointment.facility_id}:#{@appointment.appointmentdate.strftime('%d%m%Y')}"
    # @used_tokens = $REDIS.get("used_tokens:#{@appointment.facility_id.to_s}:#{@appointment.appointmentdate.strftime('%d%m%Y')}") || "{}"
    @used_tokens = Redis::Master.new.get(key) || '{}'
    @new_used_tokens = JSON.parse(@used_tokens)
    @new_used_tokens.delete(@appointment.token_number)

    # $REDIS.set("used_tokens:#{@appointment.facility_id.to_s}:#{@appointment.appointmentdate.strftime('%d%m%Y')}", @new_used_tokens.to_json)
    Redis::Master.new.set(key, @new_used_tokens.to_json)
    Redis::Master.new.expireat(key, ((Date.current + 1).to_time + 2.hours).to_i)

    if @appointment.appointmentdate == Date.current
      @token_setting.update(used_tokens: @new_used_tokens)
    end # If Old Appointment is Marked Not Arrived
    @appointment.update(token_number: nil)
  end

  def create_patient_referral
    # Create SubReferral, Case: Relative, Self
    if params[:sub_referral_type].present?
      params[:sub_referral_type][:referral_type_id] = params[:patient_referral_type][:referral_type_id]
      params[:sub_referral_type][:facility_ids] = Facility.where(organisation_id: current_user.organisation_id).pluck(:id)
      if params[:sub_referral_type][:referral_type_id] == 'FS-RT-0001'
        @sub_referral_type = SubReferralType.find_by(referral_type_id: 'FS-RT-0001', organisation_id: current_user.organisation_id) # Case Self
      end
      unless @sub_referral_type.present?
        @sub_referral_type = SubReferralType.new(sub_referral_type_params)
        @sub_referral_type.save!
      end
      params[:patient_referral_type][:sub_referral_type_id] = @sub_referral_type.try(:id).to_s
    end
    if params[:patient_referral_type][:sub_referral_type_id].present?
      # Create PatientReferral Params
      params[:patient_referral_type][:patient_id] = @patient.id.to_s
      params[:patient_referral_type][:appointment_id] = @appointment.id.to_s
      params[:patient_referral_type][:facility_id] = @appointment.facility_id.to_s
      params[:patient_referral_type][:organisation_id] = @appointment.organisation_id.to_s

      # Create PatientReferral
      @patient_referral_type = PatientReferralType.new(patient_referral_type_params)
      @patient_referral_type.save!
    end
  end

  def sub_referral_type_params
    params.require(:sub_referral_type).permit(:is_active, :existing_patient, :name, :mobile_number, :email, :relation, :comment, :facility_ids, :user_id, :referral_type_id, :organisation_id)
  end

  def patient_referral_type_params
    params.require(:patient_referral_type).permit(:referral_type_id, :sub_referral_type_id, :patient_id, :appointment_id, :facility_id, :organisation_id)
  end

  def prepare_sms
    SmsJob.perform_later('appointment_sms', @appointment.id.to_s, @appointment.class.to_s)
  end

  def communication_notification_trigger
    CommunicationNotificationJob.perform_now('appointment_scheduled', @appointment.id.to_s, @appointment.class.to_s)
    # CommunicationNotificationJob.perform_now('appointment_walkin', @appointment.id.to_s, @appointment.class.to_s) if @appointment.appointmenttype == "walkin"
  end
end
