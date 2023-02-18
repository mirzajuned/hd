class FacilityJobs::UpdateJob < ActiveJob::Base
  queue_as :urgent

  def perform(facility_id, facility_settings = nil, current_departments = nil)
    facility = Facility.find_by(id: facility_id)
    users = User.where(facility_ids: facility.id, role_ids: 158965000, is_active: true)

    if facility_settings.present?
      # EnableToken
      token_setting = TokenSetting.find_by(facility_id: facility.id.to_s)
      if token_setting.present?
        token_setting.update(token_enabled: facility_settings[:token_enabled], sort_list_by_token: facility_settings[:sort_list_by_token])
      else
        token_setting = TokenSetting.create(token_enabled: facility_settings[:token_enabled], sort_list_by_token: facility_settings[:sort_list_by_token], facility_id: facility.id.to_s)
      end
    end

    fac_settings = facility.facility_setting
    user_sms_feature = fac_settings.user_sms_feature
    opd_print_setting = fac_settings.opd_print_setting
    ipd_print_setting = fac_settings.ipd_print_setting

    users.each do |user|
      if fac_settings.user_sms_feature.keys.exclude?(user.id.to_s)
        user_sms_feature[user.id.to_s] = { :sms_feature => true, :personilized_sms => false, :name => user.fullname, :is_active => user.is_active }
        opd_print_setting[user.id.to_s] = { header_height: "3", footer_height: "2", left_margin: "1", right_margin: "1", logo_location: "", header_location: "", right: "", left: "", header: "", customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }
        ipd_print_setting[user.id.to_s] = { header_height: "3", footer_height: "2", left_margin: "1", right_margin: "1", logo_location: "", header_location: "", right: "", left: "", header: "", customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }
      end
    end

    fac_settings.user_sms_feature.keys.each do |user_id|
      if users.pluck(:id).map(&:to_s).exclude?(user_id.to_s)
        user_sms_feature.delete(user_id)
        opd_print_setting.delete(user_id)
        ipd_print_setting.delete(user_id)
      end
    end
    queue_management = facility_settings.present? ? facility_settings[:queue_management] : false
    user_set_station = facility_settings.present? ? facility_settings[:user_set_station] : false
    fac_settings.update(facility_name: facility.name, user_sms_feature: user_sms_feature,
                        opd_print_setting: opd_print_setting, ipd_print_setting: ipd_print_setting,
                        queue_management: queue_management, user_set_station: user_set_station)
    create_data_for_departments_dropdown(facility)
    MisFilters::ManageFacilityFiltersService.call(facility.organisation_id.to_s)
    # update facility related hash in the sequence for the org
    SequenceManagers::UpdateSequenceService.call('facility', facility.try(:id).try(:to_s))
    # EOF update facility related hash in the sequence for the org
  end

  private

  def create_data_for_departments_dropdown(facility)
    possible_departments = ['261904005', '309964003', '309935007', '284748001', '450368792', '50121007']
    new_departments = facility.department_ids

    possible_departments.each do |department_id|
      @department_id = department_id
      @facility_id = facility.id

      find_department_values
      create_department_keys

      if new_departments.include? @department_id
        # if $REDIS.hmget(@hmset_department_key_hash, :id)[0].nil?
        if Redis::Master.new.hmget(@hmset_department_key_hash, :id)[0].nil?
          # $REDIS.hmset(@hmset_department_key_hash, :name, @department_name, :id, @department_id.to_s, :count, "0", :to_send, @name_to_send, :department_model, @department_model, :rank, @rank, :type, @type)
          Redis::Master.new.hmset(@hmset_department_key_hash, :name, @department_name, :id, @department_id.to_s, :count, "0", :to_send, @name_to_send, :department_model, @department_model, :rank, @rank, :type, @type)
        end
        # $REDIS.zadd @zadd_department_key, 1, @hmset_department_key
        Redis::Master.new.zadd(@zadd_department_key, 1, @hmset_department_key)
      else
        # unless $REDIS.hmget(@hmset_department_key_hash, :id)[0].nil?
        unless Redis::Master.new.hmget(@hmset_department_key_hash, :id)[0].nil?
          # $REDIS.zrem(@zadd_department_key, @hmset_department_key)
          Redis::Master.new.zrem(@zadd_department_key, @hmset_department_key)
        end
      end
    end
  end

  def find_department_values
    if @department_id == '309935007'
      @department_name = "Ophthal Invest"
      @department_model = "Investigation::Queue"
      @type = "ophthal"
      @name_to_send = "ophthal_investigation"
      @rank = 3

    elsif @department_id == '309964003'
      @department_name = "Radiology Invest"
      @department_model = "Investigation::Queue"
      @type = "radiology"
      @name_to_send = "radiology_investigation"
      @rank = 4

    elsif @department_id == '261904005'
      @department_name = "Laboratory Invest"
      @department_model = "Investigation::Queue"
      @type = "laboratory"
      @name_to_send = "laboratory_investigation"
      @rank = 2

    elsif @department_id == '284748001'
      @department_name = "Pharmacy Shop"
      @department_model = "PatientPrescription"
      @type = nil
      @name_to_send = "pharmacy"
      @rank = 0

    elsif @department_id == '50121007'
      @department_name = "Optical Shop"
      @department_model = "PatientOpticalPrescription"
      @type = nil
      @name_to_send = "optical"
      @rank = 1

    elsif @department_id == '450368792'
      @department_name = "TPA Department"
      @department_model = ""
      @type = nil
      @name_to_send = "tpa_department"
      @rank = 5

    end
  end

  def create_department_keys
    @hmset_department_key = 'facility:' + @facility_id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':department:' + @department_id.to_s
    @hmset_department_key_hash = 'hash_key:facility:' + @facility_id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':department:' + @department_id.to_s
    @zadd_department_key = 'date:' + Date.current.strftime('%d%m%Y') + ':departments' + ':facility:' + @facility_id.to_s
  end
end
