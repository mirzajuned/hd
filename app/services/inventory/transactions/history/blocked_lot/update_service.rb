module Inventory::Transactions::History::BlockedLot::UpdateService
  class << self
    def call(transfer, deleted_lots = nil)
      @transfer = transfer
      @items = @transfer.items
      @type = @transfer.class.to_s
      return unless transfer.status.open?

      delete_lots(deleted_lots) if deleted_lots.present?
      update_lot_blocks
    end

    def update_lot_blocks
      @items.each do |item|
        quantity = @type == 'Invoice::InventoryOrder' ? item&.quantity.to_f : item&.stock.to_f
        lot = Inventory::Item::Lot.find_by(id: item.lot_id)
        lot_blocked = Inventory::History::LotBlocked.find_or_initialize_by(
          lot_id: item.lot_id, transaction_id: @transfer.id, transaction_type: @type, store_id: @transfer.store_id
        )
        if lot_blocked.item_id.nil?
          update_lot(lot, quantity) if lot.present?
          id = update_lot_blocked(lot_blocked, item)
          block_lot_unit(item.lot_unit_ids, id) if item.lot_unit_ids.present?
        else
          lot.blocked_stock = lot.blocked_stock - lot_blocked.quantity + quantity
          lot.update(available_stock: lot.stock - lot.blocked_stock)
          lot_blocked.update(quantity: quantity)
          update_lot_unit(item.lot_unit_ids, lot_blocked.id) if item.lot_unit_ids.present?
        end
      end
    end

    def update_lot_unit(lot_unit_ids, lot_blocked_id)
      lot_units = Inventory::Item::LotUnit.where(lot_blocked_id: lot_blocked_id).pluck(:id).map(&:to_s)
      new_lot_unit_ids = lot_unit_ids - lot_units
      deleted_lot_unit_ids = lot_units - lot_unit_ids
      unblock_lot_unit(deleted_lot_unit_ids) if deleted_lot_unit_ids.present?
      block_lot_unit(new_lot_unit_ids, lot_blocked_id) if new_lot_unit_ids.present?
    end

    def unblock_lot_unit(deleted_lot_unit_ids)
      lot_units = Inventory::Item::LotUnit.where(:id.in => deleted_lot_unit_ids)
      lot_units.update_all(is_blocked: false, blocked_stock: 0, available_stock: 1, lot_blocked_id: nil)
    end

    def update_lot(lot, quantity)
      blocked_stock = lot.blocked_stock + quantity
      available_stock = lot.stock - blocked_stock
      lot.update!(is_blocked: true, blocked_stock: blocked_stock, available_stock: available_stock)
    end

    def block_lot_unit(lot_unit_ids, lot_blocked_id)
      lot_units = Inventory::Item::LotUnit.where(:id.in => lot_unit_ids)
      lot_units.update_all(is_blocked: true, blocked_stock: 1, available_stock: 0, lot_blocked_id: lot_blocked_id)
    end

    def update_lot_blocked(lot_blocked, item)
      lot_blocked.item_id = item.item_id
      lot_blocked.quantity = item.stock.to_f
      lot_blocked.entered_by_id = @transfer.user_id
      lot_blocked.entered_by_name = @transfer.entered_by
      lot_blocked.created_on = @transfer.created_at
      lot_blocked.variant_id = item.variant_id
      lot_blocked.facility_id = @transfer.facility_id
      lot_blocked.organisation_id = @transfer.organisation_id
      lot_blocked.status = :open
      lot_blocked.save

      lot_blocked.id
    end

    def delete_lots(ids)
      lot_blocked = Inventory::History::LotBlocked
                    .where(store_id: @transfer.store_id, transaction_id: @transfer.id,
                           transaction_type: @type, :lot_id.in => ids)
      lot_blocked.each do |b_lot|
        lot = b_lot.lot
        lot.available_stock = lot.available_stock + b_lot.quantity
        lot.blocked_stock = lot.blocked_stock - b_lot.quantity
        lot.is_blocked = lot.blocked_stock != 0
        lot.update
      end
      lot_blocked.delete_all
    end
  end
end
