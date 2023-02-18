class SurgeryPackages::CloneService
  class << self
    def call(surgery_package_id, facility_ids, user_id)
      surgery_package = SurgeryPackage.find_by(id: surgery_package_id)
      return if surgery_package.nil?

      facility_ids = facility_ids.split(',')
      facility_ids.each do |facility_id|
        clone_package(surgery_package, facility_id, user_id)
      end
    end

    private

    def clone_package(surgery_package, facility_id, user_id)
      facility_surgery_package = SurgeryPackage.find_by(package_uniq_id: surgery_package.package_uniq_id,
                                                        facility_id: facility_id)
      if facility_surgery_package.present?
        data_attributes = surgery_package.attributes.merge(user_id: user_id, facility_id: facility_id,
                                                           _id: facility_surgery_package.id)
        facility_surgery_package.update!(data_attributes)
      else
        new_surgery_package = surgery_package.clone
        new_surgery_package.user_id = user_id
        new_surgery_package.facility_id = facility_id
        new_surgery_package.save!

        clone_package_definition(new_surgery_package, facility_id, user_id)
      end
    end

    def clone_package_definition(new_surgery_package, facility_id, user_id)
      package_definition = PackageDefinition.find_by(package_group_id: new_surgery_package.package_group_id)
      new_package_definition = package_definition.clone
      new_package_definition.facility_id = facility_id
      new_package_definition.user_id = user_id
      new_package_definition.save!
    end
  end
end
