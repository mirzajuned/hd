# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_counsellor_workflow_count
json.iTotalDisplayRecords @total_counsellor_workflow_count
json.set! "aaData" do
  json.array!(@counsellor_workflows) do |counsellor_workflow|
    user = @user_fields.find { |f| f[:id].to_s == counsellor_workflow[:_id].to_s }

    if user.present?
      # Table Data
      json.set! "0", user[:fullname]
      json.set! "1", counsellor_workflow[:counsellor_appointment_count]
    end
  end
end
