# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_admission_list_count
json.iTotalDisplayRecords @total_admission_list_count
json.set! "aaData" do
  json.array!(@admission_lists) do |admission_list|
    facility = @facility_fields.find { |f| f[:id].to_s == admission_list[:_id].to_s }

    if facility.present?
      current_state_counts = admission_list["current_state_counts"]
      # ["Engaged", "Completed", "Scheduled", "Waiting", "Deleted"]
      scheduled = current_state_counts.find { |cs| cs["state_name"] == "Scheduled" } || {}
      completed = current_state_counts.find { |cs| cs["state_name"] == "Admitted" } || {}
      discharged = current_state_counts.find { |cs| cs["state_name"] == "Discharged" } || {}
      deleted = current_state_counts.find { |cs| cs["state_name"] == "Deleted" } || {}

      scheduled_count = scheduled["state_count"].to_i
      completed_count = completed["state_count"].to_i
      discharged_count = discharged["state_count"].to_i
      deleted_count = deleted["state_count"].to_i
      total_count = scheduled_count + completed_count + discharged_count + deleted_count

      # Table Data
      json.set! "0", facility[:name]
      json.set! "1", scheduled_count
      json.set! "2", completed_count
      json.set! "3", discharged_count
      json.set! "4", deleted_count
      json.set! "5", total_count
    end
  end
end
