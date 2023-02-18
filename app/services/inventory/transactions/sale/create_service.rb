module Inventory::Transactions::Sale::CreateService
  def self.call(*args)
    transaction_id = args[0]
    current_user_id = args[1]
    transaction_type = 'Cancel Invoice'

    cancel_invoice_transaction = Invoice::InventoryInvoice.find_by(id: transaction_id)
    cancel_invoice_transaction.update(is_canceled: true, cancel_date: Date.current, canceled_by: args[2], refund_reason: args[3])
    transaction_items = cancel_invoice_transaction.items
    transaction_items.each do |transaction_item|
      item = Inventory::Item.find_by(id: transaction_item.item_id)
      variant = Inventory::Item::Variant.find_by(id: transaction_item.variant_id, store_id: transaction_item.store_id)
      lot = Inventory::Item::Lot.find_by(id: transaction_item.lot_id, store_id: transaction_item.store_id)
      stock_value = transaction_item.try(:quantity).to_f
      Inventory::Lots::UpdateService.call(stock_value, lot, transaction_type, transaction_id, current_user_id)

      variant.stock = variant.calculate_stock
      variant.empty = variant.stock == 0
      variant.running_low = (variant.stock.to_f <= variant.threshold_value.to_f)
      variant.save!

      item.stock = item.calculate_stock
      item.empty = item.stock == 0
      item.running_low = (item.stock.to_f <= item.threshold_value.to_f)
      item.save!
    end
  end
end
