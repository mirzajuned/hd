# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_appointment_list_count
json.iTotalDisplayRecords @total_appointment_list_count
json.set! "aaData" do
  json.array!(@appointment_lists) do |appointment_list|
    facility = @facility_fields.find { |f| f[:id].to_s == appointment_list[:_id].to_s }

    if facility.present?
      current_state_counts = appointment_list["current_state_counts"]
      # ["Engaged", "Completed", "Scheduled", "Waiting", "Deleted"]
      not_arrived = current_state_counts.find { |cs| cs["state_name"] == "Scheduled" } || {}
      completed = current_state_counts.find { |cs| cs["state_name"] == "Completed" } || {}
      waiting = current_state_counts.find { |cs| cs["state_name"] == "Waiting" } || {}
      engaged = current_state_counts.find { |cs| cs["state_name"] == "Engaged" } || {}
      incomplete = current_state_counts.find { |cs| cs["state_name"] == "Incompleted" } || {}
      deleted = current_state_counts.find { |cs| cs["state_name"] == "Deleted" } || {}

      not_arrived_count = not_arrived["state_count"].to_i
      completed_count = completed["state_count"].to_i
      incomplete_count = incomplete["state_count"].to_i + waiting["state_count"].to_i + engaged["state_count"].to_i
      deleted_count = deleted["state_count"].to_i
      total_count = not_arrived_count + completed_count + incomplete_count + deleted_count

      # Table Data
      json.set! "0", facility[:name]
      json.set! "1", not_arrived_count
      json.set! "2", completed_count
      json.set! "3", incomplete_count
      json.set! "4", deleted_count
      json.set! "5", total_count
    end
  end
end
