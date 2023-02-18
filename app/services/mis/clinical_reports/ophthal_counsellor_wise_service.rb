module Mis::ClinicalReports
  class OphthalCounsellorWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['COUNSELLOR NAME', 'COUNSELLED', 'PERFORMED', 'DECLINED'] unless @request == 'json'

        data_array, aggregation_query_count = investigation_appointment_data
        total_records = aggregation_query_count.count > 0 ? aggregation_query_count[0][:list_count] : 0
        [data_array, total_records]
      end

      private

      def investigation_appointment_data
        investigation_query, investigation_count_query = investigation_appointment_query
        @investigation_appointment_list = CaseSheet.collection.aggregate(investigation_query).to_a || []
        aggregation_query_count = CaseSheet.collection.aggregate(investigation_count_query).to_a || []
        map_investigation_count
        [@data_array, aggregation_query_count]
      end

      def forward_params
        start_date = "&start_date=#{@mis_params[:start_date]}"
        end_date = "&end_date=#{@mis_params[:end_date]}"
        time_period = '&time_period=Custom'
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=conversion'
        title = '&title=ophthal_investigations_state_wise'
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

      def map_investigation_count
        @investigation_appointment_list.each do |list|
          counselled_count = list[:counselled_count]
          declined_count = 0
          performed_count = 0
          status_wise_count = status_count([declined_count, performed_count], list)
          status_wise_count << counselled_count
          counsellor_name = list[:investigation_state_list][0][:counselled_by]
          status_wise_count = make_anchor_url(status_wise_count, list[:_id][:counselled_by_id])
          counselled_count, declined_count, performed_count = status_wise_count
          @data_array << [counsellor_name, counselled_count, performed_count, declined_count]
        end
        @data_array
      end

      def status_count(status_wise_count, list)
        list[:investigation_state_list].each do |state|
          status_wise_count[0] += 1 if state[:has_declined]
          status_wise_count[1] += 1 if state[:is_performed]
        end
        [status_wise_count[0], status_wise_count[1]]
      end

      def make_anchor_url(status_wise_count, counsellor_id)
        declined_count, performed_count, counselled_count = status_wise_count
        if @request == 'json'
          declined_count, performed_count, counselled_count = anchored_url(status_wise_count, counsellor_id)
        end
        [counselled_count, declined_count, performed_count]
      end

      def anchored_url(status_wise_count, counsellor_id)
        declined_count, performed_count, counselled_count = status_wise_count
        href = @mis_params[:url] + forward_params + back_params
        if counselled_count > 0
          counselled_count = "<a href='#{href}&current_state=counselled&counsellor_id=#{counsellor_id}'
                                data-remote='true'>#{counselled_count}</a>"
        end

        if declined_count > 0
          declined_count = "<a href='#{href}&current_state=declined&counsellor_id=#{counsellor_id}'
                              data-remote='true'>#{declined_count}</a>"
        end

        if performed_count > 0
          performed_count = "<a href='#{href}&current_state=performed&counsellor_id=#{counsellor_id}'
                                data-remote='true'> #{performed_count}</a>"
        end
        [declined_count, performed_count, counselled_count]
      end

      def investigation_appointment_query
        # appointment status wise count
        aggregation_query = [
          { "$match": match_options },
          { "$unwind": '$ophthal_investigations' },
          { "$match": match_date_options },
          { "$project": project_options },
          { "$group": group_options }
        ]
        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # AppointmentList Count Query
        [aggregation_query, aggregation_query_count_params]
      end

      def aggregation_query_count_params
        [
          { "$match": match_options },
          { "$unwind": '$ophthal_investigations' },
          { "$match": match_date_options },
          { "$project": project_options },
          { "$group": group_options },
          { "$group": { _id: 'null', list_count: { "$sum": 1 } } }
        ]
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          {
                            "ophthal_investigations.advised_at_facility_id": BSON::ObjectId(
                              (@mis_params[:facility_id]).to_s
                            )
                          }
                        else
                          { "organisation_id": BSON::ObjectId((@mis_params[:organisation_id]).to_s) }
                        end

        match_options.merge!("ophthal_investigations.is_counselled": true)
      end

      def match_date_options
        {
          "ophthal_investigations.counselled_datetime": { "$gte": @mis_params[:start_date].beginning_of_day,
                                                          "$lte": @mis_params[:end_date].end_of_day }
        }
      end

      def group_options
        {
          _id: { counselled_by_id: '$ophthal_investigations.counselled_by_id' },
          investigation_state_list: {
            "$push": { counselled_by: '$ophthal_investigations.counselled_by',
                       is_counselled: '$ophthal_investigations.is_counselled',
                       has_declined: '$ophthal_investigations.has_declined',
                       is_performed: '$ophthal_investigations.is_performed' }
          },
          counselled_count: { '$sum': 1 }
        }
      end

      def project_options
        {
          'ophthal_investigations.counselled_by': 1,
          'ophthal_investigations.counselled_by_id': 1,
          'ophthal_investigations.is_counselled': 1,
          'ophthal_investigations.has_declined': 1,
          'ophthal_investigations.is_performed': 1
        }
      end
    end
  end
end
