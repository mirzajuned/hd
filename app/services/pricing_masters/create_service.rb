class PricingMasters::CreateService
  def self.call(service_master_id, from_multiple = false)
    service_master = ServiceMaster.find_by(id: service_master_id)
    return if service_master.nil?

    facilities = Facility.where(organisation_id: service_master.organisation_id)
    departments = [['485396012', 'opd'], ['486546481', 'ipd']]

    facilities.each do |facility|
      departments.each do |department|
        pricing_masters = PricingMaster.where(service_master_id: service_master.id, facility_id: facility.id,
                                              department_id: department[0])
        if service_master.department_ids.include?(department[0])
          if pricing_masters.count <= 0
            pricing_master = PricingMaster.new
            pricing_master[:service_name] = service_master.service_name
            pricing_master[:service_type_code] = service_master.service_type_code
            pricing_master[:service_type] = service_master.service_type
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
            pricing_master[:sub_specialty_id] = service_master.sub_specialty_id
            pricing_master[:department_id] = department[0]
            pricing_master[:department_name] = department[1]

            pricing_master.save
          else
            PricingMasters::UpdateService.call(service_master, pricing_masters, from_multiple)
          end
        else
          pricing_masters.update(is_active: false)
        end
      end
    end
  end
end
