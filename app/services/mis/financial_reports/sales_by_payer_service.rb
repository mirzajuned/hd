# 2  Metrics/MethodLength
# 1  Metrics/CyclomaticComplexity
# 1  Metrics/PerceivedComplexity
# --
# 4  Total
module Mis::FinancialReports
  class SalesByPayerService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        if @request == 'xls'
          if @mis_params[:group] == 'sales'
            @data_array << ['NAME', 'OPD RECEIVED', 'IPD RECEIVED', 'TOTAL RECEIVED', 'OPD PENDING',
                            'IPD PENDING', 'TOTAL PENDING', 'OPD TOTAL', 'IPD TOTAL', 'TOTAL']
          elsif @mis_params[:group] == 'receivables'
            @data_array << ['NAME', 'OPD TOTAL', 'OPD PENDING', 'IPD TOTAL', 'IPD PENDING', 'TOTAL', 'TOTAL PENDING']
          elsif @mis_params[:group] == 'payment_received'
            @data_array << ['NAME', 'OPD TOTAL', 'OPD RECEIVED', 'IPD TOTAL', 'IPD RECEIVED', 'TOTAL', 'TOTAL RECEIVED']
          end
        end

        aggregation_query, aggregation_query_count = payer_payment_query

        @payer_payments = Analytics::Financial::PayerPayment.collection.aggregate(aggregation_query).to_a || []
        payer_payments_count = Analytics::Financial::PayerPayment.collection.aggregate(aggregation_query_count).to_a
        total_records = (payer_payments_count[0][:payer_payment_count] if payer_payments_count.count > 0) || 0

        payer_payment_data

        [@data_array, total_records]
      end

      private

      def payer_payment_data
        currency_symbol = @mis_params[:currency_symbol].to_s

        @payer_payments.try(:each) do |payer_payment|
          payer_name = payer_payment[:_id][:contact_name]

          if @request == 'json'
            received_opd = "#{currency_symbol} #{payer_payment[:received_opd_total]}"
            received_ipd = "#{currency_symbol} #{payer_payment[:received_ipd_total]}"
            received_total = "#{currency_symbol} #{payer_payment[:received_total]}"

            pending_opd = "#{currency_symbol} #{payer_payment[:pending_opd_total]}"
            pending_ipd = "#{currency_symbol} #{payer_payment[:pending_ipd_total]}"
            pending_total = "#{currency_symbol} #{payer_payment[:pending_total]}"

            opd_total = "#{currency_symbol} #{payer_payment[:opd_total]}"
            ipd_total = "#{currency_symbol} #{payer_payment[:ipd_total]}"
            total = "#{currency_symbol} #{payer_payment[:total]}"
          else
            received_opd = payer_payment[:received_opd_total]
            received_ipd = payer_payment[:received_ipd_total]
            received_total = payer_payment[:received_total]

            pending_opd = payer_payment[:pending_opd_total]
            pending_ipd = payer_payment[:pending_ipd_total]
            pending_total = payer_payment[:pending_total]

            opd_total = payer_payment[:opd_total]
            ipd_total = payer_payment[:ipd_total]
            total = payer_payment[:total]
          end

          if @mis_params[:group] == 'sales'
            @data_array << [payer_name, received_opd, received_ipd, received_total, pending_opd,
                            pending_ipd, pending_total, opd_total, ipd_total, total]
          elsif @mis_params[:group] == 'receivables'
            @data_array << [payer_name, opd_total, pending_opd, ipd_total, pending_ipd, total, pending_total]
          elsif @mis_params[:group] == 'payment_received'
            @data_array << [payer_name, opd_total, received_opd, ipd_total, received_ipd, total, received_total]
          end
        end
      end

      def payer_payment_query
        # PayerPayment Query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { date: -1 } },
          { "$group": group_options }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # PayerPayment Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$sort": { date: -1 } },
          { "$group": group_options },
          { "$group": { _id: 'null', payer_payment_count: { "$sum": 1 } } }
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
        match_options = match_options.merge(date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                    "$lte": @mis_params[:end_date].end_of_day })

        match_options
      end

      def group_options
        {
          _id: { "payer_master_id": '$payer_master_id', "contact_name": '$contact_name' },
          received_opd_total: { "$sum": '$received_opd_total' }, received_ipd_total: { "$sum": '$received_ipd_total' },
          pending_opd_total: { "$sum": '$pending_opd_total' }, pending_ipd_total: { "$sum": '$pending_ipd_total' },
          received_total: { "$sum": '$received_total' }, pending_total: { "$sum": '$pending_total' },
          opd_total: { "$sum": '$opd_total' }, ipd_total: { "$sum": '$ipd_total' }, total: { "$sum": '$total' }
        }
      end
    end
  end
end
