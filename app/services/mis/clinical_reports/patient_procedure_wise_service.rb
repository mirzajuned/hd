module Mis::ClinicalReports
  class PatientProcedureWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        unless @request == 'json'
          @data_array << ['ADMISSION DATE', 'PATIENT NAME', 'PATIENT AGE', 'PATIENT GENDER', 'PATIENT ID',
                          'ADMISSION ID', 'PROCEDURE NAME', 'SURGEON', 'INTRA COMPLICATION', 'DIAGNOSDED', 'PRE OP',
                          'POST OP(VISIT 1)', 'POST OP(VISIT 2)', 'POST OP(VISIT 3)']
        end

        @procedure_lists = Inpatient::IpdRecord.collection.aggregate(procedure_list_query[0]).to_a || {}
        procedure_list_count = Inpatient::IpdRecord.collection.aggregate(procedure_list_query[1]).to_a
        total_records = procedure_list_count.count > 0 ? procedure_list_count[0][:procedure_list_count] : 0
        procedure_list_data

        [@data_array, total_records]
      end

      private

      def procedure_list_data
        @procedure_lists.try(:each) do |procedure_list|
          procedure_list[:patient_lists].each do |list|
            admission_date = list[:admission_date].strftime('%d/%m/%y')
            patient_name = list[:patient_name].present? ? list[:patient_name][0] : '--'
            patient_age = list[:patient_age].present? ? list[:patient_age][0] : '--'
            patient_gender = list[:patient_gender].present? ? list[:patient_gender][0] : '--'
            patient_id = list[:patient_display_id].present? ? list[:patient_display_id][0] : '--'
            intra_complication = list[:intra_comlication].present? ? list[:intra_comlication][0] : '--'
            procedure_name = list[:procedure_name]
            surgeon = list[:surgeon]
            diagnosed = list[:diagnosislist]&.join(',')
            pre_post_op_visit_data(list[:admission_id])

            @data_array << [admission_date, patient_name, patient_age, patient_gender, patient_id, @admission_id,
                            procedure_name, surgeon, intra_complication, diagnosed, @data_in_previsit,
                            @data_post_v1, @data_post_v2, @data_post_v3]
          end
        end
      end

      def pre_post_op_visit_data(admission_id)
        admission = Admission.find(admission_id)
        @admission_id = admission.display_id
        created_date = admission.created_at
        patient_id = admission.patient_id
        @data_in_previsit = pre_op_vist(created_date, patient_id)
        @data_post_v1, @data_post_v2, @data_post_v3 = post_op(created_date, patient_id)
      end

      def pre_op_vist(created_date, patient_id)
        pre_visit = OpdRecord.where(patientid: patient_id.to_s, :created_at.lte => created_date).to_a[0]
        !pre_visit.blank? ? data_in_html(pre_visit) : nil
      end

      def post_op(created_date, patient_id)
        post_visit = OpdRecord.where(patientid: patient_id.to_s, :created_at.gte => created_date).to_a
        visit1 = post_visit[0]
        visit2 = post_visit[1]
        visit3 = post_visit[2]
        v1 = !visit1.blank? ? data_in_html(visit1) : nil
        v2 = !visit2.blank? ? data_in_html(visit2) : nil
        v3 = !visit3.blank? ? data_in_html(visit3) : nil
        [v1, v2, v3]
      end

      def data_in_html(vist)
        Mis::ClinicalReports::RenderHtmlService.visit_html(vist)
      end

      def procedure_list_query
        # AdmissionList Query
        aggregation_query = [
          { "$match": match_options },
          { "$unwind": '$procedure' },
          { "$match": { 'procedure.is_performed': true } },
          { "$sort": { admissiondate: -1 } }
        ]
        aggregation_query << { "$match": match_procedure } if @mis_params[:patient_type].present?
        aggregation_query << { "$group": group_options }
        aggregation_query << { "$skip": @mis_params[:iDisplayStart].to_i } if @request == 'json'
        aggregation_query << { "$limit": @mis_params[:iDisplayLength].to_i } if @request == 'json'
        aggregation_query_count = [
          { "$match": match_options },
          { "$unwind": '$procedure' },
          { "$match": { 'procedure.is_performed': true } }
        ]
        aggregation_query_count << { "$match": match_procedure } if @mis_params[:patient_type].present?
        aggregation_query_count << { "$group": { _id: 'null', procedure_list_count: { "$sum": 1 } } }

        [aggregation_query, aggregation_query_count]
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { facility_id: BSON::ObjectId(@mis_params[:facility_id]) }
                        else
                          { organisation_id: BSON::ObjectId(@mis_params[:organisation_id]) }
                        end

        # Date
        match_options = match_options.merge(
          "admissiondate": { "$gte": @mis_params[:start_date].beginning_of_day,
                             "$lte": @mis_params[:end_date].end_of_day }
        )

        match_options = match_options.merge(
          "procedure.is_performed": true
        )
        if @mis_params[:patient_type].present?
          match_options = match_options.merge(
            "procedure.procedurename": @mis_params[:patient_type]
          )
        end

        match_options
      end

      def group_options
        { _id: 'null',
          patient_lists: { "$push": { admission_date: '$admissiondate', patient_name: '$operative_notes.patient_name',
                                      patient_age: '$operative_notes.patient_age',
                                      patient_gender: '$operative_notes.patient_gender',
                                      patient_display_id: '$operative_notes.patient_identifier_id',
                                      diagnosislist: '$diagnosislist.diagnosisname',
                                      procedure_name: '$procedure.procedurename',
                                      surgeon: '$procedure.performed_by',
                                      intra_comlication: '$operative_notes.complication_comment',
                                      admission_id: '$admission_id' } },
          appointment_count: { "$sum": 1 } }
      end

      def match_procedure
        {
          "procedure.procedurename": @mis_params[:patient_type]
        }
      end
    end
  end
end
