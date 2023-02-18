module Mis::ClinicalService
  class CumulativeDoctorProcedureQueryBuilder
    class << self
      def call(mis_params, request)
        @mis_params = mis_params
        @request = request
        @mis_query_logger = Logger.new("#{Rails.root}/log/mis_query_logger.log")

        aggregation_query = [
          { "$match": match_options },
          { "$group": group_options },
          { "$sort": { '_id': 1 } }
        ]
        if @request == 'json'
          aggregation_query << { "$facet": { metadata: [{ "$count": 'total' }], data: [{ "$skip": @mis_params[:iDisplayStart].to_i }, { "$limit": @mis_params[:iDisplayLength].to_i }] } }
        end
        @mis_query_logger.info(" ============ aggregation_query: #{aggregation_query.inspect}")
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
        match_options = match_options.merge('procedure_date': { "$gte": @mis_params[:start_date].beginning_of_day,
                                                                "$lte": @mis_params[:end_date].end_of_day })
        # Doctor
        match_options[:user_id] = @mis_params[:consulting_doctor] if @mis_params[:consulting_doctor].present?
        @mis_query_logger.info(" ============ match_options: #{match_options.inspect}")
        match_options
      end

      # def group_options
      #   { _id: '$user_id',
      #     total_advised: { "$sum": '$total_advised' },
      #     performed_from_advised: { "$sum": '$performed_from_advised' },
      #     total_performed_by_self: { "$sum": '$total_performed_by_self' },
      #     total_performed_by_other: { "$sum": '$total_performed_by_other' } }
      # end

      def group_options
        { _id: '$user_id',
          data: { "$push": '$$ROOT' },
          total: { "$sum": 1 } }
      end
    end
  end
end
