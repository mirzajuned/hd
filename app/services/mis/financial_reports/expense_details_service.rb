module Mis::FinancialReports
  class ExpenseDetailsService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        if @request == 'xls'
          @data_array << ['DATE', 'DESCRIPTION', 'CATEGORY NAME', 'MERCHANT', 'STATUS',
                          'PAYMENT MODE', 'TAX AMOUNT', 'AMOUNT']
        end

        finance_expenses = Finance::Expense.collection.aggregate(finance_expense_query).to_a[0] || {}

        @finance_expenses = finance_expenses[:finance_expenses]
        total_records = finance_expenses[:finance_expense_count].to_i

        finance_expense_data

        [@data_array, total_records]
      end

      private

      def finance_expense_data(date = '')
        currency_symbol = @mis_params[:currency_symbol].to_s

        @finance_expenses.try(:each) do |finance_expense|
          currency_symbol = finance_expense[:currency_symbol]

          expense_date = finance_expense[:date].to_date.try(:strftime, '%d/%m/%Y')
          expense_date = date == expense_date ? '' : expense_date

          # Table Data
          date = expense_date
          description = finance_expense[:description].titleize
          category_name = finance_expense[:category_name]
          merchant = finance_expense[:merchant]
          status = finance_expense[:status]
          payment_mode = finance_expense[:mop]
          if @request == 'json'
            tax_amount = currency_symbol + finance_expense[:tax_amount]
            amount = currency_symbol + finance_expense[:amount]
          else
            tax_amount = finance_expense[:tax_amount]
            amount = finance_expense[:amount]
          end

          @data_array << [expense_date, description, category_name, merchant, status, payment_mode, tax_amount, amount]
        end
      end

      def finance_expense_query
        # Expense Query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { created_at: -1 } },
          { "$group": { _id: 'null', finance_expenses: { "$push": '$$ROOT' }, finance_expense_count: { "$sum": 1 } } },
          { "$project": project_options }
        ]

        aggregation_query
      end

      def match_options
        # Currency
        match_options = { currency_id: @mis_params[:currency_id] }

        # Facility/Organisation
        if @mis_params[:facility_id].present?
          facility_ids = [@mis_params[:facility_id], BSON::ObjectId(@mis_params[:facility_id])]
          match_options = match_options.merge(facility_id: { "$in": facility_ids })
        else
          organisation_ids = [@mis_params[:organisation_id], BSON::ObjectId(@mis_params[:organisation_id])]
          match_options = match_options.merge(organisation_id: { "$in": organisation_ids })
        end

        # Date/Time
        match_options = match_options.merge(date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                    "$lte": @mis_params[:end_date].end_of_day })

        match_options
      end

      def project_options
        length = @request == 'json' ? @mis_params[:iDisplayLength].to_i : 100000
        { finance_expense_count: 1,
          finance_expenses: {
            "$slice": ['$finance_expenses', @mis_params[:iDisplayStart].to_i, length]
          } }
      end
    end
  end
end
