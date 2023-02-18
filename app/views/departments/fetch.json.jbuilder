json.sEcho @sEcho
json.iTotalRecords @total_departments_count
json.iTotalDisplayRecords @departments_count
json.set! "aaData" do
  json.array!(@departments) do |department|
    json.set! "0", ""
    json.set! "1", ""
    json.set! "2", "<a id='get_org_children' resource='users' n_id='" + department.id.to_s + "' facility_id='" + @facility.id + "'>" + department.name + "</a>"
    json.set! "3", ""
    json.set! "4", ""
    json.set! "5", ""
    json.set! "6", ""
  end
end
