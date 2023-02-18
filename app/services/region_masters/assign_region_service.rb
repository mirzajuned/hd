class RegionMasters::AssignRegionService
  class << self
    def call(organisation_id, logger='')
      logger ||= Logger.new("#{Rails.root}/log/region_master.log")
      organisation = Organisation.find_by(id: organisation_id)
      logger.info("------- organisation_id: #{organisation.id}")
      facility_countries = organisation.facilities.pluck(:country_id).uniq
      facility_countries.each do |facility_country|
        logger.info("--------- facility_country: #{facility_country}")
        region_master = RegionMaster.where(organisation_id: organisation.id, country_id: facility_country).last rescue nil
        organisation.facilities.where(country_id: facility_country).update_all(region_master_id: region_master.id)
      end
    end
  end
end