json.apppointmentdate @appointment_date
json.apppointmenttime Time.current
json.organisation_id @current_user.organisation_id
json.department_id '485396012'
json.current_user_id @current_user.id
json.current_facility_id @current_facility.id

json.facilities @facilities.pluck(:id, :name)
json.selected_facility @selected_facility.id

json.available_specialties @available_specialties
json.selected_specialty @selected_specialty

json.current_doctors @available_doctors
json.selected_doctor @selected_doctor

json.appointment_types @appointment_types
json.appointment_category @sub_appointment_types.pluck(:id, :label)

json.appointmentslot @appointment_slots
