# rubocop:disable all
module Mis::NewClinicalReports
  class LocationStatsRake
    class << self
      # rubocop:disable Layout/LineLength
      def call(start_date, end_date, organisation_ids)
        mis_logger = Logger.new("#{Rails.root}/log/mis_location_stats_logger.log")
        # query = aggregation_query(start_date, end_date, organisation_ids)
        # date_wise_list = AppointmentListView.collection.aggregate(query,{ allow_disk_use: true }).to_a
        date_wise_list = AppointmentListView.where(appointment_date: start_date..end_date, :organisation_id.in => organisation_ids).group_by(&:appointment_date)
        date_wise_list.each do |appointment_date, appointment_lists|
          key = appointment_date
          value = appointment_lists
          appointment_date = key
          group_by_organisations = value.group_by { |al| al[:organisation_id] }
          group_by_organisations.each do |organisation_id, group_by_organisation|
            group_by_facilities = group_by_organisation.group_by { |al| al[:facility_id] }
            group_by_facilities.each do |facility_id, group_by_facility|
              # data_calc_start = Time.current
              city = group_by_facility.group_by { |al| al[:city].to_s }
              state = group_by_facility.group_by { |al| al[:state].to_s }
              commune = group_by_facility.group_by { |al| al[:commune].to_s }
              district = group_by_facility.group_by { |al| al[:district].to_s }
              common_arr = [[city, 'city'], [state, 'state'], [commune, 'commune'], [district, 'district']]
              common_arr.each do |loc|
                loc[0].each do |k, data|
                  location_name = k
                  location_type = loc[1]
                  current_appointmenttype_group = data.group_by { |al| al[:appointmenttype] }
                  gender_group = data.group_by { |al| al[:patient_gender] }

                  walkin = current_appointmenttype_group['walkin'].to_a.size
                  appointment = current_appointmenttype_group['appointment'].to_a.size

                  # TODO: RUN ONLY ONCE IN A DAY.
                  #  todo run this table rake first MisClinical::Opd::ClinicalReportOpd then others
                  #  todo below comment is case when we run every 5 minutes
                  # clinical_opd_record = MisClinical::Opd::ClinicalReportOpd.where(:created_at.gte => start_date, :created_at.lte => end_date))
                  clinical_opd_record = case location_type
                                          when 'city'
                                            MisClinical::Opd::ClinicalReportOpd.where('appointment_display_fields.appointment_date' => appointment_date, 'patient_display_fields.city' => location_name, facility_id: facility_id.to_s, organisation_id: organisation_id.to_s)
                                          when 'state'
                                            MisClinical::Opd::ClinicalReportOpd.where('appointment_display_fields.appointment_date' => appointment_date, 'patient_display_fields.state' => location_name, facility_id: facility_id.to_s, organisation_id: organisation_id.to_s)
                                          when 'commune'
                                            MisClinical::Opd::ClinicalReportOpd.where('appointment_display_fields.appointment_date' => appointment_date, 'patient_display_fields.commune' => location_name, facility_id: facility_id.to_s, organisation_id: organisation_id.to_s)
                                          when 'district'
                                            MisClinical::Opd::ClinicalReportOpd.where('appointment_display_fields.appointment_date' => appointment_date, 'patient_display_fields.district' => location_name, facility_id: facility_id.to_s, organisation_id: organisation_id.to_s)
                                        end
                  patient_visit = clinical_opd_record.group_by { |al| al['patient_display_fields.patient_visit'] }
                  follow_up = patient_visit['Followup'].to_a.size
                  new = patient_visit['New'].to_a.size
                  post_visit = patient_visit['Post Op'].to_a.size

                  male = gender_group['Male'].to_a.size
                  female = gender_group['Female'].to_a.size
                  transgender = gender_group['Transgender'].to_a.size
                  gender_undefined = gender_group[nil].to_a.size
                  till_twenty = above_twenty_till_forty = above_forty_till_sixty = above_sixty_till_eighty = above_eighty = undefined = 0
                  age = data.pluck(:age, :patient_age)
                  age.each do |age_value|
                    if age_value[0].nil? && !age_value[1].nil?
                      age_val = age_value[1].to_i
                    elsif !age_value[0].nil? && age_value[1].nil?
                      age_val = nil
                    else
                      age_val = age_value[0]
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

                  location_statistics =  MisClinical::Opd::LocationStatistic.find_or_create_by(
                    appointment_date: appointment_date, facility_id: facility_id,
                    type: loc[1], location_name: location_name
                  )
                  location_statistics.organisation_id = organisation_id
                  location_statistics.age_stats_fields = age_stats_fields
                  location_statistics.gender_stats_fields = gender_stats_fields
                  location_statistics.patient_type_stats_fields = patient_type_stats_fields
                  location_statistics.appointment_type_stats_fields = appointment_type_stats_fields
                  location_statistics.save!
                end
              end
            end
          end
        end
      rescue StandardError => e
        mis_logger.info(" === Error in LocationStatsRake - out : #{e.inspect}")
      end

      def aggregation_query(start_date, end_date, organisation_ids)
        match_options =  { organisation_id: { "$in": organisation_ids },
                            "appointment_date": { "$gte"=> start_date, "$lte" => end_date } }
        aggregationquery = [
                  { "$match": match_options },
                  { "$group":  {_id: '$appointment_date', appointment_lists: { "$push": '$$ROOT' }} }
                ]
        aggregationquery
      end
    end
  end
end
