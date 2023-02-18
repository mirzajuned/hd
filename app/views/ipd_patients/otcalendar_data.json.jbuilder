json.array!(@ot_list) do |ot|
  json.set! "title", ot.patient.fullname
  if ot.admission_id.nil?
    json.set! "backgroundColor", '#fed156'
    json.set! "borderColor", '#fed156'
  else
    if ot.operation_done == false
      json.set! "backgroundColor", '#354670'
      json.set! "borderColor", '#354670'
    else
      json.set! "backgroundColor", '#5cb85c'
      json.set! "borderColor", '#5cb85c'
    end
  end
  json.set! "start", "#{ot.otdate.to_date.strftime("%F")}T#{ot.ottime.to_time.strftime("%H:%M:%S.%L%:z")}"
  json.set! "end", "#{ot.otdate.to_date.strftime("%F")}T#{(ot.otendtime).to_time.strftime("%H:%M:%S.%L%:z")}"
  json.set! "ot_id", ot.id.to_s
  json.set! "patient_id", ot.patient.id.to_s
end
