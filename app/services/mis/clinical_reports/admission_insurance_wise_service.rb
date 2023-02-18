module Mis::ClinicalReports
  class AdmissionInsuranceWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['INSURANCE STATUS', 'COUNT'] unless @request == 'json'

        aggregation_query, aggregation_query_count = admission_query

        @admissions = AdmissionListView.collection.aggregate(aggregation_query).to_a || []
        admission_list_count = AdmissionListView.collection.aggregate(aggregation_query_count).to_a
        total_records = (admission_list_count[0][:admission_list_count] if admission_list_count.count > 0) || 0

        admission_data

        [@data_array, total_records]
      end

      private

      def admission_data
        @admissions.try(:each) do |admission|
          status = admission[:_id].to_s.titleize
          count = admission[:admission_count]

          if @request == 'json' && count > 0
            href = @mis_params[:url] + forward_params(admission) + back_params
            count = "<a href='#{href}' data-remote='true'>#{count}</a>"
          end

          @data_array << [status, count]
        end
      end

      def forward_params(admission)
        start_date = "&start_date=#{@mis_params[:start_date]}"
        end_date = "&end_date=#{@mis_params[:end_date]}"
        time_period = "&time_period=#{@mis_params[:time_period]}"
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=inpatient'
        title = '&title=admission_list_wise'
        insurance = "&insurance_state=#{admission[:_id]}"
        has_params = '&has_params=true'

        start_date + end_date + time_period + organisation_id + facility_id + facility_name + group + title + insurance
        + has_params
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

        back_start_date + back_end_date + back_time_period + back_group + back_title + back_skip + back_length
      end

      def admission_query
        # AdmissionInsuranceList Query
        aggregation_query = [
          { "$match": match_options },
          { "$group": { _id: '$insurance_state', admission_count: { "$sum": 1 } } },
          { "$sort": { admission_count: -1 } }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # AdmissionInsuranceList Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$group": { _id: '$insurance_state', admission_count: { "$sum": 1 } } },
          { "$group": { _id: 'null', admission_list_count: { "$sum": 1 } } }
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
          admission_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                            "$lte": @mis_params[:end_date].end_of_day }
        )

        # IsDeleted
        match_options = match_options.merge(current_state: { "$ne": 'Deleted' })

        match_options
      end
    end
  end
end
