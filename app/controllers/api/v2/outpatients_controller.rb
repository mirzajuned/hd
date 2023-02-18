class Api::V2::OutpatientsController < ApiApplicationController
  before_action :authorize_token
  before_action :current_user, :current_facility, only: [:tabs, :lists, :medications, :medication_advised]
  before_action :date_and_active_user, only: [:tabs, :lists]

  def tabs
    tabs = list_tabs(@active_user, @current_date)
    list_tabs = []
    tabs.each do |val|
      tabs_json = {}
      tabs_json[:name] = val[0]
      tabs_json[:label] = val[1]
      tabs_json[:count] = val[2]
      list_tabs << tabs_json
    end
    list = seperate_tabs_and_menue(list_tabs)
    render json: { result: list }, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def lists
    @list, @patient_params = if @current_facility.clinical_workflow
                               clinical_list(@active_user, @current_date)
                             else
                               non_clinical_list(@active_user, @current_date)
                             end
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def appointment_detail
    render json: { error: 'not found' }, status: 422 if Appointment.find(params[:appointment_id]).nil?
  end

  def medications
    render json: { error: 'not found' }, status: 422 if (@appointment = Appointment.find(params[:appointment_id])).nil?
    @opd_records = OpdRecord.where(patientid: @appointment.patient_id.to_s, :treatmentmedication.ne => nil).order_by('created_at DESC').to_a
  end

  private

  def date_and_active_user
    @current_date = params[:current_date].present? ? Date.parse(params[:current_date]) : Date.current
    @active_user = active_user(params, current_user.doctor?)
  end

  def list_tabs(active_user, current_date)
    tabs = []
    tab_service = Api::V2::TabsService
    role = current_user_role
    list = appointment_list(current_date, active_user)
    if @current_facility.clinical_workflow
      if current_date < Date.current
        if role == 'receptionist'
          tabs << tab_service.incompleted_clinical_workflow(active_user, list, current_date, role)
        end
      else
        tabs <<   tab_service.myqueue_clinical_workflow(active_user, list, current_date, role)
      end
      tabs <<   tab_service.all_clinical_workflow(active_user, list, current_date)
      tabs <<   tab_service.inprogress_clinical_workflow(active_user, list) if current_date == Date.current
      if current_date >= Date.current
        tabs <<   tab_service.referral_clinical_workflow(active_user, @current_user, current_date, list, role)
      end
      tabs << tab_service.completed_clinical_workflow(active_user, list, current_date) if current_date <= Date.current
      if current_date <= Date.current && role == 'doctor'
        tabs << tab_service.my_completed_clinical_workflow(active_user, list, current_date)
      end
      if current_date <= Date.current
        tabs << tab_service.not_arrived_clinical_workflow(active_user, list, current_date, role)
      end

      if current_date > Date.current && role == 'doctor'
        tabs << tab_service.my_appointment_clinical_workflow(active_user, list)
      end
    else
      tabs << tab_service.all_non_clinical_workflow(list) unless role == 'receptionist' && current_date <= Date.current
      if role == 'receptionist' && current_date == Date.current
        tabs << tab_service.myqueue_non_clinical_workflow(active_user, list)
      end
      tabs << tab_service.scheduled_non_clinical_workflow(list) if current_date >= Date.current
      if current_date == Date.current
        tabs <<  tab_service.waiting_non_clinical_workflow(active_user, list, current_date, role)
      end
      if current_date == Date.current
        tabs <<  tab_service.engaged_non_clinical_workflow(active_user, list, current_date, role)
      end
      if current_date <= Date.current
        tabs <<  tab_service.completed_non_clinical_workflow(active_user, list, current_date, role)
      end
      if current_date <= Date.current
        tabs <<  tab_service.my_completed_non_clinical_workflow(active_user, list, current_date, role)
      end
      if current_date < Date.current
        tabs <<  tab_service.incompleted_non_clinical_workflow(active_user, list, current_date, role)
      end
    end
    tabs.compact
  end

  def clinical_list(active_user, current_date)
    # filters hash can be used and appende here {user_id, user_type}
    list_service = Api::V2::AppointmentListsService
    @tab = params[:tab].present? ? params[:tab] : 'all'
    list = appointment_list(current_date, active_user)
    case @tab
    when 'my_queue'
      list_service.clinical_myqueue(params, list, @current_user, active_user)
    when 'referral'
      list_service.clinical_refferral(params, list, @current_user, active_user)
    when 'in_progress'
      list_service.clinical_in_progress(params, list, @current_user, active_user)
    when 'incomplete'
      list_service.clinical_incomplete(params, list, @current_user, active_user)
    when 'completed'
      list_service.clinical_complete(params, list, @current_user, active_user)
    when 'my_completed'
      list_service.clinical_my_complete(params, list, @current_user, active_user)
    when 'not_arrived'
      list_service.clinical_not_arrived(params, list, @current_user, active_user)
    else
      list_service.clinical_all(params, list, @current_user, active_user)
    end
  end

  def non_clinical_list(active_user, current_date)
    list_service = Api::V2::AppointmentListsService
    @tab = params[:tab].present? ? params[:tab] : 'all'
    list = appointment_list(current_date, active_user)
    case @tab
    when 'my_queue'
      list_service.non_clinical_myqueue(params, list, @current_user, active_user)
    when 'scheduled'
      list_service.non_clinical_scheduled(params, list, @current_user, active_user)
    when 'waiting'
      list_service.non_clinical_waiting(params, list, @current_user, active_user)
    when 'engaged'
      list_service.non_clinical_engaged(params, list, @current_user, active_user)
    when 'completed'
      list_service.non_clinical_completed(params, list, @current_user, active_user)
    when 'my_completed'
      list_service.non_clinical_my_completed(params, list, @current_user, active_user)
    when 'incomplete'
      list_service.non_clinical_incompleted(params, list, @current_user, active_user)
    else
      list_service.non_clinical_all(params, list, @current_user, active_user)
    end
  end

  def active_user(params, is_doctor)
    if params[:active_user].present?
      active_user = params[:active_user]
    elsif @current_facility.clinical_workflow || is_doctor
      active_user = current_user.id.to_s
    end
  end

  def appointment_list(current_date, active_user)
    if @current_facility.clinical_workflow
      list = OpdClinicalWorkflow.where(appointmentdate: current_date,
                                       facility_id: params[:current_facility_id].to_s,
                                       :state.ne => 'cancelled').order('start_time DESC')
      list = list.where(consultant_ids: params[:with_user]) if params[:with_user].present? && params[:with_user] != 'all'
      list
    else
      active_user = params[:with_user] if params[:with_user].present? && params[:with_user] != 'all'
      options = { appointment_date: current_date, facility_id: @current_facility.id.to_s,
                  :current_state.ne => 'Deleted' }
      options = options.merge(consulting_doctor_id: active_user) if active_user.present? && active_user != 'all'
      AppointmentListView.includes(:appointment).where(options).order('appointment_start_time ASC')

    end
  end

  def current_user_role
    @current_user.primary_role
  end

  def seperate_tabs_and_menue(list_tabs)
    list = {}
    list[:tabs] = []
    list[:menu] = []
    list_tabs.each do |val|
      if menu_condition(val)
        list[:menu] << val
      else
        list[:tabs] << val
      end
    end
    list
  end

  def menu_condition(val)
    val[:name] == 'all' ||  completed_in_menue?(val)
  end

  def completed_in_menue?(val)
    current_user_role == 'doctor' && @current_date <= Date.current && val[:name] == 'completed' && @current_facility.clinical_workflow
  end
end
