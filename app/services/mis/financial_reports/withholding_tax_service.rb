# 1  Metrics/AbcSize
# 1  Metrics/MethodLength
# --
# 2  Total
module Mis::FinancialReports
  class WithholdingTaxService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['DATE', 'OPD TAX', 'IPD TAX', 'PHARMACY TAX', 'OPTICAL TAX', 'TOTAL TAX'] if @request == 'xls'

        aggregation_query, aggregation_query_count = tax_collected_query

        @tax_collecteds = TaxCollected.collection.aggregate(aggregation_query).to_a || []
        tax_collecteds_count = TaxCollected.collection.aggregate(aggregation_query_count).to_a
        total_records = tax_collecteds_count.count > 0 ? tax_collecteds_count[0][:tax_collected_count] : 0

        tax_collected_data

        [@data_array, total_records]
      end

      private

      def tax_collected_data
        data_currency_symbol = @mis_params[:currency_symbol].to_s

        @tax_collecteds.try(:each) do |tax_collected|
          date = tax_collected[:_id].try(:strftime, '%d/%m/%Y')
          taxes = tax_collected[:tax_collecteds]

          data_opd_tax = taxes.map { |tc| tc[:opd_tax].to_f }.sum.round(2)
          data_ipd_tax = taxes.map { |tc| tc[:ipd_tax].to_f }.sum.round(2)
          data_pharmacy_tax = taxes.map { |tc| tc[:pharmacy_tax].to_f }.sum.round(2)
          data_optical_tax = taxes.map { |tc| tc[:optical_tax].to_f }.sum.round(2)

          data_total_tax = (data_opd_tax + data_ipd_tax + data_pharmacy_tax + data_optical_tax).round(2)

          opd_tax = "#{data_currency_symbol} #{data_opd_tax}"
          ipd_tax = "#{data_currency_symbol} #{data_ipd_tax}"
          pharmacy_tax = "#{data_currency_symbol} #{data_pharmacy_tax}"
          optical_tax = "#{data_currency_symbol} #{data_optical_tax}"
          if @request == 'json' && data_total_tax > 0
            href = @mis_params[:url] + forward_params(date) + back_params
            total_tax = "<a href='#{href}' data-remote='true'>#{data_currency_symbol} #{data_total_tax}</a>"
          else
            total_tax = "#{data_currency_symbol} #{data_total_tax}"
          end

          @data_array << [date, opd_tax, ipd_tax, pharmacy_tax, optical_tax, total_tax]
        end
      end

      def forward_params(date)
        start_date = "&start_date=#{date}"
        end_date = "&end_date=#{date}"
        time_period = '&time_period=Custom'
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        currency_id = "&currency_id=#{@mis_params[:currency_id]}"
        currency_symbol = "&currency_symbol=#{@mis_params[:currency_symbol]}"
        group = '&group=tax'
        title = '&title=tax_summary'

        start_date + end_date + time_period + organisation_id + facility_id + facility_name +
          currency_id + currency_symbol + group + title
      end

      def back_params
        # Back Params
        back_start_date = "&back_start_date=#{@mis_params[:start_date]}"
        back_end_date = "&back_end_date=#{@mis_params[:end_date]}"
        back_time_period = "&back_time_period=#{@mis_params[:time_period]}"
        back_group = "&back_group=#{@mis_params[:group]}"
        back_title = "&back_title=#{@mis_params[:title]}"

        back_start_date + back_end_date + back_time_period + back_group + back_title
      end

      def tax_collected_query
        # PaymentPending Query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { date: 1 } },
          { "$group": { _id: '$date', tax_collecteds: { "$push": '$$ROOT' } } }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # PaymentPending Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$sort": { date: 1 } },
          { "$group": { _id: '$date', tax_collecteds: { "$push": '$$ROOT' } } },
          { "$group": { _id: 'null', tax_collected_count: { "$sum": 1 } } }
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
    end
  end
end
