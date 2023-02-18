module Mis::ClinicalService
  class InpatientQueryBuilder
    class << self
      def call(mis_params, request)
        @mis_params = mis_params
        @request = request
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { admission_date: -1 } }
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
                          { organisation_id: BSON::ObjectId(@mis_params[:organisation_id]) }
                        end

        # Date
        if @mis_params[:date_wise] == 'Discharged'
          match_options = match_options.merge(discharge_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                                "$lte": @mis_params[:end_date].end_of_day })
        elsif @mis_params[:date_wise] == 'Scheduled'
          match_options = match_options.merge(scheduled_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                                "$lte": @mis_params[:end_date].end_of_day })
        else
          match_options = match_options.merge(admission_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                                "$lte": @mis_params[:end_date].end_of_day })
        end

        # state
        current_state = @mis_params[:ipd_current_status]
        capture_state = @mis_params[:capture_state]
        if current_state.present? && !capture_state.present?
          match_options = match_options.merge(current_state: current_state)
        end
        if !current_state.present? && capture_state.present?
          match_options[:current_state] = if capture_state == 'Admitted'
                                            { "$in": ['Discharged', 'Admitted'] }
                                          elsif capture_state == 'Discharged'
                                            { "$in": ['Discharged'] }
                                          else
                                            { "$ne": 'Cancelled' }
                                          end
        end

        moh = @mis_params[:moh]
        match_options = match_options.merge(mode_of_hospitalization: moh) if moh.present?

        if @mis_params[:initial_age].present? && @mis_params[:final_age].present? && @mis_params[:final_age].to_i != 0
          match_options = match_options.merge('patient_details.age': { "$gte": @mis_params[:initial_age].to_i, "$lte": @mis_params[:final_age].to_i })
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

        doctor = @mis_params[:consulting_doctor]
        match_options = match_options.merge(admitting_doctor_id: BSON::ObjectId(doctor)) if doctor.present?

        admission_type = @mis_params[:admission_type]
        match_options = match_options.merge(admission_type: admission_type) if admission_type.present?
        location_type = @mis_params[:location_type]
        loc_name = @mis_params[:loc_name]
        if location_type.present? || loc_name.present?
          match_options = case location_type
                          when 'city'
                            match_options = match_options.merge('patient_details.city': loc_name.to_s)
                          when 'state'
                            match_options = match_options.merge('patient_details.state': loc_name.to_s)
                          when 'commune'
                            match_options = match_options.merge('patient_details.commune': loc_name.to_s)
                          when 'district'
                            match_options = match_options.merge('patient_details.district': loc_name.to_s)
                          end
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
