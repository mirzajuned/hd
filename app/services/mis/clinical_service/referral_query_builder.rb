module Mis::ClinicalService
  class ReferralQueryBuilder
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
                          { organisation_id: BSON::ObjectId(@mis_params[:organisation_id]) }
                        end
        match_options = match_options.merge('created_date': { "$gte": @mis_params[:start_date].beginning_of_day,
                                                              "$lte": @mis_params[:end_date].end_of_day })
        match_options
      end

      def group_options
        { _id: '$created_date',
          opd_list: { "$push": '$$ROOT' },
          opd_count: { "$sum": 1 } }
      end
    end
  end
end
