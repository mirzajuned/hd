json.sEcho params[:sEcho]
json.iTotalRecords @total_facilities_count
json.iTotalDisplayRecords @facilities_count
count = 0
json.set! "aaData" do
  json.array!(@facilities) do |facility|
    names = []
    facility.departments.each do |department|
      names.push(department.name)
    end
    address = []
    address.push(facility.address)
    address.push(facility.city)
    address.push(facility.state)
    address.push(facility.pincode)
    count += 1
    json.set! "0", count
    json.set! "1", facility.name
    json.set! "2",  address.join("<br>")
    json.set! "3", facility.telephone
    json.set! "4", facility.email
    json.set! "5", names.join("<br>")
    json.set! "6", "<button class='btn btn-warning btn-xs' id='edit_org_list' resource='facilities' n_id='" + facility.id + "'><i class='fa fa-pencil-square-o'></i></button>" +
                   (current_user.facilities.first.id != facility.id ? "<button class='btn btn-danger pull-right btn-xs' id='remove_org_list' resource='facilities' n_id='" + facility.id + "'><i class='fa fa-trash-alt'></i></button>" : "")
    # json.set! "7", render('facilities/clinical_workflow.html', facility: facility)
  end
end
