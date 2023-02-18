module Inventory::Audit::HistoriesHelper
  def transaction_types
    ['Purchase', 'Invoice', 'Adjustment', 'Transfer', 'Return', 'Purchase Return']
  end

  def sub_stores_type(store_id)
    Inventory::Store.find_by(id: store_id).sub_stores.pluck(:name, :id)
  end
end
