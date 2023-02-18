# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_clinical_workflow_count
json.iTotalDisplayRecords @total_clinical_workflow_count
json.set! "aaData" do
  json.array!(@clinical_workflows) do |clinical_workflow|
    user = @user_fields.find { |f| f[:id].to_s == clinical_workflow[:_id].to_s }

    if user.present?
      # Table Data
      json.set! "0", user[:fullname]
      json.set! "1", clinical_workflow[:optometrist_appointment_count]
    end
  end
end
