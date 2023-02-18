json.array!(@invoices) do |invoice|
  json.extract! invoice, :id, :_type, :total
  json.created_at invoice.created_at.strftime('%d-%m-%Y')
  json.items invoice.items
  json.quantity invoice.items.pluck('quantity').sum
  if invoice._type == "Invoice::Inventories::DepartmentInvoice"
    json.current_department_id = invoice.current_department_id
  end
end
