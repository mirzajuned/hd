# Not in Use
json.sEcho params[:sEcho]
json.iTotalRecords @total_finance_expenses_count
json.iTotalDisplayRecords @total_finance_expenses_count
json.set! "aaData" do
  date = ""
  currency_symbol = @mis_params[:currency_symbol].to_s

  json.array!(@finance_expenses) do |finance_expense|
    # Expense Date
    expense_date = (finance_expense[:date].to_date.try(:strftime, "%d/%m/%Y") if date != expense_date) || ""

    # Currency
    currency_symbol = finance_expense[:currency_symbol]

    # Table Data
    json.set! "0", expense_date
    json.set! "1", finance_expense[:description].titleize
    json.set! "2", finance_expense[:category_name]
    json.set! "3", finance_expense[:merchant]
    json.set! "4", finance_expense[:status]
    json.set! "5", finance_expense[:mop]
    json.set! "6", currency_symbol + finance_expense[:tax_amount]
    json.set! "7", currency_symbol + finance_expense[:amount]
  end
end
