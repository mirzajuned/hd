class PricingMasters::CreateMultipleService
  def self.call(facility_id, current_user_id)
    facility = Facility.find_by(id: facility_id)
    user = User.find_by(id: current_user_id)
    return if facility.nil? && user.nil?

    service_masters = ServiceMaster.where(organisation_id: facility.organisation_id)

    departments = [{ id: '485396012', name: 'opd' }, { id: '486546481', name: 'ipd' }]

    service_masters.each do |service_master|
      service_master.department_ids.each do |department_id|
        department = departments.find { |dept| dept[:id] == department_id }
        pricing_master = PricingMaster.new
        pricing_master[:service_name] = service_master.service_name
        pricing_master[:service_type_code] = service_master.service_type_code
        pricing_master[:service_type_code_name] = service_master.service_type_code_name
        pricing_master[:service_type_code_type] = service_master.service_type_code_type
        pricing_master[:amount] = service_master.service_amount.to_f
        pricing_master[:service_master_id] = service_master.id
        pricing_master[:service_group_id] = service_master.service_group_id
        pricing_master[:service_sub_group_id] = service_master.service_sub_group_id
        pricing_master[:service_code] = service_master.organisation_service_code
        pricing_master[:facility_service_code] = CommonHelper.get_pricing_master_code(facility)
        pricing_master[:user_id] = service_master.user_id
        pricing_master[:facility_id] = facility.id
        pricing_master[:organisation_id] = service_master.organisation_id
        pricing_master[:activity_log] = service_master.activity_log
        pricing_master[:is_active] = service_master.is_active
        pricing_master[:payer_master_id] = 'general'
        pricing_master[:specialty_id] = service_master.specialty_id
        pricing_master[:department_id] = department_id
        pricing_master[:department_name] = department[:name]

        log = service_master.is_active ? 'activated' : 'deactivated'
        pricing_master[:activity_log][log] = { user_name: user.fullname, event_time: Time.current }

        pricing_master.save!
      end
    end
  end
end
