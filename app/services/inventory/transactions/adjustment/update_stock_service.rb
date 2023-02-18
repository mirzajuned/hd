module Inventory::Transactions::Adjustment::UpdateStockService
  def self.call(adjustment_transaction, current_user_id)
    transaction_type = 'Adjustment'
    transaction_id = adjustment_transaction.id

    return unless adjustment_transaction.present? && adjustment_transaction.items.present?

    transaction_items = adjustment_transaction.items

    transaction_items.each do |transaction_item|
      item = Inventory::Item.find_by(id: transaction_item.item_id)
      variant = Inventory::Item::Variant.find_by(id: transaction_item.variant_id, store_id: transaction_item.store_id)
      lot = Inventory::Item::Lot.find_by(id: transaction_item.lot_id, store_id: transaction_item.store_id)
      stock_value = transaction_item.try(:stock).to_f
      if transaction_item.item_entry_type == "in"
       Inventory::Lots::UpdateService.call(stock_value, lot, transaction_type, transaction_id, current_user_id)
      else
        Inventory::Lots::UpdateService.call(-stock_value, lot, transaction_type, transaction_id, current_user_id)
      end  
      lot_units = Inventory::Item::LotUnit.where(:id.in => transaction_item.lot_unit_ids)
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