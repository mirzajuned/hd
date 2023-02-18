class InventoryJobs::Transactions::StockUpdateJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)

    transaction_type = args[2] || 'Stock Opening'
    transaction = if transaction_type == 'Stock Opening'
    	  Inventory::Transaction::StockOpening.find_by(id: args[0])
      elsif transaction_type == 'Direct Stock'
        Inventory::Transaction::DirectStock.find_by(id: args[0])
      end
  	user_id = args[1]

    if transaction.present? && transaction.items.present?
      transaction_items = transaction.items
      transaction_items.each do |transaction_item|
        item = Inventory::Item.find_by(id: transaction_item.item_id)
        variant = Inventory::Item::Variant.find_by(item_id: transaction_item.item_id,
                                                   store_id: transaction_item.store_id,
                                                   variant_identifier: transaction_item.variant_identifier)
        variant = Inventory::Variants::CreateService.call(transaction_item, item) if variant.try(:id).blank?
        Inventory::Lots::CreateService.call(
          transaction_item, variant, transaction_type, transaction, user_id, item.id
        )
        variant.stock = variant.calculate_stock
        variant.empty = variant.stock == 0
        if variant.fixed_threshold
          new_threshold_value = variant.threshold_value || 0
        else
          new_threshold_value = (variant.stock * variant.threshold) / 100
          variant.threshold_value = new_threshold_value
        end
        running_low = (variant.stock <= new_threshold_value)
        variant.running_low = running_low
        variant.save!

        item.stock = item.calculate_stock
        item.empty = item.stock == 0
        if item.fixed_threshold
          new_threshold_value = item.threshold_value || 0
        else
          new_threshold_value = (item.stock * item.threshold) / 100
          item.threshold_value = new_threshold_value
        end
        running_low = (item.stock <= new_threshold_value)
        item.running_low = running_low
        item.save!
      end
    end
  end
end
