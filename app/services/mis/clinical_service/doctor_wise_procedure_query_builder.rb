module Mis::ClinicalService
  class DoctorWiseProcedureQueryBuilder
    class << self
      def call(mis_params, request)
        @mis_params = mis_params
        @request = request

        aggregation_query = [
          { "$match": match_options },
          { "$group": group_options },
          { "$sort": { '_id': -1 } }
        ]
        if @request == 'json'
          aggregation_query << { "$facet": {
            metadata: [{ "$count": 'total' }],
            data: [{ "$skip": @mis_params[:iDisplayStart].to_i }, { "$limit": @mis_params[:iDisplayLength].to_i }]
          } }
        end
        aggregation_query
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { facility_id: BSON::ObjectId(@mis_params[:facility_id]) }
                        else
                          facilities_ids = Organisation.find_by(id: BSON::ObjectId(@mis_params[:organisation_id]))
                                                       .facilities
                                                       .pluck(:id)
                          { facility_id: { "$in": facilities_ids } }
                        end
        # Date
        match_options[:procedure_date] = { "$gte": @mis_params[:start_date].beginning_of_day,
                                           "$lte": @mis_params[:end_date].end_of_day }

        # Doctor
        match_options[:user_id] = @mis_params[:consulting_doctor] if @mis_params[:consulting_doctor].present?
        match_options
      end

      def group_options
        { _id: '$procedure_date',
          procedure_list: { "$push": '$$ROOT' },
          procedure_count: { "$sum": 1 } }
      end
    end
  end
end
