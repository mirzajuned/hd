# rubocop:disable all
module Mis::ClinicalReports
  class DailyDoctorProcedureService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []

        unless @request == 'json'
          @data_array << Mis::Constants::ReportSheetFilters.procedure_filters(@mis_params)
        end
        aggregation_query = admission_list_query
        lists =  MisClinical::Common::UserProcedureConversion.collection.aggregate(aggregation_query).to_a || []
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
          date = procedure_list[:_id].strftime('%d/%m/%Y')
          alias_date = procedure_list[:_id].strftime('%d/%m/%Y')
          procedure = procedure_list[:procedure_list].group_by { |val| val[:user_name] }
          procedure.each do |key, stats|
            @doc_name = key.present? ? key.titleize : '----'
            advised = stats[0][:total_advised]
            doctor_id = stats[0][:user_id]
            performed = stats[0][:total_performed]

            if @request == 'json'
              href = @mis_params[:url] + forward_params(alias_date) + back_params
              advised = if advised > 0
                          "<a href='#{href}&procedure_date_wise=advised&procedure_state=pre_advised&advised_by=#{doctor_id}' data-remote='true'>#{advised}</a>"
                        else
                          '0'
                        end
              performed = if performed > 0
                            "<a href='#{href}&procedure_date_wise=performed&procedure_state=performed&performed_by=#{doctor_id}' data-remote='true'>#{performed}</a>"
                          else
                            '0'
                          end
              @data_array << [date, @doc_name, advised, performed ]

            else
              @data_array << [date, @doc_name, advised, performed]
            end
            date =''
          end
        end
        @data_array
      end

      def forward_params(appointment_date)
        start_date = "&start_date=#{appointment_date}"
        end_date = "&end_date=#{appointment_date}"
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
        Mis::ClinicalService::DoctorWiseProcedureQueryBuilder.call(@mis_params, @request)
      end
    end
  end
end



