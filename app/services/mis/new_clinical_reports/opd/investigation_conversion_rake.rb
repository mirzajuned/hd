# bundle exec rake clinical:investigation_report\['2021-04-01','2021-04-15'\] RAILS_ENV=development
module Mis::NewClinicalReports::Opd
  class InvestigationConversionRake
    class << self
      def call(start_date, end_date, org_id = nil)
        @start_date = start_date
        @end_date = end_date
        @facilities = Organisation.find_by(id: org_id)&.facilities || []
        import
      end

      def import
        @facilities.each do |facility|
          facility_id = facility.id
          organisation_id = facility.organisation_id
          total_advised_query = aggregation_total_advised(facility_id, organisation_id)
          total_performed_query = aggregation_performed(facility_id, organisation_id)
          @total_advised_list = Investigation::InvestigationDetail.collection.aggregate(total_advised_query).to_a
          @total_performed_list = Investigation::InvestigationDetail.collection.aggregate(total_performed_query).to_a
          create_conversion_data(organisation_id, facility_id)
          # total_performed_list = Investigation::InvestigationDetail.collection.aggregate(total_performed_query).to_a
        end
      end

      private

      def create_conversion_data(organisation_id, facility_id)
        (@start_date.to_date..@end_date.to_date).each do |date|
          if @total_advised_list.present?
            total_advised = @total_advised_list.select { |arr| arr[:_id].to_date == date }
            if total_advised.present? && total_advised[0][:lists].present?
              advised_date_list = total_advised[0][:lists]
              grp_by_advised_user = advised_date_list.group_by { |al| [al[:advised_by].to_s, al[:_type]] }
              grp_by_performed_user_from_advised = advised_date_list.group_by { |al| [al[:performed_by].to_s, al[:_type]] }
            end
          end
          if @total_performed_list.present?
            total_performed = @total_performed_list.select { |arr| arr[:_id].to_date == date }
            if total_performed.present? && total_performed[0][:lists].present?
              performed_date_list = total_performed[0][:lists]
              grp_by_performed_user_from_performed = performed_date_list.group_by { |al| [al[:performed_by].to_s, al[:_type]] }
            end
          end
          grp_by_advised_user ||= {}
          grp_by_performed_user_from_advised ||= {}
          grp_by_performed_user_from_performed ||= {}

          advised_keys = grp_by_advised_user.keys
          performed_from_advised_keys = grp_by_performed_user_from_advised.keys
          performed_keys = grp_by_performed_user_from_performed.keys
          loop_in_keys = (advised_keys + performed_from_advised_keys + performed_keys).uniq # .delete_if(&:blank?)
          loop_in_keys.each do |user_id, _type|
            next if user_id.blank?

            advised_grp = grp_by_advised_user[[user_id, _type]]
            performed_from_advised_grp = grp_by_performed_user_from_advised[[user_id, _type]]
            performed_grp = grp_by_performed_user_from_performed[[user_id, _type]]
            performed_count = performed_grp.present? ? performed_grp.count : 0
            performed_from_advised_count = performed_from_advised_grp.present? ? performed_from_advised_grp.count : 0
            conversion_time_days_total = if performed_count > 0
                                           performed_grp.sum { |row| (row[:performed_at].to_date - row[:advised_at].to_date).to_i }
                                         else
                                           0
            end
            next unless advised_grp.present? || performed_grp.present?
            if advised_grp.present?
              user_name = advised_grp[0][:advised_by_username]
              advised_count = advised_grp.count
            else
              user_name = performed_grp[0][:performed_by_username]
              advised_count = 0
            end
            investigation_type = _type.split('::').last
            investigation_conversion = MisClinical::Opd::InvestigationConversion.find_or_create_by(investigation_date: date, facility_id: facility_id, user_id: user_id, investigation_type: investigation_type)
            investigation_conversion.organisation_id = organisation_id
            investigation_conversion.user_name = user_name
            investigation_conversion.total_advised = advised_count
            investigation_conversion.performed_from_advised = performed_from_advised_count
            investigation_conversion.total_performed = performed_count
            investigation_conversion.conversion_time_days_total = conversion_time_days_total
            user = User.find(user_id)
            investigation_conversion.user_role_ids = user.role_ids
            investigation_conversion.user_role_names = user.selected_role.split(',')
            investigation_conversion.save!
          end
        end
      end

      def aggregation_total_advised(facility_id, organisation_id)
        advised_at = { "advised_at": { '$gte' => @start_date, '$lte' => @end_date } }
        performed_at = { "performed_at": { '$gte' => @start_date, '$lte' => @end_date } }
        match_options = { "$or": [advised_at, performed_at] }
        match_options[:is_deleted]  = false
        match_options = match_options.merge({ facility_id: facility_id, organisation_id: organisation_id })

        aggregation_query = [
          { "$match": match_options },
          { "$project": project_options },
          { "$group": { _id: '$advised_at', lists: { "$push": '$$ROOT' }, total: { "$sum": 1 } } }
        ]
      end

      def project_options
        {
          advised_at: {
            '$dateToString': { format: '%d-%m-%Y', date: '$advised_at' }
          },
          performed_at: {
            '$dateToString': { format: '%d-%m-%Y', date: '$performed_at' }
          },
          is_advised: 1,
          is_converted: 1,
          is_performed: 1,
          has_declined: 1,
          advised_by: 1,
          advised_by_username: 1,
          performed_by: 1,
          performed_by_username: 1,
          organisation_: 1,
          facility_id: 1,
          _type: 1
        }
      end

      def aggregation_performed(facility_id, organisation_id)
        match_options = { "performed_at": { '$gte' => @start_date, '$lte' => @end_date } }
        match_options = match_options.merge({ facility_id: facility_id, organisation_id: organisation_id })
        match_options[:is_deleted]  = false

        aggregation_query = [
          { "$match": match_options },
          { "$project": project_options },
          { "$group": { _id: '$performed_at', lists: { "$push": '$$ROOT' }, total: { "$sum": 1 } } }
        ]
      end
    end
  end
end
