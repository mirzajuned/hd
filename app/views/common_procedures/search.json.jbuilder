json.array!(@procedures_array) do |common_procedure|
  json.label common_procedure.name.to_s # + " (" + common_procedure.region.map(&:capitalize).join(', ') + ")"
  json.value common_procedure.name.to_s # + " (" + common_procedure.region.map(&:capitalize).join(', ') + ")"
  json.code common_procedure.code
  json.procedure_type common_procedure.procedure_type
  json.procedure_type_label common_procedure.procedure_type_label
end
