class InventoryJobs::Transactions::AdjustmentJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    stock_receive_note = Inventory::Transaction::StockReceiveNote.where(:order_ids.in => [args[0]])[0]
    srn_items = stock_receive_note.items.where(order_id: args[0])
    transaction_type = 'Stock Receive Note'
    transaction_id = stock_receive_note.id
    current_user_id = args[1]
    if srn_items.present?
      srn_items.each do |srn_item|
        item = Inventory::Item.find_by(id: srn_item.item_id)
        variant = Inventory::Item::Variant.find_by(id: srn_item.variant_id, store_id: srn_item.store_id)
        lot = Inventory::Item::Lot.find_by(id: srn_item.lot_id, store_id: srn_item.store_id)
        stock_value = srn_item.try(:stock).to_f
        Inventory::Lots::UpdateService.call(-stock_value, lot, transaction_type, transaction_id, current_user_id)

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
