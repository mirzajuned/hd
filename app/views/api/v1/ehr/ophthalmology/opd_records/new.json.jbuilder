json.action "new"
json.opdrecord @opdrecord
json.optometrist_fullname_array @optometrist_fullname_array if @optometrist_fullname_array.present?
json.optometrist_ids_array @optometrist_ids_array if @optometrist_ids_array.present?
json.doctors_array @doctors_array if @doctors_array.present?
json.patient_self_history @patient_self_history
json.optometrist_record @optometrist_record if @optometrist_record.present?
json.facility_id @facility_id

json.patient_history @patient.patient_history
json.patient_specialstatus @patient.specialstatus
# json.patient @patient
json.patient_identifier_id @patient.patient_identifier_id

json.mr_no PatientOtherIdentifier.find_by(patient_id: @patient.id).mr_no

if @patient.calculate_age.present? || @patient.gender.present?
  patient_age_gender = @patient.calculate_age.to_s + "/" + @patient.gender.to_s
else
  patient_age_gender = "Unavailable"
end

json.patient_age_gender patient_age_gender
json.patient_name @patient.fullname
json.patient_mobilenumber @patient.mobilenumber

json.appointment_display_id @appointment.display_id
json.appointmentdate @appointment.appointmentdate.strftime("%d %b'%y")
json.facility_name @appointment.facility.name
