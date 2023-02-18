# bundle exec rake clinical:investigation_report\['2021-04-01','2021-04-15'\] RAILS_ENV=development
module Mis::NewClinicalReports::Opd
  class AdvisedInvestigationConversionRake
    class << self
      def call(start_date, end_date, org_id = nil)
        @start_date = start_date
        @end_date = end_date
        @org_id = BSON::ObjectId org_id
        @facilities = Organisation.find_by(id: @org_id)&.facilities&.pluck(:id) || []
        import
      end

      private

      def import
        @facilities.each do |facility_id|
          advised_invs = Investigation::InvestigationDetail.collection.aggregate(query(facility_id)).to_a
          investigations_by_type(advised_invs, facility_id)
          investigations_by_user(advised_invs, facility_id)
        end
      end

      def investigations_by_type(collection, facility_id)
        collection.each do |data|
          group_by_type = data[:data].group_by { |inv| inv[:_type] }
          date = data[:_id]
          group_by_type.each do |type, inv|
            total_advised = inv.size
            total_performed = total_count = total_days = 0.0
            inv.each do |i|
              if i[:performed_at].present?
                days = (i[:performed_at].to_date - i[:advised_at].to_date).to_i
                if days >= 0
                  total_days += days
                  total_count += 1
                end
                total_performed += 1
              end
            end
            avg_conv_time = total_performed > 0 ? total_days / total_count : 0
            investigation_type = type.split('::').last
            adv_inv = MisClinical::Opd::AdvisedInvestigationConversion
                      .find_or_initialize_by(facility_id: facility_id, advised_at: date, investigation_type: investigation_type)
            adv_inv.total_advised = total_advised
            adv_inv.total_performed = total_performed
            adv_inv.average_conversion_days = avg_conv_time
            adv_inv.save!
          end
        end
      end

      def investigations_by_user(collection, facility_id)
        collection.each do |data|
          group = data[:data].group_by { |inv| inv[:advised_by] }
          date = data[:_id]
          group.each do |user_id, inv|
            user = User.find(user_id)
            next unless user.role_ids.include?(158965000)

            total_advised = inv.size
            total_performed = total_days = 0.0
            inv.each do |i|
              if i[:performed_at].present?
                total_performed += 1
                total_days += (i[:performed_at].to_date - i[:advised_at].to_date).to_i
              end
            end
            adv_inv = MisClinical::Opd::AdvisedInvestigationConversionUserWise
                      .find_or_initialize_by(facility_id: facility_id, advised_at: date, user_id: user_id)
            adv_inv.total_advised = total_advised
            adv_inv.total_performed = total_performed
            adv_inv.user_name = user.fullname
            adv_inv.save!
          end
        end
      end

      def query(facility_id)
        match_options = { "advised_at": { '$gte' => @start_date, '$lte' => @end_date } }
        match_options = match_options.merge({ facility_id: facility_id, organisation_id: @org_id })
        match_options[:is_deleted] = false
        aggregation_query = [
          { "$match": match_options },
          { "$group": group_options }
        ]
      end

      def group_options
        {
          _id: { '$dateToString': { format: '%d-%m-%Y', date: '$advised_at' } },
          data: { '$push': '$$ROOT' }
        }
      end
    end
  end
end
