json.tab @tab
if @current_facility.clinical_workflow
  json.list @list do |workflow|
    appointment = Appointment.find_by(id: workflow.appointment_id)
    json.id appointment.id
    json.state workflow.state
    json.patient_mr_no workflow.patient_mr_no.present? ? workflow.patient_mr_no :  workflow.patient_display_id
    json.token_number workflow.token_number.to_i
    json.patient_id workflow.patient_id
    json.patient_name appointment.patient.fullname
    json.age appointment.patient.age
    json.gender appointment.patient.gender
    json.patient_type do
      json.label workflow.patient_type
      json.color workflow.patient_type_color
    end
    json.display_id appointment.display_id
    json.doctor appointment.consultant_id
    json.appointmentdate workflow.appointmentdate.strftime("%d %b,%y")
    json.borderColor hex_code(workflow.appointment_type_color)
    json.appointment_reason workflow.appointment_type_label
    json.reason_background_color hex_code(workflow.appointment_type_color)
    json.appointment_category workflow.appointment_category_label
    json.category_background_color hex_code(workflow.appointment_category_color)
    json.appointment_type workflow.appointmenttype
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
  end


else
  json.list @list  do |appointment|
    # json.state appointment.state
    json.id appointment.appointment_id
    json.token_number appointment.token_number.to_i
    json.appointmentdate appointment.appointment_date.strftime("%d %b,%y")
    json.patient_mr_no appointment.patient_mr_no.present? ? appointment.patient_mr_no :  appointment.patient_display_id
    json.borderColor appointment.appointment_type_color
    json.appointment_reason appointment.appointment_type
    json.reason_background_color hex_code(appointment.appointment_type_color)
    json.appointment_category appointment.appointment_category_label
    json.category_background_color hex_code(appointment.appointment_category_color)
    json.appointment_type appointment.appointmenttype

    json.patient_name appointment.patient_name.upcase
    json.age appointment.age
    json.gender appointment.patient_gender
    json.patient_type do
      json.label appointment.patient_type
      json.color appointment.patient_type_color
    end
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

