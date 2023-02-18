json.array!(@icd_code_array) do |icd_diagnosis|
  json.id icd_diagnosis.id.to_s
  json.label icd_diagnosis.originalname
  json.value icd_diagnosis.fullname
  json.code icd_diagnosis.code
  json.icd_type icd_diagnosis.icd_type
  json.icd_type_label icd_diagnosis.icd_type_label
end
