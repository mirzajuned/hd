json.array!(@inventory_item_stocks) do |inventory_item_stock|
  json.extract! inventory_item_stock, :id, :unit_price, :quantity
  json.url inventory_item_stock_url(inventory_item_stock, format: :json)
end
