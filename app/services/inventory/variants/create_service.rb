class Inventory::Variants::CreateService
  include Inventory::ItemsHelper
  def self.default(item, action_from)
    variant_code = Inventory::ItemsHelper.increment_and_create_variant_no(
      item.id, item.item_code, item.organisation_id
    )
    variant = Inventory::Item::Variant.new
    variant.description = item.description
    variant.reference_id = variant.id
    variant.stock = item.stock
    variant.item_id = item.id
    variant.item_code = item.item_code
    variant.threshold = item.threshold
    variant.threshold_value = item.threshold_value
    variant.fixed_threshold = item.fixed_threshold
    variant.running_low = item.running_low
    variant.empty = item.empty
    variant.variant_code = variant_code
    variant.category = item.category
    variant.category_id = item.category_id
    variant.sub_category_id = item.sub_category_id
    variant.category_name = item.category
    variant.sub_category_name = inventory_item_sub_category(item)
    variant.level = item.level
    variant.variant_identifier = ''
    variant.search = "#{item.description} #{item.model_no}"
    variant.custom_field_tags = []
    variant.custom_field_data = {}
    variant.store_id = item.store_id
    variant.facility_id = item.facility_id
    variant.organisation_id = item.organisation_id
    barcode_id = Inventory::Variants::GenerateBarCodeService.call(variant_code, item.organisation_id)
    variant.barcode_id = barcode_id.data
    variant.barcode_present = item.barcode_present
    variant.system_generated_barcode = item.system_generated_barcode
    variant.department_id = item.department_id
    variant.department_name = item.department_name
    variant.model_no = item.model_no
    variant.generic_display_name = item.generic_display_name
    variant.generic_display_ids = item.generic_display_ids
    variant.stockable = item.stockable
    variant.unit_level = item.unit_level
    if action_from == 'rake_task'
      variant.created_from = 'migration'
      variant.is_activated = false
    end
    variant.save!
    variant
  end

  def self.inventory_item_sub_category(item)
    if item.sub_category_id
      sub_category = Inventory::SubCategory.find(item.sub_category_id)
      sub_category.name
    end
  end

  def self.call(transaction_item, item)
    variant_code = Inventory::ItemsHelper.increment_and_create_variant_no(
      transaction_item.item_id, transaction_item.item_code, transaction_item.organisation_id
    )
    variant = Inventory::Item::Variant.new
    variant.description = transaction_item.description
    master_item = Inventory::Item.find_by(reference_id: item.reference_id, level: 'organisation')
    variant_reference_identifiers = master_item&.variant_reference_identifiers || []
    variant_identifier_hash = variant_reference_identifiers.find{ |h| h[:variant_identifier] == transaction_item.try(:variant_identifier) }
    if variant_identifier_hash.present?
      variant.reference_id = variant_identifier_hash[:reference_variant_id]
    else
      variant_data_hash = { variant_identifier: transaction_item.try(:variant_identifier), reference_variant_id: variant.id }
      master_item.variant_reference_identifiers << variant_data_hash
      master_item.save!
      variant.reference_id = variant.id
    end

    variant.item_id = transaction_item.item_id
    variant.item_code = transaction_item.item_code
    variant.threshold = item.threshold
    variant.threshold_value = item.threshold_value
    variant.fixed_threshold = item.fixed_threshold
    variant.running_low = item.running_low
    variant.empty = item.empty
    variant.variant_code = variant_code
    variant.category = item.category_name
    variant.category_id = item.category_id
    variant.sub_category_id = item.sub_category_id
    variant.category_name = item.category_name
    variant.level = item.level
    variant.variant_identifier = transaction_item.variant_identifier
    variant.search = "#{transaction_item.description} #{transaction_item.variant_identifier} #{item.model_no}"
    variant.custom_field_tags = transaction_item.custom_field_tags
    variant.custom_field_data = transaction_item.custom_field_data
    variant.store_id = transaction_item.store_id
    variant.facility_id = transaction_item.facility_id
    variant.organisation_id = transaction_item.organisation_id
    barcode_id = Inventory::Variants::GenerateBarCodeService.call(variant_code, item.organisation_id)
    variant.barcode_id = barcode_id.data
    variant.barcode_present = item.barcode_present
    variant.system_generated_barcode = item.system_generated_barcode
    variant.model_no = item.model_no
    variant.generic_display_name = item.generic_display_name
    variant.generic_display_ids = item.generic_display_ids
    variant.stockable = item.stockable
    variant.unit_level = item.unit_level
    variant.department_id = transaction_item.department_id || item.department_id
    variant.department_name = transaction_item.department_name || item.department_name
    create_custom_fields(variant, transaction_item.custom_field_data)
    variant.save!
    variant
  end

  def self.create_custom_fields(variant, custom_field_data)
    custom_field_data.each do |k, v|
      variant.custom_fields.new(name: k, value: [v])
    end
  end

  def self.transaction(transaction_variant_id, store_id, item_id)
    store = Inventory::Store.find_by(id: store_id)
    transfer_store_variant = Inventory::Item::Variant.find_by(id: transaction_variant_id)

    variant = Inventory::Item::Variant.new(
      transfer_store_variant.attributes.except(
        :_id, :stock, :checkout_count, :inventory_capacity, :store_id, :updated_at, :created_at, :item_id,
        :department_id, :department_name
      )
    )
    variant.store_id = store_id
    variant.item_id = item_id
    barcode_id = Inventory::Variants::GenerateBarCodeService.call(transfer_store_variant.variant_code, transfer_store_variant.organisation_id)
    variant.barcode_id = barcode_id.data
    variant.department_id = store.department_id
    variant.department_name = store.department_name
    variant.save!
    variant
  end
end
