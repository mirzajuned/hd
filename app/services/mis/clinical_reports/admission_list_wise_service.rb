# 2  Metrics/AbcSize
# 2  Metrics/MethodLength
# 1  Metrics/PerceivedComplexity
# --
# 5  Total
module Mis::ClinicalReports
  class AdmissionListWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @loction_type = mis_params[:loc_type].blank? ? 'city' : mis_params[:loc_type]
        @data_array = []

        unless @request == 'json'
          @data_array << ['DATE', 'PATIENT NAME', 'MOBILE', 'AGE/GENDER', 'PATIENT ID', 'ADMISSION ID', 'CURRENT STATE',
                          @loction_type.upcase]
        end

        admission_lists = AdmissionListView.collection.aggregate(admission_list_query).to_a[0] || {}

        @admission_lists = admission_lists[:admission_lists]
        total_records = admission_lists[:admission_count].to_i

        admission_list_data

        [@data_array, total_records]
      end

      private

      def admission_list_data(_date = '')
        @total_records_for_age = 0
        @admission_lists.try(:each) do |admission_list|
          admission_date = if admission_list[:current_state] == 'Discharged'
                             admission_list[:discharge_date].to_date.try(:strftime, '%d/%m/%Y')
                           else
                             admission_list[:admission_date].to_date.try(:strftime, '%d/%m/%Y')
                           end

          patient_name = admission_list[:patient_name].to_s
          patient_age = admission_list[:patient_age].present? ? admission_list[:patient_age].to_s.tr('-', ' ') : '-'
          patient_gender = admission_list[:patient_gender].present? ? admission_list[:patient_gender].to_s : '-'
          patient_age_gender = patient_age + '/' + patient_gender
          patient_display_id = admission_list[:patient_display_id]
          patient_mr_no = admission_list[:patient_mr_no].present? ? "<br/>#{admission_list[:patient_mr_no]}" : ''
          patient_id = patient_display_id.to_s + patient_mr_no.to_s
          admission_id = admission_list[:admission_display_id]
          mobile = admission_list[:mobilenumber] || '--'
          admission_state = admission_list[:current_state]
          admission_location = admission_list[:loc_type].present? ? admission_list[:loc_type] : '--'

          @data_array << [admission_date, patient_name, mobile, patient_age_gender,
                          patient_id, admission_id, admission_state, admission_location]
          date = admission_date
        end
      end

      def admission_list_query
        # AdmissionList Query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { admission_date: -1 } },
          { "$limit": 100000 },
          { "$group": group_options },
          { "$project": project_options }
        ]
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
        date_range_hash = { "$gte": @mis_params[:start_date].beginning_of_day,
                            "$lte": @mis_params[:end_date].end_of_day }
        if @mis_params[:current_state].present?
          match_options = if @mis_params[:current_state] == 'Discharged'
                            match_options.merge(discharge_date: date_range_hash)
                          else
                            match_options.merge(admission_date: date_range_hash)
                          end
          # State
          match_options = match_options.merge(current_state: @mis_params[:current_state])
        else
          match_options = match_options.merge(
            "$or": [{ admission_date: date_range_hash, current_state: { "$ne": 'Discharged' } },
                    { discharge_date: date_range_hash, current_state: 'Discharged' }]
          )
        end

        # Insurance
        insurance_state = @mis_params[:insurance_state]
        match_options = match_options.merge(insurance_state: insurance_state) if insurance_state.present?

        # Admitting Doctor
        doctor = @mis_params[:admitting_doctor_id]
        match_options = match_options.merge(admitting_doctor_id: BSON::ObjectId(doctor)) if doctor.present?

        # location type
        location_type = @mis_params[:loc_type]
        match_options = match_options.merge(@mis_params[:loc_type].to_sym => @mis_params[:loc]) if location_type.present?

        # age type
        if @mis_params[:age_type].present? && @mis_params[:age_type] == 'nil_count'
          match_options = match_options.merge(age: nil)
        end

        if @mis_params[:age_type].present? && @mis_params[:age_type] == 'zero_plus'
          match_options = match_options.merge(age: { "$gte": 0, "$lte": 19 })
        end

        if @mis_params[:age_type].present? && @mis_params[:age_type] == 'twenty_plus'
          match_options = match_options.merge(age: { "$gte": 20, "$lte": 39 })
        end

        if @mis_params[:age_type].present? && @mis_params[:age_type] == 'forty_plus'
          match_options = match_options.merge(age: { "$gte": 40, "$lte": 59 })
        end

        if @mis_params[:age_type].present? && @mis_params[:age_type] == 'sixty_plus'
          match_options = match_options.merge(age: { "$gte": 60, "$lte": 110 })
        end
        # gender type
        apt_status = @mis_params[:gender_type]
        match_options = match_options.merge(patient_gender: (@mis_params[:gender_type]).to_s) if apt_status.present?

        match_options
      end

      def group_options
        { _id: 'null',
          admission_lists: { "$push": { admission_date: '$admission_date', discharge_date: '$discharge_date',
                                        patient_name: '$patient_name', patient_age: '$patient_age',
                                        patient_gender: '$patient_gender', patient_display_id: '$patient_display_id',
                                        patient_mr_no: '$patient_mr_no', admission_display_id: '$admission_display_id',
                                        current_state: '$current_state', loc_type: "$#{@loction_type}",
                                        mobilenumber: '$patient_mobilenumber' } },
          admission_count: { "$sum": 1 } }
      end

      def project_options
        length = @request == 'json' ? @mis_params[:iDisplayLength].to_i : 100000

        # return
        { admission_count: 1,
          admission_lists: { "$slice": ['$admission_lists', @mis_params[:iDisplayStart].to_i, length] } }
      end
    end
  end
end
