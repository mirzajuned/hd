class GetFacilities
  def self.current_facility(facility_id)
    return if facility_id.nil?

    # @current_facility = $REDIS_L.get("facility:#{facility_id}")
    @current_facility = Redis::Local.new.get("facility:#{facility_id}")
    if @current_facility.nil?
      @current_facility = Facility.includes(:users, :facility_setting).find_by(id: facility_id).to_json
      # $REDIS_L.set("facility:#{facility_id}", @current_facility)
      Redis::Local.new.set("facility:#{facility_id}", @current_facility)
      Redis::Local.new.expireat("facility:#{facility_id}", ((Date.current + 1).to_time + 4.hours).to_i)

      current_hash = { "facility:#{facility_id}" => JSON.parse(@current_facility) }
      Redis::Master.new.rpush('ehr:current:list', current_hash.to_json)
      # Redis::Master.new.xadd('ehr:redis_key', '*', "facility:#{facility_id}", @current_facility)
      current_json = { "facility:#{facility_id}" => @current_facility }
      Redis::Master.new.xadd('ehr:redis_key', current_json, id: '*')

    end
    @current_facility = JSON.parse(@current_facility, object_class: Facility)
  end

  def self.current_user_facilities(user_id)
    # current_user_facilities = $REDIS_L.get("user_facilities:#{user_id}")
    current_user_facilities = Redis::Local.new.get("user_facilities:#{user_id}")
    if current_user_facilities.nil?
      current_user_facilities = User.find_by(id: user_id).facilities.includes(:facility_setting).to_json
      # $REDIS_L.set("user_facilities:#{user_id}", current_user_facilities)
      Redis::Local.new.set("user_facilities:#{user_id}", current_user_facilities)
      Redis::Local.new.expireat("user_facilities:#{user_id}", ((Date.current + 1).to_time + 4.hours).to_i)

      current_hash = { "user_facilities:#{user_id}" => JSON.parse(current_user_facilities) }
      Redis::Master.new.rpush('ehr:current:list', current_hash.to_json)
      # Redis::Master.new.xadd('ehr:redis_key', '*', "user_facilities:#{user_id}", current_user_facilities)
      current_json = { "user_facilities:#{user_id}" => current_user_facilities }
      Redis::Master.new.xadd('ehr:redis_key', current_json, id: '*')


    end
    current_user_facilities = JSON.parse(current_user_facilities, object_class: Facility)
    current_user_facilities
  end

  def self.current_user_facility_settings(_facility_id, user_id)
    # current_user_facility_settings = $REDIS_L.get("user_facility_settings:#{user_id}")
    current_user_facility_settings = Redis::Local.new.get("user_facility_settings:#{user_id}")
    if current_user_facility_settings.nil?
      current_user_facility_ids = User.find_by(id: user_id).facility_ids
      current_user_facility_settings = FacilitySetting.where(:facility_id.in => current_user_facility_ids)
                                                      .order('facility_name ASC').to_json

      # $REDIS_L.set("user_facility_settings:#{user_id}", current_user_facility_settings)
      Redis::Local.new.set("user_facility_settings:#{user_id}", current_user_facility_settings)
      Redis::Local.new.expireat("user_facility_settings:#{user_id}", ((Date.current + 1).to_time + 4.hours).to_i)

      current_hash = { "user_facility_settings:#{user_id}" => JSON.parse(current_user_facility_settings) }
      Redis::Master.new.rpush('ehr:current:list', current_hash.to_json)
      # Redis::Master.new.xadd('ehr:redis_key', '*', "user_facility_settings:#{user_id}", current_user_facility_settings)
      current_json = { "user_facility_settings:#{user_id}" => current_user_facility_settings }
      Redis::Master.new.xadd('ehr:redis_key', current_json, id: '*')

    end
    current_user_facility_settings = JSON.parse(current_user_facility_settings)
    current_user_facility_settings
  end

  def self.current_facility_departments(facility_id)
    zadd = "date:#{Date.current.strftime('%d%m%Y')}:departments:facility:#{facility_id}"
    sorted_departments = Redis::Master.new.sort(zadd, by: 'alpha hash_key:*->rank',
                                                      get: ['hash_key:*->id', 'hash_key:*->name', 'hash_key:*->count',
                                                            'hash_key:*->to_send', 'hash_key:*->department_model',
                                                            'hash_key:*->rank', 'hash_key:*->type'])
    sorted_departments.to_a.sort_by! { |department| department[5] }
  end

  def self.current_facility_stations(facility_id)
    zadd = "date:#{Date.current.strftime('%d%m%Y')}:stations:facility:#{facility_id}"
    sorted_stations = $REDIS.sort(zadd, by: 'alpha hash_key:*->count',
                                        get: ['hash_key:*->id', 'hash_key:*->name', 'hash_key:*->code',
                                              'hash_key:*->user_names', 'hash_key:*->count', 'hash_key:*->user_ids'])
    sorted_stations
  end
end
