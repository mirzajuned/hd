# rubocop:disable all
module Mis::ClinicalReports
  class DailyDoctorInvestigationService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []
        @mis_params[:initial_age] = nil
        @data_array << Mis::Constants::ReportSheetFilters.filters_array(@mis_params) unless @request == 'json'
        @stats_lists = MisClinical::Opd::InvestigationConversion.collection.aggregate(data_query).to_a || []

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
        @stats_lists = @stats_lists.group_by { |record| record[:_id][:investigation_date].strftime('%d/%m/%Y') }
        @stats_lists.each do |date, list|
          list = list.group_by { |l| l[:_id][:user_id] }
          list.each_with_index do |(user_id, investigation_list), top_index|
            user_name = investigation_list[0][:user_name] if investigation_list[0].present?
            investigation_list.each_with_index do |data, index|
              total_performed = data[:total_performed]
              investigation_type = data[:_id][:investigation_type]
              total_advised = data[:total_advised]
              if @request == 'json'
                performed_href = @mis_params[:url] + forward_params(date, investigation_type, 'performed', "&performed_by=#{user_id}") + back_params
                advised_href = @mis_params[:url] + forward_params(date, investigation_type, 'advised', "&advised_by=#{user_id}") + back_params
                inv_date = index == 0 && top_index == 0 ? date : ''
                user_name = '' if index > 0
                total_performed = if total_performed > 0
                                    "<a href='#{performed_href}' data-remote='true'>#{total_performed.to_i}</a>"
                                  else
                                    '-'
                                  end
                total_advised = if total_advised > 0
                                  "<a href='#{advised_href}' data-remote='true'>#{total_advised.to_i}</a>"
                                else
                                  '-'
                                end
              else
                inv_date = date
              end
              @data_array << [inv_date, user_name, investigation_type, total_advised, total_performed]
            end
          end
        end
        @data_array
      end

      def forward_params(date, type, category, user_details)
        start_date = "&start_date=#{date}"
        end_date = "&end_date=#{date}"
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
        user_details + inv_details + has_params
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
        Mis::ClinicalService::DoctorInvestigationQueryBuilder.call(@mis_params, @request, 'data')
      end

      def count_query
        Mis::ClinicalService::DoctorInvestigationQueryBuilder.call(@mis_params, @request, 'count')
      end
    end
  end
end