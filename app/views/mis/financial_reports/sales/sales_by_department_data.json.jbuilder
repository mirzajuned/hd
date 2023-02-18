# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_financial_overviews_count
json.iTotalDisplayRecords @total_financial_overviews_count
json.set! "aaData" do
  currency_symbol = @mis_params[:currency_symbol].to_s
  financial_overviews_array = ["opd", "ipd", "pharmacy", "optical"]

  json.array!(financial_overviews_array) do |array|
    # Table Data
    json.set! "0", array.to_s.upcase
    json.set! "1", eval("@financial_overviews[:#{array}_invoice_count].to_i")
    json.set! "2", currency_symbol + eval("@financial_overviews[:#{array}_new_patient_amount].to_f + @financial_overviews[:#{array}_old_patient_amount].to_f").to_s
  end
end
