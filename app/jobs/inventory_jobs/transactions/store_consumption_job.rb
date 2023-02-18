class InventoryJobs::Transactions::StoreConsumptionJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    transaction_id = args[0]
    current_user_id = args[1]
    transaction_type = 'Store Consumption'
    store_consumption_transaction = Inventory::Transaction::StoreConsumption.find_by(id: transaction_id)

    if store_consumption_transaction.present? && store_consumption_transaction.items.present?
      type = store_consumption_transaction.class.to_s
      store_id = store_consumption_transaction.store_id
      transaction_items = store_consumption_transaction.items
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

        item.stock = item.calculate_stock
        item.empty = item.stock == 0
        item.running_low = (item.stock.to_f <= item.threshold_value.to_f)
        item.save!
      end
    end
  end
end
