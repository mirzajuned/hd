class PricingMasters::UpdateService
  def self.call(service_master, pricing_masters, update_amount = false)
    options = { service_group_id: service_master.service_group_id,
                service_sub_group_id: service_master.service_sub_group_id,
                service_type_code: service_master.service_type_code,
                service_type_code_name: service_master.service_type_code_name,
                service_type_code_type: service_master.service_type_code_type,
                specialty_id: service_master.specialty_id,
                sub_specialty_id: service_master.sub_specialty_id,
                is_active: service_master.is_active }
    options = options.merge(amount: service_master.service_amount.to_f) if update_amount

    pricing_masters.update_all(options)
    Mis::RevenueReports::UpdateSubSpecialitiesService.call(
        service_master.organisation_id.to_s, service_master.id.to_s, 'service_master', pricing_masters.pluck(:id)
    )
  end
end
