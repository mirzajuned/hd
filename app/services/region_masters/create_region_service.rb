class RegionMasters::CreateRegionService
  class << self
    def call(organisation_id, logger='')
      logger ||= Logger.new("#{Rails.root}/log/region_master.log")
      organisation = Organisation.find_by(id: organisation_id)
      organisation.facilities.each do |facility|
        if facility.state.present?
          name = facility.state
          logger.info("------- facility.state: #{facility.state}")
          abbreviation = facility.country_id.constantize.select{|s| s[:state] == facility.state.upcase}.last[:state_abbreviation] rescue facility.state
        elsif facility.district.present?
          name = facility.district
          logger.info("------- facility.district: #{facility.district}")
          abbreviation = facility.district
        end
        region_master = RegionMaster.find_or_create_by(organisation_id: organisation.id, country_id: facility.country_id)
        region_master.name = name
        region_master.abbreviation = abbreviation
        region_master.save!
      end
      # assign regions to the facilities
      RegionMasters::AssignRegionService.call(organisation_id, logger)
    end
  end
end
