class PatientJobs::PatientHistoryJob < ActiveJob::Base
  queue_as :urgent
  def perform(patientid)
    patient = Patient.find_by(id: patientid)
    if patient.present?
      if patient.patient_history.present?
        @ophthalmic_history = patient.patient_history.patientpersonalhistory
        if @ophthalmic_history.present?
          patient.opthal_history_comment = @ophthalmic_history.opthal_history_comment
          if @ophthalmic_history.glaucoma == "true"
            specility_name = "glaucoma"
            @patient_glaucoma = patient.speciality_history_records.find_by(name: specility_name) || patient.speciality_history_records.new
            if patient.speciality_histories.present?
              if !patient.speciality_histories.include?(specility_name)
                patient.speciality_histories = patient.speciality_histories + "," + specility_name
              end
            else
              patient.speciality_histories = specility_name
            end
            @patient_glaucoma.name = specility_name
            @patient_glaucoma.l_duration = @ophthalmic_history.glaucoma_duration
            @patient_glaucoma.l_duration_unit = @ophthalmic_history.glaucoma_duration_unit
            @patient_glaucoma.r_duration = @ophthalmic_history.glaucoma_duration
            @patient_glaucoma.r_duration_unit = @ophthalmic_history.glaucoma_duration_unit
            @patient_glaucoma.record_created_date = patient.created_at
            @patient_glaucoma.record_updated_date = Time.current
            if @ophthalmic_history.glaucoma_duration.present? && @ophthalmic_history.glaucoma_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.glaucoma_duration_unit)
                @patient_glaucoma.r_history_started = patient.updated_at - eval("#{@ophthalmic_history.glaucoma_duration.to_i}.#{@ophthalmic_history.glaucoma_duration_unit}")
                @patient_glaucoma.l_history_started = patient.updated_at - eval("#{@ophthalmic_history.glaucoma_duration.to_i}.#{@ophthalmic_history.glaucoma_duration_unit}")
              end
            end
            @patient_glaucoma.save
          elsif @ophthalmic_history.glaucoma == "false"
            speciality_history = "glaucoma"
            @update = patient.speciality_history_records.find_by(name: speciality_history)
            if @update.present?
              @complaints_list = patient.speciality_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(speciality_history)
              patient.speciality_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end

          if @ophthalmic_history.retinal_detachment == "true"
            specility_name = "retinal_detachment"
            @patient_retinal_detachment = patient.speciality_history_records.find_by(name: specility_name) || patient.speciality_history_records.new
            if patient.speciality_histories.present?
              if !patient.speciality_histories.include?(specility_name)
                patient.speciality_histories = patient.speciality_histories + "," + specility_name
              end
            else
              patient.speciality_histories = specility_name
            end
            @patient_retinal_detachment.name = specility_name
            @patient_retinal_detachment.l_duration = @ophthalmic_history.retinal_detachment_duration
            @patient_retinal_detachment.l_duration_unit = @ophthalmic_history.retinal_detachment_duration_unit
            @patient_retinal_detachment.r_duration = @ophthalmic_history.retinal_detachment_duration
            @patient_retinal_detachment.r_duration_unit = @ophthalmic_history.retinal_detachment_duration_unit
            @patient_retinal_detachment.record_created_date = patient.created_at
            @patient_retinal_detachment.record_updated_date = Time.current
            if @ophthalmic_history.retinal_detachment_duration.present? && @ophthalmic_history.retinal_detachment_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.retinal_detachment_duration_unit)
                @patient_retinal_detachment.r_history_started = patient.updated_at - eval("#{@ophthalmic_history.retinal_detachment_duration.to_i}.#{@ophthalmic_history.retinal_detachment_duration_unit}")
                @patient_retinal_detachment.l_history_started = patient.updated_at - eval("#{@ophthalmic_history.retinal_detachment_duration.to_i}.#{@ophthalmic_history.retinal_detachment_duration_unit}")
              end
            end
            @patient_retinal_detachment.save
          elsif @ophthalmic_history.retinal_detachment == "false"
            speciality_history = "retinal_detachment"
            @update = patient.speciality_history_records.find_by(name: speciality_history)
            if @update.present?
              @complaints_list = patient.speciality_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(speciality_history)
              patient.speciality_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end

          if @ophthalmic_history.glasses == "true"
            specility_name = "glasses"
            @patient_glasses = patient.speciality_history_records.find_by(name: specility_name) || patient.speciality_history_records.new
            if patient.speciality_histories.present?
              if !patient.speciality_histories.include?(specility_name)
                patient.speciality_histories = patient.speciality_histories +  "," + specility_name
              end
            else
              patient.speciality_histories = specility_name
            end
            @patient_glasses.name = specility_name
            @patient_glasses.l_duration = @ophthalmic_history.glasses_duration
            @patient_glasses.l_duration_unit = @ophthalmic_history.glasses_duration_unit
            @patient_glasses.r_duration = @ophthalmic_history.glasses_duration
            @patient_glasses.r_duration_unit = @ophthalmic_history.glasses_duration_unit
            @patient_glasses.record_created_date = patient.created_at
            @patient_glasses.record_updated_date = Time.current
            if @ophthalmic_history.glasses_duration.present? && @ophthalmic_history.glasses_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.glasses_duration_unit)
                @patient_glasses.r_history_started = patient.updated_at - eval("#{@ophthalmic_history.glasses_duration.to_i}.#{@ophthalmic_history.glasses_duration_unit}")
                @patient_glasses.l_history_started = patient.updated_at - eval("#{@ophthalmic_history.glasses_duration.to_i}.#{@ophthalmic_history.glasses_duration_unit}")
              end
            end
            @patient_glasses.save
          elsif @ophthalmic_history.glasses == "false"
            speciality_history = "glasses"
            @update = patient.speciality_history_records.find_by(name: speciality_history)
            if @update.present?
              @complaints_list = patient.speciality_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(speciality_history)
              patient.speciality_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end

          if @ophthalmic_history.eye_disease == "true"
            specility_name = "eye_disease"
            @patient_eye_disease = patient.speciality_history_records.find_by(name: specility_name) || patient.speciality_history_records.new
            if patient.speciality_histories.present?
              if !patient.speciality_histories.include?(specility_name)
                patient.speciality_histories = patient.speciality_histories +  "," + specility_name
              end
            else
              patient.speciality_histories = specility_name
            end
            @patient_eye_disease.name = specility_name
            @patient_eye_disease.l_duration = @ophthalmic_history.eye_disease_duration
            @patient_eye_disease.l_duration_unit = @ophthalmic_history.eye_disease_duration_unit
            @patient_eye_disease.r_duration = @ophthalmic_history.eye_disease_duration
            @patient_eye_disease.r_duration_unit = @ophthalmic_history.eye_disease_duration_unit
            @patient_eye_disease.record_created_date = patient.created_at
            @patient_eye_disease.record_updated_date = Time.current
            if @ophthalmic_history.eye_disease_duration.present? && @ophthalmic_history.eye_disease_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.eye_disease_duration_unit)
                @patient_eye_disease.r_history_started = patient.updated_at - eval("#{@ophthalmic_history.eye_disease_duration.to_i}.#{@ophthalmic_history.eye_disease_duration_unit}")
                @patient_eye_disease.l_history_started = patient.updated_at - eval("#{@ophthalmic_history.eye_disease_duration.to_i}.#{@ophthalmic_history.eye_disease_duration_unit}")
              end
            end
            @patient_eye_disease.save
          elsif @ophthalmic_history.eye_disease == "false"
            speciality_history = "eye_disease"
            @update = patient.speciality_history_records.find_by(name: speciality_history)
            if @update.present?
              @complaints_list = patient.speciality_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(speciality_history)
              patient.speciality_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end

          if @ophthalmic_history.eye_surgery == "true"
            specility_name = "eye_surgery"
            @patient_eye_surgery = patient.speciality_history_records.find_by(name: specility_name) || patient.speciality_history_records.new
            if patient.speciality_histories.present?
              if !patient.speciality_histories.include?(specility_name)
                patient.speciality_histories = patient.speciality_histories + "," + specility_name
              end
            else
              patient.speciality_histories = specility_name
            end
            @patient_eye_surgery.name = specility_name
            @patient_eye_surgery.l_duration = @ophthalmic_history.eye_surgery_duration
            @patient_eye_surgery.l_duration_unit = @ophthalmic_history.eye_surgery_duration_unit
            @patient_eye_surgery.r_duration = @ophthalmic_history.eye_surgery_duration
            @patient_eye_surgery.r_duration_unit = @ophthalmic_history.eye_surgery_duration_unit
            @patient_eye_surgery.record_created_date = patient.created_at
            @patient_eye_surgery.record_updated_date = Time.current
            if @ophthalmic_history.eye_surgery_duration.present? && @ophthalmic_history.eye_surgery_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.eye_surgery_duration_unit)
                @patient_eye_surgery.r_history_started = patient.updated_at - eval("#{@ophthalmic_history.eye_surgery_duration.to_i}.#{@ophthalmic_history.eye_surgery_duration_unit}")
                @patient_eye_surgery.l_history_started = patient.updated_at - eval("#{@ophthalmic_history.eye_surgery_duration.to_i}.#{@ophthalmic_history.eye_surgery_duration_unit}")
              end
            end
            @patient_eye_surgery.save
          elsif @ophthalmic_history.eye_surgery == "false"
            speciality_history = "eye_surgery"
            @update = patient.speciality_history_records.find_by(name: speciality_history)
            if @update.present?
              @complaints_list = patient.speciality_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(speciality_history)
              patient.speciality_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end

          if @ophthalmic_history.uveitis == "true"
            specility_name = "uveitis"
            @patient_uveitis = patient.speciality_history_records.find_by(name: specility_name) || patient.speciality_history_records.new
            if patient.speciality_histories.present?
              if !patient.speciality_histories.include?(specility_name)
                patient.speciality_histories = patient.speciality_histories +  "," + specility_name
              end
            else
              patient.speciality_histories = specility_name
            end
            @patient_uveitis.name = specility_name
            @patient_uveitis.l_duration = @ophthalmic_history.uveitis_duration
            @patient_uveitis.l_duration_unit = @ophthalmic_history.uveitis_duration_unit
            @patient_uveitis.r_duration = @ophthalmic_history.uveitis_duration
            @patient_uveitis.r_duration_unit = @ophthalmic_history.uveitis_duration_unit
            @patient_uveitis.record_created_date = patient.created_at
            @patient_uveitis.record_updated_date = Time.current
            if @ophthalmic_history.uveitis_duration.present? && @ophthalmic_history.uveitis_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.uveitis_duration_unit)
                @patient_uveitis.r_history_started = patient.updated_at - eval("#{@ophthalmic_history.uveitis_duration.to_i}.#{@ophthalmic_history.uveitis_duration_unit}")
                @patient_uveitis.l_history_started = patient.updated_at - eval("#{@ophthalmic_history.uveitis_duration.to_i}.#{@ophthalmic_history.uveitis_duration_unit}")
              end
            end
            @patient_uveitis.save
          elsif @ophthalmic_history.uveitis == "false"
            speciality_history = "uveitis"
            @update = patient.speciality_history_records.find_by(name: speciality_history)
            if @update.present?
              @complaints_list = patient.speciality_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(speciality_history)
              patient.speciality_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end

          if @ophthalmic_history.retinal_laser == "true"
            specility_name = "retinal_laser"
            @patient_retinal_laser = patient.speciality_history_records.find_by(name: specility_name) || patient.speciality_history_records.new
            if patient.speciality_histories.present?
              if !patient.speciality_histories.include?(specility_name)
                patient.speciality_histories = patient.speciality_histories +  "," + specility_name
              end
            else
              patient.speciality_histories = specility_name
            end
            @patient_retinal_laser.name = specility_name
            @patient_retinal_laser.l_duration = @ophthalmic_history.retinal_laser_duration
            @patient_retinal_laser.l_duration_unit = @ophthalmic_history.retinal_laser_duration_unit
            @patient_retinal_laser.r_duration = @ophthalmic_history.retinal_laser_duration
            @patient_retinal_laser.r_duration_unit = @ophthalmic_history.retinal_laser_duration_unit
            @patient_retinal_laser.record_created_date = patient.created_at
            @patient_retinal_laser.record_updated_date = Time.current
            if @ophthalmic_history.retinal_laser_duration.present? && @ophthalmic_history.retinal_laser_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.retinal_laser_duration_unit)
                @patient_retinal_laser.r_history_started = patient.updated_at - eval("#{@ophthalmic_history.retinal_laser_duration.to_i}.#{@ophthalmic_history.retinal_laser_duration_unit}")
                @patient_retinal_laser.l_history_started = patient.updated_at - eval("#{@ophthalmic_history.retinal_laser_duration.to_i}.#{@ophthalmic_history.retinal_laser_duration_unit}")
              end
            end
            @patient_retinal_laser.save
          elsif @ophthalmic_history.retinal_laser == "false"
            speciality_history = "retinal_laser"
            @update = patient.speciality_history_records.find_by(name: speciality_history)
            if @update.present?
              @complaints_list = patient.speciality_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(speciality_history)
              patient.speciality_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end

          # personal Histories
          patient.history_comment = @ophthalmic_history.history_comment
          if @ophthalmic_history.diabetes == "true"
            personal_history = "diabetes"
            @present_diabetes = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @present_diabetes.name = personal_history
            @present_diabetes.duration = @ophthalmic_history.diabetes_duration
            @present_diabetes.duration_unit = @ophthalmic_history.diabetes_duration_unit
            @present_diabetes.record_created_date = patient.created_at
            @present_diabetes.record_updated_date = Time.current
            if @ophthalmic_history.diabetes_duration.present? && @ophthalmic_history.diabetes_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.diabetes_duration_unit)
                @present_diabetes.history_started = patient.updated_at - eval("#{@ophthalmic_history.diabetes_duration.to_i}.#{@ophthalmic_history.diabetes_duration_unit}")
              end
            end
            @present_diabetes.save
          elsif @ophthalmic_history.diabetes == "false"
            personal_history = "diabetes"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.hypertension == "true"
            personal_history = "hypertension"
            @present_hypertension = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @present_hypertension.name = personal_history
            @present_hypertension.duration = @ophthalmic_history.hypertension_duration
            @present_hypertension.duration_unit = @ophthalmic_history.hypertension_duration_unit
            @present_hypertension.record_created_date = patient.created_at
            @present_hypertension.record_updated_date = Time.current
            if @ophthalmic_history.hypertension_duration.present? && @ophthalmic_history.hypertension_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.hypertension_duration_unit)
                @present_hypertension.history_started = patient.updated_at - eval("#{@ophthalmic_history.hypertension_duration.to_i}.#{@ophthalmic_history.hypertension_duration_unit}")
              end
            end
            @present_hypertension.save
          elsif @ophthalmic_history.hypertension == "false"
            personal_history = "hypertension"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.alcoholism == "true"
            personal_history = "alcoholism"
            @present_alcoholism = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @present_alcoholism.name = personal_history
            @present_alcoholism.duration = @ophthalmic_history.alcoholism_duration
            @present_alcoholism.duration_unit = @ophthalmic_history.alcoholism_duration_unit
            @present_alcoholism.record_created_date = patient.created_at
            @present_alcoholism.record_updated_date = Time.current
            if @ophthalmic_history.alcoholism_duration.present? && @ophthalmic_history.alcoholism_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.alcoholism_duration_unit)
                @present_alcoholism.history_started = patient.updated_at - eval("#{@ophthalmic_history.alcoholism_duration.to_i}.#{@ophthalmic_history.alcoholism_duration_unit}")
              end
            end
            @present_alcoholism.save
          elsif @ophthalmic_history.alcoholism == "false"
            personal_history = "alcoholism"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.smoking_tobacco == "true"
            personal_history = "smoking_tobacco"
            @present_smoking_tobacco = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @present_smoking_tobacco.name = personal_history
            @present_smoking_tobacco.duration = @ophthalmic_history.smoking_tobacco_duration
            @present_smoking_tobacco.duration_unit = @ophthalmic_history.smoking_tobacco_duration_unit
            @present_smoking_tobacco.record_created_date = patient.created_at
            @present_smoking_tobacco.record_updated_date = Time.current
            if @ophthalmic_history.smoking_tobacco_duration.present? && @ophthalmic_history.smoking_tobacco_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.smoking_tobacco_duration_unit)
                @present_smoking_tobacco.history_started = patient.updated_at - eval("#{@ophthalmic_history.smoking_tobacco_duration.to_i}.#{@ophthalmic_history.smoking_tobacco_duration_unit}")
              end
            end
            @present_smoking_tobacco.save
          elsif @ophthalmic_history.smoking_tobacco == "false"
            personal_history = "smoking_tobacco"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.cardiac_disorder == "true"
            personal_history = "cardiac_disorder"
            @present_cardiac_disorder = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @present_cardiac_disorder.name = personal_history
            @present_cardiac_disorder.duration = @ophthalmic_history.cardiac_disorder_duration
            @present_cardiac_disorder.duration_unit = @ophthalmic_history.cardiac_disorder_duration_unit
            @present_cardiac_disorder.record_created_date = patient.created_at
            @present_cardiac_disorder.record_updated_date = Time.current
            if @ophthalmic_history.cardiac_disorder_duration.present? && @ophthalmic_history.cardiac_disorder_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.cardiac_disorder_duration_unit)
                @present_cardiac_disorder.history_started = patient.updated_at - eval("#{@ophthalmic_history.cardiac_disorder_duration.to_i}.#{@ophthalmic_history.cardiac_disorder_duration_unit}")
              end
            end
            @present_cardiac_disorder.save
          elsif @ophthalmic_history.cardiac_disorder == "false"
            personal_history = "cardiac_disorder"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end

          if @ophthalmic_history.rheumatoid_arthritis == "true"
            personal_history = "rheumatoid_arthritis"
            @present_rheumatoid_arthritis = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @present_rheumatoid_arthritis.name = personal_history
            @present_rheumatoid_arthritis.duration = @ophthalmic_history.rheumatoid_arthritis_duration
            @present_rheumatoid_arthritis.duration_unit = @ophthalmic_history.rheumatoid_arthritis_duration_unit
            @present_rheumatoid_arthritis.record_created_date = patient.created_at
            @present_rheumatoid_arthritis.record_updated_date = Time.current
            if @ophthalmic_history.rheumatoid_arthritis_duration.present? && @ophthalmic_history.rheumatoid_arthritis_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.rheumatoid_arthritis_duration_unit)
                @present_rheumatoid_arthritis.history_started = patient.updated_at - eval("#{@ophthalmic_history.rheumatoid_arthritis_duration.to_i}.#{@ophthalmic_history.rheumatoid_arthritis_duration_unit}")
              end
            end
            @present_rheumatoid_arthritis.save
          elsif @ophthalmic_history.rheumatoid_arthritis == "false"
            personal_history = "rheumatoid_arthritis"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end

          if @ophthalmic_history.steroid_intake == "true"
            personal_history = "steroid_intake"
            @present_steroid_intake = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @present_steroid_intake.name = personal_history
            @present_steroid_intake.duration = @ophthalmic_history.steroid_intake_duration
            @present_steroid_intake.duration_unit = @ophthalmic_history.steroid_intake_duration_unit
            @present_steroid_intake.record_created_date = patient.created_at
            @present_steroid_intake.record_updated_date = Time.current
            if @ophthalmic_history.steroid_intake_duration.present? && @ophthalmic_history.steroid_intake_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.steroid_intake_duration_unit)
                @present_steroid_intake.history_started = patient.updated_at - eval("#{@ophthalmic_history.steroid_intake_duration.to_i}.#{@ophthalmic_history.steroid_intake_duration_unit}")
              end
            end
            @present_steroid_intake.save
          elsif @ophthalmic_history.steroid_intake == "false"
            personal_history = "steroid_intake"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.drug_abuse == "true"
            personal_history = "drug_abuse"
            @patient_drug_abuse = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @patient_drug_abuse.name = personal_history
            @patient_drug_abuse.duration = @ophthalmic_history.drug_abuse_duration
            @patient_drug_abuse.duration_unit = @ophthalmic_history.drug_abuse_duration_unit
            @patient_drug_abuse.record_created_date = patient.created_at
            @patient_drug_abuse.record_updated_date = Time.current
            if @ophthalmic_history.drug_abuse_duration.present? && @ophthalmic_history.drug_abuse_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.drug_abuse_duration_unit)
                @patient_drug_abuse.history_started = patient.updated_at - eval("#{@ophthalmic_history.drug_abuse_duration.to_i}.#{@ophthalmic_history.drug_abuse_duration_unit}")
              end
            end
            @patient_drug_abuse.save
          elsif @ophthalmic_history.drug_abuse == "false"
            personal_history = "drug_abuse"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.hiv_aids == "true"
            personal_history = "hiv_aids"
            @patient_hiv_aids = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @patient_hiv_aids.name = personal_history
            @patient_hiv_aids.duration = @ophthalmic_history.hiv_aids_duration
            @patient_hiv_aids.duration_unit = @ophthalmic_history.hiv_aids_duration_unit
            @patient_hiv_aids.record_created_date = patient.created_at
            @patient_hiv_aids.record_updated_date = Time.current
            if @ophthalmic_history.hiv_aids_duration.present? && @ophthalmic_history.hiv_aids_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.hiv_aids_duration_unit)
                @patient_hiv_aids.history_started = patient.updated_at - eval("#{@ophthalmic_history.hiv_aids_duration.to_i}.#{@ophthalmic_history.hiv_aids_duration_unit}")
              end
            end
            @patient_hiv_aids.save
          elsif @ophthalmic_history.hiv_aids == "false"
            personal_history = "hiv_aids"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.cancer_tumor == "true"
            personal_history = "cancer_tumor"
            @patient_cancer_tumor = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @patient_cancer_tumor.name = personal_history
            @patient_cancer_tumor.duration = @ophthalmic_history.cancer_tumor_duration
            @patient_cancer_tumor.duration_unit = @ophthalmic_history.cancer_tumor_duration_unit
            @patient_cancer_tumor.record_created_date = patient.created_at
            @patient_cancer_tumor.record_updated_date = Time.current
            if @ophthalmic_history.cancer_tumor_duration.present? && @ophthalmic_history.cancer_tumor_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.cancer_tumor_duration_unit)
                @patient_cancer_tumor.history_started = patient.updated_at - eval("#{@ophthalmic_history.cancer_tumor_duration.to_i}.#{@ophthalmic_history.cancer_tumor_duration_unit}")
              end
            end
            @patient_cancer_tumor.save
          elsif @ophthalmic_history.cancer_tumor == "false"
            personal_history = "cancer_tumor"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.tuberculosis == "true"
            personal_history = "tuberculosis"
            @patient_tuberculosis = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @patient_tuberculosis.name = personal_history
            @patient_tuberculosis.duration = @ophthalmic_history.tuberculosis_duration
            @patient_tuberculosis.duration_unit = @ophthalmic_history.tuberculosis_duration_unit
            @patient_tuberculosis.record_created_date = patient.created_at
            @patient_tuberculosis.record_updated_date = Time.current
            if @ophthalmic_history.tuberculosis_duration.present? && @ophthalmic_history.tuberculosis_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.tuberculosis_duration_unit)
                @patient_tuberculosis.history_started = patient.updated_at - eval("#{@ophthalmic_history.tuberculosis_duration.to_i}.#{@ophthalmic_history.tuberculosis_duration_unit}")
              end
            end
            @patient_tuberculosis.save
          elsif @ophthalmic_history.tuberculosis == "false"
            personal_history = "tuberculosis"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.asthma == "true"
            personal_history = "asthma"
            @patient_asthma = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @patient_asthma.name = personal_history
            @patient_asthma.duration = @ophthalmic_history.asthma_duration
            @patient_asthma.duration_unit = @ophthalmic_history.asthma_duration_unit
            @patient_asthma.record_created_date = patient.created_at
            @patient_asthma.record_updated_date = Time.current
            if @ophthalmic_history.asthma_duration.present? && @ophthalmic_history.asthma_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.asthma_duration_unit)
                @patient_asthma.history_started = patient.updated_at - eval("#{@ophthalmic_history.asthma_duration.to_i}.#{@ophthalmic_history.asthma_duration_unit}")
              end
            end
            @patient_asthma.save
          elsif @ophthalmic_history.asthma == "false"
            personal_history = "asthma"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.cns_disorder_stroke == "true"
            personal_history = "cns_disorder_stroke"
            @patient_cns_disorder_stroke = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @patient_cns_disorder_stroke.name = personal_history
            @patient_cns_disorder_stroke.duration = @ophthalmic_history.cns_disorder_stroke_duration
            @patient_cns_disorder_stroke.duration_unit = @ophthalmic_history.cns_disorder_stroke_duration_unit
            @patient_cns_disorder_stroke.record_created_date = patient.created_at
            @patient_cns_disorder_stroke.record_updated_date = Time.current
            if @ophthalmic_history.cns_disorder_stroke_duration.present? && @ophthalmic_history.cns_disorder_stroke_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.cns_disorder_stroke_duration_unit)
                @patient_cns_disorder_stroke.history_started = patient.updated_at - eval("#{@ophthalmic_history.cns_disorder_stroke_duration.to_i}.#{@ophthalmic_history.cns_disorder_stroke_duration_unit}")
              end
            end
            @patient_cns_disorder_stroke.save
          elsif @ophthalmic_history.cns_disorder_stroke == "false"
            personal_history = "cns_disorder_stroke"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.hypothyroidism == "true"
            personal_history = "hypothyroidism"
            @patient_hypothyroidism = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @patient_hypothyroidism.name = personal_history
            @patient_hypothyroidism.duration = @ophthalmic_history.hypothyroidism_duration
            @patient_hypothyroidism.duration_unit = @ophthalmic_history.hypothyroidism_duration_unit
            @patient_hypothyroidism.record_created_date = patient.created_at
            @patient_hypothyroidism.record_updated_date = Time.current
            if @ophthalmic_history.hypothyroidism_duration.present? && @ophthalmic_history.hypothyroidism_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.hypothyroidism_duration_unit)
                @patient_hypothyroidism.history_started = patient.updated_at - eval("#{@ophthalmic_history.hypothyroidism_duration.to_i}.#{@ophthalmic_history.hypothyroidism_duration_unit}")
              end
            end
            @patient_hypothyroidism.save
          elsif @ophthalmic_history.hypothyroidism == "false"
            personal_history = "hypothyroidism"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.hyperthyroidism == "true"
            personal_history = "hyperthyroidism"
            @patient_hyperthyroidism = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @patient_hyperthyroidism.name = personal_history
            @patient_hyperthyroidism.duration = @ophthalmic_history.hyperthyroidism_duration
            @patient_hyperthyroidism.duration_unit = @ophthalmic_history.hyperthyroidism_duration_unit
            @patient_hyperthyroidism.record_created_date = patient.created_at
            @patient_hyperthyroidism.record_updated_date = Time.current
            if @ophthalmic_history.hyperthyroidism_duration.present? && @ophthalmic_history.hyperthyroidism_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.hyperthyroidism_duration_unit)
                @patient_hyperthyroidism.history_started = patient.updated_at - eval("#{@ophthalmic_history.hyperthyroidism_duration.to_i}.#{@ophthalmic_history.hyperthyroidism_duration_unit}")
              end
            end
            @patient_hyperthyroidism.save
          elsif @ophthalmic_history.hyperthyroidism == "false"
            personal_history = "hyperthyroidism"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.hepatitis_cirrhosis == "true"
            personal_history = "hepatitis_cirrhosis"
            @patient_hepatitis_cirrhosis = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @patient_hepatitis_cirrhosis.name = personal_history
            @patient_hepatitis_cirrhosis.duration = @ophthalmic_history.hepatitis_cirrhosis_duration
            @patient_hepatitis_cirrhosis.duration_unit = @ophthalmic_history.hepatitis_cirrhosis_duration_unit
            @patient_hepatitis_cirrhosis.record_created_date = patient.created_at
            @patient_hepatitis_cirrhosis.record_updated_date = Time.current
            if @ophthalmic_history.hepatitis_cirrhosis_duration.present? && @ophthalmic_history.hepatitis_cirrhosis_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.hepatitis_cirrhosis_duration_unit)
                @patient_hepatitis_cirrhosis.history_started = patient.updated_at - eval("#{@ophthalmic_history.hepatitis_cirrhosis_duration.to_i}.#{@ophthalmic_history.hepatitis_cirrhosis_duration_unit}")
              end
            end
            @patient_hepatitis_cirrhosis.save
          elsif @ophthalmic_history.hepatitis_cirrhosis == "false"
            personal_history = "hepatitis_cirrhosis"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.renal_disorder == "true"
            personal_history = "renal_disorder"
            @patient_renal_disorder = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @patient_renal_disorder.name = personal_history
            @patient_renal_disorder.duration = @ophthalmic_history.renal_disorder_duration
            @patient_renal_disorder.duration_unit = @ophthalmic_history.renal_disorder_duration_unit
            @patient_renal_disorder.record_created_date = patient.created_at
            @patient_renal_disorder.record_updated_date = Time.current
            if @ophthalmic_history.renal_disorder_duration.present? && @ophthalmic_history.renal_disorder_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.renal_disorder_duration_unit)
                @patient_renal_disorder.history_started = patient.updated_at - eval("#{@ophthalmic_history.renal_disorder_duration.to_i}.#{@ophthalmic_history.renal_disorder_duration_unit}")
              end
            end
            @patient_renal_disorder.save
          elsif @ophthalmic_history.renal_disorder == "false"
            personal_history = "renal_disorder"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.acidity == "true"
            personal_history = "acidity"
            @patient_acidity = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @patient_acidity.name = personal_history
            @patient_acidity.duration = @ophthalmic_history.acidity_duration
            @patient_acidity.duration_unit = @ophthalmic_history.acidity_duration_unit
            @patient_acidity.record_created_date = patient.created_at
            @patient_acidity.record_updated_date = Time.current
            if @ophthalmic_history.acidity_duration.present? && @ophthalmic_history.acidity_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.acidity_duration_unit)
                @patient_acidity.history_started = patient.updated_at - eval("#{@ophthalmic_history.acidity_duration.to_i}.#{@ophthalmic_history.acidity_duration_unit}")
              end
            end
            @patient_acidity.save
          elsif @ophthalmic_history.acidity == "false"
            personal_history = "acidity"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.on_insulin == "true"
            personal_history = "on_insulin"
            @patient_on_insulin = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @patient_on_insulin.name = personal_history
            @patient_on_insulin.duration = @ophthalmic_history.on_insulin_duration
            @patient_on_insulin.duration_unit = @ophthalmic_history.on_insulin_duration_unit
            @patient_on_insulin.record_created_date = patient.created_at
            @patient_on_insulin.record_updated_date = Time.current
            if @ophthalmic_history.on_insulin_duration.present? && @ophthalmic_history.on_insulin_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.on_insulin_duration_unit)
                @patient_on_insulin.history_started = patient.updated_at - eval("#{@ophthalmic_history.on_insulin_duration.to_i}.#{@ophthalmic_history.on_insulin_duration_unit}")
              end
            end
            @patient_on_insulin.save
          elsif @ophthalmic_history.on_insulin == "false"
            personal_history = "on_insulin"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.on_aspirin_blood_thinners == "true"
            personal_history = "on_aspirin_blood_thinners"
            @patient_on_aspirin_blood_thinners = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @patient_on_aspirin_blood_thinners.name = personal_history
            @patient_on_aspirin_blood_thinners.duration = @ophthalmic_history.on_aspirin_blood_thinners_duration
            @patient_on_aspirin_blood_thinners.duration_unit = @ophthalmic_history.on_aspirin_blood_thinners_duration_unit
            @patient_on_aspirin_blood_thinners.record_created_date = patient.created_at
            @patient_on_aspirin_blood_thinners.record_updated_date = Time.current
            if @ophthalmic_history.on_aspirin_blood_thinners_duration.present? && @ophthalmic_history.on_aspirin_blood_thinners_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.on_aspirin_blood_thinners_duration_unit)
                @patient_on_aspirin_blood_thinners.history_started = patient.updated_at - eval("#{@ophthalmic_history.on_aspirin_blood_thinners_duration.to_i}.#{@ophthalmic_history.on_aspirin_blood_thinners_duration_unit}")
              end
            end
            @patient_on_aspirin_blood_thinners.save
          elsif @ophthalmic_history.on_aspirin_blood_thinners == "false"
            personal_history = "on_aspirin_blood_thinners"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          if @ophthalmic_history.consanguinity == "true"
            personal_history = "consanguinity"
            @patient_consanguinity = patient.personal_history_records.find_by(name: personal_history) || patient.personal_history_records.new
            if patient.personal_histories.present?
              if !patient.personal_histories.include?(personal_history)
                patient.personal_histories = patient.personal_histories + "," + personal_history
              end
            else
              patient.personal_histories = personal_history
            end
            @patient_consanguinity.name = personal_history
            @patient_consanguinity.duration = @ophthalmic_history.consanguinity_duration
            @patient_consanguinity.duration_unit = @ophthalmic_history.consanguinity_duration_unit
            @patient_consanguinity.record_created_date = patient.created_at
            @patient_consanguinity.record_updated_date = Time.current
            if @ophthalmic_history.consanguinity_duration.present? && @ophthalmic_history.consanguinity_duration_unit.present?
              if ["years", "days", "weeks", "months"].include?(@ophthalmic_history.consanguinity_duration_unit)
                @patient_consanguinity.history_started = patient.updated_at - eval("#{@ophthalmic_history.consanguinity_duration.to_i}.#{@ophthalmic_history.consanguinity_duration_unit}")
              end
            end
            @patient_consanguinity.save
          elsif @ophthalmic_history.consanguinity == "false"
            personal_history = "consanguinity"
            @update = patient.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = patient.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              patient.personal_histories = @complaint_array.join(",")
              patient.save
              @update.delete
            end
          end
          @medical_history = @ophthalmic_history.medical_history_comment
          @family_history = @ophthalmic_history.family_history_comment
          @other_histories = patient.other_history
          @other_histories.medical_history = @medical_history
          @other_histories.family_history = @family_history
          @other_histories.specialstatus = patient.specialstatus
          @other_histories.record_created_date = patient.created_at
          @other_histories.record_updated_date = Time.current
          @other_histories.save
          patient.save
        end
        # allergies
        @allergies = patient.patient_history.patientallergyhistory
        if @allergies.present?
          patient.others_allergies = @allergies.others
          patient.allergy_histories.delete_all
          patient.drug_allergies = ""
          patient.antimicrobial_agents = ""
          patient.antifungal_agents = ""
          patient.antiviral_agents = ""
          patient.nsaids = ""
          patient.eye_drops = ""
          patient.food_allergies = ""
          patient.contact_allergies = ""
          if @allergies.antimicrobialagents.present?
            if patient.drug_allergies.present?
              if !patient.drug_allergies.include?("antimicrobial_agents")
                patient.drug_allergies = patient.drug_allergies + "," + "antimicrobial_agents"
              end
            else
              patient.drug_allergies = "antimicrobial_agents"
            end
            @allergies.antimicrobialagents.each do |agents|
              @old_allergies = patient.allergy_histories.find_by(allergysnomedid: agents) || patient.allergy_histories.new
              Global.send("ehrcommon").antimicrobialagents.each do |aller|
                if aller[:allergysnomedid] == agents
                  if patient.antimicrobial_agents.present?
                    if !patient.antimicrobial_agents.include?(aller[:allergyname])
                      patient.antimicrobial_agents = patient.antimicrobial_agents + "," + aller[:allergyname]
                    end
                  else
                    patient.antimicrobial_agents = aller[:allergyname]
                  end
                  @old_allergies.name = aller[:allergyname]
                  @old_allergies.allergy_type = "drug_allergies"
                  @old_allergies.allergy_subtype = "antimicrobial_agents"
                  @old_allergies.allergysnomedid = aller[:allergysnomedid]
                  @old_allergies.record_created_date = patient.created_at
                  @old_allergies.record_updated_date = Time.current
                  @old_allergies.save
                end
              end
            end
          end
          if @allergies.antifungalagents.present?
            if patient.drug_allergies.present?
              if !patient.drug_allergies.include?("antifungal_agents")
                patient.drug_allergies = patient.drug_allergies + "," + "antifungal_agents"
              end
            else
              patient.drug_allergies = "antifungal_agents"
            end
            @allergies.antifungalagents.each do |agents|
              @old_allergies = patient.allergy_histories.find_by(allergysnomedid: agents) || patient.allergy_histories.new
              Global.send("ehrcommon").antifungalagents.each do |aller|
                if aller[:allergysnomedid] == agents
                  if patient.antifungal_agents.present?
                    if !patient.antifungal_agents.include?(aller[:allergyname])
                      patient.antifungal_agents = patient.antifungal_agents + "," + aller[:allergyname]
                    end
                  else
                    patient.antifungal_agents = aller[:allergyname]
                  end
                  @old_allergies.name = aller[:allergyname]
                  @old_allergies.allergy_type = "drug_allergies"
                  @old_allergies.allergy_subtype = "antifungal_agents"
                  @old_allergies.allergysnomedid = aller[:allergysnomedid]
                  @old_allergies.record_created_date = patient.created_at
                  @old_allergies.record_updated_date = Time.current
                  @old_allergies.save
                end
              end
            end
          end
          if @allergies.antiviralagents.present?
            if patient.drug_allergies.present?
              if !patient.drug_allergies.include?("antiviral_agents")
                patient.drug_allergies = patient.drug_allergies + "," + "antiviral_agents"
              end
            else
              patient.drug_allergies = "antiviral_agents"
            end
            @allergies.antiviralagents.each do |agents|
              @old_allergies = patient.allergy_histories.find_by(allergysnomedid: agents) || patient.allergy_histories.new
              Global.send("ehrcommon").antiviralagents.each do |aller|
                if aller[:allergysnomedid] == agents
                  if patient.antiviral_agents.present?
                    if !patient.antiviral_agents.include?(aller[:allergyname])
                      patient.antiviral_agents = patient.antiviral_agents + "," + aller[:allergyname]
                    end
                  else
                    patient.antiviral_agents = aller[:allergyname]
                  end
                  @old_allergies.name = aller[:allergyname]
                  @old_allergies.allergy_type = "drug_allergies"
                  @old_allergies.allergy_subtype = "antiviral_agents"
                  @old_allergies.allergysnomedid = aller[:allergysnomedid]
                  @old_allergies.record_created_date = patient.created_at
                  @old_allergies.record_updated_date = Time.current
                  @old_allergies.save
                end
              end
            end
          end
          if @allergies.nsaids.present?
            if patient.drug_allergies.present?
              if !patient.drug_allergies.include?("nsaids")
                patient.drug_allergies = patient.drug_allergies + "," + "nsaids"
              end
            else
              patient.drug_allergies = "nsaids"
            end
            @allergies.nsaids.each do |agents|
              @old_allergies = patient.allergy_histories.find_by(allergysnomedid: agents) || patient.allergy_histories.new
              Global.send("ehrcommon").nsaids.each do |aller|
                if aller[:allergysnomedid] == agents
                  if patient.nsaids.present?
                    if !patient.nsaids.include?(aller[:allergyname])
                      patient.nsaids = patient.nsaids + "," + aller[:allergyname]
                    end
                  else
                    patient.nsaids = aller[:allergyname]
                  end
                  @old_allergies.name = aller[:allergyname]
                  @old_allergies.allergy_type = "drug_allergies"
                  @old_allergies.allergy_subtype = "nsaids"
                  @old_allergies.allergysnomedid = aller[:allergysnomedid]
                  @old_allergies.record_created_date = patient.created_at
                  @old_allergies.record_updated_date = Time.current
                  @old_allergies.save
                end
              end
            end
          end
          if @allergies.eyedrops.present?
            if patient.drug_allergies.present?
              if !patient.drug_allergies.include?("eye_drops")
                patient.drug_allergies = patient.drug_allergies + "," + "eye_drops"
              end
            else
              patient.drug_allergies = "eye_drops"
            end
            @allergies.eyedrops.each do |agents|
              @old_allergies = patient.allergy_histories.find_by(allergysnomedid: agents) || patient.allergy_histories.new
              Global.send("ehrcommon").eyedrops.each do |aller|
                if aller[:allergysnomedid] == agents
                  if patient.eye_drops.present?
                    eye_allergy_name = patient.eye_drops.split(",")
                    if !eye_allergy_name.include?(aller[:allergyname])
                      eye_allergy_name_s = eye_allergy_name.join(",")
                      patient.eye_drops = eye_allergy_name_s + "," + aller[:allergyname]
                    end
                  else
                    patient.eye_drops = aller[:allergyname]
                  end
                  @old_allergies.name = aller[:allergyname]
                  @old_allergies.allergy_type = "drug_allergies"
                  @old_allergies.allergy_subtype = "eye_drops"
                  @old_allergies.allergysnomedid = aller[:allergysnomedid]
                  @old_allergies.record_created_date = patient.created_at
                  @old_allergies.record_updated_date = Time.current
                  @old_allergies.save
                end
              end
            end
          end
          if @allergies.contact.present?
            @allergies.contact.each do |agents|
              @old_allergies = patient.allergy_histories.find_by(allergysnomedid: agents) || patient.allergy_histories.new
              Global.send("ehrcommon").contact.each do |aller|
                if aller[:allergysnomedid] == agents
                  if patient.contact_allergies.present?
                    if !patient.contact_allergies.include?(aller[:allergyname])
                      patient.contact_allergies = patient.contact_allergies + "," + aller[:allergyname]
                    end
                  else
                    patient.contact_allergies = aller[:allergyname]
                  end
                  @old_allergies.name = aller[:allergyname]
                  @old_allergies.allergy_type = "contact_allergies"
                  @old_allergies.allergy_subtype = ""
                  if aller[:allergyname] == "tegaderm"
                    @old_allergies.allergysnomedid = '419238010'
                  else
                    @old_allergies.allergysnomedid = aller[:allergysnomedid]
                  end
                  @old_allergies.record_created_date = patient.created_at
                  @old_allergies.record_updated_date = Time.current
                  @old_allergies.save
                end
              end
            end
          end
          if @allergies.food.present?
            # food_allergies  = []
            @allergies.food.each do |agents|
              # food_allergies.push >> agents
              @old_allergies = patient.allergy_histories.find_by(allergysnomedid: agents) || patient.allergy_histories.new
              Global.send("ehrcommon").food.each do |aller|
                if aller[:allergysnomedid] == agents
                  if patient.food_allergies.present?
                    if !patient.food_allergies.include?(aller[:allergyname])
                      patient.food_allergies = patient.food_allergies + "," + aller[:allergyname]
                    end
                  else
                    patient.food_allergies = aller[:allergyname]
                  end
                  @old_allergies.name = aller[:allergyname]
                  @old_allergies.allergy_type = "food_allergies"
                  @old_allergies.allergy_subtype = ""
                  @old_allergies.allergysnomedid = aller[:allergysnomedid]
                  @old_allergies.record_created_date = patient.created_at
                  @old_allergies.record_updated_date = Time.current
                  @old_allergies.save
                end
              end
            end
          end
        end
        patient.is_migrated = true
        patient.save
      end
    end
  end
end
