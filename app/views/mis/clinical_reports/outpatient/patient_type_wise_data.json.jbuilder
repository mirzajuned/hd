# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_patient_type_count
json.iTotalDisplayRecords @total_patient_type_count
json.set! "aaData" do
  json.array!(@patient_types) do |patient_type|
    # Table Data
    if patient_type[:_id]
      json.set! "0", patient_type[:_id] || "<i>No Patient Type</i>"
      json.set! "1", patient_type[:patient_type_count]
    end
  end
end
