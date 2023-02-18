class UserJobs::UpdateJob < ActiveJob::Base
  queue_as :urgent

  def perform(user_id)
    user = User.find_by(id: user_id)

    if user.present?
      non_user_facilities = user.organisation.facilities.where(:id.nin => user.facility_ids, user_ids: user.id)
      non_user_facilities.each do |facility|
        # Remove user_id from non-selected facility
        facility.pull(user_ids: user.id)

        # Remove user_sms from FacilitySetting
        facility_setting = FacilitySetting.find_by(facility_id: facility.id.to_s)
        if facility_setting.present?
          facility_setting.user_sms_feature.delete(user_id)
          facility_setting.opd_print_setting.delete(user_id)
          facility_setting.ipd_print_setting.delete(user_id)
        end

        # Remove user_id from non-selected facility Redis
        remove_redis_dropdown(user, facility)
      end

      user.facility_ids.each do |facility_id|
        # Add user_id to Facility
        facility = Facility.find_by(id: facility_id)
        facility.add_to_set(user_ids: user.id)

        # Create UserState
        user_state = UserState.find_by(facility_id: facility_id, user_id: user.id)
        if user_state.nil?
          user_state = UserState.new(facility_id: facility_id, user_id: user.id)
          user_state.save
        end

        # Create FacilitySetting
        facility_setting = FacilitySetting.find_by(facility_id: facility_id.to_s)
        if facility_setting.present?
          user_sms_feature = facility_setting.user_sms_feature
          opd_print_setting = facility_setting.opd_print_setting
          ipd_print_setting = facility_setting.ipd_print_setting
          user_sms_feature[user.id.to_s] = { sms_feature: true, personilized_sms: false, name: user.fullname, is_active: user.is_active }
          opd_print_setting[user.id.to_s] = { header_height: "3", footer_height: "2", left_margin: "1", right_margin: "1", logo_location: "", header_location: "", right: "", left: "", header: "", customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }
          ipd_print_setting[user.id.to_s] = { header_height: "3", footer_height: "2", left_margin: "1", right_margin: "1", logo_location: "", header_location: "", right: "", left: "", header: "", customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }
          facility_setting.update(user_sms_feature: user_sms_feature, opd_print_setting: opd_print_setting, ipd_print_setting: ipd_print_setting)
        end
      end

      # Create Workflow Appointment User Dropdown
      update_redis_dropdown(user)
      update_user_names(user)
    end
  end

  private

  def update_redis_dropdown(user)
    specialties = Specialty.all.pluck(:id)

    if user.specialty_ids.count > 0
      specialties.each do |specialty_id|
        user.facilities.each do |facility|
          Time.zone = facility.try(:time_zone)
          expiry_time = (Date.current.tomorrow.to_time + 2.hours).to_i
          user_state = UserState.find_by(facility_id: facility.id, user_id: user.id)
          facility_setting = FacilitySetting.find_by(facility_id: facility.id.to_s)

          admission_options = { user_id: user.id, facility_id: facility.id,
                                '$or' => [{ current_state: 'Admitted' },
                                          { current_state: 'Scheduled', admission_date: Date.current }] }

          sub_station_options = if facility_setting&.user_set_station
                                  { active_user_id: user.id, facility_id: facility.id }
                                else
                                  { user_id: user.id, facility_id: facility.id }
                                end
          sub_station = QueueManagement::SubStation.find_by(sub_station_options)

          admission_options = admission_options.merge(specialty_id: specialty_id)
          alvs = AdmissionListView.where(admission_options)

          next unless facility.specialty_ids.include?(specialty_id)


          hmset_key = 'facility:' + facility.id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':specialty_id:' + specialty_id + ':user:' + user.id.to_s
          hmset_key_hash = 'hash_key:facility:' + facility.id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':specialty_id:' + specialty_id + ':user:' + user.id.to_s
          zadd_key = 'date:' + Date.current.strftime('%d%m%Y') + ':' + user.role_ids[0].to_s + ':facility:' + facility.id.to_s + ':specialty_id:' + specialty_id

          if user.specialty_ids.include?(specialty_id) # facility.specialty_ids.include?(specialty_id)

            # if $REDIS.hmget(hmset_key_hash, :id)[0].nil?
            if Redis::Master.new.hmget(hmset_key_hash, :id)[0].nil?
              # $REDIS.hmset(hmset_key_hash, :name, user.fullname, :id, user.id.to_s, :count, "0", :active_state, user_state.try(:active_state).to_s, :state_color, user_state.try(:state_color).to_s)
              Redis::Master.new.hmset(hmset_key_hash, :name, user.fullname, :id, user.id.to_s, :count, "0", :active_state, user_state.try(:active_state).to_s,
                                      :state_color, user_state.try(:state_color).to_s, :ipd_count, alvs.count,
                                      :sub_station_code, sub_station&.display_code, :sub_station_id, sub_station&.id)
              # $REDIS.zadd zadd_key, 1, hmset_key
              Redis::Master.new.zadd(zadd_key, 1, hmset_key)

              if user.role_ids[1] != nil
                zadd_key2 = 'date:' + Date.current.strftime('%d%m%Y') + ':' + user.role_ids[1].to_s + ':facility:' + facility.id.to_s + ':specialty_id:' + specialty_id
                # $REDIS.zadd zadd_key2, 1, hmset_key
                Redis::Master.new.zadd(zadd_key2, 1, hmset_key)
              end

              # $REDIS.expireat hmset_key, expiry_time
              Redis::Master.new.expireat(hmset_key, expiry_time)
              # $REDIS.expireat zadd_key, expiry_time
              Redis::Master.new.expireat(zadd_key, expiry_time)
              # $REDIS.expireat zadd_key2, expiry_time
              Redis::Master.new.expireat(zadd_key2, expiry_time)

            else
              # $REDIS.zadd zadd_key, 1, hmset_key
              Redis::Master.new.zadd(zadd_key, 1, hmset_key)
            end
          else
            # unless $REDIS.hmget(hmset_key_hash, :id)[0].nil?
            unless Redis::Master.new.hmget(hmset_key_hash, :id)[0].nil?
              # $REDIS.zrem(zadd_key, hmset_key)
              Redis::Master.new.zrem(zadd_key, hmset_key)
            end
          end
        end
      end
    else
      user.facilities.each do |facility|

        Time.zone = facility.try(:time_zone)
        expiry_time = (Date.current.tomorrow.to_time + 2.hours).to_i

        facility_id = facility.id.to_s
        facility_setting = FacilitySetting.find_by(facility_id: facility_id.to_s)
        user_state = UserState.find_by(user_id: user.id, facility_id: facility_id)
        active_state = user_state.try(:active_state)
        state_color = user_state.try(:state_color)
        admission_options = { user_id: user.id, facility_id: facility_id,
                              '$or' => [{ current_state: 'Admitted' },
                                        { current_state: 'Scheduled', admission_date: Date.current }] }
        sub_station_options = if facility_setting&.user_set_station
                                { active_user_id: user.id, facility_id: facility_id }
                              else
                                { user_id: user.id, facility_id: facility_id }
                              end
        sub_station = QueueManagement::SubStation.find_by(sub_station_options)
        alvs = AdmissionListView.where(admission_options)
        date = Date.current.strftime('%d%m%Y')
        hmset_key = "facility:#{facility_id}:date:#{date}:user:#{user.id}"
        hmset_key_hash = "hash_key:facility:#{facility_id}:date:#{date}:user:#{user.id}"

        # next if $REDIS.hmget(hmset_key_hash, :id)[0].present?
        next if Redis::Master.new.hmget(hmset_key_hash, :id).to_a[0].present?

        # $REDIS.hmset(hmset_key_hash, :name, user.fullname, :id, user.id.to_s, :count, '0',
        Redis::Master.new.hmset(hmset_key_hash, :name, user.fullname, :id, user.id.to_s, :count, '0',
                            :active_state, active_state.to_s, :state_color, state_color.to_s, :ipd_count, alvs.count,
                            :sub_station_code, sub_station&.display_code, :sub_station_id, sub_station&.id)

        zadd_key = "date:#{date}:#{user.role_ids[0]}:facility:#{facility_id}"
        # $REDIS.zadd zadd_key, 1, hmset_key
        Redis::Master.new.zadd(zadd_key, 1, hmset_key)

        if user.role_ids[1].present?
          zadd_key2 = "date:#{date}:#{user.role_ids[1]}:facility:#{facility_id}"
          # $REDIS.zadd zadd_key2, 1, hmset_key
          Redis::Master.new.zadd(zadd_key2, 1, hmset_key)
        end

        # $REDIS.expireat hmset_key, expiry_time
        Redis::Master.new.expireat(hmset_key_hash, expiry_time)
        # $REDIS.expireat zadd_key, expiry_time
        Redis::Master.new.expireat(zadd_key, expiry_time)
        # $REDIS.expireat zadd_key2, expiry_time
        Redis::Master.new.expireat(zadd_key2, expiry_time)
      end
    end
  end

  def remove_redis_dropdown(user, facility)
    specialty_ids = facility.specialty_ids
    Time.zone = facility.try(:time_zone)
    if user.specialty_ids.count > 0
      specialty_ids.each do |specialty_id|
        hmset_key = 'facility:' + facility.id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':specialty_id:' + specialty_id + ':user:' + user.id.to_s
        zadd_key = 'date:' + Date.current.strftime('%d%m%Y') + ':' + user.role_ids[0].to_s + ':facility:' + facility.id.to_s + ':specialty_id:' + specialty_id

        # $REDIS.zrem zadd_key, hmset_key
        Redis::Master.new.zrem(zadd_key, hmset_key)

        if user.role_ids[1].present?
          zadd_key2 = 'date:' + Date.current.strftime('%d%m%Y') + ':' + user.role_ids[1].to_s + ':facility:' + facility.id.to_s + ':specialty_id:' + specialty_id

          # $REDIS.zrem zadd_key2, hmset_key
          Redis::Master.new.zrem(zadd_key2, hmset_key)
        end
      end
    else
      hmset_key = 'facility:' + facility.id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':user:' + user.id.to_s
      zadd_key = 'date:' + Date.current.strftime('%d%m%Y') + ':' + user.role_ids[0].to_s + ':facility:' + facility.id.to_s

      # $REDIS.zrem zadd_key, hmset_key
      Redis::Master.new.zrem(zadd_key, hmset_key)

      if user.role_ids[1].present?
        zadd_key2 = 'date:' + Date.current.strftime('%d%m%Y') + ':' + user.role_ids[1].to_s + ':facility:' + facility.id.to_s

        # $REDIS.zrem zadd_key2, hmset_key
        Redis::Master.new.zrem(zadd_key2, hmset_key)
      end
    end
  end

  # def commented
  # expiry_time = (Date.current.tomorrow.to_time + 2.hours).to_i

  # hmset_key = "facility:" + facility_id.to_s + ":date:" + Date.current.strftime("%d%m%Y") + ":user:" + user.id.to_s
  # hmset_key_hash = "hash_key:facility:" + facility_id.to_s + ":date:" + Date.current.strftime("%d%m%Y") + ":user:" + user.id.to_s

  # hmset_present = $REDIS.hmget(hmset_key_hash, :id)[0].present?

  # if hmset_present
  #   $REDIS.hmset(hmset_key_hash, :name, user.fullname, :id, user.id.to_s, :active_state, user_state.try(:active_state) || "OPD", :state_color, user_state.try(:state_color) || "#008000")
  # else
  #   $REDIS.hmset(hmset_key_hash, :name, user.fullname, :id, user.id.to_s, :count, "0", :active_state, "OPD", :state_color, "#008000")
  # end

  # zadd_key = "date:" + Date.current.strftime("%d%m%Y") + ":" + user.role_ids[0].to_s + ":facility:" + facility_id.to_s
  # $REDIS.zadd zadd_key, 1, hmset_key
  # if user.role_ids[1] != nil
  #   zadd_key2 = "date:" + Date.current.strftime("%d%m%Y") + ":" + user.role_ids[1].to_s + ":facility:" + facility_id.to_s
  #   $REDIS.zadd zadd_key2, 1, hmset_key
  # end

  # $REDIS.expireat hmset_key, expiry_time
  # $REDIS.expireat zadd_key, expiry_time
  # $REDIS.expireat zadd_key2, expiry_time
  # end
  def update_user_names(user)
    RefundPayment.where(refunded_by_id: user.id.to_s).update_all(refunded_by: user.fullname)
    Invoice.where(refunded_by_id: user.id.to_s).update_all(refunded_by: user.fullname)
  end
end
