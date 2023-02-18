module Mis::FinancialReports
  class SalesByModeService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['DATE', 'CASH', 'CARD', 'CHEQUE', 'TRANSFER', 'OTHERS'] if @request == 'xls'

        aggregation_query, aggregation_query_count = payment_mode_query

        @payment_modes = Analytics::Financial::PaymentMode.collection.aggregate(aggregation_query).to_a || []
        payment_modes_count = Analytics::Financial::PaymentMode.collection.aggregate(aggregation_query_count).to_a
        total_records = (payment_modes_count[0][:payment_mode_count] if payment_modes_count.count > 0) || 0

        payment_mode_data

        [@data_array, total_records]
      end

      private

      def payment_mode_data
        data_currency_symbol = @mis_params[:currency_symbol].to_s

        @payment_modes.each do |payment_mode|
          payment_date = payment_mode[:_id].strftime('%d/%m/%Y')

          cash = set_url(payment_mode[:cash], data_currency_symbol, payment_date)
          card = set_url(payment_mode[:card], data_currency_symbol, payment_date)
          cheque = set_url(payment_mode[:cheque], data_currency_symbol, payment_date)
          online_transfer = set_url(payment_mode[:online_transfer], data_currency_symbol, payment_date)
          others = set_url(payment_mode[:others], data_currency_symbol, payment_date)

          @data_array << [payment_date, cash, card, cheque, online_transfer, others]
        end
      end

      def set_url(amount, currency, payment_date)
        href = @mis_params[:url] + forward_params(payment_date) + back_params
        if @request == 'json' && amount > 0
          "<a href='#{href}&payment_mode=cash' data-remote='true'>#{currency} #{amount}</a>"
        else
          "#{currency} #{amount}"
        end
      end

      def forward_params(payment_date)
        start_date = "&start_date=#{payment_date}"
        end_date = "&end_date=#{payment_date}"
        time_period = '&time_period=Custom'
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        currency_id = "&currency_id=#{@mis_params[:currency_id]}"
        currency_symbol = "&currency_symbol=#{@mis_params[:currency_symbol]}"
        group = '&group=sales'
        title = '&title=mode_by_payer'

        start_date + end_date + time_period + organisation_id + facility_id + facility_name +
          currency_id + currency_symbol + group + title
      end

      def back_params
        back_start_date = "&back_start_date=#{@mis_params[:start_date]}"
        back_end_date = "&back_end_date=#{@mis_params[:end_date]}"
        back_time_period = "&back_time_period=#{@mis_params[:time_period]}"
        back_group = "&back_group=#{@mis_params[:group]}"
        back_title = "&back_title=#{@mis_params[:title]}"

        back_start_date + back_end_date + back_time_period + back_group + back_title
      end

      def payment_mode_query
        # PaymentMode Query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { date: 1 } },
          { "$group": group_options }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # PaymentMode Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$sort": { date: 1 } },
          { "$group": group_options },
          { "$group": { _id: 'null', payment_mode_count: { "$sum": 1 } } }
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
        { _id: '$date', cash: { "$sum": '$cash' }, card: { "$sum": '$card' }, cheque: { "$sum": '$cheque' },
          online_transfer: { "$sum": '$online_transfer' }, others: { "$sum": '$others' } }
      end
    end
  end
end
