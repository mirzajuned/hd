class InventoryJobs::Orders::RequisitionReceivedStockJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    transfer_id = args[0]
    action = args[1]

    transfer = Inventory::Transaction::Transfer.find_by(id: transfer_id)
    requisition_received_id = transfer.requisition_received_id
    requisition_received = Inventory::Order::RequisitionReceived.find_by(id: requisition_received_id)

    return unless requisition_received.present? && transfer.present?

    transfer_items = transfer.items.group_by { |item| item.variant_id.to_s }
    transfer_items.each do |variant_id, items|
      stock = items.pluck(:stock).inject(&:+)
      variant = Inventory::Item::Variant.find_by(id: variant_id)
      req_received_store_item = Inventory::Item.find_by(id: variant.item_id)
      store_id = requisition_received.requisition_order_store_id
      req_store_item = Inventory::Item.find_by(reference_id: req_received_store_item.reference_id, store_id: store_id)
      variant_id = Inventory::Item::Variant.find_by(item_id: req_store_item.id, store_id: store_id, variant_identifier: variant.variant_identifier)&.id
      requisition_received_item = requisition_received.items.find_by(variant_id: variant_id&.to_s)
      if requisition_received_item.present?
        if action == 'cancel'
          remaining_stock = requisition_received_item.remaining_stock + stock
        else
          remaining_stock = requisition_received_item.remaining_stock - stock
        end
        requisition_received_item.update(remaining_stock: remaining_stock)
      end
    end
    sum_remaining_stock = requisition_received.items.pluck(:remaining_stock).inject(&:+)
    original_stock = requisition_received.items.pluck(:stock).inject(&:+)
    if sum_remaining_stock == 0
      requisition_received.update(status: 'Closed')
    elsif original_stock == sum_remaining_stock
      requisition_received.update(status: 'Pending')
    else
      requisition_received.update(status: 'Transferred')
    end
    # requisition_received.update(status: 'Completed') if sum_remaining_stock == 0
  end
end
