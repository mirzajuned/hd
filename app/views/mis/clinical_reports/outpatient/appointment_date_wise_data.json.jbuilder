# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_appointment_list_count
json.iTotalDisplayRecords @total_appointment_list_count
json.set! "aaData" do
  json.array!(@appointment_lists) do |appointment_list|
    current_state_group = appointment_list[:appointment_list].group_by { |al| al[:current_state] }

    # Date
    appointment_date = appointment_list[:_id].strftime("%d/%m/%Y")

    # ["Engaged", "Completed", "Scheduled", "Waiting", "Deleted"]
    not_arrived = current_state_group["Scheduled"].to_a.count
    completed = current_state_group["Completed"].to_a.count
    incomplete = current_state_group["Waiting"].to_a.count + current_state_group["Engaged"].to_a.count + current_state_group["Incompleted"].to_a.count
    deleted = current_state_group["Deleted"].to_a.count
    total = not_arrived + completed + incomplete + deleted

    # Table Data
    json.set! "0", appointment_date
    json.set! "1", not_arrived
    json.set! "2", completed
    json.set! "3", incomplete
    json.set! "4", deleted
    json.set! "5", total
  end
end
