# json.array!(@investigations) do |investigation|
#   json.laterality investigation['laterality']
#   json.loinc_code investigation['loinc_code']
# end
json.array!(@investigations) do |investigation|
  options = investigation.try(:options)
  if options != nil
    investigation.options.each do |inv|
      json.laterality inv['laterality']
      json.loinc_code inv['loinc_code']
    end
  end

  json.investigation_type_id investigation['investigation_type_id']
end
