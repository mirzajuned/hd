json.array!(@inventory_item_descriptions) do |inventory_item_description|
  json.extract! inventory_item_description, :id, :details, :manufacturer, :expiry
  json.url inventory_item_description_url(inventory_item_description, format: :json)
end
