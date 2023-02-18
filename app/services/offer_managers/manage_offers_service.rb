module OfferManagers::ManageOffersService
  def self.call(offer_manager_id, department_ids, store_ids)
    offer_manager = OfferManager.find_by(id: offer_manager_id)
    if store_ids.present?
      stores = store_ids.split(',')
      stores.each do |store_id|
        OfferManagers::ManageOffersService.create_offer_data(offer_manager, department_ids, store_id)
      end
    else
      OfferManagers::ManageOffersService.create_offer_data(offer_manager, department_ids)
    end
  end
  # EOf self.call

  def self.create_offer_data(offer_manager, department_ids, store_id = nil)
    # other_facilities = Facility.where(:id.ne => offer_manager.facility_id, organisation_id: offer_manager.organisation_id)
    # other_facilities.each do |facility|
      departments = department_ids.split(',')
      departments.each_with_index do |i, department_id|
        department = Department.find_by(id: department_id)
        if i == 0
          offer_manager.department_id = department_id
          offer_manager.department_name = department.try(:name)
          offer_manager.department_display_name = department.try(:display_name)
          offer_manager.department_display_order = department.try(:order)
          offer_manager.save
        else
          new_offer = OfferManager.find_or_create_by(organisation_id: offer_manager.organisation_id, facility_id: offer_manager.facility_id)
        end
      end
    # end    
  end
  # EOf self.create_offer_data
end