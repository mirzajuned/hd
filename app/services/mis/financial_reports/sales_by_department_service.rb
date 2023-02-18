# 3   Metrics/AbcSize
# 3   Metrics/CyclomaticComplexity
# 3   Metrics/MethodLength
# 1   Metrics/ClassLength
# 1   Metrics/PerceivedComplexity
# --
# 11  Total
module Mis::FinancialReports
  class SalesByDepartmentService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        if @mis_params[:group] == 'sales'
          @data_array << ['DEPARTMENT NAME', 'INVOICE COUNT', 'INVOICE AMOUNT'] if @request == 'xls'

          financial_overview = Analytics::Financial::FinancialOverview
          @financial_overviews = financial_overview.collection.aggregate(financial_overview_query).to_a[0] || {}
          total_records = 4

          financial_overview_data
        elsif @mis_params[:group] == 'receivables'
          @data_array << ['DEPARTMENT', 'COUNT', 'TOTAL PENDING'] if @request == 'xls'

          aggregation_query, aggregation_query_count = payment_pending_query

          @payment_pendings = Invoice::PaymentPending.collection.aggregate(aggregation_query).to_a || []
          payment_pendings_count = Invoice::PaymentPending.collection.aggregate(aggregation_query_count).to_a
          total_records = (payment_pendings_count[0][:payment_pending_count] if payment_pendings_count.count > 0) || 0

          payment_pending_data
        end

        [@data_array, total_records]
      end

      private

      def financial_overview_data
        data_currency_symbol = @mis_params[:currency_symbol].to_s
        financial_overviews_array = ['opd', 'ipd', 'pharmacy', 'optical']

        financial_overviews_array.try(:each) do |array|
          href = @mis_params[:url] + financial_forward_params(array) + back_params

          department = array.to_s.upcase

          count = @financial_overviews["#{array}_invoice_count".to_sym].to_i
          # if @request == 'json' && ['OPD', 'IPD', 'InventoryInvoice'].include?(department) && count > 0
          count = "<a href='#{href}' data-remote='true'>" + count.to_s + '</a>' if @request == 'json' && count > 0

          new_patient_amount = @financial_overviews["#{array}_new_patient_amount".to_sym].to_f
          old_patient_amount = @financial_overviews["#{array}_old_patient_amount".to_sym].to_f
          amount = new_patient_amount + old_patient_amount

          currency_amount = data_currency_symbol + ' ' + amount.to_s
          if amount > 0 # && @request == 'json' && ['OPD', 'IPD', 'InventoryInvoice'].include?(department)
            currency_amount = "<a href='#{href}' data-remote='true'>#{currency_amount}</a>"
          end

          @data_array << [department, count, currency_amount]
        end
      end

      def financial_forward_params(array)
        start_date = "&start_date=#{@mis_params[:start_date]}"
        end_date = "&end_date=#{@mis_params[:end_date]}"
        time_period = "&time_period=#{@mis_params[:time_period]}"
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        currency_id = "&currency_id=#{@mis_params[:currency_id]}"
        currency_symbol = "&currency_symbol=#{@mis_params[:currency_symbol]}"
        group = '&group=sales'
        title = '&title=sales_by_invoices'
        invoice_type = "&invoice_type=#{array.to_s.downcase}"

        start_date + end_date + time_period + organisation_id + facility_id + facility_name +
          currency_id + currency_symbol + group + title + invoice_type
      end

      def financial_overview_query
        # FinancialOverview Query
        aggregation_query = [
          { "$match": match_options },
          { "$group": financial_group_options }
        ]

        aggregation_query
      end

      def financial_group_options
        {
          _id: 'null',
          opd_new_patient_amount: { "$sum": '$opd_new_patient_amount' },
          opd_old_patient_amount: { '$sum' => '$opd_old_patient_amount' },
          opd_invoice_count: { '$sum' => '$opd_invoice_count' },
          ipd_new_patient_amount: { "$sum": '$ipd_new_patient_amount' },
          ipd_old_patient_amount: { '$sum' => '$ipd_old_patient_amount' },
          ipd_invoice_count: { '$sum' => '$ipd_invoice_count' },
          pharmacy_new_patient_amount: { "$sum": '$pharmacy_new_patient_amount' },
          pharmacy_old_patient_amount: { '$sum' => '$pharmacy_old_patient_amount' },
          pharmacy_invoice_count: { '$sum' => '$pharmacy_invoice_count' },
          optical_new_patient_amount: { "$sum": '$optical_new_patient_amount' },
          optical_old_patient_amount: { '$sum' => '$optical_old_patient_amount' },
          optical_invoice_count: { '$sum' => '$optical_invoice_count' }
        }
      end

      def payment_pending_data
        data_currency_symbol = @mis_params[:currency_symbol].to_s

        @payment_pendings.try(:each) do |payment_pending|
          department = payment_pending[:_id].to_s.upcase

          url = @mis_params[:url]

          href = url + pending_forward_params(department) + back_params

          count = payment_pending[:payment_pending_count]
          if @request == 'json' && ['OPD', 'IPD'].include?(department) && count > 0
            count = "<a href='#{href}' data-remote='true'>" + count.to_s + '</a>'
          end

          amount = payment_pending[:payment_pending_amount]
          currency_amount = data_currency_symbol + ' ' + amount.to_s
          if @request == 'json' && ['OPD', 'IPD'].include?(department) && amount > 0
            currency_amount = "<a href='#{href}' data-remote='true'>#{currency_amount}</a>"
          end

          @data_array << [department, count, currency_amount]
        end
      end

      def pending_forward_params(department)
        # Forward Params
        start_date = "&start_date=#{@mis_params[:start_date]}"
        end_date = "&end_date=#{@mis_params[:end_date]}"
        time_period = "&time_period=#{@mis_params[:time_period]}"
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        currency_id = "&currency_id=#{@mis_params[:currency_id]}"
        currency_symbol = "&currency_symbol=#{@mis_params[:currency_symbol]}"
        group = '&group=receivables'
        title = '&title=sales_by_invoices'
        invoice_type = "&invoice_type=#{department.to_s.downcase}"

        start_date + end_date + time_period + organisation_id + facility_id + facility_name +
          currency_id + currency_symbol + group + title + invoice_type
      end

      def back_params
        back_start_date = "&back_start_date=#{@mis_params[:start_date]}"
        back_end_date = "&back_end_date=#{@mis_params[:end_date]}"
        back_time_period = "&back_time_period=#{@mis_params[:time_period]}"
        back_group = "&back_group=#{@mis_params[:group]}"
        back_title = "&back_title=#{@mis_params[:title]}"

        back_start_date + back_end_date + back_time_period + back_group + back_title
      end

      def payment_pending_query
        # PaymentPending Query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { date: 1 } },
          { "$group": pending_group_options }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # PaymentPending Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$sort": { date: 1 } },
          { "$group": pending_group_options },
          { "$group": { _id: 'null', payment_pending_count: { "$sum": 1 } } }
        ]

        [aggregation_query, aggregation_query_count]
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
        match_options = match_options.merge(
          start_date: { "$gte": @mis_params[:start_date].to_date },
          end_date: { "$lte": @mis_params[:end_date].to_date }
        )

        match_options
      end

      def pending_group_options
        { _id: '$invoice_type',
          payment_pending_amount: { "$sum": '$amount' },
          payment_pending_count: { "$sum": 1 } }
      end
    end
  end
end
