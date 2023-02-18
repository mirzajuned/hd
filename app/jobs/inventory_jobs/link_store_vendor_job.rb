class InventoryJobs::LinkStoreVendorJob < ActiveJob::Base
  queue_as :urgent

  def perform(category_id)
    category = Inventory::Category.find_by(id: category_id)
    vendor_ids = category.vendor_ids
    vendor_ids.each do |vendor_id|
      vendor = Inventory::Vendor.find_by(id: vendor_id)
      store_ids = Inventory::Item::Variant.where(category_id: category_id).pluck(:store_id).uniq&.compact
      store_ids.each do |store_id|
        store = Inventory::Store.find_by(id: store_id)
        store.add_to_set(vendor_ids: vendor.id)
      end
    end
  end
end
