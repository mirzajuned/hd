# 1  Metrics/AbcSize
# 1  Metrics/CyclomaticComplexity
# 1  Metrics/MethodLength
# --
# 3  Total
module Mis::ClinicalReports
  class AppointmentDateWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['DATE', 'NOT ARRIVED', 'COMPLETED', 'INCOMPLETE', 'DELETED', 'TOTAL'] unless @request == 'json'

        aggregation_query, aggregation_query_count = appointment_list_query

        @appointment_lists = AppointmentListView.collection.aggregate(aggregation_query).to_a || []
        appointment_list_count = AppointmentListView.collection.aggregate(aggregation_query_count).to_a
        total_records = (appointment_list_count[0][:appointment_list_count] if appointment_list_count.count > 0) || 0

        appointment_list_data

        [@data_array, total_records]
      end

      private

      def appointment_list_data
        @appointment_lists.try(:each) do |appointment_list|
          current_state_group = appointment_list[:appointment_list].group_by { |al| al[:current_state] }
          appointment_date = appointment_list[:_id].strftime('%d/%m/%Y')

          not_arrived = current_state_group['Scheduled'].to_a.size
          completed = current_state_group['Completed'].to_a.size
          incomplete = current_state_group['Waiting'].to_a.size +
                       current_state_group['Engaged'].to_a.size +
                       current_state_group['Incompleted'].to_a.size
          deleted = current_state_group['Deleted'].to_a.size
          total = not_arrived + completed + incomplete + deleted

          if @request == 'json'
            href = @mis_params[:url] + forward_params(appointment_date) + back_params
            if not_arrived > 0
              not_arrived = "<a href='#{href}&current_state=Scheduled' data-remote='true'>#{not_arrived}</a>"
            end
            completed = "<a href='#{href}&current_state=Completed' data-remote='true'>#{completed}</a>" if completed > 0
            if incomplete > 0
              incomplete = "<a href='#{href}&current_state=Incomplete' data-remote='true'>#{incomplete}</a>"
            end
            deleted = "<a href='#{href}&current_state=Deleted' data-remote='true'>#{deleted}</a>" if deleted > 0
            total = "<a href='#{href}' data-remote='true'>#{total}</a>" if total > 0
          end

          @data_array << [appointment_date, not_arrived, completed, incomplete, deleted, total]
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
        title = '&title=appointment_list_wise'
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

      def appointment_list_query
        # AppointmentList Query
        aggregation_query = [
          { "$match": match_options },
          { "$group": group_options },
          { "$sort": { _id: -1 } }
        ]
        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # AppointmentList Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$group": group_options },
          { "$group": { _id: 'null', appointment_list_count: { "$sum": 1 } } }
        ]

        [aggregation_query, aggregation_query_count]
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { facility_id: BSON::ObjectId(@mis_params[:facility_id]) }
                        else
                          { organisation_id: BSON::ObjectId(@mis_params[:organisation_id]) }
                        end

        # Date
        match_options = match_options.merge(appointment_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                                "$lte": @mis_params[:end_date].end_of_day })

        match_options
      end

      def group_options
        { _id: '$appointment_date', appointment_list: { "$push": { current_state: '$current_state' } } }
      end
    end
  end
end
