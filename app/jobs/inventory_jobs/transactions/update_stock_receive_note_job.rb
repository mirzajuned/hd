class InventoryJobs::Transactions::UpdateStockReceiveNoteJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    stock_receive_note = Inventory::Transaction::StockReceiveNote.find_by(id: args[0])
    current_user_id = args[1]
    transaction_type = 'Stock Receive Note'
    transaction_id = stock_receive_note.id
    return unless stock_receive_note.present? && stock_receive_note.items.present?

    stock_receive_note.items.each do |item|
      stock_value = item.stock
      lot = Inventory::Item::Lot.find_by(id: item.lot_id)
      Inventory::Lots::UpdateService.call(-stock_value, lot, transaction_type, transaction_id, current_user_id)
    end
  end
end
