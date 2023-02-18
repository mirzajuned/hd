json.array!(@investigations_array) do |investigation|
  json.label investigation.name.to_s
  json.value investigation.name.to_s
  json.investigation_id investigation.investigation_id
  json.investigation_type investigation.investigation_type
  json.investigation_type_label investigation.investigation_type_label
end
