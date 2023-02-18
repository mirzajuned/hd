json.array!(@ot_list) do |list|
  json.set! "title", list.patient_name.to_s.upcase
  json.set! "backgroundColor", list.current_state_color
  json.set! "borderColor", list.current_state_color
  json.set! "start", "#{list.ot_date.strftime("%F")}T#{list.ot_time.strftime("%H:%M:%S.%L%:z")}"
  json.set! "end", "#{list.ot_date.strftime("%F")}T#{(list.ot_end_time).strftime("%H:%M:%S.%L%:z")}"
  json.set! "ot_id", list.ot_id.to_s
  json.set! "patient_id", list.patient_id.to_s
  json.set! "reason_for_admission", list.reason_for_admission.to_s
  json.set! "operating_doctor", list.operating_doctor.to_s
  json.set! "current_state", list.current_state.to_s
  json.set! "current_state_color", list.current_state_color.to_s
end
