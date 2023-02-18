if @status_flag
  json.status 'Admission deleted'
  json.id @admission.id.to_s
else
  json.status 'failed to delete'
end
