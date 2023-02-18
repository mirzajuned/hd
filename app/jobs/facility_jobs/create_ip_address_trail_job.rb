class FacilityJobs::CreateIpAddressTrailJob < ActiveJob::Base
  queue_as :urgent

  def perform(facility_id, current_user_id, action, ips_to_be_removed, ips_to_be_added)
    facility = Facility.find_by(id: facility_id)
    user = User.find_by(id: current_user_id)
    role_arr = []
    all_roles = Global.send('user_roles')
    user.role_ids.each do |role_id|
      role = all_roles[role_id.to_s]
      role_arr << all_roles[role_id.to_s]['label'] if role.present?
    end
    user_role = role_arr&.join(' & ')

    if action == 'create'
      create_ip_trail(facility, user, user_role)
    else
      update_ip_trail(facility, user, user_role, ips_to_be_removed, ips_to_be_added)
    end
  end

  def create_ip_trail(facility, user, user_role)
    facility.ip_address.each do |ip_address|
      facility.facility_log_trail.create!(action_taken: 'Ip Added', ip_address: ip_address.remote_ip,
                                          user_id: user.id, user_name: user.fullname, user_role: user_role)
    end
  end

  def update_ip_trail(facility, user, user_role, ips_to_be_removed, ips_to_be_added)
    ips_to_be_removed.each do |ip_address|
      facility.facility_log_trail.create!(action_taken: 'Ip Removed', ip_address: ip_address, user_id: user.id,
                                          user_name: user.fullname, user_role: user_role)
    end
    ips_to_be_added.each do |ip_address|
      facility.facility_log_trail.create!(action_taken: 'Ip Added', ip_address: ip_address, user_id: user.id,
                                          user_name: user.fullname, user_role: user_role)
    end
  end
end
