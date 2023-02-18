module MisFilters
  class ManageFacilityFiltersService
    class << self
      def call(organisation_id)
        Reports::Filter.where(filter_name: 'facility', organisation_id: organisation_id).destroy_all
        organisation = Organisation.find_by(id: organisation_id)
        filter_values = organisation.facilities.where(is_active: true).map { |fac| [fac.name.gsub('.',''), fac.id.to_s] }.to_h
        Reports::Filter.create!(filter_name: 'facility', filter_value_name: 'facility_id', filter_type: 'dropdown',
                                category: 'default', value_type: 'string', values: filter_values, organisation_id: organisation_id.to_s,
                                filter_group: 'default', values_predefined: false)
      end
    end
  end
end