# 2  Metrics/MethodLength
# 1  Metrics/AbcSize
# 1  Metrics/BlockLength
# 1  Metrics/ClassLength
# 1  Metrics/CyclomaticComplexity
# 1  Metrics/PerceivedComplexity
# --
# 7  Total
module Mis::ClinicalReports
  class OtFacilityWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        unless @request == 'json'
          @data_array << ['FACILITY NAME', 'SCHEDULED', 'ADMITTED', 'ENGAGED', 'COMPLETED', 'DELETED', 'TOTAL']
        end

        aggregation_query, aggregation_query_count = ot_list_query

        @ot_lists = OtListView.collection.aggregate(aggregation_query).to_a || []
        ot_list_count = OtListView.collection.aggregate(aggregation_query_count).to_a
        total_records = ot_list_count.count > 0 ? ot_list_count[0][:ot_list_count] : 0

        ot_facility_ids = @ot_lists.map { |ot| ot[:_id] }
        get_facility_fields(ot_facility_ids) if ot_facility_ids.present? && ot_facility_ids.count > 0

        ot_list_data

        [@data_array, total_records]
      end

      private

      def ot_list_data
        @ot_lists.try(:each) do |ot_list|
          facility = @facility_fields.find { |f| f[:id].to_s == ot_list[:_id].to_s }

          if facility.present?
            data_facility_name = facility[:name]

            current_state_counts = ot_list['current_state_counts']
            scheduled_hash = current_state_counts.find { |cs| cs['state_name'] == 'Scheduled' } || {}
            admitted_hash = current_state_counts.find { |cs| cs['state_name'] == 'Admitted' } || {}
            engaged_hash = current_state_counts.find { |cs| cs['state_name'] == 'Engaged' } || {}
            completed_hash = current_state_counts.find { |cs| cs['state_name'] == 'Completed' } || {}
            deleted_hash = current_state_counts.find { |cs| cs['state_name'] == 'Deleted' } || {}

            scheduled = scheduled_hash['state_count'].to_i
            admitted = admitted_hash['state_count'].to_i
            engaged = engaged_hash['state_count'].to_i
            completed = completed_hash['state_count'].to_i
            deleted = deleted_hash['state_count'].to_i
            total = scheduled + admitted + engaged + completed + deleted

            if @request == 'json'
              href = @mis_params[:url] + forward_params(ot_list, data_facility_name) + back_params
              if scheduled > 0
                scheduled = "<a href='#{href}&current_state=Scheduled' data-remote='true'>#{scheduled}</a>"
              end
              admitted = "<a href='#{href}&current_state=Admitted' data-remote='true'>#{admitted}</a>" if admitted > 0
              engaged = "<a href='#{href}&current_state=Engaged' data-remote='true'>#{engaged}</a>" if engaged > 0
              if completed > 0
                completed = "<a href='#{href}&current_state=Completed' data-remote='true'>#{completed}</a>"
              end
              deleted = "<a href='#{href}&current_state=Deleted' data-remote='true'>#{deleted}</a>" if deleted > 0
              total = "<a href='#{href}' data-remote='true'>#{total}</a>' if total > "
            end

            @data_array << [data_facility_name, scheduled, admitted, engaged, completed, deleted, total]
          end
        end
      end

      def forward_params(ot_list, data_facility_name)
        start_date = "&start_date=#{@mis_params[:start_date]}"
        end_date = "&end_date=#{@mis_params[:end_date]}"
        time_period = "&time_period=#{@mis_params[:time_period]}"
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{ot_list[:_id]}"
        facility_name = "&facility_name=#{data_facility_name.tr("'", '`')}"
        group = '&group=inpatient'
        title = '&title=ot_list_wise'
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

      def ot_list_query
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
          { "$group": { _id: 'null', ot_list_count: { "$sum": 1 } } }
        ]

        [aggregation_query, aggregation_query_count]
      end

      def match_options
        # Organisation
        match_options = { organisation_id: BSON::ObjectId(@mis_params[:organisation_id]) }

        # Date
        match_options = match_options.merge(ot_date: { "$gte": @mis_params[:start_date].beginning_of_day,
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
