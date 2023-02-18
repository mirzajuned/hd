# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_ot_list_count
json.iTotalDisplayRecords @total_ot_list_count
json.set! "aaData" do
  json.array!(@ot_lists) do |ot_list|
    current_state_group = ot_list[:ot_list].group_by { |al| al[:current_state] }

    # Date
    ot_date = ot_list[:_id].strftime("%d/%m/%Y")

    # ["Deleted", "Scheduled", "Discharged", "Admitted"]
    scheduled = current_state_group["Scheduled"].to_a.count
    completed = current_state_group["Admitted"].to_a.count
    discharged = current_state_group["Discharged"].to_a.count
    deleted = current_state_group["Deleted"].to_a.count
    total = scheduled + completed + discharged + deleted

    # Table Data
    json.set! "0", ot_date
    json.set! "1", scheduled
    json.set! "2", completed
    json.set! "3", discharged
    json.set! "4", deleted
    json.set! "5", total
  end
end
