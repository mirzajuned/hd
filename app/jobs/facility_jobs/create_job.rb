class FacilityJobs::CreateJob < ActiveJob::Base
  queue_as :urgent

  def perform(facility_id, facility_settings = nil, current_user_id = nil)
    facility = Facility.find_by(id: facility_id)
    organisation_id = facility.organisation_id
    region_master = RegionMaster.find_by(id: facility.region_master_id)

    users = User.where(facility_ids: facility.id, role_ids: 158965000, is_active: true)

    if facility_settings.present?
      # EnableToken
      token_setting = TokenSetting.find_by(facility_id: facility.id.to_s)
      if token_setting.present?
        token_setting.update(token_enabled: facility_settings[:token_enabled], sort_list_by_token: facility_settings[:sort_list_by_token])
      else
        token_setting = TokenSetting.create!(token_enabled: facility_settings[:token_enabled], sort_list_by_token: facility_settings[:sort_list_by_token], facility_id: facility.id.to_s)
      end
    end

    user_sms_feature = {}
    opd_print_setting = {}
    ipd_print_setting = {}

    all_print_setting = { header_height: "3", footer_height: "2", left_margin: "1", right_margin: "1", logo_location: "", header_location: "", right: "", left: "", header: "", customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }
    pharmacy_print_setting = { header_height: "3", footer_height: "2", left_margin: "1", right_margin: "1", logo_location: "", header_location: "", right: "", left: "", header: "", customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }
    optical_print_setting = { header_height: "3", footer_height: "2", left_margin: "1", right_margin: "1", logo_location: "", header_location: "", right: "", left: "", header: "", customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }
    laboratory_print_setting = { header_height: "3", footer_height: "2", left_margin: "1", right_margin: "1", logo_location: "", header_location: "", right: "", left: "", header: "", customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }
    radiology_print_setting = { header_height: "3", footer_height: "2", left_margin: "1", right_margin: "1", logo_location: "", header_location: "", right: "", left: "", header: "", customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }
    ophthalmology_print_setting = { header_height: "3", footer_height: "2", left_margin: "1", right_margin: "1", logo_location: "", header_location: "", right: "", left: "", header: "", customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }
    invoice_print_setting = { header_height: "3", footer_height: "2", left_margin: "1", right_margin: "1", logo_location: "", header_location: "", right: "", left: "", header: "", customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }

    users.each do |user|
      user_sms_feature[user.id.to_s] = { sms_feature: true, personilized_sms: false, name: user.fullname, is_active: user.is_active }
      opd_print_setting[user.id.to_s] = { header_height: "3", footer_height: "2", left_margin: "1", right_margin: "1", logo_location: "", header_location: "", right: "", left: "", header: "", customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }
      ipd_print_setting[user.id.to_s] = { header_height: "3", footer_height: "2", left_margin: "1", right_margin: "1", logo_location: "", header_location: "", right: "", left: "", header: "", customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }
    end

    queue_management = facility_settings.present? ? facility_settings[:queue_management] : false
    user_set_station = facility_settings.present? ? facility_settings[:user_set_station] : false
    FacilitySetting.create!(
      facility_id: facility.id, user_sms_feature: user_sms_feature, sms_feature: true, facility_name: facility.name,
      all_print_setting: all_print_setting, opd_print_setting: opd_print_setting, ipd_print_setting: ipd_print_setting,
      pharmacy_print_setting: pharmacy_print_setting, optical_print_setting: optical_print_setting,
      laboratory_print_setting: laboratory_print_setting, radiology_print_setting: radiology_print_setting,
      ophthalmology_print_setting: ophthalmology_print_setting, invoice_print_setting: invoice_print_setting,
      queue_management: queue_management, user_set_station: user_set_station
    )

    unless OrganisationsSetting.find_by(organisation_id: organisation_id).try(:disable_default_investigation)
      FacilityLaboratoryInvestigationsWorker.new(facility.id, organisation_id).call
    end

    PricingMasters::CreateMultipleService.call(facility.id, current_user_id)

    create_data_for_departments_dropdown(facility)

    create_update_ips_for_facility_and_user(facility)

    # facility filters for MIS reports
    MisFilters::ManageFacilityFiltersService.call(facility.organisation_id.to_s)

    # update facility related hash in the sequence for the org
    SequenceManagers::UpdateSequenceService.call('facility', facility.try(:id).try(:to_s))
    # EOF update facility related hash in the sequence for the org
  end

  private

  def create_data_for_departments_dropdown(facility)
    department_ids = facility.department_ids

    department_ids.each do |department_id|
      if ['261904005', '309964003', '50121007', '284748001', '309935007', '450368792'].include? department_id

        if department_id == '50121007'
          create_redis_data_along_department(facility, department_id, "Optical Shop", "PatientOpticalPrescription", nil, "optical", 1)

        elsif department_id == '309935007'
          create_redis_data_along_department(facility, department_id, "Ophthal Invest", "Investigation::Queue", 'ophthal', "ophthal_investigation", 3)

        elsif department_id == '309964003'
          create_redis_data_along_department(facility, department_id, "Radiology Invest", "Investigation::Queue", 'radiology', "radiology_investigation", 4)

        elsif department_id == '261904005'
          create_redis_data_along_department(facility, department_id, "Laboratory Invest", "Investigation::Queue", 'laboratory', "laboratory_investigation", 2)

        elsif department_id == '284748001'
          create_redis_data_along_department(facility, department_id, "Pharmacy Shop", "PatientPrescription", nil, "pharmacy", 0)

        elsif department_id == '450368792'
          create_redis_data_along_department(facility, department_id, "TPA Department", "", nil, "tpa_department", 5)

        end

      end
    end
  end

  def create_redis_data_along_department(facility, department_id, department_name, department_model, type, name_to_send, rank)
    Time.zone = facility.time_zone
    expiry_time = ((Date.current + 1).to_time + 2.hours).to_i

    hmset_department_key = 'facility:' + facility.id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':department:' + department_id.to_s
    hmset_department_key_hash = 'hash_key:facility:' + facility.id.to_s + ':date:' + Date.current.strftime('%d%m%Y') + ':department:' + department_id.to_s

    # return unless $REDIS.hmget(hmset_department_key_hash, :id)[0].nil?
    return unless Redis::Master.new.hmget(hmset_department_key_hash, :id)[0].nil?

    # $REDIS.hmset(hmset_department_key_hash, :name, department_name, :id, department_id.to_s, :count, "0", :to_send, name_to_send, :department_model, department_model, :rank, rank, :type, type)
    Redis::Master.new.hmset(hmset_department_key_hash, :name, department_name, :id, department_id.to_s, :count, '0', :to_send, name_to_send, :department_model, department_model, :rank, rank, :type, type)

    zadd_department_key = 'date:' + Date.current.strftime('%d%m%Y') + ':departments' + ':facility:' + facility.id.to_s
    # $REDIS.zadd zadd_department_key, 1, hmset_department_key
    Redis::Master.new.zadd(zadd_department_key, 1, hmset_department_key)

    # $REDIS.expireat hmset_department_key, expiry_time
    Redis::Master.new.expireat(hmset_department_key, expiry_time)
    # $REDIS.expireat zadd_department_key, expiry_time
    Redis::Master.new.expireat(zadd_department_key, expiry_time)
  end

  def create_update_ips_for_facility_and_user(facility)
    facility_ip_address = facility.ip_address.pluck(:remote_ip)
    Redis::Master.new.rpush("facility:#{facility.id.to_s}:whitelisted-ips", facility_ip_address)
  end
end
