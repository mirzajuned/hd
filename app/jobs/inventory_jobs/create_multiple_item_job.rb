class CreateMultipleItemJob < ActiveJob::Base
  queue_as :urgent
  
  def perform(inventory_items, facility_id)
    organisation_id = Facility.find_by(id: facility_id).organisation_id
    inventory_items.each do |inventory_item_attributes|
      category = Inventory::Category.find_by(id: inventory_item_attributes[:category_id])

      item_code = Inventory::ItemsHelper.increment_and_create_item_code(organisation_id, inventory_item_attributes[:category_id])
      item = get_category_class(category.type.capitalize, category.name.capitalize).new(inventory_item_attributes)
      item.item_code = item_code
      item.fixed_threshold = inventory_item_attributes[:fixed_threshold] == "true"
      item.stockable = inventory_item_attributes[:stockable] == "true"
      item.prescription_mandatory = false unless category.type.capitalize == 'Medication'
      item.expiry_present = false if category.type.capitalize != 'Medication' && category.type.capitalize != "Miscellaneous"
      item.facility_id = facility_id
      item.organisation_id = organisation_id
      sub_category = Inventory::SubCategory.find_by(id: inventory_item_attributes[:sub_category_id])
      item.reference_id = item.id.to_s
      item.sub_category_name = sub_category&.name
      item.search = "#{item.description} #{item.model_no}"
      barcode_id = Inventory::Items::GenerateBarCodeService.call(item_code, facility_id)
      item.barcode_id = barcode_id.data
      generic_full_names(item)
      if item.save!
        default_variant = Inventory::Variants::CreateService.default(item, 'item_master')
        InventoryJobs::CloneItemJob.perform_later(item.id.to_s, default_variant.id.to_s)
      end
    end
  end

  def generic_full_names(inventory_item)
    generic_names = inventory_item.generic_names
    generic_names.each do |gen_name|
      full_name = "#{gen_name.name} #{gen_name.quantity} #{gen_name.unit}"
      gen_name.update(full_name: full_name)
    end
    display_name = inventory_item.generic_names.pluck(:full_name)&.join(', ')
    generic_ids = inventory_item.generic_names.pluck(:generic_id)
    inventory_item.update(generic_display_name: display_name, generic_display_ids: generic_ids)
  end

  def get_category_class(main_category, category)
    case main_category
    when 'Medication'
      category_class = Inventory::Item::Medication
    when 'Asset'
      category_class = Inventory::Item::Asset
    when 'Consumable'
      category_class = Inventory::Item::Consumable
    when 'Implant'
      category_class = Inventory::Item::Implant
    when 'Stockable'
      category_class = Inventory::Item::Stockable
    when 'Miscellaneous'
      category_class = Inventory::Item::Miscellaneous
    when 'Optical'
      case category
      when 'Frame'
        category_class = Inventory::Item::Optical::Frame
      when 'Contact'
        category_class = Inventory::Item::Optical::Contact
      when 'Other'
        category_class = Inventory::Item::Optical::Other
      else
        category_class = Inventory::Item::Optical::Other
      end
    else
      Inventory::Item
    end
    category_class
  end
end
  