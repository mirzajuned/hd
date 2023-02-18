json.array! @investigation_list do |list|
  patient = PatientSearch.find_by(patient_id: list.patient_id)
  json.list_created_on list.created_at.strftime('%d/%m/%y')
  json.list_id list.id
  json.id list.patient_id.to_s
  json.label list.patient_name.to_s.upcase
  json.value list.patient_name.to_s.upcase
  json.patient_display_id patient.patient_identifier_id
  json.patient_mrn patient.mr_no
  json.mobile_number patient.mobile_number
  json.filter @filter
  json.department @department
  json.appointment_id list.appointment_id
  json.appointment_date list.appointment_date
  json.date list.appointment_date.strftime('%d/%m/%y')
end
