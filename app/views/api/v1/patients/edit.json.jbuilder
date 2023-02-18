json.patient @patient
if !@patient.blank?
  json.patientallergyhistory @patient.patient_history.try(:patientallergyhistory)
  json.patientpersonalhistory @patient.patient_history.try(:patientpersonalhistory)
end
json.patient_mrn @patient.patient_mrn
json.patient_types @patient_types
json.patient_identifier_id @patient.patient_identifier_id
