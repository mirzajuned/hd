json.array!(@appointment_list) do |appointment|
  json.set! "title", appointment.patient.fullname
  json.set! "start", "#{appointment.appointmentdate.to_date.strftime("%F")}T#{appointment.start_time.to_time.strftime("%H:%M:%S.%L%:z")}"
  json.set! "end", "#{appointment.appointmentdate.to_date.strftime("%F")}T#{appointment.end_time.to_time.strftime("%H:%M:%S.%L%:z")}"
  json.set! "backgroundColor", appointment.appointment_type.try(:background)
  json.set! "borderColor", appointment.appointment_type.try(:background)
  json.set! "appointment_id", appointment.id.to_s
  json.set! "patient_id", appointment.patient.id.to_s
  json.appointment_status appointment.appointmentstatus
  json.appointment_state appointment.current_state
  json.dilation_start_time appointment.dilation_start_time
  json.dilation_end_time appointment.dilation_end_time
  if appointment.dilation_start_time != nil
    json.difference TimeDifference.between(appointment.dilation_start_time, Time.current).in_seconds.to_i
  end
  if appointment.dilation_start_time != nil && appointment.dilation_end_time != nil
    json.end_difference Time.at(TimeDifference.between(appointment.dilation_start_time, appointment.dilation_end_time).in_seconds.to_i).utc.strftime("%M:%S")
  end
end
