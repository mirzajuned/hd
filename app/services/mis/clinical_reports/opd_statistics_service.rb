module Mis::ClinicalReports
  class OpdStatisticsService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << Mis::Constants::ReportSheetFilters.filters_array(@mis_params) unless @request == 'json'
        lists = MisClinical::Opd::OpdStatistic.collection.aggregate(opd_stats_query).to_a || []
        total_records = unless @request == 'json'
                          @stats_lists = lists || []
                          0
                        else
                          @stats_lists = lists[0][:data] || []
                          lists[0][:metadata].present? ? lists[0][:metadata][0][:total] : 0
                        end
        opd_list_data
        [@data_array, total_records]
      end

      private

      def opd_list_data
        @stats_lists.try(:each) do |opd_list|
          appointment_date = opd_list[:_id].strftime('%d/%m/%Y')
          opd_list[:opd_list].each do |stats|
            not_arrived = stats[:appointment_stats_fields][:not_arrived]
            completed = stats[:appointment_stats_fields][:completed]
            incompleted = stats[:appointment_stats_fields][:incompleted]
            cancelled = stats[:appointment_stats_fields][:cancelled]
            new = stats[:patient_stats_fields][:new]
            follow_up = stats[:patient_stats_fields][:follow_up]
            post_op = stats[:patient_stats_fields][:post_op]
            walkin = stats[:appointment_type_stats_fields][:walkin]
            appointment = stats[:appointment_type_stats_fields][:appointment]
            avg_waiting_time = stats[:turnaround_time_stats_fields][:avg_waiting_time]
            avg_engaged_time = stats[:turnaround_time_stats_fields][:avg_engaged_time]
            avg_total_time = stats[:turnaround_time_stats_fields][:avg_total_time]
            max_total_time = stats[:turnaround_time_stats_fields][:max_total_time]
            max_waiting_time = stats[:turnaround_time_stats_fields][:max_waiting_time]
            max_engaged_time = stats[:turnaround_time_stats_fields][:max_engaged_time]
            if @request == 'json'
              href = @mis_params[:url] + forward_params(appointment_date) + back_params
              not_arrived = if not_arrived > 0
                              "<a href='#{href}&current_state=Scheduled' data-remote='true'>#{not_arrived}</a>"
                            else
                              '__'
                            end
              completed = if completed > 0
                            "<a href='#{href}&current_state=Completed' data-remote='true'>#{completed}</a>"
                          else
                            '__'
                          end
              incompleted = if incompleted > 0
                              "<a href='#{href}&current_state=Incompleted' data-remote='true'>#{incompleted}</a>"
                            else
                              '__'
                            end
              cancelled =  if cancelled > 0
                             "<a href='#{href}&current_state=Deleted' data-remote='true'>#{cancelled}</a>"
                           else
                             '__'
                           end

              new = if new > 0
                      "<a href='#{href}&patient_visit=New' data-remote='true'>#{new}</a>"
                    else
                      '__'
                    end

              follow_up = if follow_up > 0
                            "<a href='#{href}&patient_visit=Followup' data-remote='true'>#{follow_up}</a>"
                          else
                            '__'
                          end
              post_op = if post_op > 0
                          "<a href='#{href}&patient_visit=Post Op' data-remote='true'>#{post_op}</a>"
                        else
                          '__'
                        end

              walkin = if walkin > 0
                         "<a href='#{href}&appointmenttype=walkin' data-remote='true'>#{walkin}</a>"
                       else
                         '__'
                       end
              appointment = if appointment > 0
                              "<a href='#{href}&appointmenttype=appointment' data-remote='true'>#{appointment}</a>"
                            else
                              '__'
                            end

            end

            @data_array << [appointment_date, not_arrived, completed, incompleted, cancelled, new, follow_up, post_op,
                            avg_total_time, max_total_time, walkin, appointment]
          end
        end
      end

      def forward_params(appointment_date)
        start_date = "&start_date=#{appointment_date}"
        end_date = "&end_date=#{appointment_date}"
        time_period = '&time_period=Custom'
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=outpatient'
        title = '&title=patient_detail'
        has_params = '&has_params=true'
        initial_age = "&initial_age=#{@mis_params[:initial_age]}"
        final_age = "&final_age=#{@mis_params[:final_age]}"
        gender_type = "&gender_type=#{@mis_params[:gender_type]}"
        appointmenttype = "&appointmenttype=#{@mis_params[:appointmenttype]}"

        start_date + end_date + time_period + organisation_id + facility_id + facility_name + group + title +
          has_params + initial_age + final_age + gender_type + appointmenttype
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
        initial_age = "&initial_age=#{@mis_params[:initial_age]}"
        final_age = "&final_age=#{@mis_params[:final_age]}"
        gender_type = "&gender_type=#{@mis_params[:gender_type]}"
        appointmenttype = "&appointmenttype=#{@mis_params[:appointmenttype]}"

        back_start_date + back_end_date + back_time_period + back_group + back_title + back_skip + back_length +
          has_params + initial_age + final_age + gender_type + appointmenttype
      end

      def opd_stats_query
        Mis::ClinicalService::StatsQueryBuilder.call(@mis_params, @request)
      end
    end
  end
end
