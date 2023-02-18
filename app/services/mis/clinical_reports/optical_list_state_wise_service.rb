module Mis::ClinicalReports
  class OpticalListStateWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        @data_array << ['DATE', 'STATUS', 'PATIENT ID', 'PATIENT NAME', 'MOBILE', 'ADVISED BY', 'CONVERTED BY', 'STORE NAME', 'COMMENT'] unless @request == 'json'

        aggregation_query, aggregation_query_count = appointment_list_query

        @pharmacy_lists = PatientOpticalPrescription.collection.aggregate(aggregation_query).to_a || []
        pharmacy_list_count = PatientOpticalPrescription.collection.aggregate(aggregation_query_count).to_a
        total_records = (pharmacy_list_count[0][:pharmacy_list_count] if pharmacy_list_count.count > 0) || 0

        pharmacy_list_data

        [@data_array, total_records]
      end

      private

      def pharmacy_list_data
        @pharmacy_lists.try(:each) do |list|
          date = list[:date].to_date.strftime('%d/%m/%Y')
          status = list[:converted] == 'true' ? 'Converted' : 'Prescribed'
          advised_by = list[:doctor_name] || '--'
          patient_name = list[:patient_name] || '--'
          mobile_number = list[:mobile_number] || '--'
          pat_id = list[:patient_identifier_id] || '--'
          store_name = list[:store_name] || '--'
          converted_by = if list[:mark_converted_by].present? && status == 'Converted'
                           User.find(list[:mark_converted_by]).fullname
                         else
                           '--'
                         end
          comment = ''
          comment += '<li>Collection not good</li>' if list[:reason_one] == 'true'
          comment += '<li>Dilate</li>' if list[:reason_two] == 'true'
          comment += '<li>Will come later with relatives</li>' if list[:reason_three] == 'true'
          comment += '<li>Known optical shop</li>' if list[:reason_four] == 'true'
          comment += '<li>Optical DRT referral</li>' if list[:reason_five] == 'true'
          comment += '<li>Expensive</li>' if list[:reason_six] == 'true'
          comment += '<li>Looking for high discount</li>' if list[:reason_seven] == 'true'
          comment += '<li>Not interested in wearing glasses</li>' if list[:reason_eight] == 'true'
          comment += "<li>#{list[:optical_comment]}</li>" unless list[:optical_comment].nil?
          comment =  '--' if comment.empty?

          @data_array << [date, status, pat_id, patient_name, mobile_number, advised_by, converted_by, store_name, comment]
        end
      end

      def appointment_list_query
        # AppointmentList Query
        aggregation_query = [
          { "$match": match_options },
          { "$project": project_options },
          { "$sort": { date: -1 } }
        ]
        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'

        # AppointmentList Count Query
        aggregation_query_count = [
          { "$match": match_options },
          { "$project": project_options },
          { "$group": { _id: 'null', pharmacy_list_count: { "$sum": 1 } } }
        ]

        [aggregation_query, aggregation_query_count]
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { facility_id: BSON::ObjectId(@mis_params[:facility_id]) }
                        else
                          { reg_hosp_ids: [@mis_params[:organisation_id]] }
                        end

        # Date
        match_options = match_options.merge(prescription_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                                 "$lte": @mis_params[:end_date].end_of_day })

        match_options = match_options.merge(is_deleted: false)
        match_options = match_options.merge(store_id: BSON::ObjectId(@mis_params[:store_id])) if @mis_params[:store_id].present?
        match_options = match_data(match_options)

        match_options
      end

      def match_data(match_options)
        match_options = case @mis_params[:current_state]
                        when 'converted'
                          match_options.merge({ converted: "true" })
                        when 'prescribed'
                          match_options.merge({ "$and": [{ "advise_glasses": 'advise' },
                                                         "$or": [{ "converted": 'false' }, { "converted": nil }]] })
                        else
                          match_options.merge(match_prescribed_data)
                        end
        match_options
      end

      def match_prescribed_data
        {
          "$or": [
            {
              "$and": [
                { "advise_glasses": '' },
                { "converted": 'true' }
              ]
            },
            {
              "advise_glasses": 'advise'
            }
          ]
        }
      end

      def project_options
        {
          converted: 1,
          advise_glasses: 1,
          encounterdate: 1,
          doctor_name: 1,
          patient_name: 1,
          mobile_number: 1,
          patient_identifier_id: 1,
          mark_converted_by: 1,
          store_name: 1,
          optical_comment: 1,
          reason_one: 1,
          reason_two: 1,
          reason_three: 1,
          reason_four: 1,
          reason_five: 1,
          reason_six: 1,
          reason_seven: 1,
          reason_eight: 1,
          date: { "$dateToString": { format: '%Y-%m-%d', date: '$encounterdate' } }
        }
      end
    end
  end
end
