class InventoryJobs::Transactions::StockReceiveNoteJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    Inventory::Transactions::UpdateStockReceiveNoteService.call(args[0], args[1])
  end
end
