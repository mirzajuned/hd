class InventoryJobs::Transactions::InvoiceJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: args[0])
    @order_id = @inventory_invoice.order_id
    @stock_receive_note = Inventory::Transaction::StockReceiveNote.find_by(id: @inventory_invoice.srn_id)
    @requisition = Inventory::Order::Requisition.find_by(id: @inventory_invoice.requisition_id)
    current_user_id = args[1]
    transaction_type = 'Invoice'
    transaction_id = args[0]
    return unless @inventory_invoice.present? && @inventory_invoice.items.present?

    transaction_items = @inventory_invoice.items
    store_id = @inventory_invoice.store_id
    transaction_items.each do |transaction_item|
      type = @stock_receive_note&.id.present? ? 'Stock Receive Note' : 'Invoice'
      transaction_id = @stock_receive_note&.id.present? ? @stock_receive_note.id : args[0]
      item = Inventory::Item.find_by(id: transaction_item.item_id)
      variant = Inventory::Item::Variant.find_by(id: transaction_item.variant_id, store_id: store_id)
      stock_value = transaction_item.try(:quantity).to_f
      if @requisition.present? && transaction_item.requisition_required
        lots = Inventory::Item::Lot.where(optical_order_id: @order_id, item_id: transaction_item.item_id, store_id: store_id, :available_stock.gte => 1)
        lots.each do |lot|
          unless stock_value == 0
            if lot.available_stock >= stock_value
              Inventory::Lots::UpdateService.call(-stock_value, lot, type, transaction_id, current_user_id)
              break
            else
              Inventory::Lots::UpdateService.call(-lot.available_stock, lot, type, transaction_id, current_user_id)
              stock_value -= lot.available_stock
            end
          end
        end
      else
        lot = Inventory::Item::Lot.find_by(id: transaction_item.lot_id, store_id: store_id)
        Inventory::Lots::UpdateService.call(-stock_value, lot, type, transaction_id, current_user_id, 'true')
        Inventory::History::LotBlocked
          .where(transaction_id: transaction_id, transaction_type: type, store_id: store_id)
          .update_all(status: :close)
      end

      lot_unit_ids = transaction_item.lot_unit_ids
      if lot_unit_ids.present?
        lot_units = Inventory::Item::LotUnit.where(:id.in => lot_unit_ids)
        lot_units.update_all(is_blocked: false, blocked_stock: 0, available_stock: 0, lot_blocked_id: nil, stock: 0)
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
