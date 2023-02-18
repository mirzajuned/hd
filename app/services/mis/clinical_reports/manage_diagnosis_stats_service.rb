module Mis::ClinicalReports
  class ManageDiagnosisStatsService
    class << self
      def call(filtered_diagnoses, organisation_ids, diagnosis_date, mis_logger=nil)
        @mis_logger = mis_logger || Logger.new("#{Rails.root}/log/mis_diagnosis_logger.log")
        group_by_organisations = filtered_diagnoses.group_by { |al| al[:organisation_id] }
        group_by_organisations.each do |organisation_id, group_by_organisation|
          @organisation_id = organisation_id
          group_by_facilities = group_by_organisation.group_by { |al| al[:facility_id] }
          group_by_facilities.each do |facility_id, group_by_facility|
            @facility_id = facility_id
            @filter_fields_hash = { organisation_id: @organisation_id, facility_id: @facility_id }
            facility = Facility.find_by(id: @facility_id)
            @facility_name = facility.try(:name)
            @facility_timezone = facility.try(:time_zone)
            diagnoses = group_by_facility.select do |diagnosis|
              diagnosis[:diagnosis_date].to_date == diagnosis_date
            end
            if diagnoses && diagnoses.count > 0
              date_wise_diagnoses = diagnoses.group_by { |i| i[:diagnosis_date].to_date }
              stats_by_department(date_wise_diagnoses)
            end
          end
        end
      end
      # end call method

      def stats_by_department(diagnoses)
        diagnoses.each do |diagnosis_date, date_wise_diagnoses|
          @filter_fields_hash[:diagnosis_date] = diagnosis_date
          department_wise_diagnoses = date_wise_diagnoses.group_by do |date_wise_diagnosis|
            date_wise_diagnosis[:from_department_id]
          end
          specialty_wise_stats(department_wise_diagnoses, diagnosis_date)
        end
      end
      # end stats_by_department method

      def specialty_wise_stats(department_wise_diagnoses, diagnosis_date)
        department_wise_diagnoses.each do |department_id, d_diagnoses|
          @filter_fields_hash[:department_id] = department_id
          specialty_wise_diagnoses = d_diagnoses.group_by do |department_wise_diagnosis|
            department_wise_diagnosis[:specialty_id]
          end
          doctor_wise_stats(specialty_wise_diagnoses, diagnosis_date, department_id)
        end
      end
      # end specialty_wise_stats

      def doctor_wise_stats(specialty_wise_diagnoses, diagnosis_date, department_id)
        specialty_wise_diagnoses.each do |specialty_id, s_diagnoses|
          @filter_fields_hash[:specialty_id] = specialty_id
          doctor_wise_diagnoses = s_diagnoses.group_by do |specialty_wise_diagnosis|
            specialty_wise_diagnosis[:doctor_id]
          end
          diagnoses_code_wise_stats(doctor_wise_diagnoses, diagnosis_date, department_id, specialty_id)
        end
      end
      # end user_wise_stats

      def diagnoses_code_wise_stats(doctor_wise_diagnoses, diagnosis_date, department_id, specialty_id)
        doctor_wise_diagnoses.each do |doctor_id, doctor_wise_diagnosis|
          @filter_fields_hash[:doctor_id] = doctor_id
          diagnoses_code_stats = doctor_wise_diagnosis.group_by do |dtype_diagnosis|
            dtype_diagnosis[:full_diagnosis_code]
          end
          diagnoses_wise_stats(diagnoses_code_stats, diagnosis_date, department_id, specialty_id, doctor_id)
        end
        # end doctor_wise_diagnoses loop
      end
      # end diagnoses_code_wise_stats

      def diagnoses_wise_stats(diagnoses_code_stats, diagnosis_date, department_id, specialty_id, doctor_id)
        diagnoses_code_stats.each do |diagnosis_code, type_wise_diagnosis|
          @filter_fields_hash[:diagnosis_code] = diagnosis_code
          diagnoses_stats = type_wise_diagnosis.group_by do |d_diagnosis|
            d_diagnosis[:diagnosis_id]
          end
          generate_data(diagnoses_stats, diagnosis_date, department_id, specialty_id, doctor_id, diagnosis_code)
        end
        # end doctor_wise_diagnoses loop
      end
      # end diagnoses_code_wise_stats

      def generate_data(diagnoses_stats, diagnosis_date, department_id, specialty_id, doctor_id, diagnosis_code)
        diagnoses_stats.each do |diagnosis_id, diagnosis_stats|
          specialty = Specialty.find_by(id: specialty_id)
          specialty_name = specialty.try(:name)
          department = Department.find_by(id: department_id)
          department_name = department.try(:display_name)
          department_order = department.try(:order)
          doctor = User.find_by(id: doctor_id)
          doctor_name = doctor.try(:fullname)
          
          diagnosis_type_ids = diagnosis_stats.pluck(:diagnosis_type_id).uniq
          diagnosis_names = diagnosis_stats.pluck(:full_diagnosis_name).uniq
          diagnosis_original_names = diagnosis_stats.pluck(:diagnosis_original_name).uniq
          @mis_logger.info("======== multiple diagnosis_type_ids: #{diagnosis_type_ids.count}") if diagnosis_type_ids.count > 1
          diagnosis_type_id = diagnosis_type_ids.first
          diagnosis_name = diagnosis_names.first
          diagnosis_original_name = diagnosis_original_names.first
          # diagnosis_details = diagnosis_all_details(diagnosis_type_id, diagnosis_code)

          gender_group = diagnosis_stats.group_by { |al| al[:patient_display_fields][:gender]  }
          male = gender_group['Male'].to_a.size
          female = gender_group['Female'].to_a.size
          transgender = gender_group['Transgender'].to_a.size
          gender_undefined = gender_group[nil].to_a.size

          age_group = diagnosis_stats.group_by{ |al| al[:patient_age_at_encounter] }
          till_fifteen = above_fifteen_till_fiftyfive = above_fiftyfive = undefined = 0
          male_till_fifteen = female_till_fifteen = transgender_till_fifteen = unspecified_till_fifteen = 0
          male_above_fifteen_till_fiftyfive = female_above_fifteen_till_fiftyfive = transgender_above_fifteen_till_fiftyfive = 0
          unspecified_above_fifteen_till_fiftyfive = male_above_fiftyfive = female_above_fiftyfive = 0
          transgender_above_fiftyfive = unspecified_above_fiftyfive = above_fiftyfive = 0
          male_undefined = female_undefined = transgender_undefined = unspecified_undefined = 0

          age_group.each do |key, val|
            age_val = key.to_i
            males = val.select{|patients| patients['patient_display_fields']['gender'].present? && patients['patient_display_fields']['gender'] == 'Male'}
            females = val.select{|patients| patients['patient_display_fields']['gender'].present? && patients['patient_display_fields']['gender'] == 'Female'}
            transgender = val.select{|patients| patients['patient_display_fields']['gender'].present? && patients['patient_display_fields']['gender'] == 'Transgender'}
            unspecified_gender = val.select{|patients| patients['patient_display_fields']['gender'].nil?}
            case age_val
              when 0..15
                till_fifteen += 1
                male_till_fifteen += (males.select{|pat| pat['patient_age_at_encounter'].to_i == age_val}.count)
                female_till_fifteen += (females.select{|pat| pat['patient_age_at_encounter'].to_i == age_val}.count)
                transgender_till_fifteen += (transgender.select{|pat| pat['patient_age_at_encounter'].to_i == age_val}.count)
                unspecified_till_fifteen += (unspecified_gender.select{|pat| pat['patient_age_at_encounter'].to_i == age_val}.count)
              when 16..54
                above_fifteen_till_fiftyfive += 1
                male_above_fifteen_till_fiftyfive += (males.select{|pat| pat['patient_age_at_encounter'].to_i == age_val}.count)
                female_above_fifteen_till_fiftyfive += (females.select{|pat| pat['patient_age_at_encounter'].to_i == age_val}.count)
                transgender_above_fifteen_till_fiftyfive += (transgender.select{|pat| pat['patient_age_at_encounter'].to_i == age_val}.count)
                unspecified_above_fifteen_till_fiftyfive += (unspecified_gender.select{|pat| pat['patient_age_at_encounter'].to_i == age_val}.count)
              when 55..150
                above_fiftyfive += 1
                male_above_fiftyfive += (males.select{|pat| pat['patient_age_at_encounter'].to_i == age_val}.count)
                female_above_fiftyfive += (females.select{|pat| pat['patient_age_at_encounter'].to_i == age_val}.count)
                transgender_above_fiftyfive += (transgender.select{|pat| pat['patient_age_at_encounter'].to_i == age_val}.count)
                unspecified_above_fiftyfive += (unspecified_gender.select{|pat| pat['patient_age_at_encounter'].to_i == age_val}.count)
              else
                undefined += 1
                male_undefined += (males.select{|pat| pat['patient_age_at_encounter'].nil? || pat['patient_age_at_encounter'].to_i == 1000}.count)
                female_undefined += (females.select{|pat| pat['patient_age_at_encounter'].nil? || pat['patient_age_at_encounter'].to_i == 1000}.count)
                transgender_undefined += (transgender.select{|pat| pat['patient_age_at_encounter'].nil? || pat['patient_age_at_encounter'].to_i == 1000}.count)
                unspecified_undefined += (unspecified_gender.select{|pat| pat['patient_age_at_encounter'].nil? || pat['patient_age_at_encounter'].to_i == 1000}.count)
            end
          end

          age_stats_fields = { till_fifteen: till_fifteen, above_fifteen_till_fiftyfive: above_fifteen_till_fiftyfive,
                               above_fiftyfive: above_fiftyfive, undefined: undefined }
          gender_stats_fields = { male: male, female: female, transgender: transgender, undefined: gender_undefined }

          gender_wise_age = {
            male_till_fifteen: male_till_fifteen, female_till_fifteen: female_till_fifteen, transgender_till_fifteen: transgender_till_fifteen,
            unspecified_till_fifteen: unspecified_till_fifteen, male_above_fifteen_till_fiftyfive: male_above_fifteen_till_fiftyfive,
            female_above_fifteen_till_fiftyfive: female_above_fifteen_till_fiftyfive, 
            transgender_above_fifteen_till_fiftyfive: transgender_above_fifteen_till_fiftyfive, 
            unspecified_above_fifteen_till_fiftyfive: unspecified_above_fifteen_till_fiftyfive,
            male_above_fiftyfive: male_above_fiftyfive, female_above_fiftyfive: female_above_fiftyfive,
            unspecified_above_fiftyfive: unspecified_above_fiftyfive, male_undefined: male_undefined,
            female_undefined: female_undefined, transgender_undefined: transgender_undefined,
            unspecified_undefined: unspecified_undefined
          }

          diagnosis_stats = MisClinical::Common::DiagnosisStats.find_or_create_by(
            diagnosis_date: diagnosis_date, diagnosis_id: diagnosis_id, facility_id: @facility_id, 
            department_id: department_id, specialty_id: specialty_id, doctor_id: doctor_id
          )

          diagnosis_stats.organisation_id = @organisation_id
          diagnosis_stats.facility_name = @facility_name
          diagnosis_stats.facility_timezone = @facility_timezone
          diagnosis_stats.department_name = department_name
          diagnosis_stats.department_order = department_order
          diagnosis_stats.specialty_name = specialty_name
          diagnosis_stats.doctor_name = doctor_name
          diagnosis_stats.diagnosis_code = diagnosis_code
          diagnosis_stats.diagnosis_name = diagnosis_name
          diagnosis_stats.diagnosis_original_name = diagnosis_original_name
          diagnosis_stats.patient_age_fields = age_stats_fields
          diagnosis_stats.patient_gender_fields = gender_stats_fields
          diagnosis_stats.gender_wise_age = gender_wise_age

          diagnosis_stats.save!
        end
      end
      # end generate_data method

      private

      def diagnosis_all_details(diagnosis_type_id, diagnosis_code)
        # Global.ehrcommon.diagnosis_icd/Global.ehrcommon.diagnosis_custom
        diagnosis_type = if diagnosis_type_id == 447634004
                            'icd'
                         elsif diagnosis_type_id == 860573009
                            'custom_icd'
                         # elsif diagnosis_type_id == 148006
                         #    'provisional'
                         # elsif diagnosis_type_id == 288790002
                         #    'commentbox'
                         end
        diagnosis = "#{diagnosis_type}_diagnosis".classify.constantize.find_by(
          code: diagnosis_code.to_s
        )
        diagnosis
      end
    end
  end
end