module Inventory::Transactions::History::BlockedLot::CreateService
  class << self
    def call(transaction)
      @transaction = transaction
      @items = @transaction.items
      @type = @transaction.class.to_s
      create_history
    end

    def create_history
      @items.each do |item|
        next if item.srn_required
        quantity = @type == 'Invoice::InventoryOrder' ? item&.quantity.to_f : item&.stock.to_f
        lot = Inventory::Item::Lot.find_by(id: item.lot_id)
        if lot.to_a.present?
          blocked_stock = (lot.blocked_stock + quantity)&.round(2)
          available_stock = (lot.stock - blocked_stock)&.round(2)
          lot.update(is_blocked: true, blocked_stock: blocked_stock, available_stock: available_stock)
        end

        lot_blocked = Inventory::History::LotBlocked.find_or_initialize_by(
          lot_id: item.lot_id, transaction_id: @transaction.id, transaction_type: @type,
          store_id: @transaction.store_id
        )
        lot_blocked.item_id = item.item_id
        lot_blocked.quantity = quantity
        lot_blocked.entered_by_id = @transaction.user_id
        lot_blocked.entered_by_name = @transaction.entered_by
        lot_blocked.created_on = @transaction.created_at
        lot_blocked.variant_id = item.variant_id
        lot_blocked.facility_id = @transaction.facility_id
        lot_blocked.organisation_id = @transaction.organisation_id
        lot_blocked.status = :open
        lot_blocked.save
        lot_unit_ids = item.lot_unit_ids
        if lot_unit_ids.present?
          lot_units = Inventory::Item::LotUnit.where(:id.in => lot_unit_ids)
          lot_units.update_all(is_blocked: true, blocked_stock: 1, available_stock: 0, lot_blocked_id: lot_blocked.id)
        end
      end
    end
  end
end
