module Inventory::Transactions::Tray::CreateService
  def self.call(*args)
    transaction_id = args[0]
    current_user_id = args[1]
    transaction_type = args[3]

    tray_transaction = Inventory::Transaction::Tray.find_by(id: transaction_id)
    if transaction_type == 'Cancel Tray'
      tray_transaction.update(is_canceled: true, cancel_date: Date.current, canceled_by: args[2], status: 'canceled',
                              canceled_by_id: args[1])
    else
      tray_transaction.update(is_closed: true, closed_date: Date.current, closed_by: args[2], status: 'closed',
                              closed_by_id: args[1])
    end
    transaction_items = tray_transaction.items
    return if transaction_items.empty?

    transaction_items.each do |transaction_item|
      item = Inventory::Item.find_by(id: transaction_item.item_id)
      variant = Inventory::Item::Variant.find_by(id: transaction_item.variant_id, store_id: transaction_item.store_id)
      lot = Inventory::Item::Lot.find_by(id: transaction_item.lot_id, store_id: transaction_item.store_id)
      stock_value = transaction_item.try(:stock).to_f
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
