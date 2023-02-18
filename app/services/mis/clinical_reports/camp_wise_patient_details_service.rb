module Mis::ClinicalReports
  class CampWisePatientDetailsService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['ARRIVAL DATE', 'CAMP', 'CAMP PATIENT ID', 'FULLNAME', 'PHONE', 'AGE', 'GENDER', 'DIAGNOSIS'] unless @request == 'json'

        aggregation_query = patient_list_query
        patient_list = CampPatient.collection.aggregate(aggregation_query).to_a || []
        @patient = patient_list
        if patient_list.present?
          total_records = patient_list[0][:count].to_i
          patient_list_data
        else
          total_records = 0
        end

        [@data_array, total_records]
      end

      private

      def patient_list_data
        @patient[0][:patient_lists].each do |patient|
          camp_name = patient[:camp_name]
          camp_patient_id = patient[:camp_patient_identifier]
          patient_name = patient[:fullname]
          gender = patient[:gender]
          age = patient[:age]
          arrival_date = patient[:created_at]&.strftime("%d/%m/%Y")
          phone = patient[:phone_number]
          diagnosis = "R-#{patient[:diagnosis_r]}, L-#{patient[:diagnosis_l]}"
          @data_array << [arrival_date, camp_name, camp_patient_id, patient_name, phone, age, gender, diagnosis]
        end
      end

      def patient_list_query
        # PatientType Query
        aggregation_query = [
          { "$match": match_options },
          { "$limit": 100000 },
          { "$group": group_options },
          { "$project": project_options }
        ]
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { facility_id: BSON::ObjectId(@mis_params[:facility_id]) }
                        else
                          { organisation_id: BSON::ObjectId(@mis_params[:organisation_id]) }
                        end

        match_options = match_options.merge(created_at: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                          "$lte": @mis_params[:end_date].end_of_day })
        if @mis_params[:camp_username].present?
          match_options = match_options.merge(camp_username: @mis_params[:camp_username])
        end
        if @mis_params[:current_state].present?
          if @mis_params[:current_state] == 'converted'
            match_options = match_options.merge(converted: true)
          else
            match_options = match_options.merge(converted: { "$nin": [true] })
          end
        end
        match_options
      end

      def group_options
        { _id: 'null',
          patient_lists: { "$push": { camp_name: '$camp_name', outreach_patient_id: '$outreach_patient_id',
                                      camp_patient_identifier: '$camp_patient_identifier', fullname: '$fullname',
                                      converted: '$converted', gender: '$gender', age: '$age', created_at: '$created_at',
                                      diagnosis_r: '$diagnosis_r', diagnosis_l: '$diagnosis_l',
                                      phone_number: '$phone_number' } },
          count: { '$sum': 1 } }
      end

      def project_options
        length = @request == 'json' ? @mis_params[:iDisplayLength].to_i : 100000

        # return
        { count: 1,
          patient_lists: { "$slice": ['$patient_lists', @mis_params[:iDisplayStart].to_i, length] } }
      end
    end
  end
end
