class OutpatientsController < ApplicationController
  layout 'loggedin'

  before_action :authorize
  before_action :authorize_onboard
  before_action :validate_user_permission
  before_action :set_session_params
  before_action :initial_params, only: [:appointment_management, :appointment_scheduler, :get_appointment_lists]
  before_action :appointment_list_params, only: [:get_appointment_lists]
  before_action :details_view_params, only: [:appointment_details]

  #################### All Actions Related to appointment List View ####################
  # Initialize appointment List View
  def appointment_management; end

  # Get appointment List LHS
  def get_appointment_lists
    respond_to do |format|
      format.js { render 'outpatients/appointment/sidebar_summary' }
    end
  end

  #################### All Actions Related to appointment Calender View ####################
  # Initialize appointment Calender
  def appointment_scheduler; end

  # Get Data for Calendar
  def appointment_calendar_data
    date_range = Date.parse(params[:start])..(Date.parse(params[:end]) - 1)

    options = { facility_id: current_facility.id, :current_state.ne => 'Deleted', appointment_date: date_range,
                :appointment_type.ne => nil }

    if params[:doctor_id].present? && params[:doctor_id] != 'all'
      options = options.merge(consulting_doctor_id: params[:doctor_id])
    end

    @appointment_list = AppointmentListView.where(options).order(appointment_start_time: :desc)

    respond_to do |format|
      format.json { render 'outpatients/appointment/appointment_calendar_data' }
    end
  end

  # Get appointment Details RHS - Common for List & Calender Views
  def appointment_details
    respond_to do |format|
      format.js { render 'outpatients/appointment/appointment_details' } # List
      format.html { render 'outpatients/appointment/appointment_details', layout: false } # Calendar
    end
  end

  # Get provisional appointment Details RHS - Common for List & Calender Views
  def provisional_appointment_details
    @provisional_appointment = ProvisionalAppointment.find_by(id: params[:appointment_id])

    respond_to do |format|
      format.js { render 'outpatients/appointment/provisional_appointment_details' } # List
      format.html { render 'outpatients/appointment/provisional_appointment_details', layout: false } # Calendar
    end
  end

  # investigation_details data on click
  def investigation_details
    @patient_id = params[:patient_id]
    @patient = Patient.find_by(id: @patient_id)
    @appointment = Appointment.find_by(id: params[:appointment_id])

    @current_date = if params[:current_date].present?
                      Date.parse(params[:current_date])
                    else
                      @appointment.try(:appointmentdate) || Date.current
                    end

    @counsellors = GetUsers.workflow_users_dropdown(@current_facility.id, [@appointment.specialty_id], 499992366)
    @patient_investigation_queue = Investigation::Queue.where(patient_id: @patient_id.to_s, facility_id: @appointment.facility_id, appointment_date: Date.current)
    @patient_investigation = Investigation::InvestigationDetail.where(patient_id: @patient_id, is_deleted: false, '$or' => [{ :state.nin => ['removed', 'performed', 'template_created'] }, { date_performed_at: @current_date }, { date_removed_at: @current_date }]).order(advised_at: :desc)
    @inv_ophthal = @patient_investigation.where(patient_id: @patient_id, _type: 'Investigation::Ophthal')
    @inv_laboratory = @patient_investigation.where(patient_id: @patient_id, _type: 'Investigation::Laboratory')
    @inv_radiology = @patient_investigation.where(patient_id: @patient_id, _type: 'Investigation::Radiology')
    @investigation_present = (true if @patient_investigation.count > 0) || false
    @uploads = PatientSummaryAssetUpload.where(:investigation_detail_id.in => @patient_investigation.pluck(:id).map(&:to_s), is_deleted: false)

    organisations_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @disable_default_investigation = organisations_setting.try(:disable_default_investigation)

    respond_to do |format|
      format.js { render 'outpatients/appointment/investigation_details' }
    end
  end

  # for loading previous states of workflow
  def load_prev_states
    @clinical_workflow_timeline = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: params[:workflow_id]).order_by('created_at ASC')
    @clinical_workflow_timeline_count = 1
    @clinical_workflow_present = true
    facility_setting = FacilitySetting.find_by(facility_id: current_facility.id)
    @queue_management_present = facility_setting.queue_management

    respond_to do |format|
      format.js { render 'outpatients/appointment/appointment_details/load_prev_states' }
    end
  end

  # search in list view
  def search_appointment_lists
    if params[:q].present?
      @appointment_list = OpdClinicalWorkflow.where(appointmentdate: params[:current_date], facility_id: @current_facility.id.to_s, :state.nin => ['cancelled'], :patient_name => /#{Regexp.escape(params[:q])}/i).order('start_time DESC').limit(15)

      available_specialties = Specialty.where(:id.in => @current_user.specialty_ids & current_facility.specialty_ids)
      specialty = params[:specialty_id] == 'all_specialties' ? available_specialties.pluck(:id) : [params[:specialty_id]]
      @appointment_list = @appointment_list.where(:specialty_id.in => specialty)
    end

    respond_to do |format|
      format.json { render 'outpatients/appointment/search_appointment_list' }
    end
  end

  # Refresh Investigation
  def refresh_investigation
    @appointment = Appointment.find_by(id: params[:appointment_id])
    @counsellors = User.where(facility_ids: @current_facility.id, is_active: true, role_ids: 499992366, specialty_ids: @appointment.specialty_id)
    @patient = Patient.find_by(id: params[:patient_id])
    @current_date = Date.parse(params[:current_date]) if params[:current_date] || Date.current

    # Lab Tests
    options = { patient_id: @patient.id, is_deleted: false }

    unless params[:show_all] && params[:show_all] == 'true'
      options = options.merge('$or' => [{ :state.nin => ['removed', 'performed', 'template_created'] },
                                        { date_performed_at: @current_date },
                                        { date_removed_at: @current_date }])
    end

    @patient_investigation = Investigation::InvestigationDetail.where(options).order(advised_at: :desc)

    @uploads = PatientSummaryAssetUpload.where(:investigation_detail_id.in => @patient_investigation.pluck(:id).map(&:to_s), patient_id: @patient.id, is_deleted: false)
    @inv_ophthal = @patient_investigation.where(_type: 'Investigation::Ophthal')
    @inv_radiology = @patient_investigation.where(_type: 'Investigation::Radiology')
    @inv_laboratory = @patient_investigation.where(_type: 'Investigation::Laboratory')
    @investigation_present = (true if @patient_investigation.count > 0) || false

    @patient_uploads = PatientSummaryAssetUpload.where(patient_id: @patient.id, is_deleted: false)
                                                .order(reported_date: :desc)

    respond_to do |format|
      format.js { render 'outpatients/appointment/investigation_details/refresh_investigation' }
    end
  end

  def alert_investigation
    @patient = Patient.find_by(id: params[:patient_id])
    @queue = Investigation::Queues::CreateService.call(@patient, 'radiology', @current_user, @current_facility, Time.current)
    @queue = Investigation::Queues::CreateService.call(@patient, 'laboratory', @current_user, @current_facility, Time.current)
    if params[:specialty_id] == '309988001'
      @queue = Investigation::Queues::CreateService.call(@patient, 'ophthal', @current_user, @current_facility,
                                                         Time.current)
    end
    # respond_to do |format|
    #   format.js{render js: "notice = new PNotify({ title: 'Warning', text: 'No performed Investigations', type: 'error' }); notice.get().click(function(){ notice.remove() });"}
    # end
    head :ok
  end

  def load_users
    facility_id = current_facility.id

    @selected_specialty = params[:specialty_id] || 'all_specialties'
    if @selected_specialty == 'all_specialties'
      specialty_ids = current_user.specialty_ids & current_facility.specialty_ids
      specialty = Specialty.where(:id.in => specialty_ids).pluck(:id)
    else
      [@selected_specialty]
    end

    @current_date = params[:current_date]
    @active_user = params[:active_user]

    load_users_list(facility_id, specialty)
  end

  def filter_procedures
    @case_sheets = CaseSheet.where(patient_id: params[:patient_id])
    @procedures = @case_sheets.map(&:procedures).flatten.reverse

    @procedures.select! { |procedure| procedure.advised_by == params[:advised_by] } if params[:advised_by]

    if params[:advised_on]
      advised_on = Date.parse(params[:advised_on])
      @procedures.select! do |procedure|
        procedure.advised_datetime.between?(advised_on.beginning_of_day, advised_on.end_of_day)
      end
    end

    if params[:performed_on]
      performed_on = Date.parse(params[:performed_on])
      @procedures.select! do |procedure|
        procedure.performed_datetime.between?(performed_on.beginning_of_day, performed_on.end_of_day)
      end
    end

    respond_to do |format|
      format.js { render 'outpatients/appointment/appointment_details/tab_details/procedures/filter.js.erb' }
    end
  end

  def filter_diagnoses
    @case_sheets = CaseSheet.where(patient_id: params[:patient_id])
    @diagnoses = @case_sheets.map(&:diagnoses).flatten.reverse

    @diagnoses.select! { |diagnosis| diagnosis.advised_by == params[:advised_by] } if params[:advised_by]

    if params[:advised_on]
      advised_on = Date.parse(params[:advised_on])
      @diagnoses.select! do |diagnosis|
        diagnosis.advised_datetime.between?(advised_on.beginning_of_day, advised_on.end_of_day)
      end
    end

    respond_to do |format|
      format.js { render 'outpatients/appointment/appointment_details/tab_details/diagnoses/filter.js.erb' }
    end
  end

  def filter_medical_prescriptions
    options = { patient_id: params[:patient_id] }

    options = options.merge(consultant_name: params[:advised_by]) if params[:advised_by]

    if params[:advised_on]
      advised_on = Date.parse(params[:advised_on])
      options = options.merge(prescription_date: advised_on.beginning_of_day..advised_on.end_of_day)
    end

    @medical_prescriptions = PatientPrescription.where(options).order(prescription_datetime: :desc).to_a
    @medical_converted_by_users = User.where(:id.in => @medical_prescriptions.pluck(:mark_converted_by).uniq).to_a

    @medication_instructions = Global.medication_instruction_option.sets

    respond_to do |format|
      format.js { render 'outpatients/appointment/appointment_details/tab_details/medical_prescriptions/filter.js.erb' }
    end
  end

  def filter_optical_prescriptions
    options = { patient_id: params[:patient_id] }

    options = options.merge(consultant_name: params[:advised_by]) if params[:advised_by]

    if params[:advised_on]
      advised_on = Date.parse(params[:advised_on])
      options = options.merge(prescription_date: advised_on.beginning_of_day..advised_on.end_of_day)
    end

    @optical_prescriptions = PatientOpticalPrescription.where(options).order(prescription_datetime: :desc).to_a
    @optical_converted_by_users = User.where(:id.in => @optical_prescriptions.pluck(:mark_converted_by).uniq).to_a

    respond_to do |format|
      format.js { render 'outpatients/appointment/appointment_details/tab_details/optical_prescriptions/filter.js.erb' }
    end
  end

  def filter_uploads
    options = { patient_id: params[:patient_id], is_deleted: false }

    options = options.merge(parent_folder_id: params[:filter]) if params[:filter]

    @patient_uploads = PatientSummaryAssetUpload.where(options).order(reported_date: :desc)

    respond_to do |format|
      format.js { render 'outpatients/appointment/appointment_details/tab_details/uploads/filter.js.erb' }
    end
  end

  ####################  Private Methods ####################
  private

  # Get Current Date & Active User
  def initial_params
    @current_date = if params[:current_date].present? && params[:current_date] != 'Invalid date'
                      Date.parse(params[:current_date])
                    else
                      Date.current
                    end

    specialty_ids = @current_user.specialty_ids & @current_facility.specialty_ids
    @available_specialties = Specialty.where(:id.in => specialty_ids)
    @selected_specialty = params[:specialty_id] || 'all_specialties'

    specialty = if @selected_specialty == 'all_specialties'
                  @available_specialties.pluck(:id)
                else
                  [@selected_specialty]
                end

    users_list(@current_facility.id.to_s, specialty) if params[:action] != 'get_appointment_lists'

    @counsellor = User.where(facility_ids: @current_facility.id, role_ids: 499992366, :specialty_ids.in => specialty, is_active: true)

    @active_user = if params[:active_user].present?
                     params[:active_user]
                   elsif @current_facility.clinical_workflow || @current_user.role_ids[0] == 158965000 # doctor
                     @current_user.id.to_s
                   end
    @active_tab = params[:active_tab]
    @appointment_id = params[:appointment_id]

    @doctors_list = params[:doctors_list] || 'in'
    if @current_facility.clinical_workflow
      @tabs = Global.appointment_tabs.send(@current_user.role_ids[0].to_s)['tab']
      @tabs_classes = Global.appointment_tabs.send(@current_user.role_ids[0].to_s)['tab_classes']
    else
      @tabs = Global.appointment_tabs.non_workflow['tab']
      @tabs_classes = Global.appointment_tabs.non_workflow['tab_classes']
    end

    @paid_for_data = current_organisation['paid_for_data']
    @organisation_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
  end

  def users_list(facility_id, specialty)
    if @current_facility.clinical_workflow && params[:doctors_list] == 'out'
      load_users_list(facility_id, specialty)
    else
      @doctors = User.where(facility_ids: facility_id, is_active: true, role_ids: 158965000,
                            :specialty_ids.in => specialty)
      @doctors = @doctors.sort_by! { |doc| doc.fullname.downcase }
    end
  end

  def load_users_list(facility_id, specialty)
    @doctors = GetUsers.workflow_users_dropdown(facility_id, specialty, 158965000)
    @doctors = @doctors.sort_by! { |doc_name| doc_name[1].downcase }.uniq { |ele| ele[0] }
    @optometrists = GetUsers.workflow_users_dropdown(facility_id, specialty, 28229004)
    @optometrists = @optometrists.sort_by! { |opt_name| opt_name[1].downcase }.uniq { |ele| ele[0] }
    @ar_ncts = GetUsers.workflow_users_dropdown(facility_id, specialty, 28221005)
    @ar_ncts = @ar_ncts.sort_by! { |ar_nct_name| ar_nct_name[1].downcase }.uniq { |ele| ele[0] }
    @receptionists = GetUsers.workflow_users_dropdown(facility_id, specialty, 159561009)
    @receptionists = @receptionists.sort_by! { |rec_name| rec_name[1].downcase }.uniq { |ele| ele[0] }
    @floormanagers = GetUsers.workflow_users_dropdown(facility_id, specialty, 59561000)
    @floormanagers = @floormanagers.sort_by! { |fmgr_name| fmgr_name[1].downcase }.uniq { |ele| ele[0] }
    @cashiers = GetUsers.workflow_users_dropdown(facility_id, specialty, 159562000)
    @cashiers = @cashiers.sort_by! { |cas_name| cas_name[1].downcase }.uniq { |ele| ele[0] }
    @nurses = GetUsers.workflow_users_dropdown(facility_id, specialty, 106292003)
    @nurses = @nurses.sort_by! { |nur_name| nur_name[1].downcase }.uniq { |ele| ele[0] }
    @counsellors = GetUsers.workflow_users_dropdown(facility_id, specialty, 499992366)
    @counsellors = @counsellors.sort_by! { |counc_name| counc_name[1].downcase }.uniq { |ele| ele[0] }
  end

  # Get List Of Appointment
  def appointment_list_params
    @queue_management_present = current_facility_setting.queue_management
    @token_setting = TokenSetting.find_by(facility_id: @current_facility.id)

    specialty = if params[:specialty_id] == 'all_specialties'
                  @available_specialties.pluck(:id)
                else
                  [params[:specialty_id]]
                end

    if @current_facility.clinical_workflow
      @user = User.find_by(id: @active_user)
      @clinical_workflow_present = true

      sort_params = @token_setting.try(:sort_list_by_token) ? 'token_number asc' : 'start_time desc'

      @all_appointment = OpdClinicalWorkflow.where(
        appointmentdate: Date.parse(params[:current_date]), facility_id: current_facility.id.to_s,
        :specialty_id.in => specialty, :state.ne => 'cancelled'
      ).order(sort_params).map(&:itself)

      get_patient_params(@all_appointment.pluck(:patient_id))

      @appointment = @all_appointment.reject { |ocw| ocw[:appointment_type_label].nil? }
      @unassigned = @all_appointment.select { |ocw| ocw[:appointment_type_label].nil? }

      @all = @all_op = @appointment.select { |ocw| ['complete', 'not_arrived'].exclude?(ocw[:state]) }

      sub_station_options = if current_facility_setting&.user_set_station
                              { active_user_id: @active_user, facility_id: current_facility.id, is_deleted: false }
                            else
                              { user_id: @active_user, facility_id: current_facility.id, is_deleted: false }
                            end
      sub_station = QueueManagement::SubStation.find_by(sub_station_options)
      user_station_id = sub_station&.station_id
      area_id = sub_station&.area_id
      primary_department_id = current_user.department_ids[0]

      @scheduled = @appointment.select { |ocw| ocw[:appointmenttype] == 'appointment' }

      @all_op_scheduled_appointment = @all_op.select { |ocw| ocw[:appointmenttype] == 'appointment' }
      # @scheduled = @all_op.select { |ocw| ocw[:appointmenttype] == "appointment" }

      @my_queue = if @active_user == 'all' || @active_user.nil?
                    @all
                  elsif @current_date < Date.current
                    @appointment.select { |ocw| ocw[:state] == 'incomplete' }
                  else
                    @appointment.select do |ocw|
                      if ocw[:user_id].present? && primary_department_id == '485396012'
                        active_user_true = ocw[:user_id] == @active_user
                        [@user&.primary_role, 'check_out', 'call', 'waiting'].include?(ocw[:state]) && active_user_true
                      elsif ocw[:station_id].present? && ocw[:station_id].to_s == user_station_id.to_s && primary_department_id == '485396012'
                        ocw[:state] == 'check_out'
                      elsif ocw[:userless_station] && ocw[:area_id].to_s == area_id.to_s && primary_department_id == '485396012'
                        ocw[:state] == 'check_out'
                      end
                    end
                  end

      @not_arrived = @appointment.select { |ocw| ocw[:state] == 'not_arrived' }

      @not_arrived_scheduled_appointment = @not_arrived.select { |ocw| ocw[:appointmenttype] == 'appointment' }
      @unassigned_scheduled_appointment = @unassigned.select { |ocw| ocw[:appointmenttype] == 'appointment' }

      if @current_user.role_ids.include? 499992366 # counsellor
        # Counsellor Variables
        @completed = @appointment.select { |ocw| ocw[:state] == 'complete' }
        @counsellor = CounsellorWorkflow.where(facility_id: @current_facility.id.to_s, :state.nin => ['deleted'], '$or' => [{ appointmentdate: params[:current_date] }, { counsellingdate: params[:current_date] }, { :counsellingdate.gt => params[:current_date], :state.nin => ['converted', 'cancelled'] }])
        @all_today = @counsellor.where(appointmentdate: params[:current_date]).order('start_time DESC')
        @today = @counsellor.where(appointmentdate: params[:current_date]).order('start_time DESC').select do |c|
          timeline_user_ids = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: OpdClinicalWorkflow.find_by(appointment_id: c.appointment_id).id).last_states.map(&:user_id)
          active_user_id = params[:active_user].blank? ? current_user.id.to_s : params[:active_user]
          c.user_id.to_s == active_user_id || timeline_user_ids.include?(active_user_id)
        end
        @counsellor_appointments = @counsellor.where(counsellingdate: params[:current_date]).order('start_time DESC')
        @followup = @counsellor_appointments.where(state: 'followup')
        @converted = @counsellor_appointments.where(state: 'converted')
        @cancelled = @today.select { |t| t.state == 'cancelled' }
        @upcoming = @counsellor.where(:counsellingdate.gt => params[:current_date], :state.nin => ['converted', 'cancelled']).order('start_time DESC')

        patient_ids = (@appointment.pluck(:patient_id) + @counsellor.pluck(:patient_id)).uniq
        get_patient_params(patient_ids)
      else
        # Clinical-Workflow
        @array = @appointment.pluck(:consultant_ids).map { |i| i[0] }

        if @current_user.role_ids.include?(158965000) || (@user.present? && @user.role_ids.include?(158965000))
          @seen_appointment = @appointment.select { |ocw| ocw[:consultant_ids].include?(@active_user) }
          @seen_today = @seen_appointment.select { |ocw| ['not_arrived', 'complete'].exclude?(ocw[:state]) }
          @seen_today_count = @seen_appointment.count
          @seen_today_not_arrived = @seen_appointment.select { |ocw| ocw[:state] == 'not_arrived' }
          @seen_today_completed = @seen_appointment.select { |ocw| ocw[:state] == 'complete' }
        end
        @completed = @appointment.select { |ocw| ocw[:state] == 'complete' }

        @completed_scheduled_appointment = @completed.select { |ocw| ocw[:appointmenttype] == 'appointment' }

        @referrals = if @current_user.role_ids.any? { |ele| [159561009, 59561000, 159562000].include?(ele) }
                       @appointment.select { |ocw| ocw[:referral] }
                     else
                       @appointment.select { |ocw| ocw[:referral] && ocw[:consultant_ids].include?(@active_user) }
                     end
        if @user.present? && @user.role_ids.include?(28229004)
          @seen_appointment = @appointment.select { |ocw| ocw[:optometrist_ids].include?(@active_user) }
          @seen_today = @seen_appointment.select { |ocw| ['not_arrived', 'complete'].exclude?(ocw[:state]) }
          @seen_today_count = @seen_appointment.count
          @seen_today_not_arrived = @seen_appointment.select { |ocw| ocw[:state] == 'not_arrived' }
          @seen_today_completed = @seen_appointment.select { |ocw| ocw[:state] == 'complete' }
        end
        if @user.present? && @user.role_ids.include?(28221005)
          @seen_appointment = @appointment.select { |ocw| ocw[:ar_nct_ids].include?(@active_user) }
          @seen_today = @seen_appointment.select { |ocw| ['not_arrived', 'complete'].exclude?(ocw[:state]) }
          @seen_today_count = @seen_appointment.count
          @seen_today_not_arrived = @seen_appointment.select { |ocw| ocw[:state] == 'not_arrived' }
          @seen_today_completed = @seen_appointment.select { |ocw| ocw[:state] == 'complete' }
        end
      end

      if @user.present? && @user.role_ids.include?(499992366)
        counselled_today = CounsellorWorkflow.where(facility_id: current_facility.id, :state.ne => 'deleted',
                                                    user_id: @active_user, appointmentdate: params[:current_date])
                                             .pluck(:appointment_id).uniq
        @seen_appointment = @appointment.select { |ocw| counselled_today.include?(ocw[:appointment_id]) }
        @seen_today = @seen_appointment.select { |ocw| ['not_arrived', 'complete'].exclude?(ocw[:state]) }
        @seen_today_count = @seen_appointment.count
        @seen_today_not_arrived = @seen_appointment.select { |ocw| ocw[:state] == 'not_arrived' }
        @seen_today_completed = @seen_appointment.select { |ocw| ocw[:state] == 'complete' }
      end
    else
      # Non-Workflow
      options = { appointment_date: @current_date, :specialty_id.in => specialty,
                  facility_id: @current_facility.id.to_s, :current_state.ne => 'Deleted' }
      options = options.merge(consulting_doctor_id: @active_user) if @active_user.present? && @active_user != 'all'
      sort_params = @token_setting.try(:sort_list_by_token) ? 'token_number ASC' : 'appointment_start_time ASC'

      @appointment = AppointmentListView.includes(:appointment).where(options).order(sort_params)

      get_patient_params(@appointment.pluck(:patient_id))

      @all = @appointment.select { |alv| ['Scheduled', 'Waiting', 'Engaged'].include?(alv[:current_state]) }
      @scheduled = @appointment.select { |alv| alv[:current_state] == 'Scheduled' }
      @waiting = @appointment.select { |alv| alv[:current_state] == 'Waiting' }
      @engaged = @appointment.select { |alv| alv[:current_state] == 'Engaged' }
      @completed = @appointment.select { |alv| alv[:current_state] == 'Completed' }
      @incompleted = @appointment.select { |alv| alv[:current_state] == 'Incompleted' }
    end

    @appointment_id = params[:appointment_id].to_s if params[:appointment_id].present?

    @active_tab = if params[:active_tab].present?
                    params[:active_tab]
                  elsif @current_facility.clinical_workflow
                    'my_queue'
                  else
                    'all'
                  end

    @provisional = ProvisionalAppointment.where(
      appointmentdate: Date.parse(params[:current_date]), facility_id: current_facility.id.to_s,
      :specialty_id.in => specialty, consultant_id: current_user.id, is_deleted: false
    ).order(sort_params).map(&:itself)

    # @registered = Patient.where(reg_date: Date.parse(params[:current_date]), reg_facility_id: current_facility.id.to_s)

    # For Single Doctor Non-Workflow Case
    @doctors = User.where(facility_ids: @current_facility.id.to_s, is_active: true, role_ids: 158965000, :specialty_ids.in => specialty)

    # Defining User Specific My Queue
    if @user == @current_user
      @queue = 'My Queue'
      @today_label = 'My Counselled Today'
      @my_appointment = 'My OP Patient'
    elsif @user.nil?
      @queue = 'All Patients in Queue'
      @my_appointment = '-'
      @today_label = 'My Counselled Today'
    else
      @queue = @user.fullname.split(' ')[0] + "'s Queue"
      @queue = 'Dr. ' + @queue if @user.role_ids.include?(158965000)
      @today_label = @user.fullname.split(' ')[0] + "'s counselled Today"
      @my_appointment = if @user.role_ids.include?(158965000)
                          'Dr. ' + @user.fullname.split(' ')[0] + "'s Appt"
                        elsif @user.role_ids.include?(28229004)
                          @user.fullname.split(' ')[0] + "'s Appt"
                        elsif @user.role_ids.include?(499992366)
                          @user.fullname.split(' ')[0] + "'s Appt"
                        else
                          '-'
                        end
    end

    @doctors_list = params[:doctors_list]
  end

  def details_view_params
    @current_date = if params[:current_date].present?
                      Date.parse(params[:current_date])
                    else
                      @appointment.try(:appointmentdate) || Date.current
                    end

    @details_section_path = 'appointment'
    @appointment = Appointment.find_by(id: params[:appointment_id])

    @type = @appointment.try(:appointmenttype)
    @appointment_label = @type == 'walkin' ? 'OP' : 'Appointment'
    return if @appointment.nil? || @appointment.appointmentstatus != 416774000

    @appointment_list_view = AppointmentListView.find_by(appointment_id: @appointment.id)
    @patient = Patient.find_by(id: @appointment.patient_id)
    facility_id = current_facility.id
    user_id = current_user.id
    organisation_id = current_user.organisation_id
    @organisation = Organisation.find_by(id: organisation_id)
    specialty_id = @appointment.specialty_id

    if current_facility.country_id == 'VN_254'
      occupation_list = Global.send('occupation_list').send('sets')
      occupation_hash = occupation_list.pluck(:snomedcode, :name).to_h
      @occupation_name = occupation_hash[@patient&.occupation]
    end

    if @appointment.case_sheet_id.nil?
      CaseSheet::CreateAppointmentService.call(@patient, @appointment, current_user, nil)
    end
    @case_sheet = CaseSheet.find_by(id: @appointment.case_sheet_id)

    # Tab Details
    @case_sheets = CaseSheet.where(patient_id: @patient.id)
    @procedures = @case_sheets.map(&:procedures).flatten.reverse
    @diagnoses = @case_sheets.map(&:diagnoses).flatten.reverse

    # Adverse Event
    @adverse_events = AdverseEvent.where(patient_id: @patient.id)

    # Referral
    @initial_referral_type = PatientReferralType.where(patient_id: @patient.try(:id), is_deleted: false).order(created_at: :asc)[0]
    @patient_referral_type = PatientReferralType.find_by(appointment_id: @appointment.id, is_deleted: false)
    @deleted_patient_referral_type = PatientReferralType.find_by(appointment_id: @appointment.id, is_deleted: true)

    @past_appointment = AppointmentListView.where(patient_id: @patient.try(:id), :appointment_date.lt => Date.current, :current_state.nin => ['Deleted', 'Scheduled']).order(appointment_date: :desc)
    patient_asset = @patient.patientassets
    @patient_asset = if patient_asset.count > 0 && patient_asset.last.asset_path_url.present?
                       patient_asset.all[-1].asset_path_url
                     else
                       'placeholder.png'
                     end

    @patient_self_histories = PatientSelfHistory.where(patient_id: @patient.id).order_by('created_at DESC')

    @patientid = @patient.id
    @patient_note = PatientNote.where(patient_id: @patientid).order(created_at: :desc).limit(5)
    @counsellor_note = CounsellorNote.where(patient_id: @patient.id).order(created_at: :desc).limit(5)

    @user_notes_templates = UserNotesTemplate.where(
        organisation_id: current_facility.organisation_id.to_s, :specialty_id.in => current_user.specialty_ids,
        is_deleted: false, '$or' => [{ facility_id: current_facility.id.to_s, level: 'facility' },
                                     { user_id: current_user.id, level: 'user' }, { level: 'organisation' }]
    ).order(level: :DESC)
    @patient_certificates = UserNote.where(patient_id: @patient.id)

    # AppointmentType
    if @appointment.appointment_type_id.nil?
      @appointment_types = AppointmentType.where(facility_id: @appointment.facility_id.to_s,
                                                 specialty_ids: specialty_id, is_active: true)
      @sub_appointment_types = OrganisationAppointmentCategoryType.where(organisation_id: organisation_id,
                                                                         specialty_ids: specialty_id, is_active: true)
      @calculate_age = @patient.calculate_age
    else

      # UserState
      @user_state = user_state
      if @current_facility.show_user_state && @user_state.present? && @user_state.active_state != 'OPD'
        @show_user_state = true
        @user_state_color = @user_state.state_color
        @active_state = @user_state.active_state
      end

      # OPD Records
      if @current_user.role_ids.any? { |ele| [158965000, 28229004, 28221005, 106292003].include?(ele) }
        @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(specialty_id)
        @opd_templates = Global.send(@speciality_folder_name.to_s).send('opdtemplates')
        @show_opd_record = true
        @old_records = PatientTimeline.where(patient_id: @patient.id.to_s, encountertype: 'OPD',
                                             specalityid: specialty_id, :appointment_id.ne => @appointment.id.to_s)
                                      .limit(3).order(encounterdate: :desc)
      end
      @old_opd_records = OpdRecord.where(patientid: @patient.id.to_s, :appointmentid.ne => @appointment.id.to_s)
                                  .limit(3).order(created_at: :desc)
      @appointment_opd_records = OpdRecord.where(appointmentid: @appointment.id.to_s)

      # Doctor Reminder Note
      # if @current_user.role_ids.include?(158965000) #doctor
      #   @show_reminder_note = true
      #   @reminder_note = DocReminderNote.find_by(patient_id: @appointment.patient.id.to_s).try(:reminder_text)
      # end

      # Invoice and Cash register Queries
      if current_facility.show_finances
        @invoices = Invoice::Opd.where(appointment_id: @appointment.id, is_deleted: false)
        @patient_invoices = Invoice.where(:_type.in => ['Invoice::Opd', 'Invoice::Ipd'], patient_id: @patient.id.to_s, is_deleted: false)
        @past_invoices = Invoice::Opd.where(patient_id: @patient.id)
        @invoice_templates = InvoiceTemplate.where(facility_id: facility_id, department_id: '485396012',
                                                   specialty_id: specialty_id, version: 'v21.0', is_active: true)
        @advance_payments = AdvancePayment.where(patient_id: @patient.id, is_deleted: false,
                                                 :department_id.nin => ['50121007', '284748001'])
                                          .order(created_at: :desc)
        @refund_payments = RefundPayment.where(patient_id: @patient.id, is_deleted: false,
                                               :department_id.nin => ['50121007', '284748001'])
                                        .order(created_at: :desc)
        @cash_register_templates = CashRegisterTemplate.where(user_id: user_id)
        @past_cash_registers = CashRegister.where(patient_id: @patient.id)
      end
      @organisations_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
      if @organisations_setting.disable_opd_templates
        @enabled_templates = OpdRecordsHelper.enabled_templates(
          @organisations_setting, @patient.id, @appointment.appointmentdate, specialty_id
        )
      end

      # NABH
      @nabh_setting = NabhSetting.find_by(facility_id: current_facility.id.to_s)

      # Admission Params
      @existing_admission = Admission.find_by(patient_id: @patient.id, isdischarged: false, is_deleted: false)
      @admission_list_view = AdmissionListView.find_by(admission_id: @existing_admission.try(:id))
      @ot_schedules = OtSchedule.where(patient_id: @patient.id.to_s, is_deleted: false)
      @admission_case_sheet = @existing_admission.try(:case_sheet)

      # Admission
      @admission_list_views = AdmissionListView.where(
        patient_id: @patient.id, :current_state.nin => ['Discharged', 'Deleted']
      )

      @clinical_workflow_present = current_facility.clinical_workflow
      if !@clinical_workflow_present
        # NonWorkflow TimeLine Calculations
        @waiting_time = @appointment_list_view.patient_time[0]
        @engaged_time = @appointment_list_view.patient_time[1]
        # Non Workflow transition states
        @clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)

        @clinical_workflow_timeline = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: @clinical_workflow.id).last_states
        @clinical_workflow_timeline_count = @clinical_workflow_timeline.size
        @clinical_workflow_timeline = @clinical_workflow_timeline.reverse
        # Doctor
        @consulting_doctor = @appointment_list_view.consulting_doctor

        # For Counsellor in Non-workflow
        @users = User.where(facility_ids: facility_id, is_active: true)
        @counsellors = @users.where(role_ids: 499992366, is_active: true)
      else
        # QueueManagement
        facility_id = current_facility.id
        @queue_management_present = current_facility_setting.queue_management
        @clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
        if @queue_management_present
          @stations = QueueManagement::Station.where(facility_id: facility_id, is_deleted: false)
          sub_station_options = if current_facility_setting&.user_set_station
                                  { active_user_id: current_user.id, facility_id: facility_id, is_deleted: false }
                                else
                                  { user_id: current_user.id, facility_id: facility_id, is_deleted: false }
                                end
          @user_station = QueueManagement::SubStation.find_by(sub_station_options)
          @stations_array = if @clinical_workflow.try(:user_id) == @current_user.id.to_s && @current_date == Date.current &&
                               @clinical_workflow.state == @current_user&.primary_role
                              GetFacilities.current_facility_stations(facility_id)
                            else
                              []
                            end
        end

        specialty_id = specialty_id
        if @clinical_workflow.try(:user_id) == @current_user.id.to_s && @current_date == Date.current &&
           @clinical_workflow.state == @current_user&.primary_role
          @dropdown_users = UsersDropdownHelper.create_opd(specialty_id, facility_id, current_facility_setting)
          @departments_array = DepartmentsDropdownHelper.create(specialty_id, current_user, facility_id)
        else
          @dropdown_users = []
          @departments_array = []
        end
        @dropdown_users.delete('tpa') unless current_user.roles.pluck(:id).include? 499992366

        # Workflow SendTo Users
        # @clinical_workflows = OpdClinicalWorkflow.where(appointmentdate: Date.current,facility_id: current_facility.id)
        @clinical_workflow_timeline = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: @clinical_workflow.id).last_states.limit(5)
        if @clinical_workflow_timeline.count > 1
          @clinical_workflow_timeline_second_last = @clinical_workflow_timeline.all[1]
        end
        @clinical_workflow_timeline_count = @clinical_workflow_timeline.size
        @clinical_workflow_timeline = @clinical_workflow_timeline.reverse

        if @appointment.consultant_frozen
          @state_transition_consultant_id = @clinical_workflow.opd_clinical_workflow_state_transitions.where(to: 'doctor')
          @state_transition_optometrist = @clinical_workflow.opd_clinical_workflow_state_transitions.where(to: 'optometrist')
        end

        @users = User.where(facility_ids: facility_id, is_active: true).order('fullname ASC')

        # Doctor
        @consultant = @users.find_by(id: @clinical_workflow.consultant_ids.last).try(:fullname)
      end

      # Counsellor
      @counsellors = GetUsers.workflow_users_dropdown(@current_facility.id, [specialty_id], 499992366)
      if @current_user.role_ids.include?(499992366) # counsellor
        @opd_records = OpdRecord.where(appointmentid: @appointment.id.to_s).order(created_at: :desc)
        @opd_record = @opd_records.find_by(templatetype: 'eye')
        @counsellor_workflows = CounsellorWorkflow.where(appointment_id: @appointment.id.to_s)
        @followups = Order::Followup.where(appointment_id: @appointment.id.to_s)
        @followupdates = @followups || []
        @counsellor_records = CounsellorRecord.where(patient_id:  @patient.id.to_s).order(created_at: :desc)
        @counsellor_record = @counsellor_records.find_by(patient_id: @patient.id.to_s, appointment_id: @appointment.id.to_s, :created_at.gte => Date.today)
        counsellor_ids = @counsellors.map { |i| i[0] }
        @investigation_appointment = Appointment.where(patient_id: @patient.id.to_s, :user_id.in => counsellor_ids, :appointmentstatus.nin => [89925002], :appointmentdate.gte => @counsellor_workflow.try(:counsellingdate))
        @counselling_records = Order::CounsellingRecord.where(appointment_id: @appointment.id.to_s).order(created_at: :desc)
      end

      # for dilation
      @patient_dilation_list = PatientDilation.where(appointment_id: @appointment.id.to_s, is_reseted: false).order(start_time: :desc)
      @patient_dilation = @patient_dilation_list[0] if @patient_dilation_list.count > 0

      # @dilation_advised_by = User.find_by(id: @appointment.dilation_advised_by).try(:fullname).to_s.titleize

      @eyedrop_allergy = []
      @patient_allergy_eye_drops = @patient.opd_allergy_histories
      @patient_allergy_eye_drops&.each do |complaint|
        if complaint.name == 'tropicamide_p' || complaint.name == 'tropicamide' || complaint.name == 'timolol' || complaint.name == 'moxifloxacin' || complaint.name == 'homide' || complaint.name == 'latanoprost' || complaint.name == 'brimonidine' || complaint.name == 'travoprost' || complaint.name == 'tobramycin' || complaint.name == 'homatropine' || complaint.name == 'pilocarpine' || complaint.name == 'cyclopentolate' || complaint.name == 'atropine' || complaint.name == 'phenylephrine' || complaint.name == 'tropicacyl' || complaint.name == 'paracain' || complaint.name == 'ciplox' || complaint.name == 'tropicamide_p_distilled_water' || complaint.name == 'tropicamide_p_lubrex'
          @eyedrop_allergy.push(complaint.name)
        end
      end


      # TokenSettings
      @token_setting = TokenSetting.find_by(facility_id: facility_id)

      # PatientCard
      @patient_card_enabled = OrganisationsSetting.find_by(organisation_id: @current_facility.organisation_id).try(:patient_card_enabled)
      @calculate_age = @patient.calculate_age

      @org_specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])

      # Tab Details
      @all_tabs = Global.user_appointment_tabs.send(current_user.primary_role.to_s).to_a

      # Prescription Tab
      @medical_prescriptions = PatientPrescription.where(patient_id: @patient.id.to_s)
                                                  .order(prescription_datetime: :desc).to_a
      if @all_tabs.find { |tab| tab[:tab_id] == 'prescriptions-tab' }
        @medical_converted_by_users = User.where(:id.in => @medical_prescriptions.pluck(:mark_converted_by).uniq).to_a
        @medication_instructions = Global.medication_instruction_option.sets
      end

      # Glasses Tab
      @optical_prescriptions = PatientOpticalPrescription.where(patient_id: @patient.id.to_s)
                                                         .order(prescription_datetime: :desc).to_a
      if @all_tabs.find { |tab| tab[:tab_id] == 'glasses-tab' }
        @optical_converted_by_users = User.where(:id.in => @optical_prescriptions.pluck(:mark_converted_by).uniq).to_a
      end

      # Overview Tab - Investigations
      investigations = Investigation::InvestigationDetail.where(patient_id: @patient.id, is_deleted: false)
                                                         .order(advised_at: :desc)
                                                         .group_by(&:_type)
      @ophthal_investigations = investigations['Investigation::Ophthal'].to_a
      @laboratory_investigations = investigations['Investigation::Laboratory'].to_a
      @radiology_investigations = investigations['Investigation::Radiology'].to_a
    end

    # fetch the current print_settings
    print_settings
  end

  def print_settings
    organisation_id = current_user.organisation_id.to_s
    facility_id = current_facility.id.to_s
    @print_settings = PrintSetting.print_options(organisation_id, facility_id, ['485396012'])
  end


  def set_session_params
    @current_user = current_user
    @current_facility = current_facility
  end

  def validate_user_permission
    redirect_to '/' if [6868009].include? current_user.role_ids[0]
  end

  def get_patient_params(patient_ids)
    patients = Patient.where(:id.in => patient_ids)
    @patient_fields = patients.map do |patient|
      age_year, age_month = patient.calculate_age(true)
      title_content = ''
      title_content += 'One Eyed' if patient.one_eyed == 'Yes'
      age_in_months = (age_year.to_i * 12) + age_month.to_i
      if age_year.present? && (49...960).exclude?(age_in_months)
        title_content += ' | ' if patient.one_eyed == 'Yes'
        title_content += age_year < 4 ? 'Baby' : 'Old Age'
      end
      bang = !title_content.empty?
      { id: patient.id, bang: bang, title: title_content }
    end
  end
end
