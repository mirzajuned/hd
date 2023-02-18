module Mis::ClinicalReports
  class OphthalInvestigationsStateWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        unless @request == 'json'
          @data_array << ['ADVISED DATE', 'PATIENT NAME', 'AGE', 'SEX', 'MOBILE', 'PROCEDURE NAME', 'ADVISED BY',
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
          investigation_name = ap_list[:ophthal_investigations][:investigationname] || '--'
          status = get_status(ap_list[:ophthal_investigations])
          payment_date = if status == 'Declined' && ap_list[:ophthal_investigations][:payment_taken_datetime].present?
                           '--'
                         else
                           list_p = ap_list[:ophthal_investigations][:payment_taken_datetime]
                           list_p&.in_time_zone&.strftime('%d/%m/%Y') || '--'
                         end
          declined_date = if status == 'Paid' && ap_list[:ophthal_investigations][:declined_datetime].present?
                            '--'
                          else
                            list_d = ap_list[:ophthal_investigations][:declined_datetime]
                            list_d&.in_time_zone&.strftime('%d/%m/%Y') || '--'
                          end
          performed_d = ap_list[:ophthal_investigations][:performed_datetime]
          performed_date = performed_d&.in_time_zone&.strftime('%d/%m/%Y') || '--'
          patient_name, age, sex, mobile = make_patient_details(ap_list[:patient_id])
          performed_by = ap_list[:ophthal_investigations][:performed_by] || '--'
          counselled_by = ap_list[:ophthal_investigations][:counselled_by] || '--'
          advised_by = ap_list[:ophthal_investigations][:advised_by] || '--'
          advised_date = ap_list[:ophthal_investigations][:advised_datetime]&.strftime('%d/%m/%Y') || '--'
          age_sex = "#{age}/#{sex}"

          @data_array << unless @request == 'json'
                           [advised_date, patient_name, age, sex, mobile, investigation_name, advised_by, counselled_by,
                            payment_date, declined_date, performed_by, performed_date, status]
                         else
                           [advised_date, patient_name, age_sex, mobile, investigation_name, advised_by, counselled_by,
                            payment_date, declined_date, performed_by, performed_date, status]
                         end
        end
      end

      def make_patient_details(patient_id)
        @patient = Patient.find(patient_id)
        [@patient.fullname, @patient.age, @patient.gender, @patient.mobilenumber]
      end

      def get_status(state)
        status = 'Advised'
        status = 'Agreed' if state[:has_agreed] == true && state[:payment_taken] == false
        status = 'Declined' if state[:has_declined]
        status = 'Paid' if state[:payment_taken]
        status = 'Performed' if state[:is_performed]
        status
      end

      def advised_date_query
        # CounsellorAppointmentList Query
        aggregation_query = [
          { "$match": match_options },
          { "$unwind": '$ophthal_investigations' },
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
          { "$unwind": '$ophthal_investigations' },
          { "$match": match_unwind_options },
          { "$project": project_options },
          { "$group": { _id: 'null', list_count: { "$sum": 1 } } }
        ]
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { "ophthal_investigations.advised_at_facility_id": BSON::ObjectId((@mis_params[:facility_id])
                                                                                              .to_s) }
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

      def match_counselled_date
        {
          "ophthal_investigations.counselled_datetime": { "$gte": @mis_params[:start_date].beginning_of_day,
                                                          "$lte": @mis_params[:end_date].end_of_day }
        }
      end

      def match_advised_date
        {
          "ophthal_investigations.advised_datetime": { "$gte": @mis_params[:start_date].beginning_of_day,
                                                       "$lte": @mis_params[:end_date].end_of_day }
        }
      end

      def counsellors
        { "ophthal_investigations.counselled_by_id": BSON::ObjectId((@mis_params[:counsellor_id]).to_s) }
      end

      def advised_doctors
        { "ophthal_investigations.advised_by_id": BSON::ObjectId((@mis_params[:operating_doctor_id]).to_s) }
      end

      def match_option_for_specific_state(mis_params, match_options)
        # based on state
        case mis_params[:current_state]
        when 'declined'
          match_options.merge("ophthal_investigations.has_declined": true)

        when 'payment_taken'
          match_options.merge("ophthal_investigations.payment_taken": true)

        when 'agreed'
          match_options[:"ophthal_investigations.payment_taken"] = { "$ne": true }
          match_options.merge("ophthal_investigations.has_agreed": true)

        when 'performed'
          match_options.merge("ophthal_investigations.is_performed": true)

        when 'counselled'
          match_options.merge("ophthal_investigations.is_counselled": true)
        else
          match_options
        end
      end

      def project_options
        {

          'ophthal_investigations.advised_datetime': 1,
          'ophthal_investigations.investigationname': 1,
          'ophthal_investigations.is_advised': 1,
          'ophthal_investigations.has_agreed': 1,
          'ophthal_investigations.has_declined': 1,
          'ophthal_investigations.payment_taken': 1,
          'ophthal_investigations.is_performed': 1,
          'ophthal_investigations.payment_taken_datetime': 1,
          'ophthal_investigations.declined_datetime': 1,
          'ophthal_investigations.performed_datetime': 1,
          'ophthal_investigations.counselled_by': 1,
          'ophthal_investigations.advised_by': 1,
          'ophthal_investigations.performed_by': 1,
          'ophthal_investigations.is_performed_outside': 1,
          'ophthal_investigations.performed_outside_by': 1,
          'patient_id': 1
        }
      end
    end
  end
end
