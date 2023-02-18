class Security::IpWhitelisting
  class << self
    def check_ip(organisation_id, user_id, remote_ip)
      @remote_ip = remote_ip
      @user_id = user_id
      org_ip_status = Redis::Master.new.get("organisation:#{organisation_id}:ip-whitelisting-enabled")
      org_status = ActiveModel::Type::Boolean.new.cast(org_ip_status)
      user_ip_status = Redis::Master.new.get("user:#{user_id}:is-open-access-enabled")
      user_status = ActiveModel::Type::Boolean.new.cast(user_ip_status)
      check_status(org_status, user_status)
    end

    private

    def check_status(org_status, user_status)
      if (org_status.nil? || org_status == false) || (user_status.nil? || user_status == true)
        true
      else
        verify_ip_address
      end
    end

    def verify_ip_address
      user_ips = Redis::Master.new.lrange("user:#{@user_id}:whitelisted-ips", 0, -1)
      user_ips.any?{|block| IPAddr.new(block) === @remote_ip}
    end
  end
end
