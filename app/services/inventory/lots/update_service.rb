module Inventory::Lots::UpdateService
  def self.call(stock_value, lot, transaction_type, transaction_id, current_user_id, unblock_lot = nil)
    return_transactions = Inventory::Transaction::Return.find_by(invoice_id: transaction_id)
    is_blocked_by_user = lot.try(:is_blocked_by_user) || false
    if return_transactions.present? && return_transactions.status == 'Received'
      return_transactions_items = return_transactions&.items
      return_lot = return_transactions_items.find_by(lot_id: lot.id)
      stock_value = if return_lot.present?
                      stock_value - return_lot.stock.to_f
                    else
                      stock_value
                    end
    else
      stock_value = stock_value
    end

    stock_before = lot.stock.round(2)
    stock_value = stock_value.round(2)
    stock_after = (stock_before + stock_value)&.round(2) || 0
    lot.update(empty: true) if stock_after == 0
    unit_cost = lot.unit_cost.to_f
    total_cost_after = stock_after * unit_cost
    if is_blocked_by_user
      lot.blocked_stock += stock_value
      lot.is_blocked = true
    elsif transaction_type == 'Transfer' || transaction_type == 'Order' || transaction_type == 'Stock Receive Note' || transaction_type == 'Store Consumption'
      lot.blocked_stock += stock_value
      lot.is_blocked = lot.blocked_stock != 0
    elsif transaction_type == 'Invoice'
      invoice = Invoice::InventoryInvoice.find_by(id: transaction_id)
      if unblock_lot == 'true'
        lot.blocked_stock += stock_value
        lot.is_blocked = lot.blocked_stock != 0
      end
    end
    lot.available_stock = (stock_after - lot.blocked_stock)&.round(2)
    lot.returned_stock = lot.returned_stock.to_f +  stock_value&.abs if transaction_type == "Purchase Return"
    if transaction_type == 'Receive'
      receive = Inventory::Transaction::Receive.find_by(id: transaction_id)
      lot.optical_order_id = receive.optical_order_id
      lot.requisition_order_id = receive.requisition_order_id
    end
    if lot.update(stock: stock_after, total_cost: total_cost_after)
      Inventory::Audit::History::CreateService.call(
        stock_before, lot, transaction_type, transaction_id, current_user_id
      )
    end
    lot
  end
end
