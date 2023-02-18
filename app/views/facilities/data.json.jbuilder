json.sEcho params[:sEcho]
json.iTotalRecords @total_facilities_count
json.iTotalDisplayRecords @facilities_count
json.set! "aaData" do
  count = 0
  json.array!(@facilities) do |facility|
    facilities_roles = []
    found_record = @facility_wise_roles.select { |ele| ele["#{facility.id}"] }

    if found_record
      if facility.is_active
        found_record = found_record.values[0]
        # roles = found_record[0].values[0]
        # roles.each do |role|
        #   role_link = "<a class='btn btn-primary btn-xs link_button' id='get_department_users' data-remote='true' href='/users?facility_id=" + facility.id.to_s + "&role_id=" + role[:role_id].to_s + "&facility_name=" + facility.name.to_s + "'>" + role[:name] + "</a>"

        #   facilities_roles << role_link
        # end
        if found_record
          found_record.each do |role_id, role|
            role_link = "<a class='btn btn-primary btn-xs link_button' id='get_department_users' data-remote='true' href='/users?facility_id=" + facility.id.to_s + "&level=" + params[:level] + "&role_id=" + role_id.to_s + "&facility_name=" + facility.name.to_s + "'>" + role["label"] + "</a>"
            facilities_roles << role_link
          end
        end
      else
        facilities_roles << "<span style='color:#428bca;opacity:0.5;font-style:italic;'>Activate Facility first</span>"
      end
    end

    # Address
    address = []
    address.push(facility.address)
    address.push(facility.city)
    address.push(facility.state)
    address.push(facility.district)
    address.push(facility.commune)
    address.push(facility.pincode)

    # Actions
    if facility.is_active
      edit_facility = "<a class='btn btn-primary btn-xs' style='margin:0 5px 5px 0;' href='/facilities/" + facility.id.to_s + "/edit' data-remote='true' data-toggle='modal' data-target='#facility-modal' ><i class='fa fa-pencil-square-o'></i> Edit </a>"
      if @current_facility.id.to_s != facility.id.to_s
        delete_facility = "<a class='btn btn-danger btn-xs' style='margin:0 5px 5px 0;' href='/facilities/" + facility.id.to_s + "' data-remote='true' data-confirm='Are you sure?' data-method='delete' rel='nofollow'><i class='fa fa-trash-alt'></i> Disable </a>"
      else
        delete_facility = "<a class='btn btn-danger btn-xs' style='margin:0 5px 5px 0;' disabled='disabled'><i class='fa fa-trash-alt'></i> Disable </a>"
      end

      link_users = "<a class='btn btn-success btn-xs' style='margin:0 5px 5px 0;' href='/users/link_unlink_multiple_users?facility_id=" + facility.id.to_s + "&flag=link' data-remote='true' data-toggle='modal' data-target='#user-modal'><i class='fa fa-link'></i>  Link users</a>"

      unlink_users = "<a class='btn btn-danger btn-xs' style='margin:0 5px 5px 0;' href='/users/link_unlink_multiple_users?facility_id=" + facility.id.to_s + "&flag=unlink' data-remote='true' data-toggle='modal' data-target='#user-modal'><i class='fa fa-unlink'></i>  Un-link users</a>"

      facility_actions = edit_facility.to_s + delete_facility.to_s + link_users.to_s + unlink_users.to_s
    else
      facility_actions = "<a class='btn btn-primary btn-xs' href='/facilities/activate?id=" + facility.id.to_s + "' data-remote='true'>Activate</a>"
    end
    # Data Displayed
    json.set! "0", count += 1
    json.set! "1", facility.name + "<div style='display: none'>#{facility.try(:integration_identifier)}</div>"
    json.set! "2", address.join("<br>")
    json.set! "3", facility.try(:email) + '<br/>' + facility.try(:telephone)
    json.set! "4", facilities_roles.join(" ")
    json.set! "5", facility_actions
  end
end
