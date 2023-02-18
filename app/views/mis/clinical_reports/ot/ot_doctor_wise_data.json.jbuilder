# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_ot_list_count
json.iTotalDisplayRecords @total_ot_list_count
json.set! "aaData" do
  json.array!(@ot_lists) do |ot_list|
    user = @user_fields.find { |f| f[:id].to_s == ot_list[:_id].to_s }

    if user.present?
      # Table Data
      json.set! "0", user[:fullname]
      json.set! "1", ot_list[:doctor_ot_count]
    end
  end
end
