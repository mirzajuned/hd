module Mis::NewClinicalReports
  class DailyProcedureWiseRake
    class << self
      def call(start_date, end_date, org_id = nil)
        mis_logger = Logger.new("#{Rails.root}/log/mis_procedure_logger.log")
        # TODO: send facility id or organisation id to decide to migrated and also add is_migrated
        facilities = Organisation.find_by(id: org_id)&.facilities || []
        facilities.each do |facility|
          facility_id = facility.id
          organisation_id = facility.organisation_id
          total_advised_query = aggregation_total_advised(start_date, end_date, facility_id, organisation_id)
          total_performed_query = aggregation_performed(start_date, end_date, facility_id, organisation_id)
          total_advised_list = MisClinical::Common::PatientProcedureWise.collection.aggregate(total_advised_query).to_a
          total_performed_list = MisClinical::Common::PatientProcedureWise.collection.aggregate(total_performed_query).to_a

          (start_date.to_date..end_date.to_date).each do |date|
            if total_advised_list.present?
              total_advised = total_advised_list.select { |arr| arr[:_id].to_date == date }
              if total_advised.present? && total_advised[0][:lists].present?
                advised_date_list = total_advised[0][:lists]
                grp_by_advised_procedure = advised_date_list.group_by { |al| al[:procedure_id].to_s }
                grp_by_performed_procedure_from_advised = advised_date_list.select { |proc| proc[:is_advised] == true && proc[:is_performed] == true }.group_by { |al| al[:procedure_id].to_s }
              end
            end
            if total_performed_list.present?
              total_performed = total_performed_list.select { |arr| arr[:_id].to_date == date }
              if total_performed.present? && total_performed[0][:lists].present?
                performed_date_list = total_performed[0][:lists]
                grp_by_performed_procedure_from_performed = performed_date_list.select { |proc| proc[:is_advised] == true && proc[:is_performed] == true }.group_by { |al| al[:procedure_id].to_s }
              end
            end
            grp_by_advised_procedure ||= {}
            grp_by_performed_procedure_from_advised ||= {}
            grp_by_performed_procedure_from_performed ||= {}

            advised_keys = grp_by_advised_procedure.keys
            performed_from_advised_keys = grp_by_performed_procedure_from_advised.keys
            performed_keys = grp_by_performed_procedure_from_performed.keys
            loop_in_keys = (advised_keys + performed_from_advised_keys + performed_keys).uniq.delete_if(&:blank?)
            loop_in_keys.each do |procedure|
              advised_grp = grp_by_advised_procedure[procedure]
              procedure_name = advised_grp.pluck(:procedurename).uniq.reject(&:empty?).last rescue ''
              performed_from_advised_grp = grp_by_performed_procedure_from_advised[procedure]
              performed_grp = grp_by_performed_procedure_from_performed[procedure]
              performed_count = performed_grp.present? ? performed_grp.count : 0
              performed_from_advised_count = performed_from_advised_grp.present? ? performed_from_advised_grp.count : 0
              advised_count = advised_grp.present? ? advised_grp.count : 0
              procedure_details = MisClinical::Common::DailyProcedureConversion.find_or_create_by(
                procedure_date: date, facility_id: facility_id, procedure_id: procedure
              )
              procedure_details.organisation_id = organisation_id
              procedure_details.procedure_name = procedure_name
              procedure_details.advised = advised_count
              procedure_details.performed_from_advised = performed_from_advised_count
              procedure_details.performed = performed_count
              procedure_details.save!
            end
          end
        end
      rescue StandardError => e
        # puts e.inspect
        mis_logger.info(" === Error in DailyProcedureWiseRake while importing admission data: #{e.inspect}")
      end

      def aggregation_total_advised(start_date, end_date, facility_id, organisation_id)
        match_options = { "advised_datetime": { '$gte' => start_date, '$lte' => end_date } }
        match_options = match_options.merge({ facility_id: facility_id, organisation_id: organisation_id })

        aggregation_query = [
          { "$match": match_options },
          { "$project": project_options },
          { "$group": { _id: '$advised_date', lists: { "$push": '$$ROOT' }, total: { "$sum": 1 } } }
        ]
      end

      def project_options
        {
          advised_date: {
            '$dateToString': { format: '%d-%m-%Y', date: '$advised_datetime' }
          },
          performed_date: {
            '$dateToString': { format: '%d-%m-%Y', date: '$performed_time' }
          },
          is_advised: 1, is_converted: 1, is_performed: 1,
          procedure_id: 1, procedurename: 1, has_declined: 1, advised_by: 1,
          advised_by_id: 1, performed_by: 1, performed_by_id: 1,
          organisation_id: 1, facility_id: 1
        }
      end

      def aggregation_performed(start_date, end_date, facility_id, organisation_id)
        match_options = { "performed_time": { '$gte' => start_date, '$lte' => end_date } }
        match_options = match_options.merge({ facility_id: facility_id, organisation_id: organisation_id })
        match_options = match_options.merge({ is_performed: true })

        aggregation_query = [
          { "$match": match_options },
          { "$project": project_options },
          { "$group": { _id: '$performed_date', lists: { "$push": '$$ROOT' }, total: { "$sum": 1 } } }
        ]
      end
    end
  end
end
