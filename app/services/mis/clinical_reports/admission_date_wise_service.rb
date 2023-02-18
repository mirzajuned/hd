# 1  Metrics/AbcSize
# 1  Metrics/CyclomaticComplexity
# 1  Metrics/MethodLength
# --
# 3  Total
module Mis::ClinicalReports
  class AdmissionDateWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['DATE', 'SCHEDULED', 'ADMITTED', 'DISCHARGED', 'DELETED', 'TOTAL'] if @request == 'xls'

        aggregation_query, aggregation_query_count = admission_list_query

        @admission_lists = AdmissionListView.collection.aggregate(aggregation_query).to_a || []
        admission_list_count = AdmissionListView.collection.aggregate(aggregation_query_count).to_a
        total_records = (admission_list_count[0][:admission_list_count] if admission_list_count.count > 0) || 0

        admission_list_data

        [@data_array, total_records]
      end

      private

      def admission_list_data
        @admission_lists.try(:each) do |admission_list|
          current_state_group = admission_list[:admission_list].group_by { |al| al[:current_state] }
          admission_date = admission_list[:_id].strftime('%d/%m/%Y')

          scheduled = current_state_group['Scheduled'].to_a.size
          admitted = current_state_group['Admitted'].to_a.size
          discharged = current_state_group['Discharged'].to_a.size
          deleted = current_state_group['Deleted'].to_a.size
          total = scheduled + admitted + discharged + deleted

          if @request == 'json'
            href = @mis_params[:url] + forward_params(admission_date) + back_params

            scheduled = "<a href='#{href}&current_state=Scheduled' data-remote='true'>#{scheduled}</a>" if scheduled > 0
            admitted = "<a href='#{href}&current_state=Admitted' data-remote='true'>#{admitted}</a>" if admitted > 0
            if discharged > 0
              discharged = "<a href='#{href}&current_state=Discharged' data-remote='true'>#{discharged}</a>"
            end
            deleted = "<a href='#{href}&current_state=Deleted' data-remote='true'>#{deleted}</a>" if deleted > 0
            total = "<a href='#{href}' data-remote='true'>#{total}</a>" if total > 0
          end

          @data_array << [admission_date, scheduled, admitted, discharged, deleted, total]
        end
      end

      def forward_params(admission_date)
        start_date = "&start_date=#{admission_date}"
        end_date = "&end_date=#{admission_date}"
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
          { "$group":  { _id: { "$cond": { "if": { "$eq": ["$current_state", 'Discharged'] }, "then": "$discharge_date", "else": "$admission_date" } }, admission_list: { "$push": { current_state: '$current_state' } } } },
          { "$sort": { _id: -1 } }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # AppointmentList Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$group": { _id: '$admission_date', admission_list: { "$push": { current_state: '$current_state' } } } },
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
          "$or": [{ admission_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                      "$lte": @mis_params[:end_date].end_of_day },
                    current_state: { "$ne": 'Discharged' } },
                  { discharge_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                      "$lte": @mis_params[:end_date].end_of_day },
                    current_state: 'Discharged' }]
        )

        match_options
      end
    end
  end
end
