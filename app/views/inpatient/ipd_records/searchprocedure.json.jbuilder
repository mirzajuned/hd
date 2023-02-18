json.array!(@procedure) do |procedure|
  json.id procedure.id.to_s
  json.label procedure.procedure_name
  json.value procedure.procedure_name
  json.code procedure.procedure_id
end
