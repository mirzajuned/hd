json.array!(@appointment_list) do |workflow|
  appointment = Appointment.find_by(id: workflow.appointment_id)
  counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: appointment.id.to_s)
  investigation_appointment = Appointment.where(patient_id: appointment.patient.id.to_s, :user_id.in => [current_user.id], :appointmentstatus.nin => [89925002])

  # away time calculation
  away_time = workflow.away_transition_time

  json.extract! appointment, :id, :appointmentstatus, :arrived, :arrived_time, :current_state, :department_id, :departmenttype, :display_id, :doctor, :engaged, :engage_time, :engaged_time_min, :facility_id, :patient_id, :ref_doc_name, :seen, :total_time_min, :user_id, :waiting_time_min, :dilation_start_time, :dilation_end_time
  json.state workflow.state
  json.appointmentdate workflow.appointmentdate.strftime("%d %b,%y")
  json.borderColor appointment.appointment_type.try(:background)
  json.appointment_booked_type appointment.appointment_type.try(:label)
  json.backgroundColor appointment.appointment_type.try(:background)
  json.title appointment.patient.fullname
  json.end_time workflow.end_time
  json.start_time workflow.start_time
  json.current_user_id workflow.user_id
  json.workflow_id workflow.id
  json.doctor_ids workflow.doctor_ids
  json.away_time away_time.try(:round)
  puts appointment.id
  inv_workflow = InvestigationWorkflow.find_by(appointment_id: appointment.id.to_s)
  json.ophthal_assessment inv_workflow.present?
  json.workflow_state inv_workflow.try(:state)
  if counsellor_workflow
    json.counsellor_state counsellor_workflow.try(:state).split("_").join(" ").capitalize
    json.counsellingtoday counsellor_workflow.appointmentdate
    length = counsellor_workflow.converted_state.count
    json.converted_state counsellor_workflow.converted_state[length - 1]
  end
  if investigation_appointment.count > 0
    json.investigation_date investigation_appointment.order("created_at DESC")[0].appointmentdate.strftime("%d %b,%y")
  end
  if appointment.dilation_start_time != nil
    json.difference TimeDifference.between(appointment.dilation_start_time, Time.current).in_seconds.to_i
  end
  if appointment.dilation_start_time != nil && appointment.dilation_end_time != nil
    json.end_difference Time.at(TimeDifference.between(appointment.dilation_start_time, appointment.dilation_end_time).in_seconds.to_i).utc.strftime("%M:%S")
  end
end
