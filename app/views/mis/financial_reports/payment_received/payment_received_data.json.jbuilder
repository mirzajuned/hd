# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_payment_receiveds_count
json.iTotalDisplayRecords @total_payment_receiveds_count
json.set! "aaData" do
  date = ""
  json.array!(@payment_receiveds) do |payment_received|
    # Received Date
    received_date = (payment_received[:date].try(:strftime, "%d/%m/%Y") if date != payment_received[:date]) || ""
    date = payment_received[:date]

    # Invoice Type
    invoice_type = payment_received[:invoice_type].to_s.upcase

    # Received From
    received_from = eval("@#{payment_received[:received_from_type].downcase}_fields").to_a.find { |rf| rf if rf[:id] == payment_received[:received_from].to_s }
    if received_from.present?
      received_from = received_from[:fullname] || received_from[:display_name]
    end

    # Mode of Payment
    mode_of_payment = payment_received[:mode_of_payment].to_s

    # Amount Received
    amount_received = payment_received[:currency_symbol].to_s + payment_received[:amount].to_s

    # Table Data
    json.set! "0", received_date
    json.set! "1", invoice_type
    json.set! "2", received_from
    json.set! "3", mode_of_payment
    json.set! "4", amount_received
  end
end
