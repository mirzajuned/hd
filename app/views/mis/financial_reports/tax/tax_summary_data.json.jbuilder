# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_tax_collecteds_count
json.iTotalDisplayRecords @total_tax_collecteds_count
json.set! "aaData" do
  currency_symbol = @mis_params[:currency_symbol].to_s

  json.array!(@tax_collecteds) do |tax_collected|
    # Date
    date = tax_collected[:_id].try(:strftime, "%d/%m/%Y")

    # Tax Breakup
    types = ["CGST", "SGST", "IGST", "UTGST", "Cess", "Others"]
    cgst = tax_collected[:tax_collecteds].map { |tc| tc[:tax_details].select { |td| td if td[:type] == "CGST" }.pluck(:total) }.flatten.sum
    sgst = tax_collected[:tax_collecteds].map { |tc| tc[:tax_details].select { |td| td if td[:type] == "SGST" }.pluck(:total) }.flatten.sum
    igst = tax_collected[:tax_collecteds].map { |tc| tc[:tax_details].select { |td| td if td[:type] == "IGST" }.pluck(:total) }.flatten.sum
    utgst = tax_collected[:tax_collecteds].map { |tc| tc[:tax_details].select { |td| td if td[:type] == "UTGST" }.pluck(:total) }.flatten.sum
    cess = tax_collected[:tax_collecteds].map { |tc| tc[:tax_details].select { |td| td if td[:type] == "Cess" }.pluck(:total) }.flatten.sum
    others = tax_collected[:tax_collecteds].map { |tc| tc[:tax_details].select { |td| td if td[:type] == "Others" }.pluck(:total) }.flatten.sum

    # Table Data
    json.set! "0", date
    json.set! "1", currency_symbol + " " + cgst.to_s
    json.set! "2", currency_symbol + " " + sgst.to_s
    json.set! "3", currency_symbol + " " + igst.to_s
    json.set! "4", currency_symbol + " " + utgst.to_s
    json.set! "5", currency_symbol + " " + cess.to_s
    json.set! "6", currency_symbol + " " + others.to_s
  end
end
