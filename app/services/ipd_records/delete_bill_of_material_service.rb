class IpdRecords::DeleteBillOfMaterialService
  def self.call(bom_id, user_id)
    transaction_id = bom_id
    current_user_id = user_id
    transaction_type = 'Bill Of Material Return'

    @bom_transaction = Inpatient::BillOfMaterial.find_by(id: transaction_id)

    bom_items = @bom_transaction.items
    return if bom_items.empty?

    bom_items.each do |bom_item|
      item = Inventory::Item.find_by(id: bom_item.item_id)
      variant = Inventory::Item::Variant.find_by(id: bom_item.variant_id, store_id: bom_item.store_id)
      lot = Inventory::Item::Lot.find_by(id: bom_item.lot_id, store_id: bom_item.store_id)
      stock_value = bom_item.try(:bom_quantity).to_f
      tray = Inventory::Transaction::Tray.find_by(id: bom_item.tray_id)
      if tray.present? && (tray.status != 'closed')
        bom_quantity = bom_item.bom_quantity
        tray_item = tray.items.find_by(lot_id: bom_item.lot_id)
        tray_item.update(stock: tray_item.stock + bom_quantity)
        if tray.items.pluck(:stock)&.sum == tray.items.pluck(:initial_stock)&.sum
          tray.update(status: 'open')
        else
          tray.update(status: 'partially_consumed')
        end
      else
        Inventory::Lots::UpdateService.call(stock_value, lot, transaction_type, transaction_id, current_user_id)
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
