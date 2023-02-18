json.created @status_flag
json.parent_id @patientsummaryuploads.parent_id
if @status_flag
  json.filethumb @patientsummaryuploads.asset_path_url(:api_thumb)
  json.fileactual @patientsummaryuploads.asset_path_url
end
