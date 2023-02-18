json.appointment_id @appointment.id
json.patient_id @patient.id
json.facility_id @facility.id
json.start_time Time.current.strftime('%I:%M %p %d/%m/%Y')
json.doctors @doctors
json.eye_drops @eye_drops
json.eyedrop_allergy @eyedrop_allergy
json.last_dilation @last_dilation
