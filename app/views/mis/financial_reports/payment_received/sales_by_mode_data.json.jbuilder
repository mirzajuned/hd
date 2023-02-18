# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_payment_modes_count
json.iTotalDisplayRecords @total_payment_modes_count
json.set! "aaData" do
  currency_symbol = @mis_params[:currency_symbol].to_s

  json.array!(@payment_modes) do |payment_mode|
    # Date
    payment_date = payment_mode[:_id].strftime("%d/%m/%Y")

    # Payment Modes
    cash = currency_symbol + " " + (payment_mode[:payment_modes].map { |pm| pm[:cash] }.sum).to_s
    card = currency_symbol + " " + (payment_mode[:payment_modes].map { |pm| pm[:card] }.sum).to_s
    cheque = currency_symbol + " " + (payment_mode[:payment_modes].map { |pm| pm[:cheque] }.sum).to_s
    online_transfer = currency_symbol + " " + (payment_mode[:payment_modes].map { |pm| pm[:online_transfer] }.sum).to_s
    others = currency_symbol + " " + (payment_mode[:payment_modes].map { |pm| pm[:others] }.sum).to_s

    # Table Data
    json.set! "0", payment_date
    json.set! "1", cash
    json.set! "2", card
    json.set! "3", cheque
    json.set! "4", online_transfer
    json.set! "5", others
  end
end
