# 2  Metrics/MethodLength
# 1  Metrics/AbcSize
# 1  Metrics/ClassLength
# --
# 4  Total
module Mis::FinancialReports
  class AgingSummaryService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        if @request == 'xls'
          @data_array << ['CONTACT', 'CURRENT', '1-15 DAYS', '16-30 DAYS',
                          '31-45 DAYS', '46-60 DAYS', '> 60 DAYS', 'TOTAL']
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
        data_currency_symbol = @mis_params[:currency_symbol].to_s
        date_today = Date.current

        @payer_payments.try(:each) do |payer_payment|
          grouped_by_days = payer_payment[:payer_payments].group_by { |v| (date_today - v[:date].to_date).to_i }

          contact_name = payer_payment[:_id][:contact_name]

          data_current = set_data(grouped_by_days, [0])
          data_o_f_days = set_data(grouped_by_days, [*1..15])
          data_s_t_days = set_data(grouped_by_days, [*16..30])
          data_t_f_days = set_data(grouped_by_days, [*31..45])
          data_f_s_days = set_data(grouped_by_days, [*46..60])
          data_a_s_days = set_data(grouped_by_days, [*60..1000])

          data_total = data_current + data_o_f_days + data_s_t_days + data_t_f_days + data_f_s_days + data_a_s_days

          current = set_url(payer_payment, date_today, date_today, data_currency_symbol, data_current)
          o_f_days = set_url(payer_payment, date_today - 15, date_today - 1, data_currency_symbol, data_o_f_days)
          s_t_days = set_url(payer_payment, date_today - 30, date_today - 16, data_currency_symbol, data_s_t_days)
          t_f_days = set_url(payer_payment, date_today - 45, date_today - 31, data_currency_symbol, data_t_f_days)
          f_s_days = set_url(payer_payment, date_today - 60, date_today - 46, data_currency_symbol, data_f_s_days)
          a_s_days = set_url(payer_payment, date_today - 3.years, date_today - 61, data_currency_symbol, data_a_s_days)
          total = set_url(payer_payment, date_today - 3.years, date_today, data_currency_symbol, data_total)

          @data_array << [contact_name, current, o_f_days, s_t_days, t_f_days, f_s_days, a_s_days, total]
        end
      end

      def set_data(grouped_by_days, range)
        grouped_by_days.map { |k, v| v if range.include?(k) }.delete_if(&:nil?)
                       .flatten.pluck(:pending_total).sum.to_f.round(2)
      end

      def set_url(payer_payment, start_date, end_date, currency, total)
        href = @mis_params[:url] + forward_params(payer_payment) + back_params
        if @request == 'json' && total > 0
          "<a href='#{href}&start_date=#{start_date}&end_date=#{end_date}' data-remote='true'>#{currency}#{total}</a>"
        else
          # currency + total.to_s
          total.to_s
        end
      end

      def forward_params(payer_payment)
        time_period = '&time_period=Custom'
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        currency_id = "&currency_id=#{@mis_params[:currency_id]}"
        currency_symbol = "&currency_symbol=#{@mis_params[:currency_symbol]}"
        group = '&group=receivables'
        title = '&title=sales_by_invoices'
        invoice_type = '&invoice_type=all'
        payer_id = "&payer_id=#{payer_payment[:_id][:payer_master_id]}"

        forward_params = time_period + organisation_id + facility_id + facility_name + currency_id + currency_symbol
        forward_params += group + title + invoice_type + payer_id

        forward_params
      end

      def back_params
        back_start_date = "&back_start_date=#{@mis_params[:start_date]}"
        back_end_date = "&back_end_date=#{@mis_params[:end_date]}"
        back_time_period = "&back_time_period=#{@mis_params[:time_period]}"
        back_group = "&back_group=#{@mis_params[:group]}"
        back_title = "&back_title=#{@mis_params[:title]}"
        back_skip = "&back_iDisplayStart=#{@mis_params[:iDisplayStart]}"
        back_length = "&back_iDisplayLength=#{@mis_params[:iDisplayLength]}"

        back_start_date + back_end_date + back_time_period + back_group + back_title + back_skip + back_length
      end

      def payer_payment_query
        # PayerPayment Query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { date: -1 } },
          { "$group": { _id: { "payer_master_id": '$payer_master_id', "contact_name": '$contact_name' },
                        payer_payments: { "$push": '$$ROOT' } } }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # PayerPayment Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$sort": { date: -1 } },
          { "$group": { _id: { "payer_master_id": '$payer_master_id', "contact_name": '$contact_name' },
                        payer_payments: { "$push": '$$ROOT' } } },
          { "$group": { _id: 'null', payer_payment_count: { "$sum": 1 } } }
        ]

        [aggregation_query, aggregation_query_count]
      end

      def match_options
        match_options = {}

        # Currency
        match_options = match_options.merge(currency_id: @mis_params[:currency_id])

        # Facility/Organisation
        if @mis_params[:facility_id].present?
          facility_ids = [@mis_params[:facility_id], BSON::ObjectId(@mis_params[:facility_id])]
          match_options = match_options.merge(facility_id: { "$in": facility_ids })
        else
          organisation_ids = [@mis_params[:organisation_id], BSON::ObjectId(@mis_params[:organisation_id])]
          match_options = match_options.merge(organisation_id: { "$in": organisation_ids })
        end

        # PendingTotal
        match_options = match_options.merge(pending_total: { "$gte": 0 })

        match_options
      end
    end
  end
end
