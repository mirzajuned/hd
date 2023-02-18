module Mis::NewClinicalReports::Ipd
  class UserProcedureConversionRake
    class << self
      def call(start_date, end_date, org_id = nil)
        # TODO: send facility id or organisation id to decide to migrated and also add is_migrated
        facilities = if org_id.present?
                       Organisation.find_by(id: org_id)&.facilities || []
                     else
                       # Facility.all
                     end
        mis_logger = Logger.new("#{Rails.root}/log/mis_logger.log")
        facilities.each do |facility|
          facility_id = facility.id
          organisation_id = facility.organisation_id
          total_advised_query = aggregation_total_advised(start_date, end_date, facility_id, organisation_id)
          total_performed_query = aggregation_performed(start_date, end_date, facility_id, organisation_id)
          total_advised_list = MisClinical::Ipd::PatientProcedureWise.collection.aggregate(total_advised_query).to_a
          total_performed_list = MisClinical::Ipd::PatientProcedureWise.collection.aggregate(total_performed_query).to_a

          # mis_logger.info(" === total_advised_list: #{total_advised_list.count}")
          # mis_logger.info(" === total_performed_list: #{total_performed_list.count}")

          (start_date.to_date..end_date.to_date).each do |date|
            if total_advised_list.present?
              total_advised = total_advised_list.select { |arr| arr[:_id].to_date == date }
              # mis_logger.info(" === total_advised: #{total_advised.inspect}")
              if total_advised.present? && total_advised[0][:lists].present?
                advised_date_list = total_advised[0][:lists]
                grp_by_advised_user = advised_date_list.group_by { |al| al[:advised_by_id].to_s }
                grp_by_performed_user_from_advised = advised_date_list.select { |proc| proc[:is_advised] == true && proc[:is_performed] == true }.group_by { |al| al[:performed_by_id].to_s }
                grp_by_total_performed_by_self = advised_date_list.select { |proc| proc[:is_advised] == true && proc[:is_performed] == true && proc[:advised_by_id] == proc[:performed_by_id] }.group_by { |al| al[:performed_by_id].to_s }
                # mis_logger.info(" === grp_by_total_performed_by_self: #{grp_by_total_performed_by_self.inspect}")
                grp_by_total_performed_by_other = advised_date_list.select { |proc| proc[:is_advised] == true && proc[:is_performed] == true && proc[:advised_by_id] != proc[:performed_by_id] }.group_by { |al| al[:performed_by_id].to_s }
                # mis_logger.info(" === grp_by_total_performed_by_other: #{grp_by_total_performed_by_other.inspect}")
              end
            end

            if total_performed_list.present?
              total_performed = total_performed_list.select { |arr| arr[:_id].to_date == date }
              # mis_logger.info(" === total_performed: #{total_performed.inspect}")
              if total_performed.present? && total_performed[0][:lists].present?
                performed_date_list = total_performed[0][:lists]
                grp_by_total_performed_user = performed_date_list.select { |proc| proc[:is_advised] == true && proc[:is_performed] == true }.group_by { |al| al[:performed_by_id].to_s }
                advised_date_arr = performed_date_list.pluck(:advised_date).uniq.map(&:to_date)
                advised_date_arr.delete(date)
              end
            end
            grp_by_advised_user ||= {}
            grp_by_performed_user_from_advised ||= {}
            grp_by_total_performed_user ||= {}
            grp_by_total_performed_by_self ||= {}
            grp_by_total_performed_by_other ||= {}

            advised_keys = grp_by_advised_user.keys
            performed_from_advised_keys = grp_by_performed_user_from_advised.keys
            performed_keys = grp_by_total_performed_user.keys
            performed_by_self_keys = grp_by_total_performed_by_self.keys
            performed_by_other_keys = grp_by_total_performed_by_other.keys
            loop_in_keys = (advised_keys + performed_from_advised_keys + performed_keys + performed_by_self_keys + performed_by_other_keys).uniq.delete_if(&:blank?)
            loop_in_keys.each do |user_id|
              # mis_logger.info(" === user_id: #{user_id.inspect}")
              advised_grp = grp_by_advised_user[user_id]
              performed_from_advised_grp = advised_grp&.select { |proc| proc[:is_advised] == true && proc[:is_performed] == true }
              performed_by_self_grp = advised_grp&.select { |proc| proc[:is_advised] == true && proc[:is_performed] == true && proc[:advised_by_id] == proc[:performed_by_id] }
              performed_by_other_grp = advised_grp&.select { |proc| proc[:is_advised] == true && proc[:is_performed] == true && proc[:advised_by_id] != proc[:performed_by_id] }
              performed_grp = grp_by_total_performed_user[user_id]
              
              performed_count = 0
              conversion_in_days_avg = nil
              conversion_in_days_total = nil
              if performed_grp.present?
                performed_count = performed_grp.count
                conversion_in_days_total = performed_grp.map{|arr| arr[:conversion_time_days]&.to_i}.sum
                conversion_in_days_avg = (conversion_in_days_total / performed_count).to_i
              end

              time_performed_from_advised = nil
              if performed_from_advised_grp.present?
                performed_from_advised_count = performed_from_advised_grp.count
                time_performed_from_advised = performed_from_advised_grp.map{|arr| arr[:conversion_time_days]&.to_i}.sum
              end

              if performed_by_self_grp.present?
                performed_by_self_count = performed_by_self_grp.count
                time_performed_by_self = performed_by_self_grp.map{|arr| arr[:conversion_time_days]&.to_i}.sum
              end

              if performed_by_other_grp.present?
                performed_by_other_count = performed_by_other_grp.count
                time_performed_by_other = performed_by_other_grp.map{|arr| arr[:conversion_time_days]&.to_i}.sum
              end

              user = User.find_by(id: user_id)
              if user.present?
                user_role_id = user&.role_ids[0]
                user_role_name = user&.primary_role
                user_name = user&.fullname
                advised_count = advised_grp.present? ? advised_grp.count : 0

                procedure_details = MisClinical::Ipd::UserProcedureConversion.find_or_create_by(
                  organisation_id: organisation_id, facility_id: facility_id,
                  procedure_date: date, user_id: user_id
                )
                procedure_details.user_name = user_name
                procedure_details.user_role_id = user_role_id
                procedure_details.user_role_name = user_role_name
                procedure_details.total_advised = advised_count
                procedure_details.performed_from_advised = performed_from_advised_count
                procedure_details.total_performed = performed_count
                procedure_details.conversion_time_days_avg = conversion_in_days_avg
                procedure_details.conversion_time_days_total = conversion_in_days_total
                procedure_details.time_performed_from_advised = time_performed_from_advised

                procedure_details.total_performed_by_self = performed_by_self_count
                procedure_details.time_performed_by_self = time_performed_by_self

                procedure_details.total_performed_by_other = performed_by_other_count
                procedure_details.time_performed_by_other
                procedure_details.save!
                # update_past_date_data(facility_id, organisation_id, advised_date_arr) if advised_date_arr.present?
              end
              # End user.present?
            end
          end
        end
      rescue StandardError => e
        mis_logger.info(" === Error in UserProcedureConversionRake: #{e.inspect}")
      end

      def update_past_date_data(facility_id, organisation_id, date_arr)
        # note - path to update all the cases when advised date is in past and performed date is current, this method
        # will go and update all the records whose performed date is current and was advised earlier.
        date_arr.each do |date|
          start_date = date.beginning_of_day
          end_date = date.end_of_day
          total_advised_query = aggregation_total_advised(start_date, end_date, facility_id, organisation_id)
          total_performed_query = aggregation_performed(start_date, end_date, facility_id, organisation_id)
          total_advised_list = MisClinical::Ipd::PatientProcedureWise.collection.aggregate(total_advised_query).to_a
          total_performed_list = MisClinical::Ipd::PatientProcedureWise.collection.aggregate(total_performed_query).to_a
          date = date.to_date
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
              grp_by_total_performed_user = performed_date_list.select { |proc| proc[:is_advised] == true && proc[:is_performed] == true }.group_by { |al| al[:performed_by_id].to_s }
            end
          end
          grp_by_advised_user ||= {}
          grp_by_performed_user_from_advised ||= {}
          grp_by_total_performed_user ||= {}

          advised_keys = grp_by_advised_user.keys
          performed_from_advised_keys = grp_by_performed_user_from_advised.keys
          performed_keys = grp_by_total_performed_user.keys
          loop_in_keys = (advised_keys + performed_from_advised_keys + performed_keys).uniq.delete_if(&:blank?)
          loop_in_keys.each do |user_id|
            advised_grp = grp_by_advised_user[user_id]
            performed_from_advised_grp = advised_grp&.select { |proc| proc[:is_advised] == true && proc[:is_performed] == true }
            performed_grp = grp_by_total_performed_user[user_id]

            performed_count = 0
            conversion_in_days_avg = nil
            conversion_in_days_total = nil
            if performed_grp.present?
              performed_count = performed_grp.count
              conversion_in_days_total = performed_grp.map{|arr| arr[:conversion_time_days]&.to_i}.sum
              conversion_in_days_avg = (conversion_in_days_total / performed_count).to_i
            end
            time_performed_from_advised = nil
            if performed_from_advised_grp.present?
              performed_from_advised_count = performed_from_advised_grp.count
              time_performed_from_advised = performed_grp.map{|arr| arr[:conversion_time_days]&.to_i}.sum
            end

            user = User.find(user_id)
            user_role_id = user&.role_ids[0]
            user_role_name = user&.primary_role
            user_name = user&.fullname
            advised_count = advised_grp.present? ? advised_grp.count : 0

            procedure_details = MisClinical::Ipd::UserProcedureConversion.find_or_create_by(
              organisation_id: organisation_id, facility_id: facility_id,
              procedure_date: date, user_id: user_id
            )
            procedure_details.user_name = user_name
            procedure_details.user_role_id = user_role_id
            procedure_details.user_role_name = user_role_name
            procedure_details.total_advised = advised_count
            procedure_details.performed_from_advised = performed_from_advised_count
            procedure_details.total_performed = performed_count
            procedure_details.conversion_time_days_avg = conversion_in_days_avg
            procedure_details.conversion_time_days_total = conversion_in_days_total
            procedure_details.time_performed_from_advised = time_performed_from_advised
            procedure_details.save!

          end
        end
      end

      def aggregation_total_advised(start_date, end_date, facility_id, organisation_id)
        advised_date_condition = { "advised_datetime": { '$gte' => start_date, '$lte' => end_date } }
        performed_condition = { "performed_datetime": { '$gte' => start_date, '$lte' => end_date } }

        match_options = { facility_id: facility_id, organisation_id: organisation_id }
        match_options = match_options.merge({ "$or": [advised_date_condition, performed_condition] })

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
          facility_id: 1,
          conversion_time_days: 1
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
