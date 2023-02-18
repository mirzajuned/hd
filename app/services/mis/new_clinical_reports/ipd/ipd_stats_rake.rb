module Mis::NewClinicalReports::Ipd
  class IpdStatsRake
    class << self
      def call(start_date, end_date, org_id = nil)
        facilities = if org_id.present?
                       Organisation.find_by(id: org_id)&.facilities || []
                     else
                      []
                       # Facility.all
                     end
        facilities.each do |facility|
          facility_id = facility.id
          organisation_id = facility.organisation_id
          query = aggregation_query(start_date, end_date, facility_id, organisation_id)
          date_wise_list = AdmissionListView.collection.aggregate(query).to_a
          date_wise_list.each do |val|
            admission_date = val[:_id]
            value = val[:admission_lists]
            gender_group = value.group_by { |al| al[:patient_gender] }

            male = gender_group['Male'].to_a.size
            female = gender_group['Female'].to_a.size
            transgender = gender_group['Transgender'].to_a.size
            gender_undefined = gender_group[nil].to_a.size
            age = value.pluck(:age, :patient_age)
            # {"till_twenty": 10, above_twenty_till_forty: 20, above_forty_till_sixty: 20, above_sixty_till_eighty: 20 , above_eighty: 0, undefined: 9 }
            till_twenty = above_twenty_till_forty = above_forty_till_sixty = above_sixty_till_eighty = above_eighty = undefined = 0
            age.each do |val|
              age_val = if val[0].nil? && !val[1].nil?
                          val[1].to_i
                        elsif !val[0].nil? && val[1].nil?
                          nil
                        else
                          val[0]
                        end
              case age_val
              when 0..20
                till_twenty += 1
              when 21..40
                above_twenty_till_forty += 1
              when 41..60
                above_forty_till_sixty += 1
              when 61..80
                above_sixty_till_eighty += 1
              when 81..150
                above_eighty += 1
              else
                undefined += 1
              end
            end
            age_stats_fields = { till_twenty: till_twenty, above_twenty_till_forty: above_twenty_till_forty,
                                 above_forty_till_sixty: above_forty_till_sixty,
                                 above_sixty_till_eighty: above_sixty_till_eighty, above_eighty: above_eighty,
                                 undefined: undefined }
            gender_stats_fields = { male: male, female: female, transgender: transgender, undefined: gender_undefined }

            location_statistics = MisClinical::Ipd::IpdStatistic.find_or_create_by(
              organisation_id: organisation_id, facility_id: facility_id,
              admission_date: admission_date
            )

            location_statistics.age_stats_fields = age_stats_fields
            location_statistics.gender_stats_fields = gender_stats_fields
            location_statistics.save!
            # state
          end
        end
      end

      def aggregation_query(start_date, end_date, facility_id, organisation_id)
        created_at_condition = { "created_at": { '$gte' => start_date, '$lte' => end_date }  }
        updated_at_condition = { "updated_at": { '$gte' => start_date, '$lte' => end_date }  }
        admission_date_condition = { "admission_date": { '$gte' => start_date, '$lte' => end_date } }
        match_options = { facility_id: facility_id, organisation_id: organisation_id }
        match_options = match_options.merge({ "$or": [created_at_condition, updated_at_condition,
                                                      admission_date_condition] })
        aggregation_query = [
          { "$match": match_options },
          { "$group": { _id: '$admission_date', admission_lists: { "$push": '$$ROOT' } } }
        ]
      end
    end
  end
end
