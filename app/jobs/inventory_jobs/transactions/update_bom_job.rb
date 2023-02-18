class InventoryJobs::Transactions::UpdateBomJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    bom_transaction = Inpatient::BillOfMaterial.find_by(id: args[0])
    bom_old_item = args[2]
    bom_old_item_hash = bom_old_item.to_h
    transaction_type = 'Bill Of Material'
    return unless bom_transaction.present? && bom_transaction.items.present?

    bom_transaction.items.each do |bom_item|
      item = Inventory::Item.find_by(id: bom_item.item_id)
      variant = Inventory::Item::Variant.find_by(id: bom_item.variant_id, store_id: bom_item.store_id)
      lot = Inventory::Item::Lot.find_by(id: bom_item.lot_id, store_id: bom_item.store_id)
      tray_id = bom_item.tray_id
      earlier_bom_quantity = bom_old_item_hash[bom_item.lot_id.to_s].to_f
      current_bom_quantity = bom_item.bom_quantity
      quantity = earlier_bom_quantity.to_f - current_bom_quantity.to_f
      if tray_id.present?
        tray = Inventory::Transaction::Tray.find_by(id: tray_id)
        tray_item_lot_id = tray.items.pluck(:lot_id)
        if (tray_item_lot_id.include? bom_item.lot_id) && (tray.status != 'closed')
          tray_item = tray.items.find_by(lot_id: bom_item.lot_id)
          tray_item_stock = tray_item.stock.to_f
          total_stock = tray_item_stock + earlier_bom_quantity
          if current_bom_quantity > earlier_bom_quantity
            qty = current_bom_quantity - earlier_bom_quantity
            if total_stock > current_bom_quantity
              tray_item.update(stock: tray_item_stock - qty)
            else
              tray_item.update(stock: 0)
            end
          else
            qty = earlier_bom_quantity - current_bom_quantity
            tray_item.update(stock: tray_item_stock + qty)
          end
          if current_bom_quantity > total_stock
            Inventory::Lots::UpdateService.call(total_stock - current_bom_quantity, lot, transaction_type, args[0], args[1])
          end
          if tray.items.pluck(:stock)&.sum == 0
            tray.update(status: 'consumed')
          else
            tray.update(status: 'partially_consumed')
          end
        else
          Inventory::Lots::UpdateService.call(quantity, lot, transaction_type, args[0], args[1])
        end
      else
        if bom_old_item_hash&.keys.include? bom_item.lot_id
          if earlier_bom_quantity != current_bom_quantity
            Inventory::Lots::UpdateService.call(quantity, lot, transaction_type, args[0], args[1])
          end
        else
          quantity = bom_item.bom_quantity
          Inventory::Lots::UpdateService.call(-quantity, lot, transaction_type, args[0], args[1]) if quantity > 0
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
