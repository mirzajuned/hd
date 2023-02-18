json.array!(@patient_list) do |patient|
  json.id patient.id.to_s
  json.label patient.fullname
  json.value patient.fullname
end
