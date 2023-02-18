json.array!(@invoice_inventory_department_opticals) do |invoice_inventory_department_optical|
  json.extract! invoice_inventory_department_optical, :id, :recipient, :recipient_mobile, :recipient_email, :bill_number, :discount, :notify, :notify_type, :notified, :delivery_date, :sms, :email, :called
  quantity = invoice_inventory_department_optical.items.pluck("quantity").inject(&:+)
  json.quantity quantity
  json.created_at invoice_inventory_department_optical.created_at.strftime("%d %b %Y")
  # json.url invoice_inventory_department_optical_url(invoice_inventory_department_optical, format: :json)
  json.items invoice_inventory_department_optical.items do |item|
    json.extract! item, :id, :description, :quantity, :barcode, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :manufacturer, :expiry, :inventory_item_id, :vat, :service
  end
end
