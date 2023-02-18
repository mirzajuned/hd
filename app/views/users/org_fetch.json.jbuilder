json.sEcho @sEcho
json.iTotalRecords @users.count
json.iTotalDisplayRecords @users.count
count = 0
json.set! "aaData" do
  json.array!(@users) do |user|
    name = []
    count += 1

    button = "<span class='mr5'><button class='btn btn-warning btn-xs' id='edit_org_list' resource='users' n_id='" + user.id.to_s + "'><i class='fa fa-pencil-square-o'></i></button></span>" +
             (current_user.id != user.id ? "<span><button class='btn btn-danger pull-right btn-xs' id='remove_org_list' resource='users' n_id='" + user.id.to_s + "'><i class='fa  fa-trash-o'></i></button></span>" : "")

    # b = (user.has_role? :owner and user.has_role? :doctor) ? "main doctor" : user.roles.pluck(:name)
    b = (user.has_role? :doctor) ? "main doctor" : user.roles.pluck(:name).join(",")
    role = []

    if user.roles[1].present?
      role.push(user.roles[0].name.capitalize)
      role.push("&")
      role.push(user.roles[1].name.capitalize)
    else
      role.push(user.roles[0].name.capitalize)
    end
    name.push(user.salutation)
    name.push(user.fullname)
    json.set! "0", count
    json.set! "1", name.join(" ")
    json.set! "2", user.email
    json.set! "3", role.join(" ")
    json.set! "4", (user.facilities.pluck(:name)).join(" ; ")
    json.set! "5", button
  end
end
