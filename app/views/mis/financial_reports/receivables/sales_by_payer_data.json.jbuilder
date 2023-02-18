# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_payer_payments_count
json.iTotalDisplayRecords @total_payer_payments_count
json.set! "aaData" do
  currency_symbol = @mis_params[:currency_symbol].to_s

  json.array!(@payer_payments) do |payer_payment|
    # Name
    payer_name = payer_payment[:_id][:contact_name]

    # Pending
    pending_opd_total = currency_symbol + " " + (payer_payment[:payer_payments].map { |pd| pd[:pending_opd_total] }.sum).to_s
    pending_ipd_total = currency_symbol + " " + (payer_payment[:payer_payments].map { |pd| pd[:pending_ipd_total] }.sum).to_s
    pending_total = currency_symbol + " " + (payer_payment[:payer_payments].map { |pd| pd[:pending_total] }.sum).to_s

    # Total
    opd_total = currency_symbol + " " + (payer_payment[:payer_payments].map { |pd| pd[:opd_total] }.sum).to_s
    ipd_total = currency_symbol + " " + (payer_payment[:payer_payments].map { |pd| pd[:ipd_total] }.sum).to_s
    total = currency_symbol + " " + (payer_payment[:payer_payments].map { |pd| pd[:total] }.sum).to_s

    # Table Data
    json.set! "0", payer_name
    json.set! "1", opd_total
    json.set! "2", pending_opd_total
    json.set! "3", ipd_total
    json.set! "4", pending_ipd_total
    json.set! "5", total
    json.set! "6", pending_total
  end
end
