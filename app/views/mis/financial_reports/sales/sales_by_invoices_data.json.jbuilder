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

    # Advance Payment Breakup
    advance_payment_array = []
    invoice[:advance_payment_breakups].to_a.each do |advance_payment|
      advance_payment_array << "#{advance_payment[:currency_symbol]} #{advance_payment[:amount]} (#{advance_payment[:mode_of_payment]})"
    end

    # Payment Received Breakup
    payment_received_array = []
    invoice[:payment_received_breakups].to_a.each do |payment_received|
      payment_received_array << "#{payment_received[:currency_symbol]} #{payment_received[:amount]} (#{payment_received[:mode_of_payment]})"
    end

    # Empty Payment Array
    empty_payment_array = invoice_currency_symbol + "0.0"

    # Table Data
    json.set! "0", invoice[:_type].to_s.split(":")[-1].upcase
    json.set! "1", invoice[:created_at].strftime("%d/%m/%Y")
    json.set! "2", invoice[:bill_number]
    json.set! "3", patient_fullname
    json.set! "4", (advance_payment_array.join("<br>") if advance_payment_array.count > 0) || empty_payment_array
    json.set! "5", (payment_received_array.join("<br>") if payment_received_array.count > 0) || empty_payment_array
    json.set! "6", invoice_currency_symbol + ((invoice[:payment_pending].to_s if invoice[:payment_pending_breakups].to_a.count > 0) || "0.0")
    json.set! "7", invoice_currency_symbol + invoice[:net_amount].to_s
  end
end
