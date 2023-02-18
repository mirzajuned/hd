json.array!(@inventory_item_lots) do |inventory_item_lot|
  json.extract! inventory_item_lot, :id, :batch_no, :self_batched, :price, :mark_up, :mrp, :list_price, :vendor, :expiry, :warranty_expiry, :stock # , :condition
  # json.url inventory_item_lot_url(inventory_item_lot, format: :json)
end
