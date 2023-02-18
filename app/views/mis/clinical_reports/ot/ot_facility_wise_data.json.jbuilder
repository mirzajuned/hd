# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_ot_list_count
json.iTotalDisplayRecords @total_ot_list_count
json.set! "aaData" do
  json.array!(@ot_lists) do |ot_list|
    facility = @facility_fields.find { |f| f[:id].to_s == ot_list[:_id].to_s }

    if facility.present?
      current_state_counts = ot_list["current_state_counts"]
      # ["Engaged", "Completed", "Scheduled", "Waiting", "Deleted"]
      scheduled = current_state_counts.find { |cs| cs["state_name"] == "Scheduled" } || {}
      admitted = current_state_counts.find { |cs| cs["state_name"] == "Admitted" } || {}
      engaged = current_state_counts.find { |cs| cs["state_name"] == "Engaged" } || {}
      deleted = current_state_counts.find { |cs| cs["state_name"] == "Deleted" } || {}
      completed = current_state_counts.find { |cs| cs["state_name"] == "Completed" } || {}

      scheduled_count = scheduled["state_count"].to_i
      admitted_count = admitted["state_count"].to_i
      engaged_count = engaged["state_count"].to_i
      deleted_count = deleted["state_count"].to_i
      completed_count = completed["state_count"].to_i
      total_count = scheduled_count + admitted_count + engaged_count + deleted_count + completed_count

      # Table Data
      json.set! "0", facility[:name]
      json.set! "1", scheduled_count
      json.set! "2", admitted_count
      json.set! "3", engaged_count
      json.set! "4", deleted_count
      json.set! "5", completed_count
      json.set! "6", total_count
    end
  end
end
