# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_tax_collecteds_count
json.iTotalDisplayRecords @total_tax_collecteds_count
json.set! "aaData" do
  currency_symbol = @mis_params[:currency_symbol].to_s

  json.array!(@tax_collecteds) do |tax_collected|
    # Date
    date = tax_collected[:_id].try(:strftime, "%d/%m/%Y")

    # Department Wise Taxes
    opd_tax = tax_collected[:tax_collecteds].map { |tc| tc[:opd_tax].to_f }.sum.round(2)
    ipd_tax = tax_collected[:tax_collecteds].map { |tc| tc[:ipd_tax].to_f }.sum.round(2)
    pharmacy_tax = tax_collected[:tax_collecteds].map { |tc| tc[:pharmacy_tax].to_f }.sum.round(2)
    optical_tax = tax_collected[:tax_collecteds].map { |tc| tc[:optical_tax].to_f }.sum.round(2)

    # Total Tax
    total_tax = (opd_tax + ipd_tax + pharmacy_tax + optical_tax).round(2)

    # Table Data
    json.set! "0", date
    json.set! "1", currency_symbol + opd_tax.to_s
    json.set! "2", currency_symbol + ipd_tax.to_s
    json.set! "3", currency_symbol + pharmacy_tax.to_s
    json.set! "4", currency_symbol + optical_tax.to_s
    json.set! "5", currency_symbol + total_tax.to_s
  end
end
