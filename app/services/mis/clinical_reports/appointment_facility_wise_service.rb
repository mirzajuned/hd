# 3  Metrics/MethodLength
# 2  Metrics/CyclomaticComplexity
# 1  Metrics/AbcSize
# 1  Metrics/BlockLength
# 1  Metrics/ClassLength
# 1  Metrics/PerceivedComplexity
# --
# 9  Total
module Mis::ClinicalReports
  class AppointmentFacilityWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        unless @request == 'json'
          @data_array << ['FACILITY NAME', 'NOT ARRIVED', 'COMPLETED', 'INCOMPLETE', 'DELETED', 'TOTAL']
        end

        aggregation_query, aggregation_query_count = appointment_list_query

        @appointment_lists = AppointmentListView.collection.aggregate(aggregation_query).to_a || []
        appointment_list_count = AppointmentListView.collection.aggregate(aggregation_query_count).to_a
        total_records = (appointment_list_count[0][:appointment_list_count] if appointment_list_count.count > 0) || 0

        appointment_facility_ids = @appointment_lists.map { |appointment| appointment[:_id] }
        if appointment_facility_ids.present? && appointment_facility_ids.count > 0
          get_facility_fields(appointment_facility_ids)
        end

        appointment_list_data

        [@data_array, total_records]
      end

      private

      def appointment_list_data
        @appointment_lists.try(:each) do |appointment_list|
          facility = @facility_fields.find { |f| f[:id].to_s == appointment_list[:_id].to_s }
          next if facility.nil?

          data_facility_name = facility[:name]

          href = @mis_params[:url] + forward_params(appointment_list, data_facility_name) + back_params

          current_state_counts = appointment_list['current_state_counts']
          # ["Engaged", "Completed", "Scheduled", "Waiting", "Deleted"]
          not_arrived_hash = current_state_counts.find { |cs| cs['state_name'] == 'Scheduled' } || {}
          completed_hash = current_state_counts.find { |cs| cs['state_name'] == 'Completed' } || {}
          waiting_hash = current_state_counts.find { |cs| cs['state_name'] == 'Waiting' } || {}
          engaged_hash = current_state_counts.find { |cs| cs['state_name'] == 'Engaged' } || {}
          incomplete_hash = current_state_counts.find { |cs| cs['state_name'] == 'Incompleted' } || {}
          deleted_hash = current_state_counts.find { |cs| cs['state_name'] == 'Deleted' } || {}

          not_arrived = not_arrived_hash['state_count'].to_i
          completed = completed_hash['state_count'].to_i
          incomplete = incomplete_hash['state_count'].to_i +
                       waiting_hash['state_count'].to_i +
                       engaged_hash['state_count'].to_i
          deleted = deleted_hash['state_count'].to_i
          total = not_arrived + completed + incomplete + deleted

          if @request == 'json'
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

          @data_array << [data_facility_name, not_arrived, completed, incomplete, deleted, total]
        end
      end

      def forward_params(appointment_list, data_facility_name)
        start_date = "&start_date=#{@mis_params[:start_date]}"
        end_date = "&end_date=#{@mis_params[:end_date]}"
        time_period = '&time_period=Custom'
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{appointment_list[:_id]}"
        facility_name = "&facility_name=#{data_facility_name.tr("'", '`')}"
        group = '&group=outpatient'
        title = '&title=appointment_list_wise'
        has_params = '&has_params=true'

        start_date + end_date + time_period + organisation_id + facility_id + facility_name + group + title +
          has_params
      end

      def back_params
        # Back Params
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
        # FacilityAppointmentList Query
        aggregation_query = [
          { "$match": match_options },
          { "$group": { _id: { facility_id: '$facility_id', current_state: '$current_state' },
                        current_state_count: { "$sum": 1 } } },
          { "$group": { _id: '$_id.facility_id',
                        current_state_counts: { "$push": { state_name: '$_id.current_state',
                                                           state_count: '$current_state_count' } } } },
          { "$sort": { current_state_counts: -1 } }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # FacilityAppointmentList Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$group": { _id: '$facility_id', current_state_count: { "$sum": 1 } } },
          { "$group": { _id: 'null', appointment_list_count: { "$sum": 1 } } }
        ]

        [aggregation_query, aggregation_query_count]
      end

      def match_options
        # Organisation
        match_options = { organisation_id: BSON::ObjectId(@mis_params[:organisation_id]) }

        # Date
        match_options = match_options.merge(appointment_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                                "$lte": @mis_params[:end_date].end_of_day })

        match_options
      end

      def get_facility_fields(facility_ids)
        facilitys = Facility.where(:id.in => facility_ids)
        @facility_fields = facilitys.map { |facility| { id: facility.id.to_s, name: facility.name } }
      end
    end
  end
end
