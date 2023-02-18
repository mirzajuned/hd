module Mis::ClinicalReports
  class AdvisedDateWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        unless @request == 'json'
          @data_array << ['ADVISED DATE', 'PATIENT NAME', 'AGE(IN YEARS)', 'SEX', 'MOBILE', 'PROCEDURE NAME', 'ADVISED BY',
                          'COUNSELLED_BY', 'DECLINED DATE', 'PAYMENT DATE', 'PERFORMED BY', 'PERFORMED DATE', 'STATUS']
        end
        aggregation_query, aggregation_query_count = advised_date_query
        @advised_appointment_lists = CaseSheet.collection.aggregate(aggregation_query).to_a || []
        query_count = CaseSheet.collection.aggregate(aggregation_query_count).to_a || []
        total_records = query_count.count > 0 ? query_count[0][:list_count] : 0

        advised_appointment_list_data
        [@data_array, total_records]
      end

      private

      def advised_appointment_list_data
        @advised_appointment_lists&.each do |ap_list|
          procedure_name = ap_list[:procedures][:procedurename] || '--'
          status = get_status(ap_list[:procedures])
          payment_date = if status == 'Declined' && ap_list[:procedures][:payment_taken_datetime].present?
                           '--'
                         else
                           ap_list[:procedures][:payment_taken_datetime]&.in_time_zone&.strftime('%d/%m/%Y') || '--'
                         end

          declined_date = if status == 'Paid' && ap_list[:procedures][:declined_datetime].present?
                            '--'
                          else
                            ap_list[:procedures][:declined_datetime]&.in_time_zone&.strftime('%d/%m/%Y') || '--'
                          end
          patient_name, age, sex, mobile = make_patient_details(ap_list[:patient_id])
          performed_date = ap_list[:procedures][:performed_datetime]&.in_time_zone&.strftime('%d/%m/%Y') || '--'
          performed_by = ap_list[:procedures][:performed_by] || '--'
          counselled_by = ap_list[:procedures][:counselled_by] || '--'
          advised_by = ap_list[:procedures][:advised_by] || '--'
          advised_date = ap_list[:procedures][:advised_datetime]&.strftime('%d/%m/%Y') || '--'
          age_sex = "#{age}/#{sex}"

          @data_array << unless @request == 'json'
                           [advised_date, patient_name, age, sex, mobile, procedure_name, advised_by, counselled_by,
                            declined_date, payment_date, performed_by, performed_date, status]
                         else
                           [advised_date, patient_name, age_sex, mobile, procedure_name, advised_by, counselled_by,
                            declined_date, payment_date, performed_by, performed_date, status]
                         end
        end
      end

      def get_status(state)
        status = 'Advised'
        status = 'Agreed' if state[:has_agreed] == true && state[:payment_taken] == false
        status = 'Declined' if state[:has_declined]
        status = 'Paid' if state[:payment_taken]
        status = 'Performed' if state[:is_performed]
        status
      end

      def make_patient_details(patient_id)
        @patient = Patient.find(patient_id)
        [@patient.fullname, @patient.age, @patient.gender, @patient.mobilenumber]
      end

      def advised_date_query
        # CounsellorAppointmentList Query
        aggregation_query = [
          { "$match": match_options },
          { "$unwind": '$procedures' },
          { "$match": match_unwind_options },
          { "$project": project_options }
        ]
        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'
        [aggregation_query, aggregation_query_count_params]
      end

      def aggregation_query_count_params
        [
          { "$match": match_options },
          { "$unwind": '$procedures' },
          { "$match": match_unwind_options },
          { "$project": project_options },
          { "$group": { _id: 'null', list_count: { "$sum": 1 } } }
        ]
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { "procedures.advised_at_facility_id": BSON::ObjectId((@mis_params[:facility_id]).to_s) }
                        else
                          { "organisation_id": BSON::ObjectId((@mis_params[:organisation_id]).to_s) }
                        end

        # Date
        match_options = match_date(match_options)
        match_options
      end

      def match_unwind_options
        match_options = {}
        match_options = match_date(match_options)

        if @mis_params[:current_state].present?
          match_options = match_option_for_specific_state(@mis_params, match_options)
        end
        match_options.merge!(advised_doctors) unless @mis_params[:operating_doctor_id].blank?
        match_options.merge!(counsellors) unless @mis_params[:counsellor_id].blank?
        match_options
      end

      def match_date(match_options)
        match_options.merge!(!@mis_params[:counsellor_id].blank? ? match_counselled_date : match_advised_date)
      end

      def match_advised_date
        {
          "procedures.advised_datetime": { "$gte": @mis_params[:start_date].beginning_of_day,
                                           "$lte": @mis_params[:end_date].end_of_day }
        }
      end

      def match_counselled_date
        {
          "procedures.counselled_datetime": { "$gte": @mis_params[:start_date].beginning_of_day,
                                              "$lte": @mis_params[:end_date].end_of_day }
        }
      end

      def counsellors
        { "procedures.counselled_by_id": BSON::ObjectId((@mis_params[:counsellor_id]).to_s) }
      end

      def advised_doctors
        { "procedures.advised_by_id": BSON::ObjectId((@mis_params[:operating_doctor_id]).to_s) }
      end

      def match_option_for_specific_state(mis_params, match_options)
        # based on state
        case mis_params[:current_state]
        when 'declined'
          match_options.merge("procedures.has_declined": true)

        when 'payment_taken'
          match_options.merge("procedures.payment_taken": true)

        when 'agreed'
          match_options[:"procedures.payment_taken"] = { "$ne": true }
          match_options.merge("procedures.has_agreed": true)

        when 'performed'
          match_options.merge("procedures.is_performed": true)

        when 'counselled'
          match_options.merge("procedures.is_counselled": true)
        else
          match_options
        end
      end

      def project_options
        {
          'procedures.advised_datetime': 1,
          'procedures.procedurename': 1,
          'procedures.is_advised': 1,
          'procedures.has_agreed': 1,
          'procedures.has_declined': 1,
          'procedures.payment_taken': 1,
          'procedures.is_performed': 1,
          'procedures.payment_taken_datetime': 1,
          'procedures.declined_datetime': 1,
          'procedures.performed_datetime': 1,
          'procedures.counselled_by': 1,
          'procedures.advised_by': 1,
          'procedures.performed_by': 1,
          'patient_id': 1
        }
      end
    end
  end
end
