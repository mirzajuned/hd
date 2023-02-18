module Mis::NewClinicalReports::Ipd
  class ProcedureConversionStateRake
    class << self
      def call(start_date, end_date, org_id = nil)
        # TODO: send facility id or organisation id to decide to migrated and also add is_migrated
        facilities = if org_id.present?
                       Organisation.find_by(id: org_id)&.facilities || []
                     else
                       Facility.all
                     end
        mis_logger = Logger.new("#{Rails.root}/log/mis_logger.log")
        facilities.each do |facility|
          facility_id = facility.id
          organisation_id = facility.organisation_id
          total_advised_query = aggregation_total_advised(start_date, end_date, facility_id, organisation_id)
          total_performed_query = aggregation_performed(start_date, end_date, facility_id, organisation_id)
          total_advised_list = MisClinical::Ipd::PatientProcedureWise.collection.aggregate(total_advised_query).to_a
          total_performed_list = MisClinical::Ipd::PatientProcedureWise.collection.aggregate(total_performed_query).to_a

          (start_date.to_date..end_date.to_date).each do |date|
            if total_advised_list.present?
              total_advised = total_advised_list.select { |arr| arr[:_id].to_date == date }
              if total_advised.present? && total_advised[0][:lists].present?
                advised_date_list = total_advised[0][:lists]
                grp_by_advised_user = advised_date_list.group_by { |al| al[:advised_by_id].to_s }
                grp_by_performed_user_from_advised = advised_date_list.select { |proc| proc[:is_advised] == true && proc[:is_performed] == true }.group_by { |al| al[:performed_by_id].to_s }
              end
            end
            if  total_performed_list.present?
              total_performed = total_performed_list.select { |arr| arr[:_id].to_date == date }
              if total_performed.present? && total_performed[0][:lists].present?
                performed_date_list = total_performed[0][:lists]
                grp_by_performed_user_from_performed = performed_date_list.select { |proc| proc[:is_advised] == true && proc[:is_performed] == true }.group_by { |al| al[:performed_by_id].to_s }
              end
            end
            grp_by_advised_user ||= {}
            grp_by_performed_user_from_advised ||= {}
            grp_by_performed_user_from_performed ||= {}

            advised_keys = grp_by_advised_user.keys
            performed_from_advised_keys = grp_by_performed_user_from_advised.keys
            performed_keys = grp_by_performed_user_from_performed.keys
            loop_in_keys = (advised_keys + performed_from_advised_keys + performed_keys).uniq.delete_if(&:blank?)
            loop_in_keys.each do |user_id|
              advised_grp = grp_by_advised_user[user_id]
              performed_from_advised_grp = grp_by_performed_user_from_advised[user_id]
              performed_grp = grp_by_performed_user_from_performed[user_id]
              performed_count = performed_grp.present? ? performed_grp.count : 0
              performed_from_advised_count = performed_from_advised_grp.present? ? performed_from_advised_grp.count : 0
              next unless advised_grp.present?

              user_name = advised_grp[0][:advised_by]
              advised_count = advised_grp.count
              procedure_details = MisClinical::Ipd::ProcedureConversionState.find_or_create_by(organisation_id: organisation_id, facility_id: facility_id, procedure_date: date, user_id: user_id)
              procedure_details.user_name = user_name
              procedure_details.advised = advised_count
              procedure_details.performed_from_advised = performed_from_advised_count
              procedure_details.performed = performed_count
              procedure_details.save!
            end
          end
        end
      rescue StandardError => e
        # puts e.inspect
        mis_logger.info(" === Error in ProcedureConversionStateRake while importing procedure conversion data : #{e.inspect}")
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
            '$dateToString': { format: '%d-%m-%Y', date: '$performed_datetime' }
          },
          is_advised: 1,
          is_converted: 1,
          is_performed: 1,
          has_declined: 1,
          advised_by: 1,
          advised_by_id: 1,
          performed_by: 1,
          performed_by_id: 1,
          organisation_id: 1,
          facility_id: 1
        }
      end

      def aggregation_performed(start_date, end_date, facility_id, organisation_id)
        match_options = { "performed_datetime": { '$gte' => start_date, '$lte' => end_date } }
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
