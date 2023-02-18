module Mis::ClinicalReports
  class CumulativeInvestigationAdvisedService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []
        @period = "#{@mis_params[:start_date]&.strftime('%d/%m/%Y')} - #{@mis_params[:end_date]&.strftime('%d/%m/%Y')}"
        @mis_params[:initial_age] = nil
        @data_array << Mis::Constants::ReportSheetFilters.filters_array(@mis_params) unless @request == 'json'
        @collection = MisClinical::Opd::InvestigationConversion.collection.aggregate(data_query).to_a || []

        if @request == 'json'
          total_records = (MisClinical::Opd::InvestigationConversion.collection.aggregate(count_query).to_a || []).size
        else
          total_records = 0
        end

        collection
        [@data_array, total_records]
      end

      private

      def collection
        @collection.each do |investigation_list|
          total_performed = investigation_list[:total_performed]
          investigation_type = investigation_list[:_id]
          total_advised = investigation_list[:total_advised]
          if @request == 'json'
            inv_type = "Investigation::#{investigation_type}"
            performed_href = @mis_params[:url] + forward_params(investigation_type, 'performed') + back_params
            advised_href = @mis_params[:url] + forward_params(investigation_type, 'advised') + back_params
            total_performed = if total_performed > 0
                                "<a href='#{performed_href}&investigation_type=#{inv_type}' data-remote='true'>#{total_performed.to_i}</a>"
                              else
                                '-'
                              end
            total_advised = if total_advised > 0
                              "<a href='#{advised_href}&investigation_type=#{inv_type}' data-remote='true'>#{total_advised.to_i}</a>"
                            else
                              '0'
                            end
          end
          @data_array << [@period, investigation_type, total_advised, total_performed]
        end
        @data_array
      end

      def forward_params(type, category)
        start_date = "&start_date=#{@mis_params[:start_date]}"
        end_date = "&end_date=#{@mis_params[:end_date]}"
        time_period = '&time_period=Custom'
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=investigation'
        title = '&title=investigation_detail'
        has_params = '&has_params=true'
        inv_type = "Investigation::#{type}"
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

      def data_query
        Mis::ClinicalService::CumulativeInvestigationAdvisedQueryBuilder.call(@mis_params, @request, 'data')
      end

      def count_query
        Mis::ClinicalService::CumulativeInvestigationAdvisedQueryBuilder.call(@mis_params, @request, 'count')
      end
    end
  end
end
