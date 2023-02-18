# rubocop:disable all
module Mis::NewClinicalReports
  class ReferralStatsRake
    class << self
      # rubocop:disable Layout/LineLength
      def call(start_date, end_date, organisation_ids)
        mis_logger = Logger.new("#{Rails.root}/log/mis_referral_stats_logger.log")
        # query_start = Time.current
        # get all appointment for specific date for organisation and facility
        query = aggregation_query(start_date, end_date, organisation_ids)
        query_list = MisClinical::Opd::ClinicalReportOpd.where(query)
        # query_end = Time.current
        # mis_logger.info(" ======== ReferralStatsRake query time taken: #{(query_end.to_f - query_start.to_f).to_i}")
        date_wise_list = query_list.group_by{|x| x[:appointment_display_fields][:appointment_date]}
        date_wise_list.keys.uniq.each do |appointment_date|
          appointment_query = appointment_aggregation_query(appointment_date, organisation_ids)
          appointment_query_list = MisClinical::Opd::ClinicalReportOpd.where(appointment_query)
          appointment_date_wise_list = appointment_query_list.group_by{|x| x[:appointment_display_fields][:appointment_date]}
          appointment_date_wise_list.each do |key, value|
            created_date = key
            group_by_organisations = value.group_by { |al| al[:organisation_id] }
            group_by_organisations.each do |organisation_id, group_by_organisation|
              group_by_facilities = group_by_organisation.group_by { |al| al[:facility_id] }
              group_by_facilities.each do |facility_id, group_by_facility|
                # data_calc_start = Time.current
                referral_codes = group_by_facility.group_by { |al| al[:patient_display_fields][:referral_type_id] }
                referral_codes.each do |k, data|
                  referral = ReferralType.find_by(id: k)
                  referral_name = referral&.try(:name)
                  referral_type_id = k
                  appointmenttype_group = data.group_by { |al| al[:appointment_display_fields][:appointmenttype]  }
                  gender_group = data.group_by { |al| al[:patient_display_fields][:patient_gender]  }
                  patient_visit = data.group_by { |al| al[:patient_display_fields][:patient_visit] }
                  follow_up = patient_visit['Followup'].to_a.size
                  new = patient_visit['New'].to_a.size
                  post_visit = patient_visit['Post Op'].to_a.size
                  walkin = appointmenttype_group['walkin'].to_a.size
                  appointment = appointmenttype_group['appointment'].to_a.size
                  male = gender_group['Male'].to_a.size
                  female = gender_group['Female'].to_a.size
                  transgender = gender_group['Transgender'].to_a.size
                  gender_undefined = gender_group[nil].to_a.size
                  age = data.map do |val|
                    [val[:patient_display_fields][:age], val[:patient_display_fields][:patient_age]]
                  end
                  till_twenty = above_twenty_till_forty = above_forty_till_sixty = above_sixty_till_eighty = above_eighty = undefined = 0
                  age.each do |val|
                    if val[0].nil? && !val[1].nil?
                      age_val = val[1].to_i
                    elsif !val[0].nil? && val[1].nil?
                      age_val = nil
                    else
                      age_val = val[0]
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
                  patient_type_stats_fields = { new: new, follow_up: follow_up, post_op: post_visit }
                  appointment_type_stats_fields = { walkin: walkin, appointment: appointment }

                  referral_statistics =  MisClinical::Opd::PatientReferralStats.find_or_create_by(
                    created_date: created_date, facility_id: facility_id,
                    referral_type_id: referral_type_id
                  )
                  referral_statistics.organisation_id = organisation_id
                  referral_statistics.age_stats_fields = age_stats_fields
                  referral_statistics.gender_stats_fields = gender_stats_fields
                  referral_statistics.patient_type_stats_fields = patient_type_stats_fields
                  referral_statistics.appointment_type_stats_fields = appointment_type_stats_fields
                  referral_statistics.referral_name = referral_name
                  referral_statistics.save!
                end
                # data_calc_end = Time.current
                # mis_logger.info(" ********** ReferralStatsRake info generate and save time taken: #{(data_calc_end.to_f - data_calc_start.to_f).to_i}")
              end
            end
          end
        end
      rescue StandardError => e
        mis_logger.info(" === Error in ReferralStatsRake - out : #{e.inspect}")
      end
      
      def aggregation_query(start_date, end_date, organisation_ids)
        match_options = { organisation_id: { "$in": organisation_ids },
                          "filtering_fields.appointment_date": { "$gte"=> start_date, "$lte" => end_date } }
        match_options = match_options.merge( { "patient_display_fields.referral_type_id": { "$exists": true, "$ne": nil } })
        return match_options
      end

      def appointment_aggregation_query(appointment_date, organisation_ids)
        match_options = { 
          organisation_id: { "$in": organisation_ids },
          "filtering_fields.appointment_date": { "$gte"=> appointment_date, "$lte" => appointment_date }
        }
        match_options = match_options.merge( { "patient_display_fields.referral_type_id": { "$exists": true, "$ne": nil } })
        return match_options
      end
    end
  end
end
