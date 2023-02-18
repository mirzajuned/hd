json.array!(@investigations_array) do |investigation|
  if investigation.try(:radiology_type).present?
    json.label investigation.try(:radiology_type) + ", " + investigation.name.to_s
    json.value investigation.try(:radiology_type) + ", " + investigation.name.to_s
  else
    json.label investigation.name.to_s
    json.value investigation.name.to_s
  end
  json.investigation_id investigation.investigation_id
  json.investigation_type investigation.investigation_type
  json.investigation_type_label investigation.investigation_type_label
end
