json.array!(@patientlist) do |patient|
  json.id patient.patient_id.to_s
  json.label patient.patient_name.to_s.upcase
  json.value patient.patient_name.to_s.upcase
  json.patient_display_id patient.patient_identifier_id
  json.patient_mrn patient.mr_no
  json.mobile_number patient.mobile_number
end
