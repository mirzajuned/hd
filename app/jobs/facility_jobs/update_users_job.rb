class FacilityJobs::UpdateUsersJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    user_ids = args[0]
    facility_ips = args[1]
    facility_id = args[2]
    user_ids.each do |user_id|
      user = User.find_by(id: user_id)
      facility = Facility.find_by(id: facility_id)
      user.pull(facility_ids: facility.id)
      update_user_ip(facility_ips, user_id, facility_id)
    end
  end

  def update_user_ip(facility_ips, user_id, facility_id)
    user = User.find_by(id: user_id)
    user.ip_address.where(facility_id: facility_id, level: 'facility').delete_all
    facility_ips.each do |ip|
      Redis::Master.new.lrem("user:#{user_id}:whitelisted-ips", 0, ip)
    end
  end
end
