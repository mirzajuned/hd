module Analytics::PatientOutcomes
  include Analytics::PatientOutcome
  class CreateService
    def self.call(opdrecord_id)
      # find opdrecord
      opdrecord       = OpdRecord.find_by(id: opdrecord_id)
      patient_id      = opdrecord.try(:patientid)
      admission       = ::Admission.where(patient_id: patient_id).last

      if admission.present?
        ipd_record_data = Inpatient::IpdRecord.where(admission_id: admission.try(:id)).last
        case_sheet_data = CaseSheet.find_by(id: admission.try(:case_sheet_id))
        procedure_list_data = case_sheet_data.procedures.where(:procedurestage.in => ['p', 'performed', 'P', 'Performed']) if case_sheet_data.present?

        if ipd_record_data.present? && procedure_list_data.present?
          # if any procedure performed are there then only do the below
          operative_notes_data = ipd_record_data.operative_notes
          diagnosis_list_data = ipd_record_data.diagnosislist
          all_opdrecord = OpdRecord.where(patientid: patient_id)
          opdrecord_created_dates_and_ids = all_opdrecord.pluck(:created_at, :id)
          opdrecord_created_date = opdrecord_created_dates_and_ids.map { |only_dates| only_dates[0] }
          # patient_data
          patient_data = Patient.find_by(id: patient_id)
          patient_gender = patient_data.try(:gender)
          patient_age = patient_data.try(:age)
          patient_dob_year = patient_data.try(:dob_year).to_i
          helper_instance = Analytics::PatientOutcome::LogmarValues.new
          cornea_procedures_hash = helper_instance.cornea_procedures
          cataract_procedures_hash = helper_instance.cataract_procedures

          procedure_list_data.each_with_index do |procedure, indx|
            if cornea_procedures_hash.key?(procedure.try(:procedure_id)) || cataract_procedures_hash.key?(procedure.try(:procedure_id))
              performed_note_id = procedure.try(:performed_note_id)
              operative_note    = operative_notes_data.find_by(id: performed_note_id)
              patient_outcome   = Analytics::Ophthalmology::PatientSurgicalOutcome.where(
                patient_id: patient_id, admission_id: admission.try(:id),
                surgery_code: procedure.try(:procedurefullcode), laterality: procedure.try(:procedureoriginalside)
              )

              if patient_outcome.length == 0 && operative_note.present?
                surgery_time = procedure.try(:performed_datetime).in_time_zone
                after_surgery, before_surgery = max_min_array(opdrecord_created_date, surgery_time)

                if after_surgery.present? && before_surgery.present?

                  @complete_data = true
                  opd_record_id_before_surgery = opdrecord_created_dates_and_ids[before_surgery][1]
                  opd_record_id_after_surgery  = opdrecord_created_dates_and_ids[after_surgery][1]

                  @last_opd_before_surgery = all_opdrecord.find_by(id: opd_record_id_before_surgery)
                  @first_opd_after_surgery = all_opdrecord.find_by(id: opd_record_id_after_surgery)

                  patient_surgical_outcome = Analytics::Ophthalmology::PatientSurgicalOutcome.new
                  patient_surgical_outcome[:speciality_id] = @last_opd_before_surgery.try(:specalityid)
                  patient_surgical_outcome[:organisation_id] = @last_opd_before_surgery.try(:organisation_id)
                  patient_surgical_outcome[:facility_id] = @last_opd_before_surgery.try(:facility_id)
                  # patient date
                  patient_surgical_outcome[:patient_name] = admission.try(:patient).try(:fullname)
                  patient_surgical_outcome[:patient_id] = admission.try(:patient_id)
                  patient_surgical_outcome[:patient_gender] = patient_gender
                  patient_surgical_outcome[:patient_age] = patient_age
                  patient_surgical_outcome[:patient_dob_year] = patient_dob_year
                  patient_surgical_outcome[:admission_id] = admission.try(:id)

                  patient_surgical_outcome[:icd_code] = procedure.try(:procedurefullcode)
                  patient_surgical_outcome[:type_of_surgery_performed] = operative_note.try(:surgerytype)
                  patient_surgical_outcome[:surgery_code] = procedure.try(:procedurefullcode)
                  patient_surgical_outcome[:laterality] = procedure.try(:procedureside)
                  patient_surgical_outcome[:surgery_date] = procedure.try(:performed_datetime)
                  patient_surgical_outcome[:has_complication] = operative_note.try(:complication)
                  patient_surgical_outcome[:complication_text] = operative_note.try(:complication_comment)
                  patient_surgical_outcome[:doctor] = procedure.try(:performed_by_id)
                  patient_surgical_outcome[:advised_by_doc] = procedure.try(:advised_by_id)
                  #---------------------------Pre data left right data start-----------------
                  # left side data for pre
                  patient_surgical_outcome[:uncorrected_va_pre_surgery_left_far]  = @last_opd_before_surgery.try(:l_visualacuity_unaided)
                  patient_surgical_outcome[:uncorrected_va_pre_surgery_left_near] = @last_opd_before_surgery.try(:l_visualacuity_ua_near)
                  patient_surgical_outcome[:uncorrected_va_recorded_date_pre_surgery_left_near] = @last_opd_before_surgery.created_at.to_s

                  patient_surgical_outcome[:bestcorrected_va_pre_surgery_left_far]  = @last_opd_before_surgery.try(:l_visualacuity_glasses)
                  patient_surgical_outcome[:bestcorrected_va_pre_surgery_left_near] = @last_opd_before_surgery.try(:l_visualacuity_near)
                  patient_surgical_outcome[:bestcorrected_va_recorded_date_pre_surgery_left] = @last_opd_before_surgery.created_at.to_s

                  # right side data for pre
                  patient_surgical_outcome[:uncorrected_va_pre_surgery_right_far] = @last_opd_before_surgery.try(:r_visualacuity_unaided)
                  patient_surgical_outcome[:uncorrected_va_pre_surgery_right_near] = @last_opd_before_surgery.try(:r_visualacuity_ua_near)
                  patient_surgical_outcome[:uncorrected_va_recorded_date_pre_surgery_right] = @last_opd_before_surgery.created_at.to_s

                  patient_surgical_outcome[:bestcorrected_va_pre_surgery_right_far] = @last_opd_before_surgery.try(:r_visualacuity_glasses)
                  patient_surgical_outcome[:bestcorrected_va_pre_surgery_right_near] = @last_opd_before_surgery.try(:l_visualacuity_near)
                  patient_surgical_outcome[:bestcorrected_va_recorded_date_pre_surgery_right] = @last_opd_before_surgery.created_at.to_s

                  #--------------------------- pre data left right end ---------------------------------------

                  #-----------------------------Post data left right side start

                  # left side data for post
                  patient_surgical_outcome[:uncorrected_va_post_surgery_left_far] = @first_opd_after_surgery.try(:l_visualacuity_unaided)
                  patient_surgical_outcome[:uncorrected_va_post_surgery_left_near] = @first_opd_after_surgery.try(:l_visualacuity_ua_near)
                  patient_surgical_outcome[:uncorrected_va_recorded_date_post_surgery_left] = @first_opd_after_surgery.created_at.to_s

                  patient_surgical_outcome[:bestcorrected_va_post_surgery_left_far] = @first_opd_after_surgery.try(:l_visualacuity_glasses)
                  patient_surgical_outcome[:bestcorrected_va_post_surgery_left_near] = @first_opd_after_surgery.try(:l_visualacuity_near)
                  patient_surgical_outcome[:bestcorrected_va_recorded_date_post_surgery_left] = @first_opd_after_surgery.created_at.to_s
                  # right side data

                  patient_surgical_outcome[:uncorrected_va_post_surgery_right_far]  = @first_opd_after_surgery.try(:r_visualacuity_unaided)
                  patient_surgical_outcome[:uncorrected_va_post_surgery_right_near] = @first_opd_after_surgery.try(:r_visualacuity_ua_near)
                  patient_surgical_outcome[:uncorrected_va_recorded_date_post_surgery_right] = @first_opd_after_surgery.created_at.to_s

                  patient_surgical_outcome[:bestcorrected_va_post_surgery_right_far]  = @first_opd_after_surgery.try(:r_visualacuity_glasses)
                  patient_surgical_outcome[:bestcorrected_va_post_surgery_right_near] = @first_opd_after_surgery.try(:r_visualacuity_near)
                  patient_surgical_outcome[:bestcorrected_va_recorded_date_post_surgery_right] = @first_opd_after_surgery.created_at.to_s

                  data_completion_test

                  # percentage_changed

                  # left side near data calculation
                  if @last_opd_before_surgery.try(:l_visualacuity_ua_near).present? && @first_opd_after_surgery.try(:l_visualacuity_ua_near).present?
                    left_near_before = helper_instance.logmar_values_near[@last_opd_before_surgery.try(:l_visualacuity_ua_near)]
                    left_near_after  = helper_instance.logmar_values_near[@first_opd_after_surgery.try(:l_visualacuity_ua_near)]
                    left_near_surgery_percent = helper_instance.percentage_change_in_vision(left_near_before, left_near_after)
                    patient_surgical_outcome[:uncorrected_va_pre_surgery_percentage_left_near] = left_near_surgery_percent
                  end

                  # left side far data calculation
                  if @last_opd_before_surgery.try(:l_visualacuity_unaided).present? && @first_opd_after_surgery.try(:l_visualacuity_unaided).present?
                    left_far_before = helper_instance.logmar_values_far[@last_opd_before_surgery.try(:l_visualacuity_unaided)]
                    left_far_after  = helper_instance.logmar_values_far[@first_opd_after_surgery.try(:l_visualacuity_unaided)]
                    left_far_surgery_percent = helper_instance.percentage_change_in_vision(left_far_before, left_far_after)
                    patient_surgical_outcome[:uncorrected_va_pre_surgery_percentage_left_far] = left_far_surgery_percent
                  end

                  # left side glasses data
                  if @last_opd_before_surgery.try(:l_visualacuity_near).present? && @first_opd_after_surgery.try(:l_visualacuity_near).present?
                    left_near_before_glass = helper_instance.logmar_values_near[@last_opd_before_surgery.try(:l_visualacuity_near)]
                    left_near_after_glass  = helper_instance.logmar_values_near[@first_opd_after_surgery.try(:l_visualacuity_near)]
                    left_near_surgery_percent_glass = helper_instance.percentage_change_in_vision(left_near_before_glass, left_near_after_glass)
                    patient_surgical_outcome[:bestcorrected_va_post_surgery_percentage_left_near] = left_near_surgery_percent_glass
                  end

                  if @last_opd_before_surgery.try(:l_visualacuity_glasses).present? && @first_opd_after_surgery.try(:l_visualacuity_glasses).present?
                    left_far_before_glass = helper_instance.logmar_values_far[@last_opd_before_surgery.try(:l_visualacuity_glasses)]
                    left_far_after_glass  = helper_instance.logmar_values_far[@first_opd_after_surgery.try(:l_visualacuity_glasses)]
                    left_far_surgery_percent_glass = helper_instance.percentage_change_in_vision(left_far_before_glass, left_far_after_glass)
                    patient_surgical_outcome[:bestcorrected_va_post_surgery_percentage_left_far] = left_far_surgery_percent_glass
                  end

                  # right side near data calculation

                  if @last_opd_before_surgery.try(:r_visualacuity_ua_near).present? && @first_opd_after_surgery.try(:r_visualacuity_ua_near).present?
                    right_near_before = helper_instance.logmar_values_near[@last_opd_before_surgery.try(:r_visualacuity_ua_near)]
                    right_near_after  = helper_instance.logmar_values_near[@first_opd_after_surgery.try(:r_visualacuity_ua_near)]
                    right_near_surgery_percent = helper_instance.percentage_change_in_vision(right_near_before, right_near_after)
                    patient_surgical_outcome[:uncorrected_va_pre_surgery_percentage_right_near] = right_near_surgery_percent
                  end

                  if @last_opd_before_surgery.try(:r_visualacuity_unaided).present? && @first_opd_after_surgery.try(:r_visualacuity_unaided).present?
                    right_far_before = helper_instance.logmar_values_far[@last_opd_before_surgery.try(:r_visualacuity_unaided)]
                    right_far_after  = helper_instance.logmar_values_far[@first_opd_after_surgery.try(:r_visualacuity_unaided)]
                    right_far_surgery_percent = helper_instance.percentage_change_in_vision(right_near_before, right_near_after)
                    patient_surgical_outcome[:uncorrected_va_pre_surgery_percentage_right_far] = right_far_surgery_percent
                  end

                  if @last_opd_before_surgery.try(:r_visualacuity_near).present? && @first_opd_after_surgery.try(:r_visualacuity_near).present?
                    right_near_before_glass = helper_instance.logmar_values_near[@last_opd_before_surgery.try(:r_visualacuity_near)]
                    right_near_after_glass  = helper_instance.logmar_values_near[@first_opd_after_surgery.try(:r_visualacuity_near)]
                    right_near_surgery_percent_glass = helper_instance.percentage_change_in_vision(right_near_before_glass, right_near_after_glass)
                    patient_surgical_outcome[:bestcorrected_va_post_surgery_percentage_right_near] = right_near_surgery_percent_glass
                  end

                  if @last_opd_before_surgery.try(:r_visualacuity_glasses).present? && @first_opd_after_surgery.try(:r_visualacuity_glasses).present?
                    right_far_before_glass = helper_instance.logmar_values_far[@last_opd_before_surgery.try(:r_visualacuity_glasses)]
                    right_far_after_glass  = helper_instance.logmar_values_far[@first_opd_after_surgery.try(:r_visualacuity_glasses)]
                    right_far_surgery_percent_glass = helper_instance.percentage_change_in_vision(right_far_before_glass, right_far_after_glass)
                    patient_surgical_outcome[:bestcorrected_va_post_surgery_percentage_right_far] = right_far_surgery_percent_glass
                  end

                  patient_surgical_outcome[:complete_data] = @complete_data
                  patient_surgical_outcome.save!

                end # after_surgery before surgery end

              end # length condition end
            end
          end # loop end

        end

      end
    end

    def self.max_min_array(array, compare_date)
      array_data = array.map { |date| date.to_i - compare_date.to_i }
      positive_array = array_data.select { |date| date > 0 }
      negative_array = array_data.select { |date| date < 0 }
      min_positive   = positive_array.min
      min_negative   = negative_array.max
      greater_index  = array_data.find_index(min_positive)
      less_index     = array_data.find_index(min_negative)
      return greater_index, less_index
    end

    def self.data_completion_test
      if @last_opd_before_surgery.try(:l_visualacuity_ua_near).present? && @first_opd_after_surgery.try(:l_visualacuity_ua_near).blank? ||
         @last_opd_before_surgery.try(:l_visualacuity_ua_near).blank? && @first_opd_after_surgery.try(:l_visualacuity_ua_near).present?
        @complete_data = false
      end

      if @last_opd_before_surgery.try(:l_visualacuity_unaided).present? && @first_opd_after_surgery.try(:l_visualacuity_unaided).blank? ||
         @last_opd_before_surgery.try(:l_visualacuity_unaided).blank? && @first_opd_after_surgery.try(:l_visualacuity_unaided).present?
        @complete_data = false
      end

      if @last_opd_before_surgery.try(:l_visualacuity_near).present? && @first_opd_after_surgery.try(:l_visualacuity_near).blank? ||
         @last_opd_before_surgery.try(:l_visualacuity_near).blank? && @first_opd_after_surgery.try(:l_visualacuity_near).present?
        @complete_data = false
      end

      if @last_opd_before_surgery.try(:l_visualacuity_glasses).present? && @first_opd_after_surgery.try(:l_visualacuity_glasses).blank? ||
         @last_opd_before_surgery.try(:l_visualacuity_glasses).blank? && @first_opd_after_surgery.try(:l_visualacuity_glasses).present?
        @complete_data = false
      end
      # sss

      if @last_opd_before_surgery.try(:r_visualacuity_ua_near).present? && @first_opd_after_surgery.try(:r_visualacuity_ua_near).blank? ||
         @last_opd_before_surgery.try(:r_visualacuity_ua_near).blank? && @first_opd_after_surgery.try(:r_visualacuity_ua_near).present?
        @complete_data = false
      end

      if @last_opd_before_surgery.try(:r_visualacuity_unaided).present? && @first_opd_after_surgery.try(:r_visualacuity_unaided).blank? ||
         @last_opd_before_surgery.try(:r_visualacuity_unaided).blank? && @first_opd_after_surgery.try(:r_visualacuity_unaided).present?
        @complete_data = false
      end

      if @last_opd_before_surgery.try(:r_visualacuity_glasses).present? && @first_opd_after_surgery.try(:r_visualacuity_glasses).blank? ||
         @last_opd_before_surgery.try(:r_visualacuity_glasses).blank? && @first_opd_after_surgery.try(:r_visualacuity_glasses).present?
        @complete_data = false
      end

      if @last_opd_before_surgery.try(:r_visualacuity_glasses).present? && @first_opd_after_surgery.try(:r_visualacuity_glasses).blank? ||
         @last_opd_before_surgery.try(:r_visualacuity_glasses).blank? && @first_opd_after_surgery.try(:r_visualacuity_glasses).present?
        @complete_data = false
      end
    end
  end
end

# fields to be included

# r_visualacuity_unaided_p
# r_visualacuity_unaided
# l_visualacuity_unaided_p
# l_visualacuity_unaided
