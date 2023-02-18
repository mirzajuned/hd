# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
module Mis::RevenueReports
  class ProcedureBillTypeStatsService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << Mis::Constants::ReportSheetFilters.revenue_filters(@mis_params) if @request == 'xls'

        items = Finance::ItemWiseBillTypeStats.collection.aggregate(statistic_query).to_a || {}
        @items = if @request == 'xls'
            items || []
          else
            items[0][:data] || []
          end

        total_records = if items.present? && @request == 'xls'
            items[0][:total] || 0
          elsif items.present? && items[0][:metadata].present?
            items[0][:metadata][0][:total]
          else
            0
          end

        stats_data
        [@data_array, total_records]
      end
      # EOF call

      private

      def stats_data
        @items.try(:each) do |items_list|
          items_data = items_list[:data]
          items_data.group_by{ |itms| itms['service_type_code_name'] }.each do |service_type_code_name, items|
            generate_table_data(items, service_type_code_name)
          end
        end
      end
      # EOF item_data

      def statistic_query
        Mis::QueryBuilders::ItemWiseBillTypeQueryBuilderService.call(@mis_params, @request)
      end
      # EOF item_query

      def generate_table_data(items, service_type_code_name)
        service_type_code_name = service_type_code_name
        ['free', 'discounted', 'paid'].each do |bill_type|
          b_type = if bill_type == 'discounted'
                    ['paid_discounted']
                   elsif bill_type == 'free'
                    [bill_type, 'free_discounted']
                   else
                    [bill_type]
                   end
          bill_type_items = items.select { |b_types| b_types['bill_type'].in?(b_type) }
          ['male', 'female', 'transgender', 'unspecified'].each do |gender|
            instance_variable_set("@#{gender}_till_fifteen", bill_type_items.map { |d| d['gender_wise_age']["#{gender}_till_fifteen"].to_i }.sum)
            instance_variable_set("@#{gender}_above_fifteen_till_fiftyfive", bill_type_items.map { |d| d['gender_wise_age']["#{gender}_above_fifteen_till_fiftyfive"].to_i }.sum)
            instance_variable_set("@#{gender}_above_fiftyfive", bill_type_items.map { |d| d['gender_wise_age']["#{gender}_above_fiftyfive"].to_i }.sum)
            instance_variable_set("@#{gender}_undefined", bill_type_items.map { |d| d['gender_wise_age']["#{gender}_undefined"].to_i }.sum)

            total = (instance_variable_get("@#{gender}_till_fifteen") + instance_variable_get("@#{gender}_above_fifteen_till_fiftyfive") + instance_variable_get("@#{gender}_above_fiftyfive") + instance_variable_get("@#{gender}_undefined"))
            
            if @request == 'json'
              @data_array << [ service_type_code_name, bill_type.titleize, gender.titleize, instance_variable_get("@#{gender}_till_fifteen") || 0, instance_variable_get("@#{gender}_above_fifteen_till_fiftyfive") || 0, instance_variable_get("@#{gender}_above_fiftyfive") || 0, instance_variable_get("@#{gender}_undefined") || 0, total ]
              service_type_code_name = ''
            else
              @data_array << [ service_type_code_name, bill_type.titleize, gender.titleize, instance_variable_get("@#{gender}_till_fifteen") || 0, instance_variable_get("@#{gender}_above_fifteen_till_fiftyfive") || 0, instance_variable_get("@#{gender}_above_fiftyfive") || 0, instance_variable_get("@#{gender}_undefined") || 0, total ]
            end
          end
        end
      end
      # EOF generate_table_data
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
