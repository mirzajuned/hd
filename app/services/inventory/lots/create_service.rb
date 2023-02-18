module Inventory::Lots::CreateService
  def self.call(transaction_item, variant, transaction_type, purchase_transaction, current_user_id, item_id)
    if transaction_item.batch_no&.empty?
      batch_no = Inventory::ItemsHelper.increment_and_create_batch_no(transaction_item.item_id, transaction_item.organisation_id)
      self_batched = true
    else
      batch_no = transaction_item.try(:batch_no)
      self_batched = false
    end
    item = Inventory::Item.find_by(id: transaction_item.item_id)

    lot = Inventory::Item::Lot.new
    lot.batch_no = batch_no
    lot.reference_id = lot.id
    lot.description = transaction_item.description
    lot.self_batched = self_batched
    lot.total_cost = transaction_item.total_cost
    if transaction_item.unit_cost.present?
      lot.unit_cost = transaction_item.unit_cost
    else
      unit_cost_without_tax = transaction_item.unit_cost_without_tax.to_f
      tax_rate = transaction_item.tax_rate.to_i
      unit_cost = (unit_cost_without_tax * tax_rate) / 100 + unit_cost_without_tax
      lot.unit_cost = unit_cost
    end
    lot.search = "#{transaction_item.description} #{variant&.model_no}"
    lot.custom_field_tags = transaction_item.custom_field_tags
    lot.custom_field_data = transaction_item.custom_field_data
    lot.mark_up = transaction_item.mark_up
    lot.mrp = transaction_item.mrp
    lot.list_price = transaction_item.list_price
    lot.unit_non_taxable_amount = transaction_item.unit_non_taxable_amount
    lot.unit_taxable_amount = transaction_item.unit_taxable_amount
    lot.tax_rate = item.tax_rate
    lot.tax_name = item.tax_name
    lot.tax_group_id = item.tax_group_id
    lot.tax_inclusive = item.tax_inclusive
    lot.unit_cost_without_tax = transaction_item.unit_cost_without_tax
    lot.net_unit_cost_without_tax = transaction_item.net_unit_cost_without_tax
    lot.margin = transaction_item.margin
    lot.item_discount = transaction_item.item_discount
    lot.discount_per_unit = transaction_item.discount_per_unit
    if transaction_type == "Purchase"
      lot.lot_actual_source = "GRN"
      lot.transaction_time = purchase_transaction.transaction_time
      lot.transaction_date = purchase_transaction.transaction_date
      lot.transaction_display_id = purchase_transaction.purchase_display_id
    end
    unless transaction_type == 'Stock Opening'
      lot.vendor_name = purchase_transaction.vendor_name
      lot.vendor_id = purchase_transaction.vendor_id
    end
    lot.transaction_type = transaction_type
    lot.transaction_id = purchase_transaction.id
    lot.expiry = transaction_item.expiry
    lot.expiry_present = transaction_item.expiry_present
    lot.stock = transaction_item.stock
    lot.available_stock = lot.stock
    lot.item_id = item_id
    lot.item_code = variant&.item_code
    lot.variant_code = variant&.variant_code
    lot.variant_identifier = variant&.variant_identifier
    lot.variant_id = variant&.id
    lot.store_id = transaction_item.store_id
    lot.facility_id = transaction_item.facility_id
    lot.organisation_id = transaction_item.organisation_id
    lot.category = transaction_item.category
    lot.category_id = item.category_id
    code = Inventory::ItemsHelper.increment_and_create_lot_no(lot.variant_id, lot.variant_code, lot.organisation_id)
    lot.lot_code = code
    # unless item.unit_level
    #   if transaction_item.barcode_id.present?
    #     lot.barcode_id = transaction_item.barcode_id
    #     lot.system_generated_barcode = false
    #   else
    #     barcode_id = Inventory::Lots::GenerateBarCodeService.default(lot.item_code, lot.organisation_id)
    #     lot.barcode_id = barcode_id.data
    #     lot.system_generated_barcode = true
    #   end
    # end
    #lot.barcode_present = transaction_item.barcode_present
    lot.department_id = purchase_transaction.department_id
    lot.department_name = purchase_transaction.department_name
    lot.model_no = variant&.model_no
    lot.generic_display_name = item.generic_display_name
    lot.generic_display_ids = item.generic_display_ids
    lot.stockable = item.stockable
    sub_store = Inventory::Store.find_by(id: transaction_item.store_id).sub_stores[0]
    lot.sub_store_name = transaction_item.sub_store_name || sub_store&.name
    lot.sub_store_id = transaction_item.sub_store_id || sub_store&.id
    lot.unit_level = item.unit_level
    lot.purchase_item_id = transaction_item.id
    if lot.save!
      InventoryJobs::Transactions::Lot::CreateLotUnitJob.perform_later(lot.id.to_s) if item.unit_level
      Inventory::Audit::History::CreateService.call(
        0, lot, transaction_type, purchase_transaction.id, current_user_id
      )
    end
    lot.id
  end

  def self.transaction(transaction_lot_id, transaction_type, store_id, item_id, variant_id, stock, transaction_id, current_user_id, total_cost, sub_store_id, sub_store_name)
    transfer_store_lot = Inventory::Item::Lot.find_by(id: transaction_lot_id)
    item = Inventory::Item.find_by(id: item_id)
    if transaction_type == 'Receive'
      receive = Inventory::Transaction::Receive.find_by(id: transaction_id)
      optical_order_id = receive.optical_order_id
      requisition_order_id = receive.requisition_order_id
    end

    lot = Inventory::Item::Lot.new(transfer_store_lot.attributes.except(
                                     :_id, :stock, :checkout_count, :inventory_capacity, 
                                     :store_id, :updated_at, :created_at, :item_id, 
                                     :variant_id, :total_cost, :transaction_type, 
                                     :sub_store_id, :sub_store_name, :is_blocked_by_user, 
                                     :blocked_by_user, :blocked_by_user_name, 
                                     :blocked_datetime, :blocked_stock_by_user, 
                                     :blocked_stock_by_user_comment, :blocked_stock
                                   ))
    lot.stock = stock
    lot.available_stock = stock
    lot.total_cost = total_cost
    lot.store_id = store_id
    lot.item_id = item_id
    lot.variant_id = variant_id
    lot.transaction_type = transaction_type
    lot.sub_store_id = sub_store_id
    lot.sub_store_name = sub_store_name
    lot.optical_order_id = optical_order_id
    lot.requisition_order_id = requisition_order_id
    if lot.save!
      InventoryJobs::Transactions::Lot::CreateLotUnitJob.perform_later(lot.id.to_s) if item.unit_level
      Inventory::Audit::History::CreateService.call(
        0, lot, transaction_type, transaction_id, current_user_id
      )
    end
    lot
  end
end
