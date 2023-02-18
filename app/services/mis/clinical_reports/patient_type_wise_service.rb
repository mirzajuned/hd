module Mis::ClinicalReports
  class PatientTypeWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['PATIENT TYPE', 'TOTAL'] unless @request == 'json'

        aggregation_query, aggregation_query_count = appointment_list_query

        @patient_types = AppointmentListView.collection.aggregate(aggregation_query).to_a || []
        patient_type_count = AppointmentListView.collection.aggregate(aggregation_query_count).to_a
        total_records = (patient_type_count[0][:patient_type_list_count] if patient_type_count.count > 0) || 0

        appointment_list_data

        [@data_array, total_records]
      end

      private

      def appointment_list_data
        @patient_types.try(:each) do |patient_type|
          next if patient_type[:_id].nil?

          type = patient_type[:_id] || '<i>No Patient Type</i>'
          count = patient_type[:patient_type_count]

          if @request == 'json' && count > 0
            href = @mis_params[:url] + forward_params(type) + back_params
            count = "<a href='#{href}' data-remote='true'>#{count}</a>"
          end

          @data_array << [type, count]
        end
      end

      def forward_params(type)
        # Forward Params
        start_date = "&start_date=#{@mis_params[:start_date]}"
        end_date = "&end_date=#{@mis_params[:end_date]}"
        time_period = "&time_period=#{@mis_params[:time_period]}"
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=outpatient'
        title = '&title=appointment_list_wise'
        type = "&patient_type=#{type}"
        has_params = '&has_params=true'

        start_date + end_date + time_period + organisation_id + facility_id + facility_name + group + title + type +
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
        # PatientType Query
        aggregation_query = [
          { "$match": match_options },
          { "$group": { _id: '$patient_type', patient_type_count: { "$sum": 1 } } },
          { "$sort": { _id: 1 } }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # PatientType Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$group": { _id: '$patient_type', patient_type_count: { "$sum": 1 } } },
          { "$group": { _id: 'null', patient_type_list_count: { "$sum": 1 } } }
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
    end
  end
end
