# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_advance_payments_count
json.iTotalDisplayRecords @total_advance_payments_count
json.set! "aaData" do
  date = ""
  json.array!(@advance_payments) do |advance_payment|
    # Patient Details
    patient_field = @patient_fields.to_a.find { |patient| patient[:id] == advance_payment[:patient_id].to_s }
    patient_fullname = patient_field[:fullname] if patient_field.present?

    # Currency
    advance_payment_currency_symbol = advance_payment[:currency_symbol].to_s

    # Table Data
    json.set! "0", advance_payment[:type]
    json.set! "1", advance_payment[:payment_date].strftime("%d/%m/%Y")
    json.set! "2", advance_payment[:advance_display_id]
    json.set! "3", patient_fullname
    json.set! "4", advance_payment_currency_symbol + advance_payment[:amount].to_f.to_s
    json.set! "5", advance_payment_currency_symbol + advance_payment[:amount_remaining].to_f.to_s
  end
end
