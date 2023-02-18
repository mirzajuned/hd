class UserJobs::LinkFacilityCreateJob < ActiveJob::Base
  queue_as :urgent

  def perform(user_id, facility_ids)
    user = User.find_by(id: user_id)
    facility_ids = facility_ids.map { |fac_id| BSON::ObjectId("#{fac_id}") }

    if user.present?

      user.facility_ids = facility_ids
      user.save!(validate: false)

      user.facility_ids.each do |facility_id|
        # Add user_id to Facility
        facility = Facility.find_by(id: facility_id)
        facility.add_to_set(user_ids: user.id)

        # Create UserState
        user_state = UserState.create(facility_id: facility_id, user_id: user.id)

        # Create FacilitySetting
        facility_setting = FacilitySetting.find_by(facility_id: facility_id.to_s)
        if facility_setting.present?
          user_sms_feature = facility_setting.user_sms_feature
          opd_print_setting = facility_setting.opd_print_setting
          ipd_print_setting = facility_setting.ipd_print_setting
          user_sms_feature[user.id.to_s] = { sms_feature: true, personilized_sms: false, name: user.fullname, is_active: user.is_active }
          opd_print_setting[user.id.to_s] = { header_height: "3", footer_height: "2", left_margin: "1", right_margin: "1", logo_location: "", header_location: "", right: "", left: "", header: "", customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }
          ipd_print_setting[user.id.to_s] = { header_height: "3", footer_height: "2", left_margin: "1", right_margin: "1", logo_location: "", header_location: "", right: "", left: "", header: "", customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }
          facility_setting.update(user_sms_feature: user_sms_feature, opd_print_setting: opd_print_setting, ipd_print_setting: ipd_print_setting)
        end
      end

      # Create Workflow Appointment User Dropdown
      create_redis_dropdown(user)
    end
  end

  private

  def create_redis_dropdown(user)
    user.facilities.each do |facility|
      expiry_time = (Date.current.tomorrow.to_time + 2.hours).to_i

      user.specialty_ids.each do |specialty_id|
        # if facility.specialty_ids.include?(specialty_id)

        hmset_key = 'facility:' + facility.id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':specialty_id:' + specialty_id + ':user:' + user.id.to_s
        hmset_key_hash = 'hash_key:facility:' + facility.id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':specialty_id:' + specialty_id + ':user:' + user.id.to_s

        # $REDIS.hmset(hmset_key_hash, :name, user.fullname, :id, user.id.to_s, :count, "0", :active_state, "OPD", :state_color, "#008000")
        Redis::Master.new.hmset(hmset_key_hash, :name, user.fullname, :id, user.id.to_s, :count, '0', :active_state, 'OPD', :state_color, '#008000')
        zadd_key = 'date:' + Date.current.strftime('%d%m%Y') + ':' + user.role_ids[0].to_s + ':facility:' + facility.id.to_s + ':specialty_id:' + specialty_id
        # $REDIS.zadd zadd_key, 1, hmset_key
        Redis::Master.new.zadd zadd_key, 1, hmset_key

        if user.role_ids[1] != nil
          zadd_key2 = 'date:' + Date.current.strftime('%d%m%Y') + ':' + user.role_ids[1].to_s + ':facility:' + facility.id.to_s + ':specialty_id:' + specialty_id
          # $REDIS.zadd zadd_key2, 1, hmset_key
          Redis::Master.new.zadd zadd_key2, 1, hmset_key
        end

        # $REDIS.expireat hmset_key, expiry_time
        Redis::Master.new.expireat hmset_key, expiry_time
        # $REDIS.expireat zadd_key, expiry_time
        Redis::Master.new.expireat zadd_key, expiry_time
        # $REDIS.expireat zadd_key2, expiry_time
        Redis::Master.new.expireat zadd_key2, expiry_time

        # end
      end
    end
  end
end
