class FacilityJobs::UpdateIpAddressJob < ActiveJob::Base
  queue_as :urgent

  def perform(facility_id, current_user_id)
    facility = Facility.find_by(id: facility_id)
    new_ips = facility.ip_address.pluck(:remote_ip)
    fac_old_ips = Redis::Master.new.lrange("facility:#{facility.id}:whitelisted-ips", 0, -1)
    fac_common_ips = new_ips & fac_old_ips
    fac_new_added_ips = new_ips + fac_common_ips - (new_ips & fac_common_ips)
    fac_ips_to_be_removed = fac_old_ips + fac_common_ips - (fac_old_ips & fac_common_ips)
    fac_ips_to_be_removed.each do |ip|
      Redis::Master.new.lrem("facility:#{facility.id}:whitelisted-ips", 0, ip)
    end
    Redis::Master.new.rpush("facility:#{facility.id}:whitelisted-ips", fac_new_added_ips)

    # logic to add and remove ip address for each user of particular facility
    facility_ids = [BSON::ObjectId(facility_id.to_s)]
    users = User.where(organisation_id: facility.organisation_id, :facility_ids.in => facility_ids)
    users.each do |user|
      # user_old_ips = user.ip_address.where(level: 'facility').pluck(:remote_ip)
      # user_old_ips = Redis::Master.new.lrange("user:#{user.id}:whitelisted-ips", 0, -1)
      # user_common_ips = new_ips & user_old_ips
      # fetch_other_facilities_ip_address(user, facility_id)
      # new_added_ips = new_ips + user_common_ips - (new_ips & user_common_ips)
      # user_new_added_ips = (new_added_ips << @ip_array).flatten.uniq
      # user_ips_to_be_removed = user_old_ips + user_common_ips - (user_old_ips & user_common_ips)
      fac_ips_to_be_removed.each do |ip|
        Redis::Master.new.lrem("user:#{user.id}:whitelisted-ips", 0, ip)
      end
      Redis::Master.new.rpush("user:#{user.id}:whitelisted-ips", fac_new_added_ips)
      create_update_user_ip(user, facility, fac_new_added_ips)
      delete_user_ip(user, facility, fac_ips_to_be_removed)
    end
    FacilityJobs::CreateIpAddressTrailJob.perform_later(facility.id.to_s, current_user_id, 'update',
                                                        fac_ips_to_be_removed, fac_new_added_ips)
  end

  def create_update_user_ip(user, facility, user_new_added_ips)
    return if user_new_added_ips.empty?

    user_new_added_ips.each do |ip_address|
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

  def delete_user_ip(user, facility, user_ips_to_be_removed)
    return if user_ips_to_be_removed.empty?

    user_ips_to_be_removed.each do |ip_address|
      facility_ip = facility.ip_address.find_by(remote_ip: ip_address)
      user_ip = user.ip_address.find_by(remote_ip: ip_address)
      user_ip.destroy if facility_ip.nil? && user_ip.present?
    end
  end

  # def fetch_other_facilities_ip_address(user, facility_id)
  #   @ip_array = []
  #   user.facility_ids.each do |fac_id|
  #     @ip_array << Facility.find_by(id: fac_id).ip_address&.pluck(:remote_ip).uniq unless fac_id.to_s == facility_id
  #   end
  # end
end
