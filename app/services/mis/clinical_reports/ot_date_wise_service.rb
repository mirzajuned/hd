# 1  Metrics/AbcSize
# 1  Metrics/CyclomaticComplexity
# 1  Metrics/MethodLength
# 1  Metrics/PerceivedComplexity
# --
# 4  Total
module Mis::ClinicalReports
  class OtDateWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        unless @request == 'json'
          @data_array << ['DATE', 'SCHEDULED', 'ADMITTED', 'ENGAGED', 'COMPLETED', 'DELETED', 'TOTAL']
        end

        aggregation_query, aggregation_query_count = ot_list_query

        @ot_lists = OtListView.collection.aggregate(aggregation_query).to_a || []
        ot_list_count = OtListView.collection.aggregate(aggregation_query_count).to_a
        total_records = (ot_list_count[0][:ot_list_count] if ot_list_count.count > 0) || 0

        ot_list_data

        [@data_array, total_records]
      end

      private

      def ot_list_data
        @ot_lists.try(:each) do |ot_list|
          current_state_group = ot_list[:ot_list].group_by { |al| al[:current_state] }

          ot_date = ot_list[:_id].strftime('%d/%m/%Y')

          scheduled = current_state_group['Scheduled'].to_a.size
          admitted = current_state_group['Admitted'].to_a.size
          engaged = current_state_group['Engaged'].to_a.size
          completed = current_state_group['Completed'].to_a.size
          deleted = current_state_group['Deleted'].to_a.size
          total = scheduled + admitted + engaged + completed + deleted

          if @request == 'json'
            href = @mis_params[:url] + forward_params(ot_date) + back_params
            scheduled = "<a href='#{href}&current_state=Scheduled' data-remote='true'>#{scheduled}</a>" if scheduled > 0
            admitted = "<a href='#{href}&current_state=Admitted' data-remote='true'>#{admitted}</a>" if admitted > 0
            engaged = "<a href='#{href}&current_state=Engaged' data-remote='true'>#{engaged}</a>" if engaged > 0
            completed = "<a href='#{href}&current_state=Completed' data-remote='true'>#{completed}</a>" if completed > 0
            deleted = "<a href='#{href}&current_state=Deleted' data-remote='true'>#{deleted}</a>" if deleted > 0
            total = "<a href='#{href}' data-remote='true'>#{total}</a>" if total > 0
          end

          @data_array << [ot_date, scheduled, admitted, engaged, completed, deleted, total]
        end
      end

      def forward_params(ot_date)
        start_date = "&start_date=#{ot_date}"
        end_date = "&end_date=#{ot_date}"
        time_period = '&time_period=Custom'
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
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
        # OtList Query
        aggregation_query = [
          { "$match": match_options },
          { "$group": { _id: '$ot_date', ot_list: { "$push": { current_state: '$current_state' } } } },
          { "$sort": { _id: -1 } }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # OtList Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$group": { _id: '$ot_date', ot_list: { "$push": { current_state: '$current_state' } } } },
          { "$group": { _id: 'null', ot_list_count: { "$sum": 1 } } }
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
        match_options = match_options.merge(ot_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                       "$lte": @mis_params[:end_date].end_of_day })

        match_options
      end
    end
  end
end
