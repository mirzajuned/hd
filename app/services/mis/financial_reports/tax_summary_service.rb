module Mis::FinancialReports
  class TaxSummaryService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['DATE', 'CGST', 'SGST', 'IGST', 'UTGST', 'CESS', 'OTHERS'] if @request == 'xls'

        aggregation_query, aggregation_query_count = tax_collected_query

        @tax_collecteds = TaxCollected.collection.aggregate(aggregation_query).to_a || []
        tax_collecteds_count = TaxCollected.collection.aggregate(aggregation_query_count).to_a
        total_records = (tax_collecteds_count[0][:tax_collected_count] if tax_collecteds_count.count > 0) || 0

        tax_collected_data

        [@data_array, total_records]
      end

      private

      def tax_collected_data
        currency_symbol = @mis_params[:currency_symbol].to_s

        @tax_collecteds.try(:each) do |tax_collected|
          date = tax_collected[:_id].try(:strftime, '%d/%m/%Y')
          taxes = tax_collected[:tax_collecteds]

          cgst = set_data(taxes, currency_symbol, 'CGST')
          sgst = set_data(taxes, currency_symbol, 'SGST')
          igst = set_data(taxes, currency_symbol, 'IGST')
          utgst = set_data(taxes, currency_symbol, 'UTGST')
          cess = set_data(taxes, currency_symbol, 'Cess')
          others = set_data(taxes, currency_symbol, 'Others')

          @data_array << [date, cgst, sgst, igst, utgst, cess, others]
        end
      end

      def set_data(taxes, currency_symbol, tax_type)
        amount = taxes.map { |tc| tc[:tax_details].select { |td| td if td[:type] == tax_type }.pluck(:total) }.flatten

        if @request == 'json'
          text = "#{currency_symbol} #{amount.sum}"
        else
          text = amount.sum
        end
        text
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

        # Date/Time
        match_options = match_options.merge(date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                    "$lte": @mis_params[:end_date].end_of_day })

        match_options
      end
    end
  end
end
