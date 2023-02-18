json.array!(@invoice_inventory_departments) do |invoice_inventory_department|
  json.extract! invoice_inventory_department, :id, :recipient, :discount
  json.created_at invoice_inventory_department.created_at.strftime("%d %b %Y")
  # quantity = invoice_inventory_department.items.pluck("quantity").inject(&:+)
  json.quantity invoice_inventory_department.items.pluck("quantity").inject(&:+)

  json.items invoice_inventory_department.items do |item|
    json.extract! item, :description, :quantity
  end
  # json.url invoice_inventory_department_url(invoice_inventory_department, format: :json)
end
