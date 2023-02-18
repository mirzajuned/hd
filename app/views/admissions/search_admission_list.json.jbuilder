json.array!(@admission_list) do |admission_list_view|
  json.id admission_list_view.admission_id.to_s
  json.label admission_list_view.patient_name
  json.value admission_list_view.patient_name
end
