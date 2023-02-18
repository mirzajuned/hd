json.array!(@invoices) do |invoice|
  json.extract! invoice, :id, :total, :department_id, :recipient
  json.created_at invoice.created_at.strftime('%d-%m-%Y')
  json.items invoice.items
  json.quantity invoice.items.pluck('quantity').sum
end
