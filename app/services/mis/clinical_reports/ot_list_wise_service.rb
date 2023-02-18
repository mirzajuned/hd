# 1  Metrics/AbcSize
# --
# 1  Total
module Mis::ClinicalReports
  class OtListWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        unless @request == 'json'
          @data_array << ['DATE', 'PATIENT NAME', 'AGE/GENDER', 'PATIENT ID', 'ADMISSION ID', 'CURRENT STATE']
        end

        ot_lists = OtListView.collection.aggregate(ot_list_query).to_a[0] || {}

        @ot_lists = ot_lists[:ot_lists]
        total_records = ot_lists[:ot_count].to_i

        ot_list_data

        [@data_array, total_records]
      end

      private

      def ot_list_data(date = '')
        @ot_lists.try(:each) do |ot_list|
          ot_date = ot_list[:ot_date].to_date.try(:strftime, '%d/%m/%Y')
          display_ot_date = date == ot_date ? '' : ot_date

          patient_name = ot_list[:patient_name].to_s
          patient_age =  ot_list[:patient_age].present? ? ot_list[:patient_age].to_s.tr('-', ' ') : '-'
          patient_gender = ot_list[:patient_gender].present? ? ot_list[:patient_gender].to_s : '-'
          patient_age_gender = patient_age + '/' + patient_gender
          patient_display_id = ot_list[:patient_display_id]
          patient_mr_no = ot_list[:patient_mr_no].present? ? '<br/>' + ot_list[:patient_mr_no].to_s : ''
          patient_id = patient_display_id.to_s + patient_mr_no.to_s
          ot_id = ot_list[:ot_display_id]
          ot_state = ot_list[:current_state]

          @data_array << [display_ot_date, patient_name, patient_age_gender, patient_id, ot_id, ot_state]

          date = ot_date
        end
      end

      def ot_list_query
        # OtList Query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { ot_date: -1 } },
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
        match_options = match_options.merge(ot_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                       "$lte": @mis_params[:end_date].end_of_day })

        # State
        state = @mis_params[:current_state]
        match_options = match_options.merge(current_state: state) if state.present?

        # Operating Doctor
        doctor = @mis_params[:operating_doctor_id]
        match_options = match_options.merge(operating_doctor_id: BSON::ObjectId(doctor)) if doctor.present?

        match_options
      end

      def group_options
        { _id: 'null',
          ot_lists: { "$push": { ot_date: '$ot_date', patient_name: '$patient_name',
                                 patient_age: '$patient_age', patient_gender: '$patient_gender',
                                 patient_display_id: '$patient_display_id', patient_mr_no: '$patient_mr_no',
                                 ot_display_id: '$ot_display_id', current_state: '$current_state' } },
          ot_count: { "$sum": 1 } }
      end

      def project_options
        length = @request == 'json' ? @mis_params[:iDisplayLength].to_i : 100000

        # return
        { ot_count: 1,
          ot_lists: { "$slice": ['$ot_lists', @mis_params[:iDisplayStart].to_i, length] } }
      end
    end
  end
end
