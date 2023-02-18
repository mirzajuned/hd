class Inventory::Transactions::UpdateStockReceiveNoteService
  class << self
    def call(srn_id, current_user_id)
      stock_receive_note = Inventory::Transaction::StockReceiveNote.find_by(id: srn_id)
      inventory_order = Invoice::InventoryOrder.find_by(id: stock_receive_note.order_id)
      transaction_type = 'Stock Receive Note'
      if inventory_order.present? && stock_receive_note.items.present?
        stock_receive_note.items.each do |transaction_item|
          item = Inventory::Item.find_by(id: transaction_item.item_id)
          variant = Inventory::Item::Variant.find_by(item_id: transaction_item.item_id,
                                                     store_id: transaction_item.store_id,
                                                     reference_id: transaction_item.variant_reference_id)
          lot_id = Inventory::Lots::CreateService.call(
            transaction_item, variant, transaction_type, stock_receive_note, current_user_id, item.id
          )
          order_item = inventory_order.items.find_by(item_id: transaction_item.item_id, srn_required: true)
          order_item.update!(lot_id: lot_id, srn_pending: false, variant_id: variant.id)
          transaction_item.update!(lot_id: lot_id)

          variant.stock = variant.calculate_stock
          variant.empty = variant.stock == 0
          variant.running_low = (variant.stock.to_f <= variant.threshold_value.to_f)
          variant.save!

          item.stock = item.calculate_stock
          item.empty = item.stock == 0
          item.running_low = (item.stock.to_f <= item.threshold_value.to_f)
          item.save!
        end
        inventory_order.update!(srn_pending: false, srn_status: 'completed', srn_id: stock_receive_note.id,
                                srn_created: true, srn_created_by_id: current_user_id)
      end
      Inventory::Transactions::History::BlockedLot::CreateService.call(stock_receive_note)
    end
  end
end