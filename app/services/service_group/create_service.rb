class ServiceGroup::CreateService
  def self.call(organisation_id, user_id)
    # service_groups = ["Administration", "Outpatient", "Inpatient", "Operation Theatre", "Ward", "Investigation", "Pharmacy", "Optical", "Inventory", "Legacy"]
    service_groups = ["Administration", "Outpatient", "Inpatient", "Operation Theatre", "Investigation", "Legacy"]

    service_groups.each do |service_group|
      new_service_group = ServiceGroup.new

      new_service_group.name = service_group
      new_service_group.user_id = user_id
      new_service_group.organisation_id = organisation_id
      new_service_group.is_deletable = true
      new_service_group.is_active = !(service_group == "Legacy")

      new_service_group.save!
    end
  end
end
