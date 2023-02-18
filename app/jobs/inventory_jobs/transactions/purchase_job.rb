class InventoryJobs::Transactions::PurchaseJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    purchase_transaction = Inventory::Transaction::Purchase.find_by(id: args[0])

    # if transaction is done using purchase order
    purchase_order_ids = purchase_transaction.try(:purchase_order_ids)
    if purchase_order_ids.present?
      purchase_order_id = purchase_order_ids[0]
      purchase_order = Inventory::Order::Purchase.find_by(id: purchase_order_id)
    end

    current_user_id = args[1]

    transaction_type = 'Purchase'
    # transaction_id = args[0]

    if purchase_transaction.present? && purchase_transaction.items.present?
      transaction_items = purchase_transaction.items
      transaction_items.each do |transaction_item|
        item = Inventory::Item.find_by(reference_id: transaction_item.item_reference_id, store_id: transaction_item.store_id)
        # item = Inventory::Item.find_by(id: transaction_item.item_id)
        variant = Inventory::Item::Variant.find_by(reference_id: transaction_item.variant_reference_id,
                                                   store_id: transaction_item.store_id,
                                                   variant_identifier: transaction_item.variant_identifier)
        variant = Inventory::Variants::CreateService.call(transaction_item, item) if variant.try(:id).blank?
        Inventory::Lots::CreateService.call(
          transaction_item, variant, transaction_type, purchase_transaction, current_user_id, item.id
        )
        variant.stock = variant.calculate_stock
        variant.empty = variant.stock == 0
        if variant.fixed_threshold
          new_threshold_value = variant.threshold_value || 0
        else
          new_threshold_value = (variant.stock * variant.threshold) / 100
          variant.threshold_value = new_threshold_value
        end
        running_low = (variant.stock <= new_threshold_value)
        variant.running_low = running_low
        variant.save!

        item.stock = item.calculate_stock
        item.empty = item.stock == 0
        if item.fixed_threshold
          new_threshold_value = item.threshold_value || 0
        else
          new_threshold_value = (item.stock * item.threshold) / 100
          item.threshold_value = new_threshold_value
        end
        running_low = (item.stock <= new_threshold_value)
        item.running_low = running_low
        item.save!
        Inventory::Vendor::VendorPurchaseRateService.call(purchase_transaction, variant, transaction_item)

        next unless purchase_order.present?

        purchase_order.items.update_all(stock_blocked: 0, stock_paid_blocked: 0, stock_free_blocked: 0)
        purchase_order_item = purchase_order.items.find_by(
          item_id: transaction_item.item_id, store_id: transaction_item.store_id,
          variant_identifier: transaction_item.variant_identifier
        )
        
        stock_received = purchase_order_item.try(:stock_received).to_f
        transaction_stock_received = transaction_item.try(:stock).to_f

        stock_paid_received = purchase_order_item.try(:stock_paid_received).to_f
        paid_stock = transaction_item.try(:paid_stock).to_f

        stock_free_received = purchase_order_item.try(:stock_free_received).to_f
        stock_free_unit = transaction_item.try(:stock_free_unit).to_f

        total_stock_received = stock_received + transaction_stock_received
        total_stock_paid_received = stock_paid_received + paid_stock
        total_stock_free_received = stock_free_received + stock_free_unit

        purchase_order_item.stock_received = total_stock_received
        purchase_order_item.stock_paid_received = total_stock_paid_received
        purchase_order_item.stock_free_received = total_stock_free_received

        # blocked stock
        # stock_blocked = purchase_order_item.try(:stock_blocked).to_f
        # transaction_stock_blocked = transaction_item.try(:stock).to_f

        # stock_paid_blocked = purchase_order_item.try(:stock_paid_blocked).to_f
        # paid_stock = transaction_item.try(:paid_stock).to_f

        # stock_free_blocked = purchase_order_item.try(:stock_free_blocked).to_f
        # stock_free_unit = transaction_item.try(:stock_free_unit).to_f

        # total_stock_blocked = stock_blocked - transaction_stock_blocked
        # total_stock_paid_blocked = stock_paid_blocked - paid_stock
        # total_stock_free_blocked = stock_free_blocked - stock_free_unit

        # purchase_order_item.stock_blocked = total_stock_blocked
        # purchase_order_item.stock_paid_blocked = total_stock_paid_blocked
        # purchase_order_item.stock_free_blocked = total_stock_free_blocked

        if total_stock_received.to_f == purchase_order_item.try(:stock).to_f
          purchase_order_item.stock_received_status = true
        end
        purchase_order_item.save!
      end
    end

    return unless purchase_order.present?
    remaining_po_paid_stock = purchase_order.remaining_po_total_paid_stock
    if remaining_po_paid_stock.present?
      total_grn_paid_stock = purchase_transaction.items.pluck(:paid_stock).inject(:+)
      stock_diff = remaining_po_paid_stock.to_f - total_grn_paid_stock.to_f
      purchase_order.update(remaining_po_total_paid_stock: stock_diff)
    end
    pending_order_items = purchase_order.items.where(stock_received_status: false)
    if pending_order_items.present?
      order_status = 'Partially-Completed'
      order_completed = false
      order_closed = false
    else
      order_status = 'Completed'
      order_completed = true
      order_closed = true
    end
    purchase_order.order_status = order_status
    purchase_order.is_completed = order_completed
    purchase_order.is_closed = order_closed
    purchase_order.transaction_present = true
    purchase_order.save!
  end
end
