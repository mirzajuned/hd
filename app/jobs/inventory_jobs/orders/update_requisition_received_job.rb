class InventoryJobs::Orders::UpdateRequisitionReceivedJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    indent_id = args[0]

    indent_order = Inventory::Order::Indent.find_by(id: indent_id)
    return unless indent_order.present? && indent_order.items.present?

    indent_order.items.each do |item|
      variant = Inventory::Item::Variant.find_by(id: item.variant_id)
      # if item.requisition_received_id.present?
      #   requisition_received = Inventory::Order::RequisitionReceived.find_by(id: item.requisition_received_id)
      #   requisition_received_items = requisition_received.items
      #   requisition_received_item = requisition_received_items.find_by(id: item.requisition_received_item_id)
      #   if item.stock >= requisition_received_item.remaining_stock
      #     remaining_stock = 0
      #   else
      #     remaining_stock = requisition_received_item.remaining_stock - item.stock
      #   end
      #   requisition_received_item.update(remaining_stock: remaining_stock)
      #   sum_remaining_stock = requisition_received_items.pluck(:remaining_stock).inject(&:+)
      #   requisition_received.update(status: 'Completed') if sum_remaining_stock == 0
      # end
      variant.update!(indent_requested_quantity: variant.indent_requested_quantity + item.stock.to_f)
    end
  end
end
