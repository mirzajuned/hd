# No Offenses
class GetUsers
  class << self
    def initialize; end

    def current_user(user_id)
      return if user_id.nil?

      # @current_user = $REDIS_L.get("user:#{user_id}")
      @current_user = Redis::Local.new.get("user:#{user_id}")
      if @current_user.nil?
        @current_user = User.find_by(id: user_id).to_json
        # $REDIS_L.set("user:#{user_id}", @current_user)
        Redis::Local.new.set("user:#{user_id}", @current_user)
        Redis::Local.new.expireat("user:#{user_id}", ((Date.current + 1).to_time + 4.hours).to_i)

        current_hash = { "user:#{user_id}" => JSON.parse(@current_user) }
        Redis::Master.new.rpush('ehr:current:list', current_hash.to_json)
        current_json = { "user:#{user_id}" => @current_user }
        Redis::Master.new.xadd('ehr:redis_key', current_json, id: '*')

      end
      @current_user = JSON.parse(@current_user, object_class: User)
    end

    def current_facility_users(facility_id)
      # current_facility_users = $REDIS_L.get("facility_users:#{facility_id}")
      current_facility_users = Redis::Local.new.get("facility_users:#{facility_id}")
      if current_facility_users.nil?
        current_facility_users = Facility.find_by(id: facility_id).users.where(is_active: true).to_json
        # $REDIS_L.set("facility_users:#{facility_id}", current_facility_users)
        Redis::Local.new.set("facility_users:#{facility_id}", current_facility_users)
        Redis::Local.new.expireat("facility_users:#{facility_id}", ((Date.current + 1).to_time + 4.hours).to_i)

        current_hash = { "facility_users:#{facility_id}" => JSON.parse(current_facility_users) }
        Redis::Master.new.rpush('ehr:current:list', current_hash.to_json)
        current_json = { "facility_users:#{facility_id}" => current_facility_users }
        Redis::Master.new.xadd('ehr:redis_key', current_json, id: '*')

      end
      current_facility_users = JSON.parse(current_facility_users, object_class: User)
      current_facility_users
    end

    def workflow_users_dropdown(facility_id, specialty_ids, role_id)
      users_array = []
      date = Date.current.strftime('%d%m%Y')
      role_ids = ['573021946', '46255001', '159282002', '41904004', '387619007', '2822900478']
      if role_ids.include? role_id
        zadd = "date:#{date}:#{role_id}:facility:#{facility_id}"
        get_users_array(users_array, zadd)
      else
        specialty_ids.each do |specialty_id|
          zadd = "date:#{date}:#{role_id}:facility:#{facility_id}:specialty_id:#{specialty_id}"
          get_users_array(users_array, zadd)
        end
      end

      users_array
    end

    # Not in Use
    def queue_count(user_id, facility_id)
      # user_count = $REDIS.get("user_count:#{facility_id}#{user_id}#{Date.current.strftime('%d%m%y')}")
      user_count = Redis::Master.new.get("user_count:#{facility_id}#{user_id}#{Date.current.strftime('%d%m%y')}")
      if user_count.nil?
        GetUsers.current_facility_users(facility_id).each do |user|
          # $REDIS.del("user_count:#{facility_id}#{user.id}#{(Date.current - 1).strftime('%d%m%y')}")
          Redis::Master.new.del("user_count:#{facility_id}#{user.id}#{(Date.current - 1).strftime('%d%m%y')}")
        end
        user = GetUsers.current_user(user_id)
        @clinical_workflows = OpdClinicalWorkflow.where(appointmentdate: Date.current, facility_id: facility_id)
        user_count = @clinical_workflows.where(user_id: user_id, state: user.primary_role).size
        # $REDIS.set("user_count:#{facility_id}#{user_id}#{Date.current.strftime('%d%m%y')}", user_count)
        Redis::Master.new.set("user_count:#{facility_id}#{user_id}#{Date.current.strftime('%d%m%y')}", user_count)
      end
      user_count
    end

    # Not in Use
    def get_user_state(user_id, facility_id)
      # user_state = $REDIS.get("user_state:#{user_id}#{facility_id}")
      user_state = Redis::Master.new.get("user_state:#{user_id}#{facility_id}")
      if user_state.nil?
        user_state = UserState.find_by(user_id: user_id, facility_id: facility_id).to_json
        # $REDIS.set("user_state:#{user_id}#{facility_id}", user_state) if user_state
        Redis::Master.new.set("user_state:#{user_id}#{facility_id}", user_state) if user_state
      end
      user_state = JSON.parse(user_state, object_class: UserState)
      user_state
    end

    def get_users_array(users_array, zadd)
      # sorted_users = $REDIS.sort(zadd, by: 'alpha hash_key:*->count',
      sorted_users = Redis::Master.new.sort(zadd, by: 'alpha hash_key:*->count',
                                                  get: ['hash_key:*->id', 'hash_key:*->name', 'hash_key:*->count',
                                                        'hash_key:*->active_state', 'hash_key:*->state_color',
                                                        'hash_key:*->ipd_count', 'hash_key:*->auto_offline_on_logout',
                                                        'hash_key:*->assign_patients_to_offline_user', 'hash_key:*->clear_my_queue_before_offline',
                                                        'hash_key:*->assign_patients_to_ot_user', 'hash_key:*->clear_my_queue_before_ot',
                                                        'hash_key:*->sub_station_code', 'hash_key:*->sub_station_id'])
      sorted_users&.each { |user| users_array << user }

      users_array
    end
  end
end
