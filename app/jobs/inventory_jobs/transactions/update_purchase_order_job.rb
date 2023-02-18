class InventoryJobs::Transactions::UpdatePurchaseOrderJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    po_item_hash = args[1]
    po_item_paid_hash = args[2]
    po_item_free_hash = args[3]
    action = args[4]
    other_charges_amount = args[5] || 0

    purchase_order = Inventory::Order::Purchase.find_by(id: args[0])
    remaining_amount = purchase_order.remaining_total_other_charges_amount || 0
    if action == 'create'
      amount = remaining_amount - other_charges_amount
    else
      amount = remaining_amount + other_charges_amount
    end

    purchase_order.update!(remaining_total_other_charges_amount: amount)

    return unless purchase_order.items

    po_items = purchase_order.items
    po_item_hash.each_key do |po_item_id|
      current_stock_blocked = po_item_hash[po_item_id].to_f || 0 
      current_paid_stock_blocked = po_item_paid_hash[po_item_id].to_f || 0
      current_free_stock_blocked = po_item_free_hash[po_item_id].to_f || 0
      order_item = po_items.find_by(id: po_item_id)
     
      if action == 'create'
        current_stock_blocked += order_item&.stock_blocked if order_item&.stock_blocked
        order_item.update!(stock_blocked: current_stock_blocked)

        current_paid_stock_blocked += order_item&.stock_paid_blocked if order_item&.stock_paid_blocked
        order_item.update!(stock_paid_blocked: current_paid_stock_blocked)

        current_free_stock_blocked += order_item&.stock_free_blocked if order_item&.stock_free_blocked
        order_item.update!(stock_free_blocked: current_free_stock_blocked)
      else
        stock_blocked = order_item&.stock_blocked.to_f - current_stock_blocked
        stock_paid_blocked = order_item&.stock_paid_blocked.to_f - current_paid_stock_blocked
        stock_free_blocked = order_item&.stock_free_blocked.to_f - current_free_stock_blocked
        order_item.update!(stock_blocked: stock_blocked&.round(2), stock_paid_blocked: stock_paid_blocked&.round(2), stock_free_blocked: stock_free_blocked&.round(2))
      end
    end
  end
end
