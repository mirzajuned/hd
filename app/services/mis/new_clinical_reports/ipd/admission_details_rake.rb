module Mis::NewClinicalReports::Ipd
  class AdmissionDetailsRake
    class << self
      def call(start_date, end_date, organisation_ids)
        organisation_ids = organisation_ids
        # TODO: send facility id or organisation id to decide to migrated and also add is_migrated
        mis_logger = Logger.new("#{Rails.root}/log/mis_logger.log")
        query = aggregation_query(start_date, end_date, organisation_ids)
        admission_list_wise = AdmissionListView.collection.aggregate(query).to_a
        admission_list_wise.each do |list|
          ::Mis::NewClinicalReports::Ipd::StructureAdmissionDetails.call(list)
        end
      rescue StandardError => e
        mis_logger.error(" === Error in AdmissionDetailsRake while importing admission data: #{e.inspect}")
      end

      # def aggregation_query(start_date, end_date, facility_id, organisation_id)
      def aggregation_query(start_date, end_date, organisation_ids)
        created_at_condition = { "created_at": { '$gte' => start_date, '$lte' => end_date }  }
        updated_at_condition = { "updated_at": { '$gte' => start_date, '$lte' => end_date }  }
        admission_date_condition = { "admission_date": { '$gte' => start_date, '$lte' => end_date } }
        # match_options = { facility_id: facility_id, organisation_id: organisation_id }
        match_options = { organisation_id: { "$in": organisation_ids } }
        match_options = match_options.merge({ "$or": [created_at_condition,
                                                      updated_at_condition,
                                                      admission_date_condition] })
        aggregation_query = [{ "$match": match_options }]
      end
    end
  end
end
