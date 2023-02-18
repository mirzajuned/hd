module Mis::NewClinicalReports::Ipd
  class PatientProcedureWiseRake
    class << self
      def call(start_date, end_date, org_id = nil)
        # TODO: send facility id or organisation id to decide to migrated and also add is_migrated
        facilities = if org_id.present?
                       Organisation.find_by(id: org_id)&.facilities || []
                     else
                       []
                     end
        facilities.each do |facility|
          facility_id = facility.id
          organisation_id = facility.organisation_id
          # get admission ids from ipd record
          admission_query = get_admissions_query(start_date, end_date, facility_id, organisation_id)
          admission_query_result = Inpatient::IpdRecord.collection.aggregate(admission_query).to_a
          admission_ids = admission_query_result.pluck(:admission_id).map(&:to_s)

          if admission_ids.count > 0
            admission_ids.each do |admission_id|
              query = aggregation_query(admission_id, facility_id, organisation_id)
              query_result = CaseSheet.collection.aggregate(query).to_a
              if query_result[0].present? && query_result[0][:case_sheets].present?
                case_sheets = query_result[0][:case_sheets]
                case_sheets.each do |case_sheet|
                  ::Mis::NewClinicalReports::Ipd::StructureProcedureDetails.call(case_sheet, facility_id, admission_id)
                end
              end
            end
          end
        end
      end

      def get_admissions_query(start_date, end_date, facility_id, organisation_id)
        created_at_condition = { "created_at": { '$gte' => start_date, '$lte' => end_date }  }
        updated_at_condition = { "updated_at": { '$gte' => start_date, '$lte' => end_date }  }
        admission_date_condition = { "admissiondate": { '$gte' => start_date, '$lte' => end_date } }
        match_options = { facility_id: facility_id, organisation_id: organisation_id }
        match_options = match_options.merge(procedure: { "$exists": true, "$ne": [] })
        match_options = match_options.merge({ "$or": [created_at_condition, updated_at_condition, admission_date_condition] })
        aggregation_query = [
          { "$match": match_options }, { "$project": { "admission_id": 1 } }
        ]
      end

      def aggregation_query(admission_id, facility_id, organisation_id)
        match_options = { 
                          organisation_id: organisation_id, 
                          'procedures.admission_id': { "$in" => [admission_id, BSON::ObjectId(admission_id)]} 
                        }
        aggregation_query = [
          { "$match": match_options }, { "$group": group_options }
        ]
      end

      def group_options
        { _id: 'null', case_sheets: { "$push": '$$ROOT' }, procedure_count: { "$sum": 1 } }
      end
    end
  end
end
