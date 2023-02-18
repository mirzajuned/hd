# 1  Metrics/CyclomaticComplexity
# 1  Metrics/MethodLength
# --
# 2  Total
module Mis::ClinicalReports
  class AppointmentOptometristWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['OPTOMETRIST NAME', 'TOTAL PATIENTS SEEN'] unless @request == 'json'

        aggregation_query, aggregation_query_count = clinical_workflow_query

        @clinical_workflows = OpdClinicalWorkflow.collection.aggregate(aggregation_query).to_a || []
        clinical_workflow_count = OpdClinicalWorkflow.collection.aggregate(aggregation_query_count).to_a
        total_records = (clinical_workflow_count[0][:clinical_workflow_count] if clinical_workflow_count.count > 0) || 0

        appointment_user_ids = @clinical_workflows.map { |appointment| appointment[:_id] }
        get_user_fields(appointment_user_ids) if appointment_user_ids.present? && appointment_user_ids.count > 0

        clinical_workflow_data

        [@data_array, total_records]
      end

      private

      def clinical_workflow_data
        @clinical_workflows.try(:each) do |clinical_workflow|
          user = @user_fields.find { |f| f[:id].to_s == clinical_workflow[:_id].to_s }

          if user.present?
            fullname = user[:fullname]
            count = clinical_workflow[:optometrist_appointment_count]

            @data_array << [fullname, count]
          end
        end
      end

      def clinical_workflow_query
        # OptometristAppointmentList Query
        aggregation_query = [
          { "$match": match_options },
          { "$project": { _id: 0, optometrist_ids: 1 } },
          { "$unwind": '$optometrist_ids' },
          { "$group": { _id: '$optometrist_ids', optometrist_appointment_count: { "$sum": 1 } } },
          { "$sort": { optometrist_appointment_count: -1 } }
        ]

        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # OptometristAppointmentList Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$project": { _id: 0, optometrist_ids: 1 } },
          { "$unwind": '$optometrist_ids' },
          { "$group": { _id: '$optometrist_ids', optometrist_appointment_count: { "$sum": 1 } } },
          { "$group": { _id: 'null', clinical_workflow_count: { "$sum": 1 } } }
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
        match_options = match_options.merge(state: { "$nin": ['not_arrived', 'cancelled'] })

        match_options
      end

      def get_user_fields(user_ids)
        users = User.where(:id.in => user_ids)
        @user_fields = users.map { |user| { id: user.id.to_s, fullname: user.fullname } }
      end
    end
  end
end
