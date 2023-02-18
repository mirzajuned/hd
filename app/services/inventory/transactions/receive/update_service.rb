module Inventory::Transactions::Receive::UpdateService
  def self.call(*args) 
    transaction_id = args[0]
    user_id = args[1]
    transaction_type = 'Receive'
    params = args[2]

    received_items = params['items_attributes']
    total_cost = params['total_cost'].to_f
    receive_transaction = Inventory::Transaction::Receive.find_by(id: transaction_id)
    transfer_transaction = Inventory::Transaction::Transfer.find_by(id: receive_transaction.transfer_id)
    @requisition = Inventory::Order::Requisition.find_by(id: transfer_transaction.requisition_id)
    receive_items(
      receive_transaction, transfer_transaction, received_items, transaction_type, user_id
    )
    # receive_total_items = receive_transaction.items.pluck(:stock).inject(&:+)
    update_requisition_fulfilment_status if @requisition.present?
    receive_transaction.total_cost = total_cost
    receive_transaction.status = 'Received'
    receive_transaction.user_id = user_id
    receive_transaction.transaction_date = Date.current
    receive_transaction.transaction_time = Time.current
    update_transfer_transaction(transfer_transaction) if receive_transaction.save!
    [receive_transaction, transfer_transaction]
  end

  def self.update_transfer_transaction(transfer_transaction)
    rejected_stock = transfer_transaction.items.pluck(:rejected_stock).inject(&:+)
    if rejected_stock > 0
      transfer_transaction.update(status: :pending, receive_status: :partially_received)
    else
      transfer_transaction.update(status: :closed, receive_status: :completed)
    end
  end

  def self.update_requisition_fulfilment_status
    items = @requisition.items
    requested_stock = items.pluck(:stock).inject(&:+)
    received_requested_stock = items.pluck(:received_requested_stock).inject(&:+)
    if received_requested_stock == 0
      fulfilment_status = 'none'
      status = @requisition.status
    elsif requested_stock == received_requested_stock
      fulfilment_status = 'completed'
      status = 'closed'
    else
      fulfilment_status = 'partial-completed'
      status = 'Transferred'
    end
    @requisition.update!(fulfilment_status: fulfilment_status, status: status)
  end

  def self.receive_items(receive, transfer, received_items, transaction_type, user_id)
    store_id = receive.store_id
    transfer_items = transfer.items
    received_items.each do |_index, received_item|
      transfer_item = transfer_items.find_by(id: received_item['transfer_item_id'])
      item = Inventory::Item.find_by(reference_id: transfer_item.item_reference_id, store_id: store_id)
      item = Inventory::Items::CreateService.call(transfer_item.item_id, store_id) unless item.to_a.present?
      stock = received_item['stock'].to_f
      total_cost = received_item['total_cost'].to_f
      rejected_lot_unit_ids = received_item[:rejected_lot_unit_ids]
      received_lot_unit_ids = received_item[:received_lot_unit_ids]
      sub_store_id = received_item[:sub_store_id]
      sub_store_name = received_item[:sub_store_name]
      if @requisition.present?
        requisition_item = @requisition.items.find_by(id: transfer_item.requisition_item_id)
        if requisition_item.present?
          received_requested_stock = requisition_item.received_requested_stock.to_f + stock
          requisition_item.update!(received_requested_stock: received_requested_stock)
        end
      end
      rejected_stock = received_item[:rejected_stock]
      not_received_comment = received_item[:not_received_comment]
      # variant = Inventory::Item::Variant
      #           .find_by(reference_id: transfer_item.variant_reference_id, store_id: store_id)
      variant_identifier = Inventory::Item::Variant.find_by(id: transfer_item.variant_id).variant_identifier
      variant = Inventory::Item::Variant.find_by(item_id: item.id, store_id: store_id, variant_identifier: variant_identifier)
      unless variant.to_a.present?
        variant = Inventory::Variants::CreateService.transaction(transfer_item.variant_id, store_id, item.id)
      end
      lot = Inventory::Item::Lot
            .find_by(reference_id: transfer_item.lot_reference_id, store_id: store_id, sub_store_id: sub_store_id)  
      lot = if lot.to_a.present?
              Inventory::Lots::UpdateService.call(stock, lot, transaction_type, receive.id, user_id)
            else
              Inventory::Lots::CreateService.transaction(
                transfer_item.lot_id, transaction_type, store_id, item.id, variant.id,
                stock, receive.id.to_s, user_id, total_cost, sub_store_id, sub_store_name
              )
            end

      receive_item_params = transfer_item.attributes
                                         .except(:_id, :lot_id, :item_id, :variant_id, :store_id, :stock, :total_cost )
      receive_item_params = receive_item_params.merge(
        lot_id: lot.id, item_id: item.id, variant_id: variant.id, store_id: store_id,
        stock: stock, total_cost: total_cost, rejected_lot_unit_ids: rejected_lot_unit_ids,
        received_lot_unit_ids: received_lot_unit_ids, sub_store_id: sub_store_id, sub_store_name: sub_store_name,
        rejected_stock: rejected_stock, not_received_comment: not_received_comment
      )
      receive.items.build(receive_item_params)

      # transfer_variant = Inventory::Item::Variant.find_by(id: transfer_item.variant_id)
      # if transfer_variant.pending_tranfered_quantity.present? && transfer_variant.pending_tranfered_quantity >= transfer_item.stock
      #   transfer_variant.update!(pending_tranfered_quantity: transfer_variant.pending_tranfered_quantity - transfer_item.stock)
      # end

      variant.stock = variant.calculate_stock
      variant.empty = variant.stock.to_f == 0
      if variant.fixed_threshold
        new_threshold_value = variant.threshold_value.to_f
        running_low = (variant&.stock.to_f <= new_threshold_value)
        variant.running_low = running_low
      else
        new_threshold_value = (variant.try(:stock).to_f * variant.try(:threshold).to_f) / 100
        variant.threshold_value = new_threshold_value
        running_low = (variant&.stock.to_f <= new_threshold_value)
        variant.running_low = running_low
      end
      if variant.pending_tranfered_quantity.present? && variant&.pending_tranfered_quantity.to_f >= transfer_item.stock.to_f
        requisition_validation = variant&.requested_quantity.to_f == 0 ? true : false
        variant.update!(
          pending_tranfered_quantity: variant.pending_tranfered_quantity - transfer_item.stock,
          requisition_validation: requisition_validation
        )
      end
      variant.save!

      item.stock = item.calculate_stock
      item.empty = item.stock == 0
      if item.fixed_threshold
        new_threshold_value = item.threshold_value.to_f
        running_low = (item&.stock.to_f <= new_threshold_value)
        item.running_low = running_low
      else
        new_threshold_value = (item.try(:stock).to_f * item.try(:threshold).to_f) / 100
        item.threshold_value = new_threshold_value
        running_low = (item&.stock.to_f <= new_threshold_value)
        item.running_low = running_low
      end
      item.save!

      rejected_stock = transfer_item.rejected_stock + (transfer_item.stock - stock) 
      transfer_item.update(rejected_stock: rejected_stock, received_rejected_stock: false)
      if transaction_type == "Receive" && rejected_stock != 0.0
        transfer_lot = Inventory::Item::Lot.find_by(id: transfer_item.lot_id, store_id: transfer_item.store_id )
        missing_stock = transfer_lot&.missing_stock.to_f + rejected_stock
        transfer_lot&.update(missing_stock: missing_stock, received_missing_stock: false) if missing_stock > 0.0
      end
      transfer.update(is_missing_stock_available: true) if rejected_stock > 0.0
    end
  end
end
