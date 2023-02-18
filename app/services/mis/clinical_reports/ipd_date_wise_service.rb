# rubocop:disable all
module Mis::ClinicalReports
  class IpdDateWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []

       unless @request == 'json'
          @data_array << Mis::Constants::ReportSheetFilters.inpatient_filters(@mis_params)
        end
        aggregation_query = admission_list_query
        lists = MisClinical::Ipd::AdmissionDateWise.collection.aggregate(aggregation_query).to_a || []
        total_records = unless @request == 'json'
                          @stats_lists = lists || []
                          0
                        else
                          @stats_lists = lists[0][:data] || []
                          lists[0][:metadata].present? ? lists[0][:metadata][0][:total] : 0
                        end

        ipd_list_data
        [@data_array, total_records]
      end

      private

      def ipd_list_data
        @stats_lists.try(:each) do |ipd_list|
          created_date = ipd_list[:_id].strftime('%d/%m/%Y')
          ipd_list[:ipd_list].each do |stats|
            scheduled = stats[:admission_stats_fields][:scheduled]
            admitted = stats[:admission_stats_fields][:admitted]
            discharged = stats[:admission_stats_fields][:discharged]

            if @request == 'json'
              href = @mis_params[:url] + forward_params(created_date) + back_params
              scheduled = if scheduled > 0
                              "<a href='#{href}&date_wise=Scheduled&capture_state=Scheduled' data-remote='true'>#{scheduled}</a>"
                            else
                              '__'
                            end
              admitted = if admitted > 0
                            "<a href='#{href}&date_wise=Admitted&capture_state=Admitted' data-remote='true'>#{admitted}</a>"
                          else
                            '__'
                          end
              discharged = if discharged > 0
                              "<a href='#{href}&date_wise=Discharged&capture_state=Discharged' data-remote='true'>#{discharged}</a>"
                            else
                              '__'
                           end
              @data_array << [created_date, scheduled, admitted, discharged ]

            else
              @data_array << [created_date, scheduled, admitted, discharged ]
            end

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
        group = '&group=inpatient'
        title = '&title=inpatient_detail'
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
        Mis::ClinicalService::IpdDatewiseQueryBuilder.call(@mis_params, @request)
      end
    end

  end
end



