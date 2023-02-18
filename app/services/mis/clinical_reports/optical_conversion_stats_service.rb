# rubocop:disable all
module Mis::ClinicalReports
  class OpticalConversionStatsService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << Mis::Constants::ReportSheetFilters.revenue_filters(@mis_params) if @request == 'xlsx'

        prescriptions = Inventory::StoreConversionStatistic.collection.aggregate(statistic_query).to_a || {}
        @prescriptions = if @request == 'xlsx'
            prescriptions || []
          else
            prescriptions[0][:data] || []
          end

        total_records = if prescriptions.present? && @request == 'xlsx'
            prescriptions[0][:total] || 0
          elsif prescriptions.present? && prescriptions[0][:metadata].present?
            prescriptions[0][:metadata][0][:total]
          else
            0
          end

        prescriptions_data
        [@data_array, total_records]
      end
      # EOF call

      private

      def prescriptions_data
        @prescriptions.try(:each) do |prescription|
          advised_date = prescription[:_id].to_s(:hg_date_format)
          presciptions = prescription['data']

          presciptions.each do |prscription|
            @data_array << generate_table_data(prscription, advised_date)
            advised_date = ''
          end
        end
      end
      # EOF presciption_data

      def statistic_query
        Mis::QueryBuilderService.call(@mis_params, @request)
      end
      # EOF presciption_query

      def generate_table_data(presciption, advised_date)
        forward_params_with_store = forward_params(presciption['facility_id'], presciption['facility_name'], presciption['advised_on'], presciption['store_id'], presciption['store_name'])
        forward_params_converted = forward_params(presciption['facility_id'], presciption['facility_name'], presciption['advised_on'], presciption['store_id'], presciption['store_name'], 'converted')

        href_with_store = @mis_params[:url] + forward_params_with_store + back_params(presciption['store_id'], presciption['store_name'])
        href_with_conversion = @mis_params[:url] + forward_params_converted + back_params(presciption['store_id'], presciption['store_name'])

        total_advised = presciption['total_advised']
        total_converted = (presciption['total_converted'].present?) ? presciption['total_converted'] : '-'

        # conversion_in_days = (presciption['conversion_in_days'].present?) ? presciption['conversion_in_days'].round(2) : '-'
        # conversion_in_percentage = (presciption['conversion_in_percentage'].present?) ? presciption['conversion_in_percentage'].round(2) : '-'
        conversion_in_percentage = '-'
        conversion_in_percentage = ((total_converted * 100) / total_advised).round(2) if total_converted != '-' && total_advised > 0

        if @request == 'json'
          total_advised = "<a href='#{href_with_store}' "\
          "data-remote='true'>#{total_advised}</a>"
          total_converted = "<a href='#{href_with_conversion}' "\
          "data-remote='true'>#{total_converted}</a>" unless total_converted == '-'
        end

        t_data = [
          advised_date, total_advised, total_converted, conversion_in_percentage
        ]

        t_data
      end
      # EOF generate_table_data

      def forward_params(facility_id, facility_name, advised_date, store_id, store_name, is_converted = nil)
        params_str = "&start_date=#{advised_date}"
        params_str += "&end_date=#{advised_date}"
        params_str += "&time_period=#{@mis_params[:time_period]}"
        params_str += "&organisation_id=#{@mis_params[:organisation_id]}"
        params_str += "&facility_id=#{facility_id}"
        params_str += "&facility_name=#{facility_name.to_s.gsub(/\'/,'`')}"
        params_str += "&optical_store_id=#{store_id}"
        params_str += "&optical_store_name=#{store_name}"
        params_str += "&conversion_status=#{is_converted}" if is_converted.present?
        params_str += '&group=conversion'
        params_str += '&title=optical_conversion_summary'
        params_str += '&has_params=true'

        params_str
      end
      # EOF forward_params

      def back_params(store_id, store_name)
        back_params_str = "&back_start_date=#{@mis_params[:start_date]}"
        back_params_str += "&back_end_date=#{@mis_params[:end_date]}"
        back_params_str += "&back_time_period=#{@mis_params[:time_period]}"
        back_params_str += "&back_group=#{@mis_params[:group]}"
        back_params_str += "&back_title=#{@mis_params[:title]}"
        back_params_str += "&back_optical_store_id=#{store_id}"
        back_params_str += "&back_optical_store_name=#{store_name}"
        back_params_str += "&back_iDisplayStart=#{@mis_params[:iDisplayStart]}"
        back_params_str += "&back_iDisplayLength=#{@mis_params[:iDisplayLength]}"
        back_params_str += '&has_params=true'

        back_params_str
      end
      # EOF back_params
    end
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
