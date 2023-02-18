class InventoryJobs::CloneMultipleItemJob < ActiveJob::Base
  queue_as :urgent

  def perform(store_id, linked_categories)


    store = Inventory::Store.find_by(id: store_id)

    master_items = Inventory::Item.where(organisation_id: store.organisation_id, level: 'organisation', :category_id.in => linked_categories)

    master_items.each do |item|
      item = Inventory::Item.find_by(reference_id: item.reference_id, store_id: store_id)
      next if item.present?
      item = Inventory::Item.new(
          master_item.attributes.except(
              :_id, :stock, :checkout_count, :inventory_capacity, :store_id, :updated_at, :created_at, :level
          )
      )
      item.store_id = store_id
      item.level = 'store'
      item.save!
    end
  end
end