# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_appointment_count
json.iTotalDisplayRecords @total_appointment_count
json.set! "aaData" do
  json.array!(@appointments) do |appointment|
    # Table Data
    if appointment[:_id]
      json.set! "0", appointment[:_id].to_s.upcase
      json.set! "1", appointment[:appointment_count]
    end
  end
end
