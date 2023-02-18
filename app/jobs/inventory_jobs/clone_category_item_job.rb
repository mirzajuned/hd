class InventoryJobs::CloneCategoryItemJob < ActiveJob::Base
  queue_as :urgent

  def perform(category_id, store_id, organisation_id)
    store = Inventory::Store.find_by(id: store_id)
    category_items = Inventory::Item.where(category_id: category_id, level: 'organisation', organisation_id: organisation_id)
    return unless category_items.present? && store.present?

    category_items.each do |item|
      store_item = Inventory::Item.find_by(reference_id: item.reference_id, store_id: store.id)
      variant = Inventory::Item::Variant.find_by(level: 'organisation', item_id: item.id)
      next if store_item.to_a.present?

      store_item = Inventory::Item.new(
        item.attributes.except(
          :_id, :stock, :checkout_count, :inventory_capacity, :store_id, :updated_at, :created_at, :level, :facility_id
        )
      )
      store_item.store_id = store.id
      store_item.facility_id = store.facility_id
      store_item.level = 'store'
      store_item.department_id = store.department_id
      store_item.department_name = store.department_name
      store_item.save!

      # default variant creation
      if variant.to_a.present?
        store_variant = Inventory::Item::Variant.new(
          variant.attributes.except(
            :_id, :stock, :checkout_count, :inventory_capacity, :store_id, :updated_at, :created_at, :item_id, :facility_id
          )
        )
        store_variant.store_id = store.id
        store_variant.facility_id = store.facility_id
        store_variant.item_id = store_item.id
        store_variant.level = 'store'
        barcode_id = Inventory::Variants::GenerateBarCodeService.call(variant.variant_code,
                                                                      variant.organisation_id)
        store_variant.barcode_id = barcode_id.data
        store_variant.department_id = store_item.department_id
        store_variant.department_name = store_item.department_name
        store_variant.save!
      else
        Inventory::Variants::CreateService.default(store_item, 'category_item')
      end
    end
  end
end
