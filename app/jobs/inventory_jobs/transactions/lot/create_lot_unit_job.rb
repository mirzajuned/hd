class InventoryJobs::Transactions::Lot::CreateLotUnitJob < ActiveJob::Base
  queue_as :urgent
  def perform(*args)
    # This is not a permanent solution.
    lot_id = args[0]
    lot = Inventory::Item::Lot.find_by(id: lot_id)
    stock = lot.stock.to_i
    (1..stock).each_with_index do |_unit, index|
      lot_unit = Inventory::Item::LotUnit.new(lot.attributes.except!(:_id, :stock, :available_stock, :barcode_id))
      barcode_id = Inventory::Lots::GenerateBarCodeService.default("#{lot.lot_code}-#{index}", lot.organisation_id)
      code = Inventory::ItemsHelper.increment_and_create_lot_unit_no(args[0], lot.lot_code, lot.organisation_id)
      lot_unit.barcode_id = barcode_id
      lot_unit.lot_unit_code = code
      lot_unit.lot_id = args[0]
      lot_unit.stock = 1
      lot_unit.available_stock = 1
      lot_unit.save!
    end
  end
end
