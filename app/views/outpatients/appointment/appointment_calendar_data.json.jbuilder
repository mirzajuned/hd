json.array!(@appointment_list) do |list|
  json.set! "title", list.patient_name.to_s.upcase
  json.set! "backgroundColor", list.current_state_color
  json.set! "borderColor", list.current_state_color
  json.set! "start", "#{list.appointment_date.try(:strftime, "%F")}T#{list.appointment_start_time.try(:strftime, "%H:%M:%S.%L%:z")}"
  json.set! "end", "#{list.appointment_date.try(:strftime, "%F")}T#{(list.appointment_start_time + 15.minutes).strftime("%H:%M:%S.%L%:z")}"
  json.set! "appointment_id", list.appointment_id.to_s
  json.set! "patient_id", list.patient_id.to_s
  json.set! "consulting_doctor", list.consulting_doctor.to_s
  json.set! "current_state", list.current_state.to_s
  json.set! "current_state_color", list.current_state_color.to_s
  json.set! "dilation_state", list.dilation_state.to_s
  json.set! "dilation_state_color", list.dilation_state_color.to_s
end
