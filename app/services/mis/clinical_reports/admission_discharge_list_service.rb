module Mis::ClinicalReports
  class AdmissionDischargeListService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['DATE', 'DISCHARGED'] unless @request == 'json'

        aggregation_query, aggregation_query_count = admission_list_query

        @discharge_lists = AdmissionListView.collection.aggregate(aggregation_query).to_a || []
        discharge_list_count = AdmissionListView.collection.aggregate(aggregation_query_count).to_a
        total_records = (discharge_list_count[0][:discharge_list_count] if discharge_list_count.count > 0) || 0

        admission_list_data

        [@data_array, total_records]
      end

      private

      def admission_list_data
        @discharge_lists.try(:each) do |discharge_list|
          discharge_date = discharge_list[:_id].strftime('%d/%m/%Y')

          date = discharge_date
          count = discharge_list[:discharge_count]

          if @request == 'json'
            href = @mis_params[:url] + forward_params(discharge_date) + back_params
            count = "<a href='#{href}&current_state=Discharged' data-remote='true'>#{count}</a>" if count > 0
          end

          @data_array << [date, count]
        end
      end

      def forward_params(discharge_date)
        start_date = "&start_date=#{discharge_date}"
        end_date = "&end_date=#{discharge_date}"
        time_period = '&time_period=Custom'
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=inpatient'
        title = '&title=admission_list_wise'
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
        # AppointmentList Query
        aggregation_query = [
          { "$match": match_options },
          { "$group": { _id: '$discharge_date', discharge_count: { "$sum": 1 } } },
          { "$sort": { _id: -1 } }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # AppointmentList Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$group": { _id: '$discharge_date', discharge_count: { "$sum": 1 } } },
          { "$group": { _id: 'null', discharge_list_count: { "$sum": 1 } } }
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
        match_options = match_options.merge(
          discharge_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                            "$lte": @mis_params[:end_date].end_of_day }
        )

        # Discharged
        match_options = match_options.merge(current_state: 'Discharged')

        match_options
      end
    end
  end
end
