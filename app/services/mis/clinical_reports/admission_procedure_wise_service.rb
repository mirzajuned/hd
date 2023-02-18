module Mis::ClinicalReports
  class AdmissionProcedureWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        unless @request == 'json'
          @data_array << ['S No.', 'Patient Name', 'Patient ID', 'Surgery Name', 'Advised Date', 'Performed Date',
                          'Length of Stay']
        end

        @ipd_record_lists = Inpatient::IpdRecord.collection.aggregate(admission_list_query).to_a || []

        admission_patient_ids = @ipd_record_lists.map { |ipd_record| ipd_record[:patient_id] }
        get_patient_fields(admission_patient_ids) if admission_patient_ids.present? && admission_patient_ids.count > 0
        admission_ids = @ipd_record_lists.map { |ipd_record| ipd_record[:admission_id] }
        get_admission_fields(admission_ids) if admission_ids.present? && admission_ids.count > 0

        ipd_record_list_data

        if @request == 'json'
          [@data_array[@mis_params[:iDisplayStart].to_i, @mis_params[:iDisplayLength].to_i], @data_array.count]
        else
          [@data_array, @data_array.count]
        end
      end

      private

      def ipd_record_list_data
        range = @mis_params[:start_date].beginning_of_day..@mis_params[:end_date].end_of_day
        sorting_array = []
        @ipd_record_lists.try(:each) do |ipd_record|
          patient = @patient_fields.find { |p| p[:id].to_s == ipd_record[:patient_id].to_s }
          admission = @admission_fields.find { |p| p[:id].to_s == ipd_record[:admission_id].to_s }

          next if patient.nil? || admission.nil?

          patient_identifiers = if patient[:mr_no].present? && @request == 'json'
                                  "#{patient[:mr_no]}<br>#{patient[:identifier_id]}"
                                elsif patient[:mr_no].present? && @request != 'json'
                                  "#{patient[:mr_no]} | #{patient[:identifier_id]}"
                                else
                                  patient[:identifier_id]
                                end

          expected_stay = if ipd_record[:expected_stay].present?
                            "#{ipd_record[:expected_stay]} Days"
                          elsif admission[:admission_date].present? && admission[:discharge_date].present?
                            "#{(admission[:discharge_date] - admission[:admission_date]).to_i + 1} Days"
                          else
                            '-'
                          end

          ipd_record[:procedure].each do |procedure|
            next unless procedure[:is_performed] && range.cover?(procedure[:performed_datetime])

            advised_datetime = procedure[:advised_datetime].try(:strftime, '%d/%m/%Y')
            performed_datetime = procedure[:performed_datetime].try(:strftime, '%d/%m/%Y')

            if procedure[:procedureside].present?
              side = case procedure[:procedureside]
                     when '18944008'
                       'R'
                     when '8966001'
                       'L'
                     else
                       'BE'
                     end
              procedure_name = "#{procedure[:procedurename]}, #{side}"
            else
              procedure_name = procedure[:procedurename]
            end

            sorting_array << [patient[:fullname], patient_identifiers, procedure_name,
                              advised_datetime, performed_datetime, expected_stay]
          end
        end

        sorting_array = sorting_array.sort { |a, b| b[4] <=> a[4] }
        sorting_array.each_with_index do |sorted, i|
          sorted.prepend(i + 1)
          @data_array << sorted
        end
      end

      def admission_list_query
        # Admission List Query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { 'procedure.performed_datetime': -1 } }
        ]

        aggregation_query
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { 'facility_id': BSON::ObjectId((@mis_params[:facility_id]).to_s) }
                        else
                          { 'organisation_id': BSON::ObjectId((@mis_params[:organisation_id]).to_s) }
                        end

        # Date
        match_options = match_options.merge('procedure.performed_datetime': {
                                              '$gte': @mis_params[:start_date].beginning_of_day,
                                              '$lte': @mis_params[:end_date].end_of_day
                                            })

        match_options = match_options.merge('procedure.is_performed': true)

        match_options
      end

      def get_patient_fields(patient_ids)
        patients = Patient.where(:id.in => patient_ids)
        @patient_fields = patients.map do |patient|
          { id: patient.id.to_s, fullname: patient.fullname, identifier_id: patient.patient_identifier_id,
            mr_no: patient.patient_mrn }
        end
      end

      def get_admission_fields(admission_ids)
        admissions = Admission.where(:id.in => admission_ids)
        @admission_fields = admissions.map do |admission|
          { id: admission.id.to_s, admission_date: admission.admissiondate, discharge_date: admission.dischargedate }
        end
      end
    end
  end
end
