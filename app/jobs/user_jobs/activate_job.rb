class UserJobs::ActivateJob < ActiveJob::Base
  queue_as :urgent

  def perform(*user_ids)
    user_ids = user_ids.flatten
    users = User.where(:id.in => user_ids)

    if users.count > 0

      users.each do |user|
        user_id = user.id
        # $REDIS.set("user:#{user_id}", user.to_json) # reset current_user
        Redis::Master.new.set("user:#{user_id}", user.to_json)

        facilities = user.facilities.includes(:facility_setting)
        facilities.each do |facility|
          # $REDIS.set("facility:#{facility.id}", facility.to_json) # reset current_facility
          Redis::Master.new.set("facility:#{facility.id}", facility.to_json)
          # $REDIS.set("user_facilities:#{user_id}", facilities.to_json) # reset current_user_facilities
          Redis::Master.new.set("user_facilities:#{user_id}", facilities.to_json)

          update_redis_dropdown(user, facility.id) # Create Workflow Appointment User Dropdown

          # Update FacilitySetting SMS Active State (Needs Work)
          facility_setting = FacilitySetting.find_by(facility_id: facility.id)
          if facility_setting.try(:user_sms_feature).present?
            if facility_setting.user_sms_feature[user.id.to_s].present?
              facility_setting.update("user_sms_feature.#{user.id.to_s}.is_active": user.is_active)
            end
          end
        end
      end

    end
  end

  private

  def update_redis_dropdown(user, facility_id)
    user_state = UserState.find_by(user_id: user.id, facility_id: facility_id)

    hmset_key = "facility:" + facility_id.to_s + ":date:" + Date.current.strftime("%d%m%Y") + ":user:" + user.id.to_s
    hmset_key_hash = "hash_key:facility:" + facility_id.to_s + ":date:" + Date.current.strftime("%d%m%Y") + ":user:" + user.id.to_s
    zadd_key = "date:" + Date.current.strftime("%d%m%Y") + ":" + user.role_ids[0].to_s + ":facility:" + facility_id.to_s

    # hmset_present = $REDIS.hmget(hmset_key_hash, :id)[0].present?
    hmset_present = Redis::Master.new.hmget(hmset_key_hash, :id)[0].present?

    if hmset_present
      # $REDIS.hmset(hmset_key_hash, :name, user.fullname, :id, user.id.to_s, :active_state, user_state.try(:active_state) || "OPD", :state_color, user_state.try(:state_color) || "#008000")
      Redis::Master.new.hmset(hmset_key_hash, :name, user.fullname, :id, user.id.to_s, :active_state, user_state.try(:active_state) || 'OPD', :state_color, user_state.try(:state_color) || '#008000')
    else
      # $REDIS.hmset(hmset_key_hash, :name, user.fullname, :id, user.id.to_s, :count, "0", :active_state, "OPD", :state_color, "#008000")
      Redis::Master.new.hmset(hmset_key_hash, :name, user.fullname, :id, user.id.to_s, :count, '0', :active_state, 'OPD', :state_color, '#008000')
    end

    if user.is_active
      # $REDIS.zadd zadd_key, 1, hmset_key
      Redis::Master.new.zadd(zadd_key, 1, hmset_key)
    else
      # $REDIS.zrem zadd_key, hmset_key
      Redis::Master.new.zrem(zadd_key, hmset_key)
    end
  end
end
