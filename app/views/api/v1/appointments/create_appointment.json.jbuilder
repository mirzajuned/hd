if @status_flag
  json.status "success"
  json.id @appointment.id.to_s
  json.display_id @appointment.display_id.to_s
else
  json.status "failure"
end
