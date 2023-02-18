class InventoryJobs::CreateDefaultSubStoreJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    store_id = args[0]
    store = Inventory::Store.find_by(id: store_id)
    sub_store = Inventory::SubStore.new
    sub_store.name = 'Default'
    sub_store.store_id = store.id
    sub_store.is_active = true
    sub_store.is_deleted = false
    sub_store.facility_id = store.facility_id
    sub_store.organisation_id = store.organisation_id
    sub_store.save!
  end
end
