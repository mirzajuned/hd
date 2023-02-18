json.array!(@ot_list) do |ot_list_view|
  json.id ot_list_view.ot_id.to_s
  json.label ot_list_view.patient_name
  json.value ot_list_view.patient_name
end
