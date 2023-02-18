module Mis::ClinicalReports
  class ProcedureDoctorWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['DOCTOR NAME', 'ADVISED', 'PERFORMED', 'DECLINED'] unless @request == 'json'

        data_array, aggregation_query_count = procedure_appointment_data
        total_records = aggregation_query_count.count > 0 ? aggregation_query_count[0][:list_count] : 0
        [data_array, total_records]
      end

      private

      def procedure_appointment_data
        procedure_query, procedure_count_query = procedure_appointment_query
        @procedure_appointment_list = CaseSheet.collection.aggregate(procedure_query).to_a || []
        aggregation_query_count = CaseSheet.collection.aggregate(procedure_count_query).to_a || []
        map_procedure_count
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
        title = '&title=advised_date_wise'
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

        back_start_date + back_end_date + back_time_period + back_group + back_title + back_skip + back_length
      end

      def map_procedure_count
        @procedure_appointment_list.each do |list|
          advised_count = list[:advised_count]
          declined_count = 0
          performed_count = 0
          status_wise_count = status_count([declined_count, performed_count], list)
          status_wise_count << advised_count
          doctor_name = list[:procedure_state_list][0][:advised_by]
          status_wise_count = make_anchor_url(status_wise_count, list[:_id][:advised_by_id])
          advised_count, declined_count, performed_count = status_wise_count
          @data_array << [doctor_name, advised_count, performed_count, declined_count]
        end
        @data_array
      end

      def status_count(status_wise_count, list)
        list[:procedure_state_list].each do |state|
          status_wise_count[0] += 1 if state[:has_declined]
          status_wise_count[1] += 1 if state[:is_performed]
        end
        [status_wise_count[0], status_wise_count[1]]
      end

      def make_anchor_url(status_wise_count, doctor_id)
        declined_count, performed_count, advised_count = status_wise_count
        if @request == 'json'
          href = @mis_params[:url] + forward_params + back_params
          declined_count, performed_count, advised_count = anchored_count(status_wise_count, href, doctor_id)
        end
        [advised_count, declined_count, performed_count]
      end

      def anchored_count(status_wise_count, href, doctor_id)
        declined_count, performed_count, advised_count = status_wise_count
        if advised_count > 0
          advised_count = "<a href='#{href}&current_state=advised&operating_doctor_id=#{doctor_id}'
                             data-remote='true'>#{advised_count}</a>"
        end

        if declined_count > 0
          declined_count = "<a href='#{href}&current_state=declined&operating_doctor_id=#{doctor_id}'
                              data-remote='true'>#{declined_count}</a>"
        end

        if performed_count > 0
          performed_count = "<a href='#{href}&current_state=performed&operating_doctor_id=#{doctor_id}'
                               data-remote='true'> #{performed_count}</a>"
        end
        [declined_count, performed_count, advised_count]
      end

      def procedure_appointment_query
        # appointment status wise count
        aggregation_query = [
          { "$match": match_options },
          { "$unwind": '$procedures' },
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
          { "$unwind": '$procedures' },
          { "$project": project_options },
          { "$group": group_options },
          { "$group": { _id: 'null', list_count: { "$sum": 1 } } }
        ]
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { "procedures.advised_at_facility_id": BSON::ObjectId((@mis_params[:facility_id]).to_s) }
                        else
                          { "organisation_id": BSON::ObjectId((@mis_params[:organisation_id]).to_s) }
                        end

        # Date
        match_options = match_options.merge(
          "procedures.advised_datetime": { "$gte": @mis_params[:start_date].beginning_of_day,
                                           "$lte": @mis_params[:end_date].end_of_day }
        )

        match_options
      end

      def group_options
        {
          _id: { advised_by_id: '$procedures.advised_by_id' },
          procedure_state_list: {
            "$push": {  advised_by: '$procedures.advised_by',
                        is_advised: '$procedures.is_advised',
                        has_declined: '$procedures.has_declined',
                        is_performed: '$procedures.is_performed' }
          },
          advised_count: { '$sum': 1 }
        }
      end

      def project_options
        {
          'procedures.advised_by': 1, 'procedures.advised_by_id': 1, 'procedures.is_advised': 1,
          'procedures.has_declined': 1, 'procedures.is_performed': 1
        }
      end
    end
  end
end
