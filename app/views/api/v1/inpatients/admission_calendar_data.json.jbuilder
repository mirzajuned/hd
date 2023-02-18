json.array!(@admission_list) do |list|
  json.set! "title", list.patient_name.to_s.upcase
  json.set! "backgroundColor", list.current_state_color
  json.set! "borderColor", list.current_state_color
  if list.current_state == "Discharged"
    json.set! "start", "#{list.discharge_date.strftime("%F")}T#{list.discharge_time.strftime("%H:%M:%S.%L%:z")}"
    json.set! "end", "#{list.discharge_date.strftime("%F")}T#{(list.discharge_time + 30.minutes).strftime("%H:%M:%S.%L%:z")}"
  else
    json.set! "start", "#{list.admission_date.strftime("%F")}T#{list.admission_time.strftime("%H:%M:%S.%L%:z")}"
    json.set! "end", "#{list.admission_date.strftime("%F")}T#{(list.admission_time + 30.minutes).strftime("%H:%M:%S.%L%:z")}"
  end
  json.set! "admission_id", list.admission_id.to_s
  json.set! "patient_id", list.patient_id.to_s
  json.set! "reason_for_admission", list.reason_for_admission.to_s
  json.set! "admitting_doctor", list.admitting_doctor.to_s
  json.set! "current_state", list.current_state.to_s
  json.set! "current_state_color", list.current_state_color.to_s
end
