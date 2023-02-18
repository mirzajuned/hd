# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_discharge_list_count
json.iTotalDisplayRecords @total_discharge_list_count
json.set! "aaData" do
  json.array!(@discharge_lists) do |discharge_list|
    # Date
    admission_date = discharge_list[:_id].strftime("%d/%m/%Y")

    # Table Data
    json.set! "0", admission_date
    json.set! "1", discharge_list[:discharge_count]
  end
end
