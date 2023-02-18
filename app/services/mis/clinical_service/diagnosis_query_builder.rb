module Mis::ClinicalService
  class DiagnosisQueryBuilder
    class << self
      def call(mis_params, request, is_aggregate)
        @mis_params = mis_params
        @request = request
        @is_aggregate = is_aggregate
        sort_query = (@is_aggregate == true) ? ({ "$sort": { '_id': 1 } }) : ({ "$sort": { '_id': -1 } })

        aggregation_query = [
          { "$match": match_options },
          { "$group": group_options },
          sort_query
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
        match_options = match_options.merge('diagnosis_date': { "$gte": @mis_params[:start_date].beginning_of_day,
                                                                "$lte": @mis_params[:end_date].end_of_day })
        # Date
        match_options
      end

      def group_options
        if @is_aggregate == true
          group_hash = { _id: '$diagnosis_original_name', data: { "$push": '$$ROOT' }, total: { "$sum": 1 } }
        else
          group_hash = { _id: '$diagnosis_date', data: { "$push": '$$ROOT' }, total: { "$sum": 1 } }
        end
        group_hash
      end
    end
  end
end
