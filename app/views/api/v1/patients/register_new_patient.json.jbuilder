if @status_flag
  json.status "success"
  json.id @patient.id.to_s
  json.display_id @patient_identifier.try(:patient_org_id)
  json.picthumb @patient.patientassets.present? ? @patient.patientassets.last.asset_path_url(:api_thumb) : ''
  json.picactual @patient.patientassets.present? ? @patient.patientassets.last.asset_path_url : ''
else
  json.status "failure"
end
