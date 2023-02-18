module Inventory::Transactions::Return::CreateService
  def self.call(*args)
    transaction_id = args[0]
    current_user_id = args[1]
    transaction_type = 'Return'

    return_transaction = Inventory::Transaction::Return.find_by(id: transaction_id)
    @stock_receive_note = Inventory::Transaction::StockReceiveNote.find_by(id: return_transaction.srn_id)
    return_transaction.update(status: 'Received', transaction_date: Date.current)

    transaction_items = return_transaction.items
    transaction_items.each do |transaction_item|
      transaction_type = transaction_item.srn_required ? 'Stock Receive Note' : 'Return'
      transaction_id = transaction_item.srn_required ? @stock_receive_note.id : args[0]
      item = Inventory::Item.find_by(id: transaction_item.item_id)
      variant = Inventory::Item::Variant.find_by(id: transaction_item.variant_id, store_id: transaction_item.store_id)
      lot = Inventory::Item::Lot.find_by(id: transaction_item.lot_id, store_id: transaction_item.store_id)
      is_blocked_by_user = lot.try(:is_blocked_by_user) || false
      stock_value = transaction_item.try(:stock).to_f
      Inventory::Lots::UpdateService.call(stock_value, lot, transaction_type, transaction_id, current_user_id)

      lot_unit_ids = transaction_item.lot_unit_ids
      if lot_unit_ids.present?
        lot_units = Inventory::Item::LotUnit.where(:id.in => lot_unit_ids)
        if is_blocked_by_user == true
          lot_units.update_all(is_blocked: true, blocked_stock: 1, available_stock: 0, lot_blocked_id: lot.id, stock: 1)
        else
          lot_units.update_all(is_blocked: false, blocked_stock: 0, available_stock: 1, lot_blocked_id: nil, stock: 1)
        end
      end

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
