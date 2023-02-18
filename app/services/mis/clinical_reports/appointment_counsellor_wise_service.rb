module Mis::ClinicalReports
  class AppointmentCounsellorWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['COUNSELLOR NAME', 'TOTAL PATIENTS SEEN'] unless @request == 'json'

        aggregation_query, aggregation_query_count = counsellor_workflow_query

        @counsellor_workflows = CounsellorWorkflow.collection.aggregate(aggregation_query).to_a || []
        workflow_count = CounsellorWorkflow.collection.aggregate(aggregation_query_count).to_a
        total_records = workflow_count.count > 0 ? workflow_count[0][:counsellor_workflow_count] : 0

        appointment_user_ids = @counsellor_workflows.map { |appointment| appointment[:_id] }
        get_user_fields(appointment_user_ids) if appointment_user_ids.present? && appointment_user_ids.count > 0

        counsellor_workflow_data

        [@data_array, total_records]
      end

      private

      def counsellor_workflow_data
        @counsellor_workflows.try(:each) do |counsellor_workflow|
          user = @user_fields.find { |f| f[:id].to_s == counsellor_workflow[:_id].to_s }
          next if user.nil?

          fullname = user[:fullname]
          count = counsellor_workflow[:counsellor_appointment_count]

          @data_array << [fullname, count]
        end
      end

      def counsellor_workflow_query
        match_options

        # CounsellorAppointmentList Query
        aggregation_query = [
          { "$match": match_options },
          { "$group": { _id: '$user_id', counsellor_appointment_count: { "$sum": 1 } } },
          { "$sort": { counsellor_appointment_count: -1 } }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # CounsellorAppointmentList Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$group": { _id: '$user_id', counsellor_appointment_count: { "$sum": 1 } } },
          { "$group": { _id: 'null', counsellor_workflow_count: { "$sum": 1 } } }
        ]

        [aggregation_query, aggregation_query_count]
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { facility_id: @mis_params[:facility_id] }
                        else
                          { organisation_id: @mis_params[:organisation_id] }
                        end

        # Date
        match_options = match_options.merge(appointmentdate: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                               "$lte": @mis_params[:end_date].end_of_day })

        # Seen Patients
        match_options = match_options.merge(state: { "$ne": 'deleted' })

        match_options
      end

      def get_user_fields(user_ids)
        users = User.where(:id.in => user_ids)
        @user_fields = users.map { |user| { id: user.id.to_s, fullname: user.fullname } }
      end
    end
  end
end
