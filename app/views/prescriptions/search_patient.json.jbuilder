json.array! @prescriptions do |prescription|
  # patient = PatientSearch.find_by(patient_id: prescription.patient_id)
  json.label prescription.patient_name.to_s.upcase
  json.value prescription.patient_name.to_s.upcase
  json.prescription_created_on prescription.created_at.strftime('%d/%m/%y')
  json.prescription_id prescription.id
  json.id prescription.patient_id.to_s
  json.patient_display_id prescription.patient_identifier_id
  json.patient_mrn prescription.mr_no
  json.mobile_number prescription.mobile_number
  json.prescription_id prescription.id
  json.filter @filter
end
