json.iTotalRecords @total_users_count
json.iTotalDisplayRecords @users_count

count = 0
all_roles = Global.send("user_roles")

json.set! "aaData" do
    json.array!(@users) do |user|
        
        count+=1
        name = []
        name.push(user.salutation)
        name.push(user.fullname)

        role_arr = []

        user.role_ids.each do |role_id|
            role = all_roles["#{role_id.to_s}"]
            role_arr << all_roles["#{role_id.to_s}"]["label"] if role.present?
        end

        role_arr = '<br><span class="label label-info"> ' + role_arr.join(" & ") + ' </span>'
        name << role_arr

        address = []
        address.push(user.address)
        address.push(user.city)
        address.push(user.state)
        address.push(user.district)
        address.push(user.commune)
        address.push(user.pincode)

        facilities = []
        user.facilities.each do |facility|
            if facility.is_active    
                facilities.push(facility.name)
            end
        end

        if @current_user.role_ids.include?(686800945) && user.role_ids.any? { |i| [160943002, 6868009].include? i }
            if user.is_active?
                edit_user = "<span class ='mr5'><a class='btn btn-primary btn-xs' href='/users/" + user.id.to_s + "/edit' data-remote='true' data-toggle='modal' data-target='#user-modal' disabled='disabled'><i class='fa fa-pencil-square-o' ></i>  Edit</a></span> <br>"
                if @current_user.id.to_s != user.id.to_s
                    delete_user = "<span><a class='btn btn-danger btn-xs' style='margin-top: 4px;' disabled='disabled'><i class='fa fa-trash-alt'></i>  Disable</a></span>"
                end

                user_policy = "<span class ='mr5'><a class='btn btn-primary btn-xs' href='/authorization/user_policies/add_policy?user_id=" + user.id.to_s + "' data-remote='true' data-toggle='modal' data-target='#user-policy-modal' disabled='disabled'>Policy</a></span>"

                reset_user_password = "<span class ='mr5'><a class='btn btn-primary btn-xs' href='/users/reset_password?id=" + user.id.to_s + "' data-remote='true' data-toggle='modal' data-target='#user-modal' disabled='disabled'>Reset Password</a></span>"

                link_facilities = "<span><a class='btn btn-success btn-xs' style='margin: 4px 0px;padding-right: 25px;' href='/users/link_unlink_multiple_facilities?user_id=" + user.id.to_s + "&level=" + params[:level] + "&flag=link' data-remote='true' data-toggle='modal' data-target='#user-modal' disabled='disabled'><i class='fa fa-link'></i>  Link Facilities</a></span>"

                if user.facility_ids.count > 1
                    unlink_facilities = "<span><a class='btn btn-danger btn-xs' href='/users/link_unlink_multiple_facilities?user_id=" + user.id.to_s + "&flag=unlink' data-remote='true' data-toggle='modal' data-target='#user-modal' disabled='disabled'><i class='fa fa-unlink' ></i>  Un-link Facilities</a></span>"
                end

                user_actions = edit_user.to_s + delete_user.to_s + link_facilities.to_s + unlink_facilities.to_s + reset_user_password.to_s + user_policy.to_s
            else
                if user.username.present?
                    user_actions = "<span><a class='btn btn-info btn-xs' href='/users/activate_button?id=" + user.id.to_s + "' data-remote='true' rel='nofollow' disabled='disabled'>Activate</span>"
                else
                    user_actions = "<span class ='mr5'><a class='btn btn-primary btn-xs' href='/users/edit_email?id=" + user.id.to_s + "' data-remote='true' data-toggle='modal' data-target='#user-modal' disabled='disabled'>Activate</a></span>"
                    delete_user = "<span><a class='btn btn-danger btn-xs' href='/users/" + user.id.to_s + "' data-remote='true' data-confirm='This will delete PERMANENTLY. Are you sure?' data-method='delete' rel='nofollow' disabled='disabled'><i class='fa fa-trash-alt'></i>  Delete</a></span>"
                    user_actions = user_actions.to_s + delete_user.to_s
                end
            end
        else
            if user.is_active?
                edit_user = "<span class ='mr5'><a class='btn btn-primary btn-xs' href='/users/" + user.id.to_s + "/edit' data-remote='true' data-toggle='modal' data-target='#user-modal' ><i class='fa fa-pencil-square-o'></i>  Edit</a></span> <br>"
    
                if @current_user.id.to_s != user.id.to_s
                    delete_user = "<span><a class='btn btn-danger btn-xs' style='margin-top: 4px;' href='/users/" + user.id.to_s + "' data-remote='true' data-confirm='Are you sure?' data-method='delete' rel='nofollow'><i class='fa fa-trash-alt'></i>  Disable</a></span>"
                else
                    delete_user = "<span><a class='btn btn-danger btn-xs' style='margin-top: 4px;' disabled='disabled'><i class='fa fa-trash-alt'></i>  Disable</a></span>"
                end

                reset_user_password = "<span class ='mr5'><a class='btn btn-primary btn-xs' href='/users/reset_password?id=" + user.id.to_s + "' data-remote='true' data-toggle='modal' data-target='#user-modal' >Reset Password</a></span>"

                user_policy = "<span class ='mr5'><a class='btn btn-primary btn-xs' href='/authorization/user_policies/add_policy?user_id=" + user.id.to_s + "' data-remote='true' data-toggle='modal' data-target='#user-policy-modal'>Policy</a></span>"

                link_facilities = "<span><a class='btn btn-success btn-xs' style='margin: 4px 0px;padding-right: 25px;' href='/users/link_unlink_multiple_facilities?user_id=" + user.id.to_s + "&level=organisation" + "&flag=link' data-remote='true' data-toggle='modal' data-target='#user-modal'><i class='fa fa-link'></i>  Link Facilities</a></span>"

                if user.facility_ids.count > 1
                    unlink_facilities = "<span><a class='btn btn-danger btn-xs' href='/users/link_unlink_multiple_facilities?user_id=" + user.id.to_s + "&flag=unlink' data-remote='true' data-toggle='modal' data-target='#user-modal'><i class='fa fa-unlink'></i>  Un-link Facilities</a></span>"
                end

                user_actions = edit_user.to_s + delete_user.to_s + link_facilities.to_s + unlink_facilities.to_s + reset_user_password.to_s + user_policy.to_s
            else
                if user.username.present?
                    user_actions = "<span><a class='btn btn-info btn-xs' href='/users/activate_button?id=" + user.id.to_s + "' data-remote='true' rel='nofollow'>Activate</span>"
                else
                    user_actions = "<span class ='mr5'><a class='btn btn-primary btn-xs' href='/users/edit_email?id=" + user.id.to_s + "' data-remote='true' data-toggle='modal' data-target='#user-modal' >Activate</a></span>"
                    delete_user = "<span><a class='btn btn-danger btn-xs' href='/users/" + user.id.to_s + "' data-remote='true' data-confirm='This will delete PERMANENTLY. Are you sure?' data-method='delete' rel='nofollow'><i class='fa fa-trash-alt'></i>  Delete</a></span>"
                    user_actions = user_actions.to_s + delete_user.to_s
                end
            end
        end
        
        json.set! "0", count
        json.set! "1", name.join(" ")
        json.set! "2", facilities.join("<br>")
        json.set! "3", user.try(:designation).to_s
        json.set! "4", address.join("<br>") + ' / ' + user.try(:mobilenumber).to_s
        json.set! "5", user.try(:email).to_s + " / " + user.try(:username).to_s + "<div style='display: none'>#{user.try(:integration_identifier)}</div>"
        json.set! "6", user.specialty_names.count > 0 ? user.specialty_names.map { |ele| "<div class='row'><div style='margin-left:15px;margin-bottom:-10px;'>#{ele.upcase}</div></div>" }.join("<br>") : '-'
        json.set! "7", user_actions
    end
end