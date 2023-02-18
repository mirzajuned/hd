class UserJobs::UpdateIpAddressJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    level = args[3]
    return unless args[0].present?

    if level == 'users'
      update_users_level_ip_address(args)
    else
      update_facilities_level_ip_address(args)
    end
  end

  def update_users_level_ip_address(args)
    users = args[0]
    facility_id = args[1]
    flag = args[2]
    facility_ips = Redis::Master.new.lrange("facility:#{facility_id}:whitelisted-ips", 0, -1)
    users.each do |user|
      if flag == 'link'
        Redis::Master.new.rpush("user:#{user}:whitelisted-ips", facility_ips)
        update_user_db_ip(facility_ips, user, facility_id)
      else
        update_user_ip(facility_ips, user)
      end
    end
  end

  def update_facilities_level_ip_address(args)
    facilities = args[0]
    user_id = args[1]
    flag = args[2]
    facilities.each do |facility|
      facility_ips = Redis::Master.new.lrange("facility:#{facility}:whitelisted-ips", 0, -1)
      if flag == 'link'
        Redis::Master.new.rpush("user:#{user_id}:whitelisted-ips", facility_ips)
        update_user_db_ip(facility_ips, user_id, facility)
      else
        update_user_ip(facility_ips, user_id)
      end
    end
  end

  def update_user_db_ip(facility_ips, user_id, facility_id)
    user = User.find_by(id: user_id)
    facility = Facility.find_by(id: facility_id)
    facility_ips.each do |ip_address|
      facility_ip = facility.ip_address.find_by(remote_ip: ip_address)
      next unless facility_ip.present?

      user_ip_address = user.ip_address.new
      user_ip_address.remote_ip = facility_ip.remote_ip
      user_ip_address.remote_ip_name = facility_ip.remote_ip_name
      user_ip_address.level = 'facility'
      user_ip_address.facility_id = facility.id
      user_ip_address.facility_name = facility.name
      user_ip_address.save
    end
  end

  def update_user_ip(facility_ips, user_id)
    user = User.find_by(id: user_id)
    facility_ips.each do |ip|
      Redis::Master.new.lrem("user:#{user_id}:whitelisted-ips", 0, ip)
      user.ip_address.where(remote_ip: ip, level: 'facility').delete_all
    end
  end
end
