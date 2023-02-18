json.facilities @facilities.pluck(:id, :name)
json.apppointmentdate Date.current
json.apppointmenttime Time.current
json.organisation_id @current_user.organisation_id
json.department_id "485396012"
json.selected_doctor @selected_doctor
json.selected_facility @selected_facility

json.current_doctors @available_doctors.pluck(:id, :fullname)
json.appointment_types @appointment_types
json.appointment_category @appointment_category.pluck(:id, :label)
# # json.patient @patient
# json.patient_mrn @patient.patient_mrn
# json.patient_identifier_id @patient.patient_identifier_id

json.patient @patient
if !@patient.blank?
  json.patientallergyhistory @patient.patient_history.try(:patientallergyhistory)
  json.patientpersonalhistory @patient.patient_history.try(:patientpersonalhistory)
end

json.patient_mrn @patient.patient_mrn
json.patient_identifier_id @patient.patient_identifier_id

json.appointmentslot @appointment_slots
