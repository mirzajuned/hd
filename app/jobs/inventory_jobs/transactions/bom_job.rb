class InventoryJobs::Transactions::BomJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    bom_transaction = Inpatient::BillOfMaterial.find_by(id: args[0])

    return unless bom_transaction.present? && bom_transaction.items.present?

    bom_transaction.items.each do |bom_item|
      tray_id = bom_item.tray_id
      bom_quantity = bom_item.bom_quantity
      if tray_id.present?
        tray_item_id = bom_item.tray_item_id
        tray = Inventory::Transaction::Tray.find_by(id: tray_id)
        tray_item = tray.items.find_by(id: tray_item_id)
        if bom_quantity.to_f <= tray_item.stock.to_f
          less_qty = tray_item.stock.to_f - bom_quantity.to_f
          tray_item.update(stock: less_qty)
        end
        if tray.items.pluck(:stock)&.sum == 0
          tray.update(status: 'consumed')
        else
          tray.update(status: 'partially_consumed')
        end
      else
        item = Inventory::Item.find_by(id: bom_item.item_id)
        variant = Inventory::Item::Variant.find_by(id: bom_item.variant_id, store_id: bom_item.store_id)
        lot = Inventory::Item::Lot.find_by(id: bom_item.lot_id, store_id: bom_item.store_id)
        quantity = bom_item.try(:bom_quantity).to_f
        transaction_type = 'Bill Of Material'
        Inventory::Lots::UpdateService.call(-quantity, lot, transaction_type, args[0], args[1])

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
