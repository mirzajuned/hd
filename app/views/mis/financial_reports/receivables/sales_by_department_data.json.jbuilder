# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_payment_pendings_count
json.iTotalDisplayRecords @total_payment_pendings_count
json.set! "aaData" do
  currency_symbol = @mis_params[:currency_symbol].to_s

  json.array!(@payment_pendings) do |payment_pending|
    # Table Data
    json.set! "0", payment_pending[:_id].to_s.upcase
    json.set! "1", payment_pending[:payment_pending_count]
    json.set! "2", currency_symbol + payment_pending[:payment_pending_amount].to_s
  end
end
