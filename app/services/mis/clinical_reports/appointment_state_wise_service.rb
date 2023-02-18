module Mis::ClinicalReports
  class AppointmentStateWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        unless @request == 'json'
          @data_array << %w(STATE COUNT AGE UNDEFINED MALE FEMALE OTHER(GENDER) TYPE)
        end

        aggregation_query, aggregation_query_count = appointment_list_query

        @state = AppointmentListView.collection.aggregate(aggregation_query).to_a || []
        @state_count = AppointmentListView.collection.aggregate(aggregation_query_count).to_a
        total_records = (@state_count[0][:total_records] if @state_count.count > 0) || 0

        appointment_list_data

        [@data_array, total_records]
      end

      private

      def appointment_list_data
        @state.each do |location|
          next if location[:_id].nil?

          href = @mis_params[:url] + forward_params + back_params
          href_req = [href, @request]
          arr = Mis::ClinicalReports::ClinicalUtility.clinical_location_data(location, href_req, 'state')
          @data_array << arr
          # loop
        end
      end

      def forward_params
        # Forward Params
        start_date = "&start_date=#{@mis_params[:start_date]}"
        end_date = "&end_date=#{@mis_params[:end_date]}"
        time_period = "&time_period=#{@mis_params[:time_period]}"
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=outpatient'
        title = '&title=appointment_list_wise'
        has_params = '&has_params=true'

        start_date + end_date + time_period + organisation_id + facility_id + facility_name + group + title + has_params
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

        back_start_date + back_end_date + back_time_period + back_group + back_title + back_skip + back_length + has_params
      end

      def appointment_list_query
        # PatientType Query
        aggregation_query = [
          { "$match": match_options },
          { "$group": group_options }
        ]
        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'
        # PatientType Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$group": group_options },
          { "$group": { _id: 'null', total_records: { "$sum": 1 } } }
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
        match_options = match_options.merge(appointment_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                                "$lte": @mis_params[:end_date].end_of_day })
        match_options = match_options.merge(current_state: { "$nin": ["Deleted"] })
        match_options = match_options.merge(state: { "$nin": ['', nil] })
        match_options
      end

      def group_options
        { _id: '$state',
          appointment_lists: { "$push": { appointment_id: '$appointment_id', appointment_date: '$appointment_date',
                                          patient_age: '$patient_age', age: '$age', patient_gender: '$patient_gender',
                                          appointment_type: '$appointment_type' } },
          count: { '$sum': 1 } }
      end
    end
  end
end
