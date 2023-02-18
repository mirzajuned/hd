json.created @status_flag
if @status_flag
  json.picthumb @patientasset.asset_path_url(:api_thumb)
  json.picactual @patientasset.asset_path_url
end
