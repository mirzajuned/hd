module Mis::ClinicalService
  class InvestigationQueryBuilder
    class << self
      def call(mis_params, request)
        @mis_params = mis_params
        @request = request
        aggregation_query = [
          { "$match": match_options_query },
          { "$sort": sort_by }
        ]

        if @request == 'json'
          aggregation_query << metadata
        else
          aggregation_query << { "$limit": 5000 }
          aggregation_query << { "$group": group_options }
        end
        aggregation_query
      end

      private

      def metadata
        { "$facet":
          { metadata:
            [{ "$count": 'total' }], data: [{ "$skip": @mis_params[:iDisplayStart].to_i },
                                            { "$limit": @mis_params[:iDisplayLength].to_i }] } }
      end

      def sort_by
        if @mis_params[:investigation_date_wise] == 'performed'
          { performed_at: -1 }
        else
          { advised_at: -1 }
        end
      end

      def match_options_query
        match_options = facility_filter
        match_options[:is_deleted]  = false
        current_state = @mis_params[:investigation_state]

        # Date
        if @mis_params[:investigation_date_wise] == 'performed' && current_state != 'advised'
          match_options = match_options.merge(performed_at: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                              "$lte": @mis_params[:end_date].end_of_day })
        else
          match_options = match_options.merge(advised_at: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                            "$lte": @mis_params[:end_date].end_of_day })
        end
        if current_state.present?
          if current_state == 'advised'
            match_options = match_options.merge({ performed_at: nil, removed_at: nil })
          elsif current_state == 'performed' && @mis_params[:investigation_date_wise] != 'performed'
            match_options = match_options.merge({ performed_at: { "$ne": nil }, removed_at: nil })
          elsif current_state == 'removed'
            match_options = match_options.merge({ removed_at: { "$ne": nil } })
          end
        end

        if @mis_params[:initial_age].present? && @mis_params[:final_age].present? && @mis_params[:final_age].to_i != 0
          match_options = if @mis_params[:initial_age] == 0
                            match_options.merge(patient_age: { "$lte": @mis_params[:final_age].to_i })
                          else
                            match_options.merge(patient_age: { "$gte": @mis_params[:initial_age].to_i,
                                                               "$lte": @mis_params[:final_age].to_i })
                          end
        end

        if @mis_params[:final_age].present? && (@mis_params[:final_age] == 'undefined' || @mis_params[:final_age] == 0)
          match_options = match_options.merge(patient_age: nil)
        end
        # gender type
        gender = @mis_params[:gender_type]
        if gender.present? && gender != 'undefined'
          match_options = match_options.merge(patient_gender: (@mis_params[:gender_type]).to_s)
        end

        match_options = match_options.merge(patient_gender: nil) if gender.present? && gender == 'undefined'
        if @mis_params[:performed_by].present?
          performed_by = @mis_params[:performed_by]
          match_options = match_options.merge(performed_by: BSON::ObjectId(performed_by))
        end
        if @mis_params[:investigation_type].present?
          match_options[:_type] = @mis_params[:investigation_type]
        end
        if @mis_params[:performed_at].present?
          if @mis_params[:performed_at] == 'outside'
            match_options = match_options.merge(performed_outside: true)
          elsif @mis_params[:performed_at] == 'inside' && @mis_params[:investigation_date_wise] != 'performed'
            match_options = match_options.merge(performed_outside: nil, performed_at: { "$ne": nil })
          else
            match_options[:performed_outside] = nil
          end
        end
        if @mis_params[:investigation_id].present?
          match_options[:investigation_id] = @mis_params[:investigation_id]
        end
        match_options[:advised_by] = BSON::ObjectId(@mis_params[:advised_by]) if @mis_params[:advised_by].present?
        match_options
      end

      def facility_filter
        if @mis_params[:facility_id].present?
          { facility_id: BSON::ObjectId(@mis_params[:facility_id]) }
        else
          facilities_ids = Organisation.find_by(id: BSON::ObjectId(@mis_params[:organisation_id]))
                                       .facilities
                                       .pluck(:id)
          { facility_id: { "$in": facilities_ids } }
        end
        
      end

      def group_options
        { _id: 'null',
          data: { "$push": '$$ROOT' },
          total: { "$sum": 1 } }
      end
    end
  end
end
