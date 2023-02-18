# rubocop:disable all
module Mis::ClinicalService
  class VisionImprovementQueryBuilder
    class << self
      def call(mis_params, request)
        @mis_params = mis_params
        @request = request
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { 'filtering_fields.appointment_date': -1 } }
        ]
        if @request == 'json'
          aggregation_query <<  { "$facet":    { metadata: [ { "$count": "total" } ], data: [ { "$skip":  @mis_params[:iDisplayStart].to_i }, { "$limit":  @mis_params[:iDisplayLength].to_i } ] } } 
        else
          aggregation_query << { "$limit": 5000 }
          aggregation_query << {"$group": group_options }
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
        match_options = match_options.merge('filtering_fields.appointment_date': { "$gte": @mis_params[:start_date].beginning_of_day,
        "$lte": @mis_params[:end_date].end_of_day })
        #
        # Patient Type
        patient_type = @mis_params[:patient_type]
        match_options = match_options.merge('filtering_fields.patient_type': patient_type) if patient_type.present?

        # Appointment Category
        appointment_type = @mis_params[:appointment_type]
        if appointment_type.present?
          appointment_type_arr = appointment_type.split(',')
          match_options = match_options.merge('filtering_fields.appointment_type': { "$in": appointment_type_arr })
        end
        #
        # AppointmentType
        appointmenttype = @mis_params[:appointmenttype]
        if appointmenttype.present?
          match_options = match_options.merge('filtering_fields.appointmenttype': appointmenttype)
        end
        #
        # patient visit
        patient_visit = @mis_params[:patient_visit]
        match_options = match_options.merge('filtering_fields.patient_visit': patient_visit) if patient_visit.present?

        # state
        current_state = @mis_params[:current_state]
        if current_state.present?
          current_state = map_current_state(current_state)
          match_options = match_options.merge('appointment_display_fields.current_state': { "$in": current_state })
        end

        appointmenttype = @mis_params[:appointmenttype]
        if appointmenttype.present?
          match_options = match_options.merge('filtering_fields.appointmenttype': appointmenttype)
        end
        if @mis_params[:referral_type_id].present?
          match_options = match_options.merge('filtering_fields.referral_type_id': @mis_params[:referral_type_id])
        end


        if @mis_params[:initial_age].present? && @mis_params[:final_age].present? && @mis_params[:final_age].to_i != 0
          match_options = match_options.merge('filtering_fields.age': { "$gte": @mis_params[:initial_age].to_i, "$lte": @mis_params[:final_age].to_i })
        end

        if @mis_params[:final_age].present? && (@mis_params[:final_age] == 'undefined' || @mis_params[:final_age] == 0)
          match_options = match_options.merge('filtering_fields.age': nil)
        end
        # gender type
        gender = @mis_params[:gender_type]
        if gender.present? && gender != 'undefined'
          match_options = match_options.merge('filtering_fields.patient_gender': (@mis_params[:gender_type]).to_s)
        end

        if gender.present? && gender == 'undefined'
          match_options = match_options.merge('filtering_fields.patient_gender': nil)
        end

        doctor = @mis_params[:consulting_doctor]
        match_options = match_options.merge('filtering_fields.doctor_ids': { "$in": [doctor] }) if doctor.present?

        location_type = @mis_params[:location_type]
        loc_name = @mis_params[:loc_name]
        if location_type.present? || loc_name.present?
          match_options = case location_type
                            when 'city'
                              match_options = match_options.merge('filtering_fields.city': loc_name.to_s)
                            when 'state'
                              match_options = match_options.merge('filtering_fields.state': loc_name.to_s)
                            when 'commune'
                              match_options = match_options.merge('filtering_fields.commune': loc_name.to_s)
                            when 'district'
                              match_options = match_options.merge('filtering_fields.district': loc_name.to_s)
                          end
        end
        match_options
      end

      def group_options
        { _id: 'null',
          data: { "$push": '$$ROOT' },
          total: { "$sum": 1 }
        }
      end


      def map_current_state(state)
        current_state = {
          "Scheduled": ['Scheduled'],
          "Completed": ['Completed'],
          "Incompleted": ['Incompleted', 'Waiting', 'Engaged'],
          "Deleted": ['Deleted']
        }
        current_state[state.to_sym]
      end
    end
  end
end
