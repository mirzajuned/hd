# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_payer_payments_count
json.iTotalDisplayRecords @total_payer_payments_count
json.set! "aaData" do
  currency_symbol = @mis_params[:currency_symbol].to_s

  json.array!(@payer_payments) do |payer_payment|
    # Name
    payer_name = payer_payment[:_id][:contact_name]

    # Received
    received_opd_total = currency_symbol + " " + (payer_payment[:payer_payments].map { |pd| pd[:received_opd_total] }.sum).to_s
    received_ipd_total = currency_symbol + " " + (payer_payment[:payer_payments].map { |pd| pd[:received_ipd_total] }.sum).to_s
    received_total = currency_symbol + " " + (payer_payment[:payer_payments].map { |pd| pd[:received_total] }.sum).to_s

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
    json.set! "1", received_opd_total
    json.set! "2", received_ipd_total
    json.set! "3", received_total
    json.set! "4", pending_opd_total
    json.set! "5", pending_ipd_total
    json.set! "6", pending_total
    json.set! "7", opd_total
    json.set! "8", ipd_total
    json.set! "9", total
  end
end
