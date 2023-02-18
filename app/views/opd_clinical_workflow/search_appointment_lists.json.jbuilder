json.array!(@appointment_list) do |workflow|
  json.id workflow.appointment_id.to_s
  patient = Patient.find_by(id: workflow.patient_id)
  json.label patient.fullname
  json.value patient.fullname
end
