module Mis::ClinicalService
  class PerformedInvestigationQueryBuilder
    class << self
      def call(mis_params, request, type = 'data')
        @mis_params = mis_params
        @request = request
        send("#{type}_query")
      end

      def count_query
        aggregation_query = [
          { "$match": match_options }
        ]
        aggregation_query + [{ "$group": group_options }]
      end

      def data_query
        aggregation_query = [
          { "$match": match_options },
          { "$group": group_options },
          { "$sort": { '_id.investigation_date': -1, '_id.investigation_type': 1 } }
        ]

        if @request == 'json'
          aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i }
          aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i }
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
        match_options.merge('investigation_date': { "$gte": @mis_params[:start_date].beginning_of_day,
                                                    "$lte": @mis_params[:end_date].end_of_day })
      end

      def group_options
        { _id: { investigation_date: '$investigation_date', investigation_type: '$investigation_type' },
          total_advised: { '$sum': '$total_advised' },
          total_performed: { '$sum': '$total_performed' }
          }
      end
    end
  end
end
