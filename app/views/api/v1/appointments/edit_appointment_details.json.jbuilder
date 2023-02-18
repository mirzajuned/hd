json.appointmentdate @appointment.appointmentdate.strftime("%d/%m/%Y")
json.appointmenttime @appointment.start_time.try(:strftime, '%I:%M %p')
json.selected_facility [@selected_facility.id.to_s, @selected_facility.name]
json.selected_doctor [@selected_doctor.id, @selected_doctor.fullname]
json.selected_apppointment_type_id @appointment.appointment_type_id
json.facilities @facilities.pluck(:id, :name)
json.current_doctors @current_doctors.pluck(:id, :fullname)
json.appointment_type  @appointment_type
json.appointment_slots @appointment_slots
json.organisation_id @selected_doctor.organisation_id
json.department_id @selected_doctor.department_id
json.appointment_category @appointment_category.pluck(:id, :label)
json.appointment_category_selected @appointment.appointment_category_id
json.appointmenttype_selected @appointment.appointmenttype
