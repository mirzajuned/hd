class QueueManagementJobs::SubStationJob < ActiveJob::Base
  queue_as :urgent

  QMLOGGER = Logger.new("#{Rails.root}/log/queue_management.log")

  def perform(sub_station_id, user_id, task)
    sub_station = QueueManagement::SubStation.unscoped.find_by(id: sub_station_id)
    return if sub_station.nil?

    Rails.logger.info("========logger=============sub_station========================#{sub_station.to_a}===========")

    update_hmset_key(sub_station, user_id, task)
  rescue StandardError => e
    QMLOGGER.info("SubStationJob: #{e}")
    Rails.logger.info("=============logger======================@error==========#{e.backtrace}===========")
  end

  private

  def update_hmset_key(sub_station, user_id, task)
    user = User.find_by(id: user_id)
    facility_id = sub_station.facility_id
    specialty_ids = user.specialty_ids
    date_dmy = Date.current.strftime('%d%m%Y')

    if specialty_ids.count > 0
      specialty_ids.each do |specialty_id|
        hmset_key = "hash_key:facility:#{facility_id}:date:#{date_dmy}:specialty_id:#{specialty_id}:user:#{user.id}"
        redis_hset_stations(hmset_key, sub_station, task)
      end
    else
      hmset_key = "hash_key:facility:#{facility_id}:date:#{date_dmy}:user:#{user.id}"
      redis_hset_stations(hmset_key, sub_station, task)
    end
  end

  def redis_hset_stations(hmset_key, sub_station, task)
    sub_station_id = $REDIS.hget(hmset_key, :sub_station_id)

    Rails.logger.info("=============logger======================#{hmset_key}#{sub_station}#{task}==========#{hmset_key}#{sub_station}#{task}===========")

    Rails.logger.info("=============logger======================sub_station_id==========#{sub_station_id}===========")

    if task == 'remove' && sub_station_id == sub_station&.id.to_s
      $REDIS.hset(hmset_key, :sub_station_id, nil)
      $REDIS.hset(hmset_key, :sub_station_code, nil)
    elsif task == 'update'
      $REDIS.hset(hmset_key, :sub_station_id, sub_station&.id)
      $REDIS.hset(hmset_key, :sub_station_code, sub_station&.display_code)
    end
  end
end
