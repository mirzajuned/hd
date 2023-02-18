module Mis::ReportFilters
  class ManageFiltersService
    class << self
      def call(filter_name, organisation_id, facility_id)
        filters = Reports::Filter.find_by(filter_name: filter_name, organisation_id: organisation_id, facility_id: facility_id)
        filters.destroy if filters.present?
        organisation = Organisation.find_by(id: organisation_id)
        facility = Facility.find_by(id: facility_id)
        if filter_name == 'pharmacy_store'
          inventory_stores = Inventory::Store.where(department_id: '284748001', facility_id: facility.id)
          values = inventory_stores.map { |store| [store.name.gsub('.',''), store.id.to_s] }.to_h
          Reports::Filter.create!(filter_name: 'pharmacy_store', filter_value_name: 'pharmacy_store_id', filter_type: 'dropdown',
                                  category: 'default', value_type: 'string', values: values, organisation_id: organisation.id,
                                  facility_id: facility.id, filter_group: 'default', values_predefined: false)
        elsif filter_name == 'optical_store'
          inventory_stores = Inventory::Store.where(department_id: '50121007', facility_id: facility.id)
          values = inventory_stores.map { |store| [store.name.gsub('.',''), store.id.to_s] }.to_h
          Reports::Filter.create!(filter_name: 'optical_store', filter_value_name: 'optical_store_id', filter_type: 'dropdown',
                                  category: 'default', value_type: 'string', values: values, organisation_id: organisation.id,
                                  facility_id: facility.id, filter_group: 'default', values_predefined: false)
        end
      end
    end
  end
end