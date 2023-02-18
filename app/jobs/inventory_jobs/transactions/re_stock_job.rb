class InventoryJobs::Transactions::ReStockJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
  	transaction_id = args[0]
    current_user_id = args[1]
    transaction_type = 'Re-stock'
    transfer_transaction = Inventory::Transaction::Transfer.find_by(id: transaction_id)
    receive_transaction = Inventory::Transaction::Receive.find_by(id: transfer_transaction.receive_id)
    if transfer_transaction.present? && transfer_transaction.items.present?
      type = transfer_transaction.class.to_s
      store_id = transfer_transaction.store_id
      transaction_items = transfer_transaction.items
      transaction_items.each do |transaction_item|
      	item = Inventory::Item.find_by(id: transaction_item.item_id)
        variant = Inventory::Item::Variant.find_by(id: transaction_item.variant_id, store_id: store_id)
        lot = Inventory::Item::Lot.find_by(id: transaction_item.lot_id, store_id: store_id)
        stock_value = transaction_item.try(:rejected_stock)
        missing_stock = lot.missing_stock - transaction_item.rejected_stock
        stock = lot.stock + transaction_item.rejected_stock
        available_stock = lot.available_stock + transaction_item.rejected_stock
        # stock: stock, available_stock: available_stock,
        lot.update(missing_stock: missing_stock,received_missing_stock: true) if lot.missing_stock > 0.0 || transaction_item.rejected_stock > 0.0
        if lot.to_a.present?
          Inventory::Lots::UpdateService.call(stock_value, lot, transaction_type, transfer_transaction.id, current_user_id)
        end
        variant.stock = variant.calculate_stock
        variant.empty = variant.stock == 0
        variant.running_low = (variant.stock.to_f <= variant.threshold_value.to_f)
        variant.save!
      	transfer_transaction.update(received_rejected_stock: true)
      	item.stock = item.calculate_stock
        item.empty = item.stock == 0
        item.running_low = (item.stock.to_f <= item.threshold_value.to_f)
        item.save!
        stock_value = transaction_item.rejected_stock
        tax_amount = (((stock_value&.abs * lot.net_unit_cost_without_tax.to_f) * (lot.tax_rate))/100)
      	total_transaction_cost = (stock_value&.abs * lot.net_unit_cost_without_tax.to_f) + tax_amount
      	amount_value = (stock_value.abs * lot.net_unit_cost_without_tax.to_f) + tax_amount
      	balance(lot,current_user_id,stock_value,amount_value)
      end
      receive_transaction.items.each do |receive_item|
      	rejected_lot_unit_ids = receive_item.rejected_lot_unit_ids 
      	lot_units = Inventory::Item::LotUnit.where(:id.in => rejected_lot_unit_ids) unless rejected_lot_unit_ids.nil?
      	lot_units.update_all(is_blocked: false, blocked_stock: 0, available_stock: 1, lot_blocked_id: nil, stock: 1, 
      			missing_stock: 0, received_missing_stock: true) unless lot_units.nil?
      end
  	end
  	transfer_transaction.update(is_missing_stock_available: false)
  end

  def balance(lot, current_user_id,stock_value,amount_value)
    balance = Inventory::Audit::Balance.find_by(date: Date.current, sub_store_id: lot.sub_store_id)
    balance = create_new_balance_record(lot) if balance.blank?

    balance.update(closing_stock: balance.closing_stock + stock_value,
                   closing_amount: balance.closing_amount + amount_value)
    balance.save!
  end

  def create_new_balance_record(lot,stock_value,amount_value)
    previous_day_balance = Inventory::Audit::Balance.find_by(date: Date.current - 1, sub_store_id: transaction_history.sub_store_id)
    if previous_day_balance.present?
      opening_stock = previous_day_balance.closing_stock
      opening_amount = previous_day_balance.closing_amount
    else
      lots = Inventory::Item::Lot.where(sub_store_id: lot.sub_store_id).is_active
      opening_stock = lots.pluck(:stock).map(&:to_f).inject(&:+) - stock_value
      opening_amount = lots.pluck(:total_cost).map(&:to_f).inject(&:+) - amount_value
    end
    balance = Inventory::Audit::Balance.new
    balance.opening_stock = opening_stock || 0
    balance.opening_amount = opening_amount || 0
    balance.closing_stock = opening_stock || 0
    balance.closing_amount = opening_amount || 0
    balance.store_id = lot.store_id
    balance.sub_store_id = lot.sub_store_id
    balance.facility_id = lot.facility_id
    balance.organisation_id = lot.organisation_id
    balance.date = Date.current
    balance.save!
    balance
  end
end
