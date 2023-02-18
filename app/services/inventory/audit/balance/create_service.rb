module Inventory::Audit::Balance::CreateService
  def self.call(transaction_history, current_user_id)
    balance = Inventory::Audit::Balance.find_by(date: Date.current, sub_store_id: transaction_history.sub_store_id)
    balance = create_new_balance_record(transaction_history) if balance.blank?

    balance.update(closing_stock: balance.closing_stock + transaction_history.stock_value,
                   closing_amount: balance.closing_amount + transaction_history.amount_value)
    balance.save!
  end

  def self.create_new_balance_record(transaction_history)
    previous_day_balance = Inventory::Audit::Balance.find_by(date: Date.current - 1, sub_store_id: transaction_history.sub_store_id)
    if previous_day_balance.present?
      opening_stock = previous_day_balance.closing_stock
      opening_amount = previous_day_balance.closing_amount
    else
      lots = Inventory::Item::Lot.where(sub_store_id: transaction_history.sub_store_id).is_active
      opening_stock = lots.pluck(:stock).map(&:to_f).inject(&:+) - transaction_history.try(:stock_value)
      opening_amount = lots.pluck(:total_cost).map(&:to_f).inject(&:+) - transaction_history.try(:amount_value)
    end
    balance = Inventory::Audit::Balance.new
    balance.opening_stock = opening_stock || 0
    balance.opening_amount = opening_amount || 0
    balance.closing_stock = opening_stock || 0
    balance.closing_amount = opening_amount || 0
    balance.store_id = transaction_history.store_id
    balance.sub_store_id = transaction_history.sub_store_id
    balance.facility_id = transaction_history.facility_id
    balance.organisation_id = transaction_history.organisation_id
    balance.date = Date.current
    balance.save!
    balance
  end
end
