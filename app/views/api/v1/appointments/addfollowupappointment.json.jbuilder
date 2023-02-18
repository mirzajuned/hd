json.referral_types @referral_types

# json.patient_referral_type @patient_referral_type
json.initial_patient_referral_type @initial_referral_type
json.initial_referral_type @initial_referral_type.try(:referral_type)
json.initial_sub_referral_type @initial_referral_type.try(:sub_referral_type)

json.apppointmentdate Date.current
json.apppointmenttime Time.current
json.organisation_id @current_user.organisation_id
json.department_id "485396012"

json.facilities @facilities.pluck(:id, :name)
json.selected_facility @selected_facility

json.available_specialties @available_specialties
json.selected_specialty @selected_specialty

json.current_doctors @available_doctors
json.selected_doctor @selected_doctor

json.patient_types @patient_types

json.appointment_types @appointment_types
json.appointment_category @sub_appointment_types.pluck(:id, :label)

json.patient @patient
if !@patient.blank?
  json.patientallergyhistory @patient.patient_history.try(:patientallergyhistory)
  json.patientpersonalhistory @patient.patient_history.try(:patientpersonalhistory)
end

json.patient_mrn @patient.patient_mrn
json.patient_identifier_id @patient.patient_identifier_id

json.appointmentslot @appointment_slots

json.occupation_list @occupation_list
