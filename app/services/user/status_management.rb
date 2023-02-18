class User::StatusManagement

  class << self

    def on_login(current_user_id, current_facility_id, organisation_id)
      organisation = Organisation.find_by(id: organisation_id.to_s)
      auto_offline_on_logout_flag = organisation["auto_offline_on_logout"]
      if auto_offline_on_logout_flag
        user = User.find_by(id: current_user_id.to_s)
        user_role = user.primary_role
        if ['doctor'].include?(user_role)
          user_state_for_currentfacility = UserState.find_by(user_id: current_user_id.to_s, facility_id: current_facility_id.to_s)
          if ["OPD", "OT"].include?(user&.last_known_state_at_logout)
            user_state_for_currentfacility.update_attributes(active_state: "OPD", state_color: "#008000", inactive_states: [["OT", "#f0ad4e"], ["Offline", "#ff0000"]])
            update_user_state_in_redis(user, user_state_for_currentfacility.facility_id, "OPD", "#008000")
          else
            user_state_for_currentfacility.update_attributes(active_state: "Offline", state_color: "#ff0000", inactive_states: [["OPD", "#008000"], ["OT", "#f0ad4e"]])
            update_user_state_in_redis(user, user_state_for_currentfacility.facility_id, "Offline", "#ff0000")
          end
        end
      end
    end

    def on_logout(current_user_id, current_facility_id, organisation_id)
      organisation = Organisation.find_by(id: organisation_id.to_s)
      auto_offline_on_logout_flag = organisation["auto_offline_on_logout"]
      if auto_offline_on_logout_flag
        user = User.find_by(id: current_user_id.to_s)
        user_role = user.primary_role
        if ['doctor'].include?(user_role)
          user_state_for_currentfacility = UserState.find_by(user_id: current_user_id.to_s, facility_id: current_facility_id.to_s)
          if ["OPD", "OT"].include?(user_state_for_currentfacility&.active_state)
            user.update_attribute(:last_known_state_at_logout, "OPD")
          else
            user.update_attribute(:last_known_state_at_logout, "Offline")
          end
          users_state = UserState.where(user_id: current_user_id.to_s)
          users_state&.each do |user_state|
            user_state.update_attributes(active_state: "Offline", state_color: "#ff0000", inactive_states: [["OPD", "#008000"], ["OT", "#f0ad4e"]])
            update_user_state_in_redis(user, user_state.facility_id, "Offline", "#ff0000")
          end
        end
      end
    end

    def check_user_state_before_transition(organisation, facility_id, user_id)
      os_check_before_transition_obj = OpenStruct.new # os_ = OpenStruct
      assign_patients_to_ot_user = ActiveModel::Type::Boolean.new.cast("#{organisation['assign_patients_to_ot_user']}")
      assign_patients_to_offline_user = ActiveModel::Type::Boolean.new.cast("#{organisation['assign_patients_to_offline_user']}")
      os_check_before_transition_obj.assign_patients_to_ot_user = assign_patients_to_ot_user
      os_check_before_transition_obj.assign_patients_to_offline_user = assign_patients_to_offline_user
      user_state = UserState.find_by(user_id: user_id, facility_id: facility_id)
      os_check_before_transition_obj.user_state_active_state = user_state&.active_state
      return os_check_before_transition_obj
    end

    def get_patients_counts_in_myqueue(user)
      opd_total_patient_count = 0
      ipd_total_patient_count = 0
      facility_to_myqueue_hash = {}
      user_id = user.id.to_s
      user.facilities.each do |facility|
        facility_id = facility.id.to_s
        opd_count = 0
        ipd_count = 0
        total_count = 0
        if user.specialty_ids.size > 0
          user.specialty_ids.each do |specialty_id|
            hmset_key_hash = 'hash_key:facility:' + facility_id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':specialty_id:' + specialty_id + ':user:' + user_id
            user_dropdown_hash = Redis::Master.new.hgetall(hmset_key_hash)
            if facility_to_myqueue_hash.key?("#{facility_id}")
              opd_count = facility_to_myqueue_hash["#{facility_id}"]["count"].to_i + user_dropdown_hash["count"].to_i
              ipd_count = facility_to_myqueue_hash["#{facility_id}"]["ipd_count"].to_i + user_dropdown_hash["ipd_count"].to_i
            else
              opd_count = user_dropdown_hash["count"].to_i
              ipd_count = user_dropdown_hash["ipd_count"].to_i
            end
            total_count = opd_count + ipd_count
            facility_to_myqueue_hash["#{facility_id}"] = { opd_count: opd_count, ipd_count: ipd_count, total_count: total_count,
                                                            auto_offline_on_logout: ActiveModel::Type::Boolean.new.cast("#{user_dropdown_hash['auto_offline_on_logout']}"),
                                                            assign_patients_to_offline_user: ActiveModel::Type::Boolean.new.cast("#{user_dropdown_hash['assign_patients_to_offline_user']}"),
                                                            clear_my_queue_before_offline: ActiveModel::Type::Boolean.new.cast("#{user_dropdown_hash['clear_my_queue_before_offline']}"),
                                                            assign_patients_to_ot_user:
                                                            ActiveModel::Type::Boolean.new.cast("#{user_dropdown_hash['assign_patients_to_ot_user']}"),
                                                            clear_my_queue_before_ot:
                                                            ActiveModel::Type::Boolean.new.cast("#{user_dropdown_hash['clear_my_queue_before_ot']}")
                                                        }
          end
        else
          hmset_key_hash = 'hash_key:facility:' + facility_id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':user:' + user_id
          user_dropdown_hash = Redis::Master.new.hgetall(hmset_key_hash)
          if facility_to_myqueue_hash.key?("#{facility_id}")
            opd_count = facility_to_myqueue_hash["#{facility_id}"]["count"].to_i + user_dropdown_hash["count"].to_i
            ipd_count = facility_to_myqueue_hash["#{facility_id}"]["ipd_count"].to_i + user_dropdown_hash["ipd_count"].to_i
          else
            opd_count = user_dropdown_hash["count"].to_i
            ipd_count = user_dropdown_hash["ipd_count"].to_i
          end
          total_count = opd_count + ipd_count
          facility_to_myqueue_hash["#{facility_id}"] = { opd_count: opd_count, ipd_count: ipd_count, total_count: total_count,
                                                          auto_offline_on_logout: ActiveModel::Type::Boolean.new.cast("#{user_dropdown_hash['auto_offline_on_logout']}"),
                                                          assign_patients_to_offline_user: ActiveModel::Type::Boolean.new.cast("#{user_dropdown_hash['assign_patients_to_offline_user']}"),
                                                          clear_my_queue_before_offline: ActiveModel::Type::Boolean.new.cast("#{user_dropdown_hash['clear_my_queue_before_offline']}"),
                                                          assign_patients_to_ot_user:
                                                          ActiveModel::Type::Boolean.new.cast("#{user_dropdown_hash['assign_patients_to_ot_user']}"),
                                                          clear_my_queue_before_ot:
                                                          ActiveModel::Type::Boolean.new.cast("#{user_dropdown_hash['clear_my_queue_before_ot']}")
                                                        }
        end
        opd_total_patient_count = opd_total_patient_count + opd_count
        ipd_total_patient_count = ipd_total_patient_count + ipd_count
      end
      return opd_total_patient_count, ipd_total_patient_count, facility_to_myqueue_hash
    end

    def update_user_state_in_redis(user, facility_id, active_state, state_color)
      set_redis(user, facility_id, active_state, state_color)
    end

    private

      def set_redis(user, facility_id, active_state, state_color)
        if user.specialty_ids.size > 0
          user.specialty_ids.each do |specialty_id|
            hmset_key_hash = 'hash_key:facility:' + facility_id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':specialty_id:' + specialty_id + ':user:' + user.id.to_s
            Redis::Master.new.hmset(hmset_key_hash, :active_state, active_state.to_s, :state_color, state_color.to_s)
          end
        else
          hmset_key_hash = 'hash_key:facility:' + facility_id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':user:' + user.id.to_s
          Redis::Master.new.hmset(hmset_key_hash, :active_state, active_state.to_s, :state_color, state_color.to_s)
        end
      end

  end

end
