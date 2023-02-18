# OLD in USE
json.array! @prescription do |prescription|
  patient = Patient.find_by(id: prescription.try(:patient_id))
  json.label patient.try(:fullname)
  json.value patient.try(:fullname)
  json.id prescription.id
  json.fullname patient.try(:fullname)
end
