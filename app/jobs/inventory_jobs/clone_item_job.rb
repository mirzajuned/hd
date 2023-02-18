class InventoryJobs::CloneItemJob < ActiveJob::Base
  queue_as :urgent


  def perform(item_id, default_variant_id)
    reference_item = Inventory::Item.find_by(id: item_id)

    reference_default_variant = Inventory::Item::Variant.find_by(id: default_variant_id)
    if reference_item.level == 'store'
      reference_item_store = reference_item.store_id
      master_item = Inventory::Item.find_by(reference_id: reference_item.reference_id,
                                            organisation_id: reference_item.organisation_id, level: 'organisation')
      if master_item.blank?
        master_item = Inventory::Item.new(
            reference_item.attributes.except(
                :_id, :stock, :checkout_count, :inventory_capacity, :store_id, :updated_at, :created_at, :level, :facility_id
            )
        )
        variant_data_hash = { variant_identifier: '', reference_variant_id: reference_default_variant.reference_id }
        master_item.variant_reference_identifiers << variant_data_hash
        master_item.level = 'organisation'
        master_item.save!


        #default variant creation
        master_variant = Inventory::Item::Variant.new(
            reference_default_variant.attributes.except(
                :_id, :stock, :checkout_count, :inventory_capacity, :store_id, :updated_at, :created_at, :item_id, :facility_id
            )
        )
        master_variant.item_id = master_item.id
        master_variant.level = 'organisation'
        barcode_id = Inventory::Variants::GenerateBarCodeService.call(reference_default_variant.variant_code, reference_default_variant.organisation_id)
        master_variant.barcode_id = barcode_id.data
        master_variant.vendor_id = master_item.vendor_id
        master_variant.save!
        master_variant
      end
    else
      variant_data_hash = { variant_identifier: '', reference_variant_id: reference_default_variant.reference_id }
      reference_item.variant_reference_identifiers << variant_data_hash
      reference_item.save!
    end

    stores = Inventory::Store.where(organisation_id: reference_item.organisation_id, category_ids: reference_item.category_id)

    stores.each do |store|
      item = Inventory::Item.find_by(reference_id: reference_item.reference_id, store_id: store.id)
      next if (item.present? || (reference_item_store.to_s == store.id.to_s) )
      store_item = Inventory::Item.new(
          reference_item.attributes.except(
              :_id, :stock, :checkout_count, :inventory_capacity, :store_id, :updated_at, :created_at, :level, :facility_id
          )
      )
      store_item.store_id = store.id
      store_item.facility_id = store.facility_id
      store_item.level = 'store'
      store_item.department_id = store.department_id
      store_item.department_name = store.department_name
      store_item.save!


      #default variant creation
      store_variant = Inventory::Item::Variant.new(
          reference_default_variant.attributes.except(
              :_id, :stock, :checkout_count, :inventory_capacity, :store_id, :updated_at, :created_at, :item_id, :facility_id
          )
      )
      store_variant.store_id = store.id
      store_variant.facility_id = store.facility_id
      store_variant.item_id = store_item.id
      store_variant.level = 'store'
      barcode_id = Inventory::Variants::GenerateBarCodeService.call(reference_default_variant.variant_code, reference_default_variant.organisation_id)
      store_variant.barcode_id = barcode_id.data
      store_variant.department_id = store_item.department_id
      store_variant.department_name = store_item.department_name
      store_variant.save!
      store_variant

    end
  end
end