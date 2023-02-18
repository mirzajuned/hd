json.array! @admissions do |admission|
  json.label admission.patient_name.to_s.upcase
  json.value admission.patient_name.to_s.upcase
  json.admission_created_on admission.admission_date.strftime('%d/%m/%y')
  json.admission_id admission.id
  json.id admission.patient_id.to_s
  json.patient_display_id admission.patient_display_id
  json.patient_mr_no admission.patient_mr_no
  json.mobile_number admission.patient_mobilenumber
end
