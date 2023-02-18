class QueueManagementJobs::StationJob < ActiveJob::Base
  queue_as :urgent

  QMLOGGER = Logger.new("#{Rails.root}/log/queue_management.log")

  def perform(station_id)
    station = QueueManagement::Station.find_by(id: station_id)
    return if station.nil?

    facility_setting = FacilitySetting.find_by(facility_id: station.facility&.id)

    if facility_setting&.user_set_station
      sub_stations = station.sub_stations.where(:active_user_id.ne => nil)
      user_names = sub_stations.map { |ss| ss.active_user&.fullname }.uniq.join(', ')
      user_ids = sub_stations.pluck(:active_user_id).map(&:to_s).uniq.join(', ')
    else
      sub_stations = station.sub_stations.where(:user_id.ne => nil)
      user_names = sub_stations.map { |ss| ss.user&.fullname }.uniq.join(', ')
      user_ids = sub_stations.pluck(:user_id).map(&:to_s).uniq.join(', ')
    end
    date_dmy = Date.current.strftime('%d%m%Y')

    station_key = "facility:#{station.facility_id}:date:#{date_dmy}:station:#{station.id}"
    station_key_hash = "hash_key:#{station_key}"

    
    zadd_station(station, station_key, station_key_hash, date_dmy) if $REDIS.hget(station_key_hash, :id).nil?
    station_user_count = $REDIS.hget(station_key_hash, :count) || 0
    $REDIS.hmset(station_key_hash, :name, station.name, :code, station.display_code, :id, station.id, :user_names, user_names, :user_ids, user_ids, :count, station_user_count)
    #$REDIS.hmset(station_key_hash, :name, station.name, :code, station.display_code, :user_names, user_names, :user_ids, user_ids)
    

  rescue StandardError => e
    QMLOGGER.info("StationJob: #{e}")
  end

  private

  def zadd_station(station, station_key, station_key_hash, date_dmy)
    #$REDIS.hmset(:id, station.id, :count, '0')

    # Update New HMSET Key in ZADD
    $REDIS.zadd "date:#{date_dmy}:stations:facility:#{station.facility_id}", 1, station_key
    $REDIS.expireat station_key, ((Date.current + 1).to_time + 2.hours).to_i
  end
end
