module Mis::ClinicalService
  class AdvisedProcedureQueryBuilder
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
          aggregation_query << { "$facet": { metadata: [{ "$count": 'total' }], data: [{ "$skip": @mis_params[:iDisplayStart].to_i }, { "$limit": @mis_params[:iDisplayLength].to_i }] } }
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
        match_options = match_options.merge('procedure_date': { "$gte": @mis_params[:start_date].beginning_of_day,
        "$lte": @mis_params[:end_date].end_of_day })
        # Date
        match_options
      end

      # def group_options
      #   { _id: '$procedure_date',
      #     total_advised: { "$sum": "$total_advised" },
      #     total_performed: { "$sum": "$total_performed" },
      #     performed_from_advised: { "$sum": "$performed_from_advised" },
      #     conversion_time_days_avg: { "$sum": "$conversion_time_days_avg" },
      #     conversion_time_days_total: { "$sum": "$conversion_time_days_total" },
      #     time_performed_from_advised: { "$sum": "time_performed_from_advised" }
      #   }
      # end

      def group_options
        { _id: '$procedure_date',
          data: { "$push": '$$ROOT' },
          total: { "$sum": 1 } }
      end
    end
  end
end
