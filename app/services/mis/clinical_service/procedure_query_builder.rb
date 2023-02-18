module Mis::ClinicalService
  class ProcedureQueryBuilder
    class << self
      def call(mis_params, request)
        @mis_params = mis_params
        @request = request
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { advised_datetime: -1 } }
        ]
        if @request == 'json'
          aggregation_query << { "$facet": { metadata: [{ "$count": 'total' }], data: [{ "$skip": @mis_params[:iDisplayStart].to_i }, { "$limit": @mis_params[:iDisplayLength].to_i }] } }
        end
        if @request != 'json'
          aggregation_query << { "$limit": 5000 }
          aggregation_query << { "$group": group_options }
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
        if @mis_params[:procedure_date_wise] == 'performed'
          match_options = match_options.merge(performed_datetime: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                                    "$lte": @mis_params[:end_date].end_of_day })
        else
          match_options = match_options.merge(advised_datetime: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                                  "$lte": @mis_params[:end_date].end_of_day })
        end

        # state
        current_state = @mis_params[:procedure_state]

        if current_state.present?
          current_state_hash = if current_state == 'advised'
                                 { is_advised: true, is_performed: false }
                               elsif current_state == 'performed'
                                 { is_advised: true, is_performed: true }
                               else
                                 { is_advised: true }
                               end
          match_options = match_options.merge(current_state_hash)
        end

        if @mis_params[:procedure_id].present?
          procedure_id = @mis_params[:procedure_id]
          match_options.merge!(procedure_id: procedure_id)
        end
        
        if @mis_params[:initial_age].present? && @mis_params[:final_age].present? && @mis_params[:final_age].to_i != 0
          if @mis_params[:initial_age] == 0
            match_options = match_options.merge('patient_details.age': { "$lte": @mis_params[:final_age].to_i })
          else
            match_options = match_options.merge('patient_details.age': { "$gte": @mis_params[:initial_age].to_i, "$lte": @mis_params[:final_age].to_i })
          end
        end

        if @mis_params[:final_age].present? && (@mis_params[:final_age] == 'undefined' || @mis_params[:final_age] == 0)
          match_options = match_options.merge('patient_details.age': nil)
        end
        # gender type
        gender = @mis_params[:gender_type]
        if gender.present? && gender != 'undefined'
          match_options = match_options.merge('patient_details.patient_gender': (@mis_params[:gender_type]).to_s)
        end

        if gender.present? && gender == 'undefined'
          match_options = match_options.merge('patient_details.patient_gender': nil)
        end
        if @mis_params[:advised_by].present?
          advised_by = @mis_params[:advised_by]
          match_options = match_options.merge(advised_by_id: BSON::ObjectId(advised_by))
        end
        if @mis_params[:performed_by].present?
          performed_by = @mis_params[:performed_by]
          match_options = match_options.merge(performed_by_id: BSON::ObjectId(performed_by))
        end

        match_options
      end

      def group_options
        { _id: 'null',
          data: { "$push": '$$ROOT' },
          total: { "$sum": 1 } }
      end
    end
  end
end
