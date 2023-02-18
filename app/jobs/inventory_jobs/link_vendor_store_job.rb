class InventoryJobs::LinkVendorStoreJob < ActiveJob::Base
  queue_as :urgent

  def perform(category_id, vendor_id, type)
    vendor = Inventory::Vendor.find_by(id: vendor_id)
    # category_ids = vendor.category_ids
    var_store_ids = Inventory::Item::Variant.where(category_id: category_id).pluck(:store_id).uniq&.compact
    cat_store_ids = Inventory::Category.find_by(id: category_id)&.store_ids
    store_ids = (var_store_ids + cat_store_ids).uniq
    store_ids.each do |store_id|
      store = Inventory::Store.find_by(id: store_id)
      if type == 'link'
        store.add_to_set(vendor_ids: vendor.id)
      else
        store.pull(vendor_ids: vendor.id)
      end
    end
  end
end
