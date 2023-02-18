json.sEcho params[:sEcho]
json.iTotalRecords @all_entity_groups_count
json.iTotalDisplayRecords @entity_groups_count
json.set! "aaData" do
  count = 0
  json.array!(@entity_groups) do |entity_group|
    # found_record = @entity_group_wise_roles.select { |ele| ele["#{entity_group.id}"] }

    # if found_record
    #   if entity_group.is_active
    #     found_record = found_record.values[0]
    #     if found_record
    #       found_record.each do |role_id, role|
    #         role_link = "<a class='btn btn-primary btn-xs link_button' id='get_department_users' data-remote='true' href='/users?entity_group_id=" + entity_group.id.to_s + "&level=" + params[:level] + "&role_id=" + role_id.to_s + "&entity_group_name=" + entity_group.name.to_s + "'>" + role["label"] + "</a>"
    #         entity_groups_roles << role_link
    #       end
    #     end
    #   else
    #     entity_groups_roles << "<span style='color:#428bca;opacity:0.5;font-style:italic;'>Activate Facility first</span>"
    #   end
    # end

    # Address
    address = []
    address.push(entity_group.address)
    address.push(entity_group.city)
    address.push(entity_group.state)
    address.push(entity_group.district)
    address.push(entity_group.commune)
    address.push(entity_group.pincode)

    # # Actions
    if entity_group.is_active
      edit_entity_group = "<a class='btn btn-primary btn-xs' style='margin:0 5px 5px 0;' href='/entity_groups/" + entity_group.id.to_s + "/edit' data-remote='true' data-toggle='modal' data-target='#entity-group-modal' ><i class='fa fa-pencil-square-o'></i> Edit </a>"
      delete_entity_group = "<a class='btn btn-danger btn-xs' style='margin:0 5px 5px 0;'><i class='fa fa-trash-alt'></i> Disable </a>"
      entity_group_actions = edit_entity_group.to_s + delete_entity_group.to_s
    else
      entity_group_actions = "<a class='btn btn-primary btn-xs' href='/entity_groups/activate?id=" + entity_group.id.to_s + "' data-remote='true'>Activate</a>"
    end
    # Data Displayed
    json.set! "0", count += 1
    json.set! "1", entity_group.name
    json.set! "2", entity_group.abbreviation
    json.set! "3", entity_group.display_name
    json.set! "4", address.join("<br>")
    json.set! "5", entity_group_actions
  end
end
