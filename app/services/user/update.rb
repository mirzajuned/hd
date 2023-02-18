class User::Update

  def self.update_dropdown_attributes_in_redis_master(organisation_id)
    Time.zone = 'Asia/Kolkata'
    date = Date.current.strftime('%d%m%Y')
    @redis_master = Redis::Master.new

    # Update User DropDown Attributes that are fetched from Organisation Settings to each User Dropdown.
    # Attributes such as :assign_patients_to_offline_user, :clear_my_queue_before_offline, :assign_patients_to_ot_user, :clear_my_queue_before_ot
    # Refer Auto Online and Offline Feature for more details
    User.where(is_active: true, organisation_id: organisation_id).each do |user|
      organisation_id = organisation_id.to_s
      organisation = Organisation.find_by(id: organisation_id)

      # Updating Current Organisation field in Redis Local
      oldloggedin_organisation = Redis::Local.new.get("organisation:#{organisation_id}")
      # Remove the OLD entry from ehr:current:list.
      oldloggedin_organisation_hash = { "organisation:#{organisation_id}" => JSON.parse(oldloggedin_organisation) }
      Redis::Master.new.lrem('ehr:current:list', -1, oldloggedin_organisation_hash.to_json)

      # Adding the NEW entry from ehr:current:list.
      loggedin_organisation = organisation.to_json
      Redis::Local.new.set("organisation:#{organisation_id}", loggedin_organisation)
      current_hash = { "organisation:#{organisation_id}" => JSON.parse(loggedin_organisation) }
      Redis::Master.new.rpush('ehr:current:list', current_hash.to_json)

      # Broadcasting udated user object to sync the updated loggedin_organisation i.e. User information in Redis::Local of currently running servers.
      current_json = { "organisation:#{organisation_id}" => loggedin_organisation }
      Redis::Master.new.xadd('ehr:redis_key', current_json, id: '*')

      user.facilities.each do |facility|
        facility_id = facility.id.to_s
        user_state = UserState.find_by(user_id: user.id, facility_id: facility_id)
        active_state = user_state.try(:active_state)
        state_color = user_state.try(:state_color)
        if user.specialty_ids.count > 0
          user.specialty_ids.each do |specialty_id|
            next unless facility.specialty_ids.include?(specialty_id)
            hmset_key = "facility:#{facility_id}:date:#{date}:specialty_id:#{specialty_id}:user:#{user.id}"
            hmset_key_hash = "hash_key:facility:#{facility_id}:date:#{date}:specialty_id:#{specialty_id}:user:#{user.id}"
            @redis_master.hmset(hmset_key_hash, :active_state, active_state.to_s, :state_color, state_color.to_s,
                                :auto_offline_on_logout, "#{organisation['auto_offline_on_logout']}",
                                :assign_patients_to_offline_user, "#{organisation['assign_patients_to_offline_user']}",
                                :clear_my_queue_before_offline, "#{organisation['clear_my_queue_before_offline']}",
                                :assign_patients_to_ot_user, "#{organisation['assign_patients_to_ot_user']}",
                                :clear_my_queue_before_ot, "#{organisation['clear_my_queue_before_ot']}")
          end
        else
          hmset_key = "facility:#{facility_id}:date:#{date}:user:#{user.id}"
          hmset_key_hash = "hash_key:facility:#{facility_id}:date:#{date}:user:#{user.id}"
          @redis_master.hmset(hmset_key_hash, :active_state, active_state.to_s, :state_color, state_color.to_s,
                              :auto_offline_on_logout, "#{organisation['auto_offline_on_logout']}",
                              :assign_patients_to_offline_user, "#{organisation['assign_patients_to_offline_user']}",
                              :clear_my_queue_before_offline, "#{organisation['clear_my_queue_before_offline']}",
                              :assign_patients_to_ot_user, "#{organisation['assign_patients_to_ot_user']}",
                              :clear_my_queue_before_ot, "#{organisation['clear_my_queue_before_ot']}")
        end
      end
    end

  end

end
