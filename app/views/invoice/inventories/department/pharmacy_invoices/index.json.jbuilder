json.array!(@invoice_inventory_department_pharmacies) do |invoice_inventory_department_pharmacy|
  json.extract! invoice_inventory_department_pharmacy, :id, :recipient, :recipient_mobile, :bill_number, :discount
  quantity = invoice_inventory_department_pharmacy.items.pluck("quantity").inject(&:+)
  json.quantity quantity
  json.created_at invoice_inventory_department_pharmacy.created_at.strftime("%d %b %Y")
  # json.url invoice_inventory_department_pharmacy_url(invoice_inventory_department_pharmacy, format: :json)
  json.items invoice_inventory_department_pharmacy.items do |item|
    json.extract! item, :id, :description, :quantity, :barcode, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :manufacturer, :expiry, :inventory_item_id
  end
end
