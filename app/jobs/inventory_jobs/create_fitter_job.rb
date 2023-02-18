class InventoryJobs::CreateFitterJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    vendor_id = args[0]
    facility_id = args[1]
    vendor = Inventory::Vendor.find_by(id: vendor_id)
    stores = Inventory::Store.where(facility_id: facility_id, is_active: true, department_id: '50121007',
                                    is_disable: false)
    fitter = Inventory::Fitter.find_or_initialize_by(vendor_id: vendor.id)
    fitter.name = vendor.name
    fitter.mobile_number = vendor.mobile_number
    fitter.email = vendor.email
    fitter.company_name = vendor.company_name
    fitter.organisation_id = vendor.organisation_id
    fitter.secondary_mobile_number = vendor.secondary_mobile_number
    fitter.facility_id = facility_id
    fitter.address = vendor.address
    fitter.pincode = vendor.pincode
    fitter.city = vendor.city
    fitter.state = vendor.state
    fitter.commune = vendor.commune
    fitter.district = vendor.district
    fitter.vendor_id = vendor.id
    stores.each do |store|
      fitter.store_ids << store.id.to_s
    end
    fitter.save!
  end
end
