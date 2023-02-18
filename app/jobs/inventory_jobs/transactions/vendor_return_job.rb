class InventoryJobs::Transactions::VendorReturnJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    @return_transaction = Inventory::Transaction::VendorReturn.find_by(id: args[0])
    current_user_id = args[1]

    transaction_type = 'Purchase Return'
    transaction_id = args[0]

    return unless @return_transaction.present? && @return_transaction.items.present?

    transaction_items = @return_transaction.items

    transaction_items.each do |transaction_item|
      item = Inventory::Item.find_by(id: transaction_item.item_id)
      variant = Inventory::Item::Variant.find_by(id: transaction_item.variant_id, store_id: transaction_item.store_id)
      lot = Inventory::Item::Lot.find_by(id: transaction_item.lot_id, store_id: transaction_item.store_id)
      lot.update(pr_net_unit_cost_without_tax: transaction_item.pr_net_unit_cost_without_tax)
      stock_value = transaction_item.try(:stock).to_f
      Inventory::Lots::UpdateService.call(-stock_value, lot, transaction_type, transaction_id, current_user_id)

      variant.stock = variant.calculate_stock
      variant.empty = variant.stock == 0
      variant.running_low = (variant.stock.to_f <= variant.threshold_value.to_f)
      variant.save!

      item.stock = item.calculate_stock
      item.empty = item.stock == 0
      item.running_low = (item.stock.to_f <= item.threshold_value.to_f)
      item.save!

      next unless transaction_item.unit_level && stock_value > 0

      lot_units = Inventory::Item::LotUnit.where(lot_id: lot.id).desc('_id').limit(stock_value).to_a
      lot_units.each(&:delete)
    end
  end
end
