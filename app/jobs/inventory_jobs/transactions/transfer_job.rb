class InventoryJobs::Transactions::TransferJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    transaction_id = args[0]
    current_user_id = args[1]
    transaction_type = 'Transfer'
    transfer_transaction = Inventory::Transaction::Transfer.find_by(id: transaction_id)

    if transfer_transaction.present? && transfer_transaction.items.present?
      type = transfer_transaction.class.to_s
      store_id = transfer_transaction.store_id
      transaction_items = transfer_transaction.items
      transaction_items.each do |transaction_item|
        item = Inventory::Item.find_by(id: transaction_item.item_id)
        variant = Inventory::Item::Variant.find_by(id: transaction_item.variant_id, store_id: store_id)
        lot = Inventory::Item::Lot.find_by(id: transaction_item.lot_id, store_id: store_id)
        stock_value = transaction_item.try(:stock).to_f
        Inventory::Lots::UpdateService.call(-stock_value, lot, transaction_type, transaction_id, current_user_id)
        lot_blocked = Inventory::History::LotBlocked
                      .where(transaction_id: transaction_id, transaction_type: type, store_id: store_id)
        lot_blocked.update_all(status: :close)
        lot_units = Inventory::Item::LotUnit.where(:lot_blocked_id.in => lot_blocked.pluck(:id))
        lot_units.update_all(is_blocked: false, blocked_stock: 0, available_stock: 0, lot_blocked_id: nil, stock: 0)
        variant.stock = variant.calculate_stock
        variant.empty = variant.stock == 0
        variant.running_low = (variant.stock.to_f <= variant.threshold_value.to_f)
        variant.save!

        if transfer_transaction.requisition_received.present?
          requested_store_id = transfer_transaction.requisition_received.requisition_order_store_id
          req_received_store_item = Inventory::Item.find_by(id: variant.item_id)
          req_store_item = Inventory::Item.find_by(reference_id: req_received_store_item.reference_id, store_id: requested_store_id)
          requested_variant = Inventory::Item::Variant.find_by(item_id: req_store_item.id, store_id: requested_store_id, variant_identifier: variant.variant_identifier)
          if requested_variant.to_a.present?
            if requested_variant.requested_quantity.present? && requested_variant.requested_quantity >= stock_value && stock_value > 0
              requested_variant.requested_quantity = requested_variant.requested_quantity - stock_value
              requested_variant.issue_requisition_validation = true if requested_variant.requested_quantity == 0
            end
            requested_variant.pending_tranfered_quantity = requested_variant.pending_tranfered_quantity.to_f + stock_value
            requested_variant.save!
          end
        end

        item.stock = item.calculate_stock
        item.empty = item.stock == 0
        item.running_low = (item.stock.to_f <= item.threshold_value.to_f)
        item.save!
      end
    end
    unless Inventory::Store.find_by(id: store_id)&.enable_tax_invoice
      Inventory::Transactions::Receive::CreateService.call(transaction_id)
    end
  end
end
