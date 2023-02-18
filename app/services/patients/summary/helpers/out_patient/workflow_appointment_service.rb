class Patients::Summary::Helpers::OutPatient::WorkflowAppointmentService
  def initialize(params = {})
    @params = params
    set_workflow
    set_non_workflow
    set_facility
  end

  def call
    @options = {}

    @timeline_message = Global.patient_summary_timeline.send("#{@params[:event_name]}_#{@params[:sub_event_name]}")
    # FINDERS
    set_finders
    # DISPLAY FIELDS
    set_display_fields
    # QUERY PARAMETERS
    set_query_parameter
    # EVENTS AND OTHER INFO
    set_events_and_info
    # HOUSE KEEPING FIELDS, UPDATED FROM WORKER PROCESSING THE REQUEST.
    set_updated_created_at
    # DELETED FLAG, FOR DISPLAY
    set_deleted_flag
    # LINKS
    set_specialty_params

    if ['SCHEDULED', 'RESCHEDULED', 'EDITED'].include?(@params[:sub_event_name])
      set_initial_sub_events
    elsif @params[:sub_event_name] == 'ARRIVED'
      set_arrived_sub_events
    elsif @params[:sub_event_name] == 'ENGAGED'
      set_engaged_sub_events
    elsif @params[:sub_event_name] == 'CHECKOUT'
      set_checkout_sub_events
    elsif @params[:sub_event_name] == 'COMPLETED'
      set_completed_sub_events
    elsif @params[:sub_event_name] == 'CANCELLED'
      set_cancelled_sub_events
    elsif @params[:sub_event_name] == 'WORKFLOW'
      set_workflow_subevents
    elsif @params[:sub_event_name] == 'AWAY'
      set_away_subevents
    end

    deactive_previous_appointment_timelines

    call_timeline_service
  end

  private

  def set_facility
    @facility = Facility.find_by(id: @workflow.facility_id)
  end

  def set_workflow
    @workflow = OpdClinicalWorkflow.find_by(appointment_id: @params[:appointment_id].to_s)
  end

  def set_non_workflow
    @appointment = Appointment.find_by(id: @params[:appointment_id])
    @appointment_list = AppointmentListView.find_by(appointment_id: @params[:appointment_id].to_s)
  end

  def set_finders
    @options = @options.merge(
      organisation_id: @facility.organisation_id,
      facility_id: @workflow.facility_id,
      patient_id: @workflow.patient_id
    )
  end

  def set_display_fields
    @options = @options.merge(
      facility_name: @facility.try(:name),
      encounter_type: 'OPD',
      event_type: 'Appointment',
      event_type_color: '354670'
    )
  end

  def set_query_parameter
    @options = @options.merge(
      query: { _id: @workflow.appointment_id.to_s },
      primary_model: 'Appointment'
    )
  end

  def set_events_and_info
    @options = @options.merge(event_attributes)
  end

  def set_deleted_flag
    @options = @options.merge(is_deleted: false)
  end

  def set_specialty_params
    @options = @options.merge(specialty_id: @appointment.specialty_id)
  end

  def set_updated_created_at
    @options = @options.merge(created_by: nil, updated_by: nil)
  end

  def set_initial_sub_events
    @options = @options.merge(user_attributes(@params[:user_id], @params[:user_name], [[@appointment_list.consulting_doctor_id, @appointment_list.consulting_doctor]]))

    @options = @options.merge(link_attributes(true, { appointment: @workflow.attributes }, [@timeline_message], {}))

    @options = @options.merge(encounter_attributes(@appointment_list.appointment_date, @appointment_list.appointment_start_time, Time.current))
  end

  def set_arrived_sub_events
    @options = @options.merge(user_attributes(@params[:user_id], @params[:user_name], [[@appointment_list.consulting_doctor_id, @appointment_list.consulting_doctor]]))

    @options = @options.merge(link_attributes(true, { appointment: @workflow.attributes }, [@timeline_message], {}))

    @options = @options.merge(encounter_attributes(Date.current, Time.current, Time.current))
  end

  def set_engaged_sub_events
    @options = @options.merge(user_attributes(@params[:user_id], @params[:user_name], [[@appointment_list.consulting_doctor_id, @appointment_list.consulting_doctor]]))

    @options = @options.merge(link_attributes(true, { appointment: @workflow.attributes }, [@timeline_message], {}))

    @options = @options.merge(encounter_attributes(Date.current, Time.current, Time.current))
  end

  def set_checkout_sub_events
    @options = @options.merge(last_state_name: @params[:last_state_name])

    @options = @options.merge(user_attributes(@params[:user_id], @params[:user_name], [[@workflow.user_id, @workflow.with_user]]))
    @options = @options.merge(link_attributes(true, { appointment: @workflow.attributes }, [format(@timeline_message, user_name: @workflow.with_user.to_s.upcase)], {}))

    @options = @options.merge(encounter_attributes(Date.current, Time.current, Time.current))
  end

  def set_completed_sub_events
    @options = @options.merge(last_state_name: @params[:last_state_name])

    @options = @options.merge(link_attributes(false, {}, [@timeline_message], {}))

    @options = @options.merge(encounter_attributes(Date.current, Time.current, Time.current))
  end

  def set_cancelled_sub_events
    @options = @options.merge(user_attributes(@params[:user_id], @params[:user_name], nil))

    @options = @options.merge(link_attributes(false, {}, [@timeline_message], {}))

    @options = @options.merge(encounter_attributes(Date.current, Time.current, Time.current))
  end

  def set_workflow_subevents
    if @params[:user_id].present?
      @options = @options.merge(user_attributes(@params[:user_id], @params[:user_name], [[@workflow.user_id, @workflow.with_user]]))
      @options = @options.merge(link_attributes(true, { appointment: @workflow.attributes }, [format(@timeline_message, user_name: @workflow.with_user.to_s.upcase)], {}))
    elsif @params[:department_id].present?
      with_department = find_department(@params[:department_id])
      @options = @options.merge(department_attributes(@params[:department_id], with_department, [[@workflow.department_id, with_department]]))
      @options = @options.merge(link_attributes(true, { appointment: @workflow.attributes }, [format(@timeline_message, user_name: with_department.to_s.upcase)], {}))
    end
    @options = @options.merge(encounter_attributes(Date.current, Time.current, Time.current))
  end

  def set_away_subevents
    # @options = @options.merge(user_attributes(@params[:user_id],@params[:user_name],nil))
    @options = @options.merge(last_state_name: @params[:last_state_name])

    @options = @options.merge(link_attributes(true, { appointment: @workflow.attributes }, [@timeline_message], {}))

    @options = @options.merge(encounter_attributes(Date.current, Time.current, Time.current))
  end

  def deactive_previous_appointment_timelines
    PatientSummaryTimeline.where(query: { _id: @workflow.appointment_id.to_s }).update_all(is_active: false)
  end

  def call_timeline_service
    Patients::Summary::TimelineService.call(@options)
  end

  def encounter_attributes(encounter_date, encounter_date_time, event_date_time)
    {
      encounter_date: encounter_date,
      encounter_date_time: encounter_date_time,
      event_date_time: event_date_time
    }
  end

  def user_attributes(user_id, user_name, users)
    {
      user_id: user_id,
      user_name: user_name,
      users: users
    }
  end

  def department_attributes(department_id, department_name, departments)
    {
      department_id: department_id,
      department_name: department_name,
      departments: departments
    }
  end

  def link_attributes(has_links, links, comments, optionals)
    {
      has_links: has_links,
      links: links,
      comments: comments,
      optionals: optionals
    }
  end

  def event_attributes
    { is_active: true,
      event_id: patient_summary_events(@params[:event_name])[:id],
      event_name: patient_summary_events(@params[:event_name])[:name],
      sub_event_id: patient_summary_sub_events(@params[:sub_event_name])[:id],
      sub_event_name: patient_summary_sub_events(@params[:sub_event_name])[:name],
      department_name: @facility.department_ids[0],
      sub_department_name: nil,
      sub_speciality_name: nil }
  end

  def patient_summary_events(event_name)
    "Patients::Summary::Events::#{event_name}".constantize
  end

  def patient_summary_sub_events(sub_event_name)
    "Patients::Summary::SubEvents::#{sub_event_name}".constantize
  end

  def find_department(department_id)
    department = Department.find_by(id: department_id)
    @department_name = department&.name
  end
end
