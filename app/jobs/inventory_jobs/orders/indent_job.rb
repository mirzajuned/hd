class InventoryJobs::Orders::IndentJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    indent_id = args[0]
    purchase_order_id = args[1]
    action = args[2]
    indent = Inventory::Order::Indent.find_by(id: indent_id)
    purchase_order = Inventory::Order::Purchase.find_by(id: purchase_order_id)

    indent_items = indent.items
    purchase_order.items.each do |item|
      indent_item = indent_items.find_by(id: item.indent_item_id)
      transaction_stock_received = item.try(:paid_stock).to_f
      if indent_item.present?
        stock_received = indent_item.try(:stock_received).to_f
        if action == 'close'
          total_stock_received = stock_received
        elsif action == 'create'
          total_stock_received = stock_received + transaction_stock_received
        else
          total_stock_received = stock_received - transaction_stock_received
        end
        indent_item.stock_received = total_stock_received
        indent_item.stock_received_status = true if total_stock_received.to_f == indent_item.try(:stock).to_f
        indent_remaining_quantity = indent_item.stock.to_f - total_stock_received
        indent_item.save!
      end
      variant = Inventory::Item::Variant.find_by(id: item.default_variant_id)
      if variant.to_a.present?
        if action == 'create'
          variant.indent_requested_quantity = variant.indent_requested_quantity.to_f - transaction_stock_received
          variant.pending_po_quantity = variant.pending_po_quantity.to_f + transaction_stock_received
        else
          variant.indent_requested_quantity = variant.indent_requested_quantity.to_f + transaction_stock_received
          variant.pending_po_quantity = variant.pending_po_quantity.to_f - transaction_stock_received
        end
        variant.save!
      end
      item.indent_remaining_quantity = indent_remaining_quantity
      item.save!
    end

    total_indent_stock = indent.items.pluck(:stock).inject(&:+)
    total_stock_received = indent.items.pluck(:stock_received).inject(&:+)
    if total_stock_received == 0
      status = 'Open'
      indent_completed = false
      indent_closed = false
      transaction_present = false
    elsif total_indent_stock == total_stock_received
      status = 'Completed'
      indent_completed = true
      indent_closed = true
      transaction_present = true
    else
      status = 'Partially-Completed'
      indent_completed = false
      indent_closed = false
      transaction_present = true
    end
    indent.status = status
    indent.is_completed = indent_completed
    indent.is_closed = indent_closed
    indent.transaction_present = transaction_present
    indent.purchase_order_id = purchase_order&.id
    indent.save!
  end
end
