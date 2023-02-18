# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_admission_list_count
json.iTotalDisplayRecords @total_admission_list_count
json.set! "aaData" do
  json.array!(@admission_lists) do |admission_list|
    user = @user_fields.find { |f| f[:id].to_s == admission_list[:_id].to_s }

    if user.present?
      # Table Data
      json.set! "0", user[:fullname]
      json.set! "1", admission_list[:doctor_admission_count]
    end
  end
end
