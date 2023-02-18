json.array!(@appointment_list) do |workflow|
  appointment = Appointment.find_by(id: workflow.appointment_id)
  clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: appointment.id.to_s)
  investigation_appointment = Appointment.where(patient_id: appointment.patient.id.to_s, :user_id.in => [current_user.id], :appointmentstatus.nin => [89925002])
  json.id appointment.id.to_s
  json.state clinical_workflow.state
  json.borderColor appointment.appointment_type.try(:background)
  json.appointment_booked_type appointment.appointment_type.try(:label)
  json.backgroundColor appointment.appointment_type.try(:background)
  json.title appointment.patient.fullname
  json.end_time workflow.end_time
  json.start_time workflow.start_time
  json.current_user_id workflow.user_id
  json.workflow_id workflow.id
  json.appointmentdate workflow.counsellingdate
  json.counsellor_state workflow.try(:state).split("_").join(" ").capitalize
  length = workflow.converted_state.count
  json.converted_state workflow.converted_state[length - 1]
  surgerylength = workflow.surgerydates.count
  if surgerylength > 0
    json.surgery_date Date.parse(workflow.surgerydates[surgerylength - 1]).strftime("%d %b,%y")
  end
  if investigation_appointment.count > 0
    json.investigation_date investigation_appointment.order("created_at DESC")[0].appointmentdate.strftime("%d %b,%y")
  end
end
