# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_invoices_count
json.iTotalDisplayRecords @total_invoices_count
json.set! "aaData" do
  json.array!(@invoices) do |invoice|
    # Patient Details
    patient_field = @patient_fields.to_a.find { |patient| patient[:id] == invoice[:patient_id].to_s }
    patient_fullname = patient_field[:fullname] if patient_field.present?

    # Currency
    invoice_currency_symbol = invoice[:currency_symbol].to_s

    # Table Data
    json.set! "0", invoice[:_type].to_s.split(":")[-1].upcase
    json.set! "1", invoice[:created_at].strftime("%d/%m/%Y")
    json.set! "2", invoice[:bill_number]
    json.set! "3", patient_fullname
    json.set! "4", invoice_currency_symbol + invoice[:net_amount].to_s
    json.set! "5", invoice_currency_symbol + ((invoice[:payment_received].to_s if invoice[:payment_received_breakups].to_a.count > 0) || "0.0")
  end
end
