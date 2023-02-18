json.array!(@laboratorylist) do |laboratory|
  json.id laboratory.investigation_id
  json.label laboratory.investigation_name
  json.set! :value do
    json.investigation_name laboratory.investigation_name
    json.investigation_id laboratory.investigation_id
  end
end
