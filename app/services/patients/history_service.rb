module Patients
  class HistoryService
    def self.call(record, current_user, patient_id)
      @patient = Patient.find_by(id: patient_id)
      if @patient.present?
        @patient.no_opthalmic_history_advised = record.no_opthalmic_history_advised
        @patient.no_systemic_history_advised = record.no_systemic_history_advised
        @patient.no_allergy_advised = record.no_allergy_advised
        @patient.opthal_history_comment = record.opthal_history_comment
        @patient.history_comment = record.history_comment
        @patient.others_allergies = record.others_allergies
        @patient.drug_allergies_comment = record.drug_allergies_comment
        @patient.contact_allergies_comment = record.contact_allergies_comment
        @patient.food_allergies_comment = record.food_allergies_comment
        if record.templatetype == 'paediatrics'
          @patient.nutritional_assessment = record.nutritional_assessment
          @patient.nutritional_assessment_comment = record.nutritional_assessment_comment
          @patient.immunization_assessment = record.immunization_assessment
          @patient.immunization_assessment_comment = record.immunization_assessment_comment
        end
        # speciality histories
        @patient.speciality_histories = ""
        @patient.speciality_history_records.delete_all
        if record.speciality_history_records.present?
          @patient.speciality_histories = record.speciality_histories
          record.speciality_history_records.each do |speciality|
            history = @patient.speciality_history_records.find_by(name: speciality.name) || @patient.speciality_history_records.new
            history.name = speciality.name
            history.l_duration = speciality.l_duration
            history.l_duration_unit = speciality.l_duration_unit
            history.r_duration = speciality.r_duration
            history.r_duration_unit = speciality.r_duration_unit
            history.comment = speciality.comment
            history.l_history_started = speciality.l_history_started
            history.r_history_started = speciality.r_history_started
            history.l_hidden_duration = speciality.l_hidden_duration
            history.r_hidden_duration = speciality.r_hidden_duration
            history.save
          end
        end
        # end

        # patient history service
        data_hash = Hash.new
        data_hash["old_systemic_history"] = @patient.try(:personal_histories)
        data_hash["old_eye_drop_allergy"] = @patient.try(:eye_drops)
        data_hash["new_systemic_history"] = record.personal_histories
        data_hash["new_eye_drop_allergy"] = record.eye_drops
        data_hash["old_dob_year"]         = @patient.try(:dob_year)
        data_hash["new_dob_year"]         = @patient.try(:dob_year)
        data_hash["organisation_id"]      = @patient.try(:reg_hosp_ids)[0]
        data_hash["old_gender"]           = @patient.try(:gender)
        data_hash["new_gender"]           = @patient.try(:gender)
        Analytics::UpdateService.call(data_hash, nil, nil, "patients_history")

        # Personal Hitories
        @patient.personal_histories = ""
        @patient.personal_history_records.delete_all
        if record.personal_history_records.present?
          @patient.personal_histories = record.personal_histories
          record.personal_history_records.each do |personal|
            history = @patient.personal_history_records.find_by(name: personal.name) || @patient.personal_history_records.new
            history.name = personal.name
            history.duration = personal.duration
            history.duration_unit = personal.duration_unit
            history.comment = personal.comment
            history.history_started = personal.history_started
            history.hidden_duration = personal.hidden_duration
            history.save
          end
        end
        # end

        # allergies History
        @patient.drug_allergies = ""
        @patient.antimicrobial_agents = ""
        @patient.antifungal_agents = ""
        @patient.antiviral_agents = ""
        @patient.nsaids = ""
        @patient.eye_drops = ""
        @patient.contact_allergies = ""
        @patient.food_allergies = ""
        @patient.allergy_histories.delete_all
        @patient.drug_allergies = record.drug_allergies
        @patient.antimicrobial_agents = record.antimicrobial_agents
        @patient.antifungal_agents = record.antifungal_agents
        @patient.antiviral_agents = record.antiviral_agents
        @patient.nsaids = record.nsaids
        @patient.eye_drops = record.eye_drops
        @patient.contact_allergies = record.contact_allergies
        @patient.food_allergies = record.food_allergies
        @patient.allergy_histories

        if record.allergy_histories.present?
          record.allergy_histories.each do |allergy|
            history = @patient.allergy_histories.find_by(name: allergy.name) || @patient.allergy_histories.new
            history.allergy_type = allergy.allergy_type
            history.allergy_subtype = allergy.allergy_subtype
            history.name = allergy.name
            history.duration = allergy.duration
            history.duration_unit = allergy.duration_unit
            history.comment = allergy.comment
            history.history_started = allergy.history_started
            history.hidden_duration = allergy.hidden_duration
            history.save
          end
        end
        # end

        # other histories
        if record.other_history.present?
          @opd_other_history = record.other_history
          other_history = @patient.other_history
          other_history.medical_history = @opd_other_history.medical_history
          other_history.family_history = @opd_other_history.family_history
          other_history.specialstatus = @opd_other_history.specialstatus
          other_history.save
        end
        # end

        @patient.save
      end
    end
  end
end
