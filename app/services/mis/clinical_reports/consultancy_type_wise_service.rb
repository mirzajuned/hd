module Mis::ClinicalReports
  class ConsultancyTypeWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['CONSULTANCY TYPE', 'TOTAL'] unless @request == 'json'

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
          if appointment_list[:_id].present?
            type = Global.consultancy_types[appointment_list[:_id]]
            count = appointment_list[:appointment_count]

            if @request == 'json' && count > 0
              href = @mis_params[:url] + forward_params(appointment_list) + back_params
              count = "<a href='#{href}' data-remote='true'>#{count}</a>"
            end

            @data_array << [type, count]
          end
        end
      end

      def forward_params(appointment_list)
        # Forward Params
        start_date = "&start_date=#{@mis_params[:start_date]}"
        end_date = "&end_date=#{@mis_params[:end_date]}"
        time_period = "&time_period=#{@mis_params[:time_period]}"
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=outpatient'
        title = '&title=appointment_list_wise'
        type = "&consultancy_type=#{appointment_list[:_id]}"
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
        # AppointmentPaymentTypeList Query
        aggregation_query = [
          { "$match": match_options },
          { "$group": { _id: '$consultancy_type', appointment_count: { "$sum": 1 } } },
          { "$sort": { appointment_count: -1 } }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # AppointmentPaymentTypeList Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$group": { _id: '$consultancy_type', appointment_count: { "$sum": 1 } } },
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

        # Seen Patients
        match_options = match_options.merge(current_state: { "$nin": ['Scheduled', 'Deleted'] })

        match_options
      end
    end
  end
end
