json.set! 'total_diagnosis_count_counts' do
  json.total_diagnosis @total_diagnosis
  json.total_procedure @total_procedure
  json.total_ophthal_investigations_list @total_ophthal_investigations_list
  json.total_laboratory_investigations_list @total_laboratory_investigations_list
  json.total_radiology_investigations_list @total_radiology_investigations_list
end

json.set! "top_ten_diagnoses" do
  json.top_ten_diagnosis_labels @top_ten_diagnosis_labels
  json.top_ten_diagnosis_data @top_ten_diagnosis_data
end

json.set! "top_ten_procedures" do
  json.top_ten_procedure_labels @top_ten_procedure_labels
  json.top_ten_procedure_data @top_ten_procedure_data
end

json.set! "top_ten_laboratory_investigations" do
  json.top_ten_laboratory_labels @top_ten_laboratory_labels
  json.top_ten_laboratory_data @top_ten_laboratory_data
end

json.set! "top_ten_radiology_investigations" do
  json.top_ten_radiology_labels @top_ten_radiology_labels
  json.top_ten_radiology_data @top_ten_radiology_data
end

json.set! "top_ten_ophthal_investigations" do
  json.top_ten_ophthal_labels @top_ten_ophthal_labels
  json.top_ten_ophthal_data @top_ten_ophthal_data
end

json.set! "laboratory_investigation_data" do
  json.laboratory_investigation_label @laboratory_investigation_label
  json.laboratory_investigation_data @laboratory_investigation_data
end
