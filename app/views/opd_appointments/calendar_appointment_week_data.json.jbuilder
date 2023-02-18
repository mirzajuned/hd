json.array!(@appointment_list) do |appointment|
  json.set! "title", appointment.patient.fullname
  json.set! "start", "#{appointment.appointmentdate.to_date.strftime("%F")}T#{appointment.start_time.to_time.strftime("%H:%M:%S.%L%:z")}"
  json.set! "end", "#{appointment.appointmentdate.to_date.strftime("%F")}T#{appointment.end_time.to_time.strftime("%H:%M:%S.%L%:z")}"
  json.set! "backgroundColor", appointment.appointment_type.background
  json.set! "borderColor", appointment.appointment_type.background
  json.set! "appointment_id", appointment.id.to_s
  json.set! "patient_id", appointment.patient.id.to_s
end
