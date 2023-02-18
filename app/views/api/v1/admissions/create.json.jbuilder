if @status_flag
  json.status 'success'
  json.id @admission.id.to_s
else
  json.status 'failed'
end
