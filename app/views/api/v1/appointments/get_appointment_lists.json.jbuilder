if @facility.clinical_workflow
  if @current_user.primary_role == "receptionist"
    json.tabs 5
    json.REFERRAL @appointment_list.where(:referral => true) do |workflow|
      appointment = Appointment.find_by(id: workflow.appointment_id)
      json.state workflow.state
      json.patient_id workflow.patient_id
      json.display_id appointment.display_id
      json.id appointment.id
      json.doctor appointment.consultant_id
      json.appointmentdate workflow.appointmentdate.strftime("%d %b,%y")
      json.borderColor hex_code(appointment.appointment_type.try(:background))
      json.appointment_booked_type appointment.appointment_type.try(:label)
      json.backgroundColor hex_code(appointment.appointment_type.try(:background))
      json.title appointment.patient.fullname
      json.end_time workflow.end_time
      json.start_time workflow.start_time.try(:strftime, '%I:%M %p')
      json.current_user_id workflow.user_id
      patient_params = @patient_params.find { |x| x[:id] == appointment.patient_id.to_s }
      if patient_params.present?
        json.bang patient_params[:bang]
        json.patient_title patient_params[:title]
      else
        json.bang false
        json.patient_title ''
      end

      if ["ophthal_investigation", "radiology_investigation", "laboratory_investigation", "optical", "pharmacy"].include? workflow.state
        with_user = Department.find_by(id: workflow.department_id).name
      else
        with_user = workflow.with_user
      end

      json.with_user with_user
      json.workflow_id workflow.id
      json.doctor_ids workflow.doctor_ids

      if workflow.state == "not_arrived"
        json.time_difference "NA"
      else
        json.time_difference workflow.total_transition_time_in_org
      end
      json.referral workflow.referral
      json.referring_doctor workflow.referring_doctor
      json.dilation_state workflow.dilation_state
      json.dilation_state_color workflow.dilation_state_color
      json.dilation_start_time appointment.dilation_start_time
      json.dilation_end_time appointment.dilation_end_time
    end
  elsif @current_user.primary_role == "nurse"
    json.tabs 4
  elsif @current_user.primary_role == "doctor"
    json.tabs 5
    json.MYAPPOINTMENT @appointment_list.where(:doctor_ids.in => [@active_user], :appointmentdate => @current_date) do |workflow|
      appointment = Appointment.find_by(id: workflow.appointment_id)
      json.state workflow.state
      json.patient_id workflow.patient_id
      json.display_id appointment.display_id
      json.id appointment.id
      json.doctor appointment.consultant_id
      json.appointmentdate workflow.appointmentdate.strftime("%d %b,%y")
      json.borderColor hex_code(appointment.appointment_type.try(:background))
      json.appointment_booked_type appointment.appointment_type.try(:label)
      json.backgroundColor hex_code(appointment.appointment_type.try(:background))
      json.title appointment.patient.fullname
      json.end_time workflow.end_time
      json.start_time workflow.start_time.try(:strftime, '%I:%M %p')
      json.current_user_id workflow.user_id
      patient_params = @patient_params.find { |x| x[:id] == appointment.patient_id.to_s }
      if patient_params.present?
        json.bang patient_params[:bang]
        json.patient_title patient_params[:title]
      else
        json.bang false
        json.patient_title ''
      end

      if ["ophthal_investigation", "radiology_investigation", "laboratory_investigation", "optical", "pharmacy"].include? workflow.state
        with_user = Department.find_by(id: workflow.department_id).name
      else
        with_user = workflow.with_user
      end

      json.with_user with_user
      json.workflow_id workflow.id
      json.doctor_ids workflow.doctor_ids

      if workflow.state == "not_arrived"
        json.time_difference "NA"
      else
        json.time_difference workflow.total_transition_time_in_org
      end
      json.referral workflow.referral
      json.referring_doctor workflow.referring_doctor
      json.dilation_state workflow.dilation_state
      json.dilation_state_color workflow.dilation_state_color
      json.dilation_start_time appointment.dilation_start_time
      json.dilation_end_time appointment.dilation_end_time
    end

    json.REFERRAL @appointment_list.where(:referral => true, :doctor_ids => @current_user.id.to_s) do |workflow|
      appointment = Appointment.find_by(id: workflow.appointment_id)
      counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: appointment.id.to_s)

      json.state workflow.state
      json.patient_id workflow.patient_id
      json.display_id appointment.display_id
      json.id appointment.id
      json.doctor appointment.consultant_id
      json.appointmentdate workflow.appointmentdate.strftime("%d %b,%y")
      json.borderColor hex_code(appointment.appointment_type.try(:background))
      json.appointment_booked_type appointment.appointment_type.try(:label)
      json.backgroundColor hex_code(appointment.appointment_type.try(:background))
      json.title appointment.patient.fullname
      json.end_time workflow.end_time
      json.start_time workflow.start_time.try(:strftime, '%I:%M %p')
      json.current_user_id workflow.user_id
      patient_params = @patient_params.find { |x| x[:id] == appointment.patient_id.to_s }
      if patient_params.present?
        json.bang patient_params[:bang]
        json.patient_title patient_params[:title]
      else
        json.bang false
        json.patient_title ''
      end

      if ["ophthal_investigation", "radiology_investigation", "laboratory_investigation", "optical", "pharmacy"].include? workflow.state
        with_user = Department.find_by(id: workflow.department_id).name
      else
        with_user = workflow.with_user
      end

      json.with_user with_user
      json.workflow_id workflow.id
      json.doctor_ids workflow.doctor_ids

      if workflow.state == "not_arrived"
        json.time_difference "NA"
      else
        json.time_difference workflow.total_transition_time_in_org
      end
      json.referral workflow.referral
      json.referring_doctor workflow.referring_doctor
      json.dilation_state workflow.dilation_state
      json.dilation_state_color workflow.dilation_state_color
      json.dilation_start_time appointment.dilation_start_time
      json.dilation_end_time appointment.dilation_end_time

      inv_workflow = InvestigationWorkflow.find_by(appointment_id: appointment.id.to_s)
      json.ophthal_assessment inv_workflow.present?
      json.workflow_state inv_workflow.try(:state)
      # if counsellor_workflow
      #   json.counsellor_state counsellor_workflow.try(:state).split("_").join(" ").capitalize
      #   json.counsellingtoday counsellor_workflow.appointmentdate
      #   length = counsellor_workflow.converted_state.count
      #   json.converted_state counsellor_workflow.converted_state[length -1]
      # end
    end
  elsif @current_user.primary_role == "optometrist"
    json.tabs 5
    json.MYAPPOINTMENT @appointment_list.where(:optometrist_ids.in => [@active_user], :appointmentdate => @current_date) do |workflow|
      appointment = Appointment.find_by(id: workflow.appointment_id)
      counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: appointment.id.to_s)

      json.state workflow.state
      json.patient_id workflow.patient_id
      json.display_id appointment.display_id
      json.id appointment.id
      json.doctor appointment.consultant_id
      json.appointmentdate workflow.appointmentdate.strftime("%d %b,%y")
      json.borderColor hex_code(appointment.appointment_type.try(:background))
      json.appointment_booked_type appointment.appointment_type.try(:label)
      json.backgroundColor hex_code(appointment.appointment_type.try(:background))
      json.title appointment.patient.fullname
      json.end_time workflow.end_time
      json.start_time workflow.start_time.try(:strftime, '%I:%M %p')
      json.current_user_id workflow.user_id
      patient_params = @patient_params.find { |x| x[:id] == appointment.patient_id.to_s }
      if patient_params.present?
        json.bang patient_params[:bang]
        json.patient_title patient_params[:title]
      else
        json.bang false
        json.patient_title ''
      end

      if ["ophthal_investigation", "radiology_investigation", "laboratory_investigation", "optical", "pharmacy"].include? workflow.state
        with_user = Department.find_by(id: workflow.department_id).name
      else
        with_user = workflow.with_user
      end

      json.with_user with_user
      json.workflow_id workflow.id
      json.doctor_ids workflow.doctor_ids

      if workflow.state == "not_arrived"
        json.time_difference "NA"
      else
        json.time_difference workflow.total_transition_time_in_org
      end
      json.referral workflow.referral
      json.referring_doctor workflow.referring_doctor
      json.dilation_state workflow.dilation_state
      json.dilation_state_color workflow.dilation_state_color
      json.dilation_start_time appointment.dilation_start_time
      json.dilation_end_time appointment.dilation_end_time
    end
  end

  json.COMPLETED @appointment_list.where(:state => "complete") do |workflow|
    appointment = Appointment.find_by(id: workflow.appointment_id)
    # counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: appointment.id.to_s)

    json.state workflow.state
    json.patient_id workflow.patient_id
    json.display_id appointment.display_id
    json.id appointment.id
    json.doctor appointment.consultant_id
    json.appointmentdate workflow.appointmentdate.strftime("%d %b,%y")
    json.borderColor hex_code(appointment.appointment_type.try(:background))
    json.appointment_booked_type appointment.appointment_type.try(:label)
    json.backgroundColor hex_code(appointment.appointment_type.try(:background))
    json.title appointment.patient.fullname
    json.end_time workflow.end_time
    json.start_time workflow.start_time.try(:strftime, '%I:%M %p')
    json.current_user_id workflow.user_id
    patient_params = @patient_params.find { |x| x[:id] == appointment.patient_id.to_s }
    if patient_params.present?
      json.bang patient_params[:bang]
      json.patient_title patient_params[:title]
    else
      json.bang false
      json.patient_title ''
    end

    if ["ophthal_investigation", "radiology_investigation", "laboratory_investigation", "optical", "pharmacy"].include? workflow.state
      with_user = Department.find_by(id: workflow.department_id).name
    else
      with_user = workflow.with_user
    end

    json.with_user with_user
    json.workflow_id workflow.id
    json.doctor_ids workflow.doctor_ids

    if workflow.state == "not_arrived"
      json.time_difference "NA"
    else
      json.time_difference workflow.total_transition_time_in_org
    end
    json.referral workflow.referral
    json.referring_doctor workflow.referring_doctor
    json.dilation_state workflow.dilation_state
    json.dilation_state_color workflow.dilation_state_color
    json.dilation_start_time appointment.dilation_start_time
    json.dilation_end_time appointment.dilation_end_time

    inv_workflow = InvestigationWorkflow.find_by(appointment_id: appointment.id.to_s)
    json.ophthal_assessment inv_workflow.present?
    json.workflow_state inv_workflow.try(:state)
    # if counsellor_workflow
    #   json.counsellor_state counsellor_workflow.try(:state).split("_").join(" ").capitalize
    #   json.counsellingtoday counsellor_workflow.appointmentdate
    #   length = counsellor_workflow.converted_state.count
    #   json.converted_state counsellor_workflow.converted_state[length -1]
    # end
  end

  json.ALL @appointment_list.where(:state.nin => ["not_arrived", "complete"]) do |workflow|
    appointment = Appointment.find_by(id: workflow.appointment_id)
    # counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: appointment.id.to_s)

    json.state workflow.state
    json.patient_id workflow.patient_id
    json.display_id appointment.display_id
    json.id appointment.id
    json.doctor appointment.consultant_id
    json.appointmentdate workflow.appointmentdate.strftime("%d %b,%y")
    json.borderColor hex_code(appointment.appointment_type.try(:background))
    json.appointment_booked_type appointment.appointment_type.try(:label)
    json.backgroundColor hex_code(appointment.appointment_type.try(:background))
    json.title appointment.patient.fullname
    json.end_time workflow.end_time
    json.start_time workflow.start_time.try(:strftime, '%I:%M %p')
    json.current_user_id workflow.user_id
    patient_params = @patient_params.find { |x| x[:id] == appointment.patient_id.to_s }
    if patient_params.present?
      json.bang patient_params[:bang]
      json.patient_title patient_params[:title]
    else
      json.bang false
      json.patient_title ''
    end

    if ["ophthal_investigation", "radiology_investigation", "laboratory_investigation", "optical", "pharmacy"].include? workflow.state
      with_user = Department.find_by(id: workflow.department_id).name
    else
      with_user = workflow.with_user
    end

    json.with_user with_user
    json.workflow_id workflow.id
    json.doctor_ids workflow.doctor_ids

    if workflow.state == "not_arrived"
      json.time_difference "NA"
    else
      json.time_difference workflow.total_transition_time_in_org
    end
    json.referral workflow.referral
    json.referring_doctor workflow.referring_doctor
    json.dilation_state workflow.dilation_state
    json.dilation_state_color workflow.dilation_state_color
    json.dilation_start_time appointment.dilation_start_time
    json.dilation_end_time appointment.dilation_end_time

    inv_workflow = InvestigationWorkflow.find_by(appointment_id: appointment.id.to_s)
    json.ophthal_assessment inv_workflow.present?
    json.workflow_state inv_workflow.try(:state)
    # if counsellor_workflow
    #   json.counsellor_state counsellor_workflow.try(:state).split("_").join(" ").capitalize
    #   json.counsellingtoday counsellor_workflow.appointmentdate
    #   length = counsellor_workflow.converted_state.count
    #   json.converted_state counsellor_workflow.converted_state[length -1]
    # end
  end

  json.MY_QUEUE @my_queue do |workflow|
    appointment = Appointment.find_by(id: workflow.appointment_id)
    # counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: appointment.id.to_s)

    json.state workflow.state
    json.patient_id workflow.patient_id
    json.display_id appointment.display_id
    json.id appointment.id
    json.doctor appointment.consultant_id
    json.appointmentdate workflow.appointmentdate.strftime("%d %b,%y")
    json.borderColor hex_code(appointment.appointment_type.try(:background))
    json.appointment_booked_type appointment.appointment_type.try(:label)
    json.backgroundColor hex_code(appointment.appointment_type.try(:background))
    json.title appointment.patient.fullname
    json.end_time workflow.end_time
    json.start_time workflow.start_time.try(:strftime, '%I:%M %p')
    json.current_user_id workflow.user_id
    patient_params = @patient_params.find { |x| x[:id] == appointment.patient_id.to_s }
    if patient_params.present?
      json.bang patient_params[:bang]
      json.patient_title patient_params[:title]
    else
      json.bang false
      json.patient_title ''
    end

    if ["ophthal_investigation", "radiology_investigation", "laboratory_investigation", "optical", "pharmacy"].include? workflow.state
      with_user = Department.find_by(id: workflow.department_id).name
    else
      with_user = workflow.with_user
    end

    json.with_user with_user
    json.workflow_id workflow.id
    json.doctor_ids workflow.doctor_ids

    if workflow.state == "not_arrived"
      json.time_difference "NA"
    else
      json.time_difference workflow.total_transition_time_in_org
    end
    json.referral workflow.referral
    json.referring_doctor workflow.referring_doctor
    json.dilation_state workflow.dilation_state
    json.dilation_state_color workflow.dilation_state_color
    json.dilation_start_time appointment.dilation_start_time
    json.dilation_end_time appointment.dilation_end_time

    inv_workflow = InvestigationWorkflow.find_by(appointment_id: appointment.id.to_s)
    json.ophthal_assessment inv_workflow.present?
    json.workflow_state inv_workflow.try(:state)
    # if counsellor_workflow
    #   json.counsellor_state counsellor_workflow.try(:state).split("_").join(" ").capitalize
    #   json.counsellingtoday counsellor_workflow.appointmentdate
    #   length = counsellor_workflow.converted_state.count
    #   json.converted_state counsellor_workflow.converted_state[length -1]
    # end
  end

  json.NOT_ARRIVED @appointment_list.where(:state => "not_arrived") do |workflow|
    appointment = Appointment.find_by(id: workflow.appointment_id)
    # counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: appointment.id.to_s)

    json.state workflow.state
    json.patient_id workflow.patient_id
    json.display_id appointment.display_id
    json.id appointment.id
    json.doctor appointment.consultant_id
    json.appointmentdate workflow.appointmentdate.strftime("%d %b,%y")
    json.borderColor hex_code(appointment.appointment_type.try(:background))
    json.appointment_booked_type appointment.appointment_type.try(:label)
    json.backgroundColor hex_code(appointment.appointment_type.try(:background))
    json.title appointment.patient.fullname
    json.end_time workflow.end_time
    json.start_time workflow.start_time.try(:strftime, '%I:%M %p')
    json.current_user_id workflow.user_id
    patient_params = @patient_params.find { |x| x[:id] == appointment.patient_id.to_s }
    if patient_params.present?
      json.bang patient_params[:bang]
      json.patient_title patient_params[:title]
    else
      json.bang false
      json.patient_title ''
    end

    if ["ophthal_investigation", "radiology_investigation", "laboratory_investigation", "optical", "pharmacy"].include? workflow.state
      with_user = Department.find_by(id: workflow.department_id).name
    else
      with_user = workflow.with_user
    end

    json.with_user with_user
    json.workflow_id workflow.id
    json.doctor_ids workflow.doctor_ids

    if workflow.state == "not_arrived"
      json.time_difference "NA"
    else
      json.time_difference workflow.total_transition_time_in_org
    end
    json.referral workflow.referral
    json.referring_doctor workflow.referring_doctor
    json.dilation_state workflow.dilation_state
    json.dilation_state_color workflow.dilation_state_color
    json.dilation_start_time appointment.dilation_start_time
    json.dilation_end_time appointment.dilation_end_time

    inv_workflow = InvestigationWorkflow.find_by(appointment_id: appointment.id.to_s)
    json.ophthal_assessment inv_workflow.present?
    json.workflow_state inv_workflow.try(:state)
    # if counsellor_workflow
    #   json.counsellor_state counsellor_workflow.try(:state).split("_").join(" ").capitalize
    #   json.counsellingtoday counsellor_workflow.appointmentdate
    #   length = counsellor_workflow.converted_state.count
    #   json.converted_state counsellor_workflow.converted_state[length -1]
    # end
  end
else
  json.tabs 5

  json.ALL @appointment_list.where(:current_state.in => ["Scheduled", "Waiting", "Engaged"]) do |appointment|
    # appointment = Appointment.find_by(id: workflow.appointment_id)
    # counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: appointment.id.to_s)
    #

    # json.state appointment.state
    json.appointmentdate appointment.appointment_date.strftime("%d %b,%y")
    json.borderColor appointment.appointment_type_color
    json.appointment_booked_type appointment.appointment_type
    json.backgroundColor hex_code(appointment.appointment_type_color)

    json.title appointment.patient_name.to_s.upcase
    json.start_time appointment.appointment_start_time.try(:strftime, '%I:%M %p')

    json.end_time appointment.appointment_end_time

    if appointment.current_state == "Scheduled"
      json.time_difference "NA"
    elsif appointment.current_state == "Completed" || appointment.current_state == "Incompleted"
      json.time_difference "T -" + appointment.time_difference(appointment.appointment_start_time, appointment.appointment_end_time)
    else
      json.time_difference "T -" + appointment.time_difference(Time.current, appointment.appointment_start_time)
    end

    json.referring_doctor appointment.referring_doctor
    json.dilation_state appointment.dilation_state
    json.dilation_state_color appointment.dilation_state_color

    json.referral appointment.referral

    json.scheduling_user_id appointment.scheduling_user_id
    json.scheduling_user appointment.scheduling_user

    json.appointment_id appointment.appointment_id.to_s

    patient_params = @patient_params.find { |x| x[:id] == appointment.patient_id }
    if patient_params.present?
      json.bang patient_params[:bang]
      json.patient_title patient_params[:title]
    else
      json.bang false
      json.patient_title ''
    end

    # inv_workflow = InvestigationWorkflow.find_by(appointment_id: appointment.id.to_s)
    # json.ophthal_assessment inv_workflow.present?
    # json.workflow_state inv_workflow.try(:state)
    # if counsellor_workflow
    #   json.counsellor_state counsellor_workflow.try(:state).split("_").join(" ").capitalize
    #   json.counsellingtoday counsellor_workflow.appointmentdate
    #   length = counsellor_workflow.converted_state.count
    #   json.converted_state counsellor_workflow.converted_state[length -1]
    # end
  end

  json.SCHEDULED @appointment_list.where(:current_state => "Scheduled") do |appointment|
    # json.state appointment.state
    json.appointmentdate appointment.appointment_date.strftime("%d %b,%y")
    json.borderColor appointment.appointment_type_color
    json.appointment_booked_type appointment.appointment_type
    json.backgroundColor hex_code(appointment.appointment_type_color)

    json.title appointment.patient_name.to_s.upcase
    json.start_time appointment.appointment_start_time.try(:strftime, '%I:%M %p')

    json.end_time appointment.appointment_end_time

    if appointment.current_state == "Scheduled"
      json.time_difference "NA"
    elsif appointment.current_state == "Completed"
      json.time_difference "T -" + appointment.time_difference(appointment.appointment_start_time, appointment.appointment_end_time)
    else
      json.time_difference "T -" + appointment.time_difference(Time.current, appointment.appointment_start_time)
    end

    json.referring_doctor appointment.referring_doctor
    json.dilation_state appointment.dilation_state
    json.dilation_state_color appointment.dilation_state_color

    json.referral appointment.referral

    json.scheduling_user_id appointment.scheduling_user_id
    json.scheduling_user appointment.scheduling_user

    json.appointment_id appointment.appointment_id.to_s
  end

  json.WAITING @appointment_list.where(:current_state => "Waiting") do |appointment|
    # json.state appointment.state
    json.appointmentdate appointment.appointment_date.strftime("%d %b,%y")
    json.borderColor appointment.appointment_type_color
    json.appointment_booked_type appointment.appointment_type
    json.backgroundColor hex_code(appointment.appointment_type_color)

    json.title appointment.patient_name.to_s.upcase
    json.start_time appointment.appointment_start_time.try(:strftime, '%I:%M %p')

    json.end_time appointment.appointment_end_time

    if appointment.current_state == "Scheduled"
      json.time_difference "NA"
    elsif appointment.current_state == "Completed"
      json.time_difference "T -" + appointment.time_difference(appointment.appointment_start_time, appointment.appointment_end_time)
    else
      json.time_difference "T -" + appointment.time_difference(Time.current, appointment.appointment_start_time)
    end

    json.referring_doctor appointment.referring_doctor
    json.dilation_state appointment.dilation_state
    json.dilation_state_color appointment.dilation_state_color

    json.referral appointment.referral

    json.scheduling_user_id appointment.scheduling_user_id
    json.scheduling_user appointment.scheduling_user

    json.appointment_id appointment.appointment_id.to_s

    patient_params = @patient_params.find { |x| x[:id] == appointment.patient_id }
    if patient_params.present?
      json.bang patient_params[:bang]
      json.patient_title patient_params[:title]
    else
      json.bang false
      json.patient_title ''
    end
  end

  json.ENGAGED @appointment_list.where(:current_state => "Engaged") do |appointment|
    # json.state appointment.state
    json.appointmentdate appointment.appointment_date.strftime("%d %b,%y")
    json.borderColor appointment.appointment_type_color
    json.appointment_booked_type appointment.appointment_type
    json.backgroundColor hex_code(appointment.appointment_type_color)

    json.title appointment.patient_name.to_s.upcase
    json.start_time appointment.appointment_start_time.try(:strftime, '%I:%M %p')

    json.end_time appointment.appointment_end_time

    if appointment.current_state == "Scheduled"
      json.time_difference "NA"
    elsif appointment.current_state == "Completed"
      json.time_difference "T -" + appointment.time_difference(appointment.appointment_start_time, appointment.appointment_end_time)
    else
      json.time_difference "T -" + appointment.time_difference(Time.current, appointment.appointment_start_time)
    end

    json.referring_doctor appointment.referring_doctor
    json.dilation_state appointment.dilation_state
    json.dilation_state_color appointment.dilation_state_color

    json.referral appointment.referral

    json.scheduling_user_id appointment.scheduling_user_id
    json.scheduling_user appointment.scheduling_user

    json.appointment_id appointment.appointment_id.to_s

    patient_params = @patient_params.find { |x| x[:id] == appointment.patient_id }
    if patient_params.present?
      json.bang patient_params[:bang]
      json.patient_title patient_params[:title]
    else
      json.bang false
      json.patient_title ''
    end
  end

  json.COMPLETED @appointment_list.where(:current_state => "Completed") do |appointment|
    # json.state appointment.state
    json.appointmentdate appointment.appointment_date.strftime("%d %b,%y")
    json.borderColor appointment.appointment_type_color
    json.appointment_booked_type appointment.appointment_type
    json.backgroundColor hex_code(appointment.appointment_type_color)

    json.title appointment.patient_name.to_s.upcase
    json.start_time appointment.appointment_start_time.try(:strftime, '%I:%M %p')

    json.end_time appointment.appointment_end_time

    if appointment.current_state == "Scheduled"
      json.time_difference "NA"
    elsif appointment.current_state == "Completed"
      json.time_difference "T -" + appointment.time_difference(appointment.appointment_start_time, appointment.appointment_end_time)
    else
      json.time_difference "T -" + appointment.time_difference(Time.current, appointment.appointment_start_time)
    end

    json.referring_doctor appointment.referring_doctor
    json.dilation_state appointment.dilation_state
    json.dilation_state_color appointment.dilation_state_color

    json.referral appointment.referral

    json.scheduling_user_id appointment.scheduling_user_id
    json.scheduling_user appointment.scheduling_user

    json.appointment_id appointment.appointment_id.to_s

    patient_params = @patient_params.find { |x| x[:id] == appointment.patient_id }
    if patient_params.present?
      json.bang patient_params[:bang]
      json.patient_title patient_params[:title]
    else
      json.bang false
      json.patient_title ''
    end
  end

  json.INCOMPLETED @appointment_list.where(:current_state => "Incompleted") do |appointment|
    # json.state appointment.state
    json.appointmentdate appointment.appointment_date.strftime("%d %b,%y")
    json.borderColor appointment.appointment_type_color
    json.appointment_booked_type appointment.appointment_type
    json.backgroundColor hex_code(appointment.appointment_type_color)

    json.title appointment.patient_name.to_s.upcase
    json.start_time appointment.appointment_start_time.try(:strftime, '%I:%M %p')

    json.end_time appointment.appointment_end_time

    if appointment.current_state == "Scheduled"
      json.time_difference "NA"
    elsif appointment.current_state == "Completed"
      json.time_difference "T -" + appointment.time_difference(appointment.appointment_start_time, appointment.appointment_end_time)
    else
      json.time_difference "T -" + appointment.time_difference(Time.current, appointment.appointment_start_time)
    end

    json.referring_doctor appointment.referring_doctor
    json.dilation_state appointment.dilation_state
    json.dilation_state_color appointment.dilation_state_color

    json.referral appointment.referral

    json.scheduling_user_id appointment.scheduling_user_id
    json.scheduling_user appointment.scheduling_user

    json.appointment_id appointment.appointment_id.to_s

    patient_params = @patient_params.find { |x| x[:id] == appointment.patient_id }
    if patient_params.present?
      json.bang patient_params[:bang]
      json.patient_title patient_params[:title]
    else
      json.bang false
      json.patient_title ''
    end
  end

end
