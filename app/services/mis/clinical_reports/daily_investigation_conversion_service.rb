module Mis::ClinicalReports
  class DailyInvestigationConversionService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []
        unless @request == 'json'
          @mis_params[:initial_age] = nil
          @data_array << Mis::Constants::ReportSheetFilters.filters_array(@mis_params)
        end
        @collection = MisClinical::Opd::DailyInvestigationConversion.collection.aggregate(query).to_a || {}

        if @request == 'json'
          total_records = (MisClinical::Opd::DailyInvestigationConversion.collection.aggregate(count_query).to_a || []).size
        else
          total_records = 0
        end

        collect
        [@data_array, total_records]
      end

      private

      def collect
        @collection.each do |record|
          date = record[:_id]&.strftime('%d/%m/%Y')
          record[:list].each_with_index do |inv, index|
            name = "#{inv[:investigation_name]} #{inv[:investigation_specialization]}"
            investigation_type = inv[:investigation_type]
            total_performed = inv[:total_performed]
            total_advised =inv[:total_advised]
            if @request == 'json'
              performed_href = @mis_params[:url] + forward_params(record[:_id], investigation_type, 'performed') + back_params
              advised_href = @mis_params[:url] + forward_params(record[:_id], investigation_type, 'advised') + back_params
              date = '' if index > 0
              total_performed = if total_performed > 0
                                  "<a href='#{performed_href}&investigation_id=#{inv[:investigation_id].to_s}' data-remote='true'>#{total_performed.to_i}</a>"
                                else
                                  '-'
                                end
              total_advised = if total_advised > 0
                                "<a href='#{advised_href}&investigation_id=#{inv[:investigation_id].to_s}' data-remote='true'>#{total_advised.to_i}</a>"
                              else
                                '-'
                              end
            end
            @data_array << [
              date, name, investigation_type, total_advised, total_performed
            ]
          end
        end
      end

      def query
        Mis::ClinicalService::DailyInvestigationConversionQueryBuilder.call(@mis_params, @request)
      end

      def count_query
        Mis::ClinicalService::DailyInvestigationConversionQueryBuilder.call(@mis_params, @request, 'count')
      end

      def forward_params(date, type, category)
        start_date = "&start_date=#{date}"
        end_date = "&end_date=#{date}"
        time_period = '&time_period=Custom'
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=investigation'
        title = '&title=investigation_detail'
        has_params = '&has_params=true'
        inv_type = inv_type = "Investigation::#{type}"
        inv_details = "&investigation_date_wise=#{category}&investigation_type=#{inv_type}"
        start_date + end_date + time_period + organisation_id + facility_id + facility_name + group + title +
          inv_details + has_params
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

    end
  end
end
