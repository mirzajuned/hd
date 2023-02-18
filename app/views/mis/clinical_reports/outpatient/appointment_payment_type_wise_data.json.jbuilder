# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_appointment_list_count
json.iTotalDisplayRecords @total_appointment_list_count
json.set! "aaData" do
  json.array!(@appointment_lists) do |appointment_list|
    if appointment_list[:_id].present?
      # Table Data
      json.set! "0", appointment_list[:_id]
      json.set! "1", appointment_list[:appointment_count]
    end
  end
end
