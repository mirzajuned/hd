module Inventory::Transactions::History::BlockedLot::CancelService
  class << self
    def call(transaction)
      @transaction = transaction
      @type = @transaction.class.to_s
      return unless @transaction.status.cancelled?

      update_lot_blocks
      update_non_stockable_lot_blocks if @type == 'Invoice::InventoryOrder'
    end

    def update_lot_blocks
      lot_blocks = Inventory::History::LotBlocked
                   .where(transaction_id: @transaction.id, transaction_type: @type, store_id: @transaction.store_id)
      lot_blocks.each do |lot_block|
        lot = lot_block.lot
        lot.blocked_stock -= lot_block.quantity
        lot.update!(is_blocked: lot.blocked_stock != 0, available_stock: lot.stock - lot.blocked_stock)
        update_lot_unit(lot_block.id)
      end
      lot_blocks.cancel_all
    end

    def update_lot_unit(lot_block_id)
      lot_units = Inventory::Item::LotUnit.where(lot_blocked_id: lot_block_id)
      lot_units.update_all(is_blocked: false, blocked_stock: 0, available_stock: 1, lot_blocked_id: nil)
    end

    def update_non_stockable_lot_blocks
      order = Invoice::InventoryOrder.find_by(id: @transaction.id, srn_required: true)
      return unless order.present?

      lot_blocks = Inventory::History::LotBlocked
                   .where(transaction_id: order.srn_id, transaction_type: 'Inventory::Transaction::StockReceiveNote',
                          store_id: @transaction.store_id)
      lot_blocks.each do |lot_block|
        lot = lot_block.lot
        lot.blocked_stock -= lot_block.quantity
        lot.update!(is_blocked: lot.blocked_stock != 0, available_stock: lot.stock - lot.blocked_stock)
      end
      lot_blocks.cancel_all
    end
  end
end
