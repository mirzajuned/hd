# rubocop:disable all
module Mis::ClinicalReports
  class CumulativeProcedureAdvisedService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []

        unless @request == 'json'
          @data_array << Mis::Constants::ReportSheetFilters.procedure_filters(@mis_params)
        end
        aggregation_query = admission_list_query
        lists =  MisClinical::Common::DailyProcedureConversion.collection.aggregate(aggregation_query).to_a || []
        total_records = unless @request == 'json'
                          @stats_lists = lists || []
                          0
                        else
                          @stats_lists = lists[0][:data] || []
                          lists[0][:metadata].present? ? lists[0][:metadata][0][:total] : 0
                        end
        procedure_list_data
        [@data_array, total_records]
      end

      private

      def procedure_list_data
        @stats_lists.try(:each) do |procedure_list|
          start_date = @mis_params[:start_date].strftime('%d/%m/%Y')
          end_date = @mis_params[:end_date].strftime('%d/%m/%Y')
          range = "#{start_date} - #{end_date}"
          procedure_name =  procedure_list['_id']
          advised = procedure_list[:total_advised]
          performed = procedure_list[:performed_from_advised] || 0
          if procedure_name.present?
            if @request == 'json'
              procedure_id = procedure_list[:procedure_id]
              href = @mis_params[:url] + forward_params(start_date, end_date) + back_params
              advised = if advised > 0
                          "<a href='#{href}&procedure_date_wise=advised&procedure_state=pre_advised&procedure_id=#{procedure_id}' data-remote='true'>#{advised}</a>"
                        else
                          '__'
                        end
              @data_array << [range, procedure_name, advised, performed]
            else
              @data_array << [range, procedure_name, advised, performed]
            end
          end
        end
        @data_array
      end

      def forward_params(start_date, end_date)
        start_date = "&start_date=#{start_date}"
        end_date = "&end_date=#{end_date}"
        time_period = '&time_period=Custom'
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=procedure'
        title = '&title=procedure_detail'
        has_params = '&has_params=true'

        start_date + end_date + time_period + organisation_id + facility_id + facility_name + group + title +
          has_params
      end

      def back_params
        back_start_date = "&back_start_date=#{@mis_params[:start_date]}"
        back_end_date = "&back_end_date=#{@mis_params[:end_date]}"
        back_time_period = "&back_time_period=#{@mis_params[:time_period]}"
        back_group = "&back_group=#{@mis_params[:group]}"
        back_title = "&back_title=#{@mis_params[:title]}"
        back_skip = "&back_iDisplayStart=#{@mis_params[:iDisplayStart]}"
        back_length = "&back_iDisplayLength=#{@mis_params[:iDisplayLength]}"
        has_params = '&has_params=true'

        back_start_date + back_end_date + back_time_period + back_group + back_title + back_skip + back_length +
          has_params
      end

      def admission_list_query
        Mis::ClinicalService::CumulativeProcedureAdvisedQueryBuilder.call(@mis_params, @request)
      end
    end
  end
end



