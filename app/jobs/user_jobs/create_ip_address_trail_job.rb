class UserJobs::CreateIpAddressTrailJob < ActiveJob::Base
  queue_as :urgent

  def perform(user_id, current_user_id, action, ips_to_be_removed, ips_to_be_added)
    user = User.find_by(id: user_id)
    @current_user = User.find_by(id: current_user_id)
    role_arr = []
    all_roles = Global.send('user_roles')
    @current_user.role_ids.each do |role_id|
      role = all_roles[role_id.to_s]
      role_arr << all_roles[role_id.to_s]['label'] if role.present?
    end
    user_role = role_arr&.join(' & ')

    if action == 'create'
      create_ip_trail(user, user_role)
    else
      update_ip_trail(user, user_role, ips_to_be_removed, ips_to_be_added)
    end
  end

  def create_ip_trail(user, user_role)
    user.ip_address.each do |ip_address|
      user.user_log_trail.create!(action_taken: 'Ip Added', ip_address: ip_address.remote_ip,
                                  user_id: @current_user.id, user_name: @current_user.fullname, user_role: user_role)
    end
  end

  def update_ip_trail(user, user_role, ips_to_be_removed, ips_to_be_added)
    ips_to_be_removed.each do |ip_address|
      user.user_log_trail.create!(action_taken: 'Ip Removed', ip_address: ip_address, user_id: @current_user.id,
                                  user_name: @current_user.fullname, user_role: user_role)
    end
    ips_to_be_added.each do |ip_address|
      user.user_log_trail.create!(action_taken: 'Ip Added', ip_address: ip_address, user_id: @current_user.id,
                                  user_name: @current_user.fullname, user_role: user_role)
    end
  end
end
