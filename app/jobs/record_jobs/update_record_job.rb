class UpdateRecordJob < ActiveJob::Base
  queue_as :urgent

  def perform(opdrecordid, patientid)
    @opd_record = OpdRecord.find_by(id: opdrecordid)
    if @opd_record.present?
      if @opd_record.chiefcomplaint_blurringdiminution == "true"
        complaint_name = "blurring_diminution_of_vision"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update.name = complaint_name
        @update.side = @opd_record.chiefcomplaint_blurringdiminution_side
        @update.duration = @opd_record.chiefcomplaint_blurringdiminution_duration
        @update.duration_unit = @opd_record.chiefcomplaint_blurringdiminution_duration_unit
        @update.comment = @opd_record.chiefcomplaint_blurringdiminution_comment
        @update.complaint_options = @opd_record.chiefcomplaint_blurringdiminution_options
        @update.opd_record_created_date = @opd_record.created_at
        @update.opd_record_updated_date = Time.current
        @update.save
      elsif @opd_record.chiefcomplaint_blurringdiminution == "false"
        complaint_name = "blurring_diminution_of_vision"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end
      if @opd_record.chiefcomplaint_redness == "true"
        complaint_name = "redness"
        @update_redness = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_redness.name = complaint_name
        @update_redness.side = @opd_record.chiefcomplaint_redness_side
        @update_redness.duration = @opd_record.chiefcomplaint_redness_duration
        @update_redness.duration_unit = @opd_record.chiefcomplaint_redness_duration_unit
        @update_redness.comment = @opd_record.chiefcomplaint_redness_comment
        @update_redness.opd_record_created_date = @opd_record.created_at
        @update_redness.opd_record_updated_date = Time.current
        @update_redness.save
      elsif @opd_record.chiefcomplaint_redness == "false"
        complaint_name = "redness"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      if @opd_record.chiefcomplaint_pain == "true"
        complaint_name = "pain"
        @update_pain = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_pain.name = complaint_name
        @update_pain.side = @opd_record.chiefcomplaint_pain_side
        @update_pain.duration = @opd_record.chiefcomplaint_pain_duration
        @update_pain.duration_unit = @opd_record.chiefcomplaint_pain_duration_unit
        @update_pain.comment = @opd_record.chiefcomplaint_pain_comment
        @update_pain.opd_record_created_date = @opd_record.created_at
        @update_pain.opd_record_updated_date = Time.current
        @update_pain.save
      elsif @opd_record.chiefcomplaint_pain == "false"
        complaint_name = "pain"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      if @opd_record.chiefcomplaint_injury == "true"
        complaint_name = "injury"
        @update_injury = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_injury.name = complaint_name
        @update_injury.side = @opd_record.chiefcomplaint_injury_side
        @update_injury.duration = @opd_record.chiefcomplaint_injury_duration
        @update_injury.duration_unit = @opd_record.chiefcomplaint_injury_duration_unit
        @update_injury.comment = @opd_record.chiefcomplaint_injury_comment
        @update_injury.opd_record_created_date = @opd_record.created_at
        @update_injury.opd_record_updated_date = Time.current
        @update_injury.save
      elsif @opd_record.chiefcomplaint_injury == "false"
        complaint_name = "injury"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      if @opd_record.chiefcomplaint_watering == "true"
        complaint_name = "watering"
        @update_watering = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_watering.name = complaint_name
        @update_watering.side = @opd_record.chiefcomplaint_watering_side
        @update_watering.duration = @opd_record.chiefcomplaint_watering_duration
        @update_watering.duration_unit = @opd_record.chiefcomplaint_watering_duration_unit
        @update_watering.comment = @opd_record.chiefcomplaint_watering_comment
        @update_watering.opd_record_created_date = @opd_record.created_at
        @update_watering.opd_record_updated_date = Time.current
        @update_watering.save
      elsif @opd_record.chiefcomplaint_watering == "false"
        complaint_name = "watering"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      if @opd_record.chiefcomplaint_discharge == "true"
        complaint_name = "discharge"
        @update_discharge = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_discharge.name = complaint_name
        @update_discharge.side = @opd_record.chiefcomplaint_discharge_side
        @update_discharge.duration = @opd_record.chiefcomplaint_discharge_duration
        @update_discharge.duration_unit = @opd_record.chiefcomplaint_discharge_duration_unit
        @update_discharge.comment = @opd_record.chiefcomplaint_discharge_comment
        @update_discharge.opd_record_created_date = @opd_record.created_at
        @update_discharge.opd_record_updated_date = Time.current
        @update_discharge.save
      elsif @opd_record.chiefcomplaint_discharge == "false"
        complaint_name = "discharge"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      if @opd_record.chiefcomplaint_dryness == "true"
        complaint_name = "dryness"
        @update_dryness = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_dryness.name = complaint_name
        @update_dryness.side = @opd_record.chiefcomplaint_dryness_side
        @update_dryness.duration = @opd_record.chiefcomplaint_dryness_duration
        @update_dryness.duration_unit = @opd_record.chiefcomplaint_dryness_duration_unit
        @update_dryness.comment = @opd_record.chiefcomplaint_dryness_comment
        @update_dryness.opd_record_created_date = @opd_record.created_at
        @update_dryness.opd_record_updated_date = Time.current
        @update_dryness.save
      elsif @opd_record.chiefcomplaint_dryness == "false"
        complaint_name = "dryness"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      if @opd_record.chiefcomplaint_itiching == "true"
        complaint_name = "itching"
        @update_itching = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_itching.name = complaint_name
        @update_itching.side = @opd_record.chiefcomplaint_itiching_side
        @update_itching.duration = @opd_record.chiefcomplaint_itiching_duration
        @update_itching.duration_unit = @opd_record.chiefcomplaint_itiching_duration_unit
        @update_itching.comment = @opd_record.chiefcomplaint_itiching_comment
        @update_itching.opd_record_created_date = @opd_record.created_at
        @update_itching.opd_record_updated_date = Time.current
        @update_itching.save
      elsif @opd_record.chiefcomplaint_itiching == "false"
        complaint_name = "itching"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      if @opd_record.chiefcomplaint_fbsensation == "true"
        complaint_name = "FBsensation"
        @update_FBsensation = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_FBsensation.name = complaint_name
        @update_FBsensation.side = @opd_record.chiefcomplaint_fbsensation_side
        @update_FBsensation.duration = @opd_record.chiefcomplaint_fbsensation_duration
        @update_FBsensation.duration_unit = @opd_record.chiefcomplaint_fbsensation_duration_unit
        @update_FBsensation.comment = @opd_record.chiefcomplaint_fbsensation_comment
        @update_FBsensation.opd_record_created_date = @opd_record.created_at
        @update_FBsensation.opd_record_updated_date = Time.current
        @update_FBsensation.save
      elsif @opd_record.chiefcomplaint_fbsensation == "false"
        complaint_name = "FBsensation"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      if @opd_record.chiefcomplaint_deviationsquint == "true"
        complaint_name = "deviation_squint"
        @update_deviation_squint = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_deviation_squint.name = complaint_name
        @update_deviation_squint.side = @opd_record.chiefcomplaint_deviationsquint_side
        @update_deviation_squint.duration = @opd_record.chiefcomplaint_deviationsquint_duration
        @update_deviation_squint.duration_unit = @opd_record.chiefcomplaint_deviationsquint_duration_unit
        @update_deviation_squint.comment = @opd_record.chiefcomplaint_deviationsquint_comment
        @update_deviation_squint.complaint_options = @opd_record.chiefcomplaint_deviationsquint_options
        @update_deviation_squint.opd_record_created_date = @opd_record.created_at
        @update_deviation_squint.opd_record_updated_date = Time.current
        @update_deviation_squint.save
      elsif @opd_record.chiefcomplaint_deviationsquint == "false"
        complaint_name = "deviation_squint"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      if @opd_record.chiefcomplaint_headachestrain == "true"
        complaint_name = "headache_strain"
        @update_strain = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_strain.name = complaint_name
        @update_strain.side = @opd_record.chiefcomplaint_headachestrain_side
        @update_strain.duration = @opd_record.chiefcomplaint_headachestrain_duration
        @update_strain.duration_unit = @opd_record.chiefcomplaint_headachestrain_duration_unit
        @update_strain.comment = @opd_record.chiefcomplaint_headachestrain_comment
        @update_strain.opd_record_created_date = @opd_record.created_at
        @update_strain.opd_record_updated_date = Time.current
        @update_strain.save
      elsif @opd_record.chiefcomplaint_headachestrain == "false"
        complaint_name = "headache_strain"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      if @opd_record.chiefcomplaint_changeinsizeshape == "true"
        complaint_name = "change_in_size_shape"
        @update_shape = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_shape.name = complaint_name
        @update_shape.side = @opd_record.chiefcomplaint_changeinsizeshape_side
        @update_shape.duration = @opd_record.chiefcomplaint_changeinsizeshape_duration
        @update_shape.duration_unit = @opd_record.chiefcomplaint_changeinsizeshape_duration_unit
        @update_shape.comment = @opd_record.chiefcomplaint_changeinsizeshape_comment
        @update_shape.opd_record_created_date = @opd_record.created_at
        @update_shape.opd_record_updated_date = Time.current
        @update_shape.save
      elsif @opd_record.chiefcomplaint_changeinsizeshape == "false"
        complaint_name = "change_in_size_shape"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      if @opd_record.chiefcomplaint_othervisualsymptoms == "true"
        complaint_name = "other_visual_symptoms"
        @update_symptoms = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_symptoms.name = complaint_name
        @update_symptoms.side = @opd_record.chiefcomplaint_othervisualsymptoms_side
        @update_symptoms.duration = @opd_record.chiefcomplaint_othervisualsymptoms_duration
        @update_symptoms.duration_unit = @opd_record.chiefcomplaint_othervisualsymptoms_duration_unit
        @update_symptoms.comment = @opd_record.chiefcomplaint_othervisualsymptoms_comment
        @update_symptoms.complaint_options = @opd_record.chiefcomplaint_othervisualsymptoms_options
        @update_symptoms.opd_record_created_date = @opd_record.created_at
        @update_symptoms.opd_record_updated_date = Time.current
        @update_symptoms.save
      elsif @opd_record.chiefcomplaint_othervisualsymptoms == "false"
        complaint_name = "other_visual_symptoms"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      if @opd_record.chiefcomplaint_shadowdefect == "true"
        complaint_name = "shadow_defect_in_vision"
        @update_shadow = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_shadow.name = complaint_name
        @update_shadow.side = @opd_record.chiefcomplaint_shadowdefect_side
        @update_shadow.duration = @opd_record.chiefcomplaint_shadowdefect_duration
        @update_shadow.duration_unit = @opd_record.chiefcomplaint_shadowdefect_duration_unit
        @update_shadow.comment = @opd_record.chiefcomplaint_shadowdefect_comment
        @update_shadow.opd_record_created_date = @opd_record.created_at
        @update_shadow.opd_record_updated_date = Time.current
        @update_shadow.save
      elsif @opd_record.chiefcomplaint_shadowdefect == "false"
        complaint_name = "shadow_defect_in_vision"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      if @opd_record.chiefcomplaint_discolorationeye == "true"
        complaint_name = "discoloration_of_eye"
        @update_discoloration = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_discoloration.name = complaint_name
        @update_discoloration.side = @opd_record.chiefcomplaint_discolorationeye_side
        @update_discoloration.duration = @opd_record.chiefcomplaint_discolorationeye_duration
        @update_discoloration.duration_unit = @opd_record.chiefcomplaint_discolorationeye_duration_unit
        @update_discoloration.comment = @opd_record.chiefcomplaint_discolorationeye_comment
        @update_discoloration.opd_record_created_date = @opd_record.created_at
        @update_discoloration.opd_record_updated_date = Time.current
        @update_discoloration.save
      elsif @opd_record.chiefcomplaint_discolorationeye == "false"
        complaint_name = "discoloration_of_eye"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      if @opd_record.chiefcomplaint_burning == "true"
        complaint_name = "sensation_burning"
        @update_sensation = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_sensation.name = complaint_name
        @update_sensation.side = @opd_record.chiefcomplaint_burning_side
        @update_sensation.duration = @opd_record.chiefcomplaint_burning_duration
        @update_sensation.duration_unit = @opd_record.chiefcomplaint_burning_duration_unit
        @update_sensation.comment = @opd_record.chiefcomplaint_burning_comment
        @update_sensation.opd_record_created_date = @opd_record.created_at
        @update_sensation.opd_record_updated_date = Time.current
        @update_sensation.save
      elsif @opd_record.chiefcomplaint_burning == "false"
        complaint_name = "sensation_burning"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      if @opd_record.chiefcomplaint_swelling == "true"
        complaint_name = "swelling"
        @update_swelling = @opd_record.chief_complaints.find_by(name: complaint_name) || @opd_record.chief_complaints.new
        if @opd_record.complaints.present?
          if !@opd_record.complaints.include?(complaint_name)
            @opd_record.complaints = @opd_record.complaints + "," + complaint_name
          end
        else
          @opd_record.complaints = complaint_name
        end
        @update_swelling.name = complaint_name
        @update_swelling.side = @opd_record.chiefcomplaint_swelling_side
        @update_swelling.duration = @opd_record.chiefcomplaint_swelling_duration
        @update_swelling.duration_unit = @opd_record.chiefcomplaint_swelling_duration_unit
        @update_swelling.comment = @opd_record.chiefcomplaint_swelling_comment
        @update_swelling.opd_record_created_date = @opd_record.created_at
        @update_swelling.opd_record_updated_date = Time.current
        @update_swelling.save
      elsif @opd_record.chiefcomplaint_swelling == "false"
        complaint_name = "swelling"
        @update = @opd_record.chief_complaints.find_by(name: complaint_name)
        if @update.present?
          @complaints_list = @opd_record.complaints
          @complaint_array = @complaints_list.split(",")
          @complaint_array.delete(complaint_name)
          @opd_record.complaints = @complaint_array.join(",")
          @opd_record.save
          @update.delete
        end
      end

      @patient = Patient.find_by(id: patientid)
      if @patient.present? && @patient.patient_history.present?
        @ophthalmic_history = @patient.patient_history.patientpersonalhistory
        if @ophthalmic_history.present?
          @opd_record.opthal_history_comment = @ophthalmic_history.opthal_history_comment
          if @ophthalmic_history.glaucoma == "true"
            speciality_history = "glaucoma"
            @present_glaucoma =  @opd_record.speciality_history_records.find_by(name: speciality_history) || @opd_record.speciality_history_records.new
            if @opd_record.speciality_histories.present?
              if !@opd_record.speciality_histories.include?(speciality_history)
                @opd_record.speciality_histories = @opd_record.speciality_histories + "," + speciality_history
              end
            else
              @opd_record.speciality_histories = speciality_history
            end
            @present_glaucoma.name = speciality_history
            @present_glaucoma.l_duration = @ophthalmic_history.glaucoma_duration
            @present_glaucoma.l_duration_unit = @ophthalmic_history.glaucoma_duration_unit
            @present_glaucoma.r_duration = @ophthalmic_history.glaucoma_duration
            @present_glaucoma.r_duration_unit = @ophthalmic_history.glaucoma_duration_unit
            @present_glaucoma.opd_record_created_date = @opd_record.created_at
            @present_glaucoma.opd_record_updated_date = Time.current
            @present_glaucoma.save
          elsif @ophthalmic_history.glaucoma == "false"
            speciality_history = "glaucoma"
            @update = @opd_record.speciality_history_records.find_by(name: speciality_history)
            if @update.present?
              @complaints_list = @opd_record.speciality_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(speciality_history)
              @opd_record.speciality_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.retinal_detachment == "true"
            speciality_history = "retinal_detachment"
            @retinal_detachment = @opd_record.speciality_history_records.find_by(name: speciality_history) || @opd_record.speciality_history_records.new
            if @opd_record.speciality_histories.present?
              if !@opd_record.speciality_histories.include?(speciality_history)
                @opd_record.speciality_histories = @opd_record.speciality_histories + "," + speciality_history
              end
            else
              @opd_record.speciality_histories = speciality_history
            end
            @retinal_detachment.name = speciality_history
            @retinal_detachment.l_duration = @ophthalmic_history.retinal_detachment_duration
            @retinal_detachment.l_duration_unit = @ophthalmic_history.retinal_detachment_duration_unit
            @retinal_detachment.r_duration = @ophthalmic_history.retinal_detachment_duration
            @retinal_detachment.r_duration_unit = @ophthalmic_history.retinal_detachment_duration_unit
            @retinal_detachment.opd_record_created_date = @opd_record.created_at
            @retinal_detachment.opd_record_updated_date = Time.current
            @retinal_detachment.save
          elsif @ophthalmic_history.retinal_detachment == "false"
            speciality_history = "retinal_detachment"
            @update = @opd_record.speciality_history_records.find_by(name: speciality_history)
            if @update.present?
              @complaints_list = @opd_record.speciality_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(speciality_history)
              @opd_record.speciality_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.glasses == "true"
            speciality_history = "glasses"
            @present_glasses = @opd_record.speciality_history_records.find_by(name: speciality_history) || @opd_record.speciality_history_records.new
            if @opd_record.speciality_histories.present?
              if !@opd_record.speciality_histories.include?(speciality_history)
                @opd_record.speciality_histories = @opd_record.speciality_histories + "," + speciality_history
              end
            else
              @opd_record.speciality_histories = speciality_history
            end
            @present_glasses.name = speciality_history
            @present_glasses.l_duration = @ophthalmic_history.glasses_duration
            @present_glasses.l_duration_unit = @ophthalmic_history.glasses_duration_unit
            @present_glasses.r_duration = @ophthalmic_history.glasses_duration
            @present_glasses.r_duration_unit = @ophthalmic_history.glasses_duration_unit
            @present_glasses.opd_record_created_date = @opd_record.created_at
            @present_glasses.opd_record_updated_date = Time.current
            @present_glasses.save
          elsif @ophthalmic_history.glasses == "false"
            speciality_history = "glasses"
            @update = @opd_record.speciality_history_records.find_by(name: speciality_history)
            if @update.present?
              @complaints_list = @opd_record.speciality_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(speciality_history)
              @opd_record.speciality_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.eye_disease == "true"
            speciality_history = "eye_disease"
            @eye_disease = @opd_record.speciality_history_records.find_by(name: speciality_history) || @opd_record.speciality_history_records.new
            if @opd_record.speciality_histories.present?
              if !@opd_record.speciality_histories.include?(speciality_history)
                @opd_record.speciality_histories = @opd_record.speciality_histories + "," + speciality_history
              end
            else
              @opd_record.speciality_histories = speciality_history
            end
            @eye_disease.name = speciality_history
            @eye_disease.l_duration = @ophthalmic_history.eye_disease_duration
            @eye_disease.l_duration_unit = @ophthalmic_history.eye_disease_duration_unit
            @eye_disease.r_duration = @ophthalmic_history.eye_disease_duration
            @eye_disease.r_duration_unit = @ophthalmic_history.eye_disease_duration_unit
            @eye_disease.opd_record_created_date = @opd_record.created_at
            @eye_disease.opd_record_updated_date = Time.current
            @eye_disease.save
          elsif @ophthalmic_history.eye_disease == "false"
            speciality_history = "eye_disease"
            @update = @opd_record.speciality_history_records.find_by(name: speciality_history)
            if @update.present?
              @complaints_list = @opd_record.speciality_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(speciality_history)
              @opd_record.speciality_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.eye_surgery == "true"
            speciality_history = "eye_surgery"
            @eye_surgery = @opd_record.speciality_history_records.find_by(name: speciality_history) || @opd_record.speciality_history_records.new
            if @opd_record.speciality_histories.present?
              if !@opd_record.speciality_histories.include?(speciality_history)
                @opd_record.speciality_histories = @opd_record.speciality_histories + "," + speciality_history
              end
            else
              @opd_record.speciality_histories = speciality_history
            end
            @eye_surgery.name = speciality_history
            @eye_surgery.l_duration = @ophthalmic_history.eye_surgery_duration
            @eye_surgery.l_duration_unit = @ophthalmic_history.eye_surgery_duration_unit
            @eye_surgery.r_duration = @ophthalmic_history.eye_surgery_duration
            @eye_surgery.r_duration_unit = @ophthalmic_history.eye_surgery_duration_unit
            @eye_surgery.opd_record_created_date = @opd_record.created_at
            @eye_surgery.opd_record_updated_date = Time.current
            @eye_surgery.save
          elsif @ophthalmic_history.eye_surgery == "false"
            speciality_history = "eye_surgery"
            @update = @opd_record.speciality_history_records.find_by(name: speciality_history)
            if @update.present?
              @complaints_list = @opd_record.speciality_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(speciality_history)
              @opd_record.speciality_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.uveitis == "true"
            speciality_history = "uveitis"
            @present_uveitis = @opd_record.speciality_history_records.find_by(name: speciality_history) || @opd_record.speciality_history_records.new
            if @opd_record.speciality_histories.present?
              if !@opd_record.speciality_histories.include?(speciality_history)
                @opd_record.speciality_histories = @opd_record.speciality_histories + "," + speciality_history
              end
            else
              @opd_record.speciality_histories = speciality_history
            end
            @present_uveitis.name = speciality_history
            @present_uveitis.l_duration = @ophthalmic_history.uveitis_duration
            @present_uveitis.l_duration_unit = @ophthalmic_history.uveitis_duration_unit
            @present_uveitis.r_duration = @ophthalmic_history.uveitis_duration
            @present_uveitis.r_duration_unit = @ophthalmic_history.uveitis_duration_unit
            @present_uveitis.opd_record_created_date = @opd_record.created_at
            @present_uveitis.opd_record_updated_date = Time.current
            @present_uveitis.save
          elsif @ophthalmic_history.uveitis == "false"
            speciality_history = "uveitis"
            @update = @opd_record.speciality_history_records.find_by(name: speciality_history)
            if @update.present?
              @complaints_list = @opd_record.speciality_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(speciality_history)
              @opd_record.speciality_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.retinal_laser == "true"
            speciality_history = "retinal_laser"
            @retinal_laser = @opd_record.speciality_history_records.find_by(name: speciality_history) || @opd_record.speciality_history_records.new
            if @opd_record.speciality_histories.present?
              if !@opd_record.speciality_histories.include?(speciality_history)
                @opd_record.speciality_histories = @opd_record.speciality_histories + "," + speciality_history
              end
            else
              @opd_record.speciality_histories = speciality_history
            end
            @retinal_laser.name = speciality_history
            @retinal_laser.l_duration = @ophthalmic_history.retinal_laser_duration
            @retinal_laser.l_duration_unit = @ophthalmic_history.retinal_laser_duration_unit
            @retinal_laser.r_duration = @ophthalmic_history.retinal_laser_duration
            @retinal_laser.r_duration_unit = @ophthalmic_history.retinal_laser_duration_unit
            @retinal_laser.opd_record_created_date = @opd_record.created_at
            @retinal_laser.opd_record_updated_date = Time.current
            @retinal_laser.save
          elsif @ophthalmic_history.retinal_laser == "false"
            speciality_history = "retinal_laser"
            @update = @opd_record.speciality_history_records.find_by(name: speciality_history)
            if @update.present?
              @complaints_list = @opd_record.speciality_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(speciality_history)
              @opd_record.speciality_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end

          # personal Histories
          @opd_record.history_comment = @ophthalmic_history.history_comment
          if @ophthalmic_history.diabetes == "true"
            personal_history = "diabetes"
            @present_diabetes = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @present_diabetes.name = personal_history
            @present_diabetes.duration = @ophthalmic_history.diabetes_duration
            @present_diabetes.duration_unit = @ophthalmic_history.diabetes_duration_unit
            @present_diabetes.opd_record_created_date = @opd_record.created_at
            @present_diabetes.opd_record_updated_date = Time.current
            @present_diabetes.save
          elsif @ophthalmic_history.diabetes == "false"
            personal_history = "diabetes"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.hypertension == "true"
            personal_history = "hypertension"
            @present_hypertension = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @present_hypertension.name = personal_history
            @present_hypertension.duration = @ophthalmic_history.hypertension_duration
            @present_hypertension.duration_unit = @ophthalmic_history.hypertension_duration_unit
            @present_hypertension.opd_record_created_date = @opd_record.created_at
            @present_hypertension.opd_record_updated_date = Time.current
            @present_hypertension.save
          elsif @ophthalmic_history.hypertension == "false"
            personal_history = "hypertension"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.alcoholism == "true"
            personal_history = "alcoholism"
            @present_alcoholism = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @present_alcoholism.name = personal_history
            @present_alcoholism.duration = @ophthalmic_history.alcoholism_duration
            @present_alcoholism.duration_unit = @ophthalmic_history.alcoholism_duration_unit
            @present_alcoholism.opd_record_created_date = @opd_record.created_at
            @present_alcoholism.opd_record_updated_date = Time.current
            @present_alcoholism.save
          elsif @ophthalmic_history.alcoholism == "false"
            personal_history = "alcoholism"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.smoking_tobacco == "true"
            personal_history = "smoking_tobacco"
            @present_smoking_tobacco = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @present_smoking_tobacco.name = personal_history
            @present_smoking_tobacco.duration = @ophthalmic_history.smoking_tobacco_duration
            @present_smoking_tobacco.duration_unit = @ophthalmic_history.smoking_tobacco_duration_unit
            @present_smoking_tobacco.opd_record_created_date = @opd_record.created_at
            @present_smoking_tobacco.opd_record_updated_date = Time.current
            @present_smoking_tobacco.save
          elsif @ophthalmic_history.smoking_tobacco == "false"
            personal_history = "smoking_tobacco"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.cardiac_disorder == "true"
            personal_history = "cardiac_disorder"
            @present_cardiac_disorder = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @present_cardiac_disorder.name = personal_history
            @present_cardiac_disorder.duration = @ophthalmic_history.cardiac_disorder_duration
            @present_cardiac_disorder.duration_unit = @ophthalmic_history.cardiac_disorder_duration_unit
            @present_cardiac_disorder.opd_record_created_date = @opd_record.created_at
            @present_cardiac_disorder.opd_record_updated_date = Time.current
            @present_cardiac_disorder.save
          elsif @ophthalmic_history.cardiac_disorder == "false"
            personal_history = "cardiac_disorder"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end

          if @ophthalmic_history.rheumatoid_arthritis == "true"
            personal_history = "rheumatoid_arthritis"
            @present_rheumatoid_arthritis = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @present_rheumatoid_arthritis.name = personal_history
            @present_rheumatoid_arthritis.duration = @ophthalmic_history.rheumatoid_arthritis_duration
            @present_rheumatoid_arthritis.duration_unit = @ophthalmic_history.rheumatoid_arthritis_duration_unit
            @present_rheumatoid_arthritis.opd_record_created_date = @opd_record.created_at
            @present_rheumatoid_arthritis.opd_record_updated_date = Time.current
            @present_rheumatoid_arthritis.save
          elsif @ophthalmic_history.rheumatoid_arthritis == "false"
            personal_history = "rheumatoid_arthritis"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end

          if @ophthalmic_history.steroid_intake == "true"
            personal_history = "steroid_intake"
            @present_steroid_intake = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @present_steroid_intake.name = personal_history
            @present_steroid_intake.duration = @ophthalmic_history.steroid_intake_duration
            @present_steroid_intake.duration_unit = @ophthalmic_history.steroid_intake_duration_unit
            @present_steroid_intake.opd_record_created_date = @opd_record.created_at
            @present_steroid_intake.opd_record_updated_date = Time.current
            @present_steroid_intake.save
          elsif @ophthalmic_history.steroid_intake == "false"
            personal_history = "steroid_intake"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.drug_abuse == "true"
            personal_history = "drug_abuse"
            @patient_drug_abuse = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @patient_drug_abuse.name = personal_history
            @patient_drug_abuse.duration = @ophthalmic_history.drug_abuse_duration
            @patient_drug_abuse.duration_unit = @ophthalmic_history.drug_abuse_duration_unit
            @patient_drug_abuse.opd_record_created_date = @opd_record.created_at
            @patient_drug_abuse.opd_record_updated_date = Time.current
            @patient_drug_abuse.save
          elsif @ophthalmic_history.drug_abuse == "false"
            personal_history = "drug_abuse"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.hiv_aids == "true"
            personal_history = "hiv_aids"
            @patient_hiv_aids = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @patient_hiv_aids.name = personal_history
            @patient_hiv_aids.duration = @ophthalmic_history.hiv_aids_duration
            @patient_hiv_aids.duration_unit = @ophthalmic_history.hiv_aids_duration_unit
            @patient_hiv_aids.opd_record_created_date = @opd_record.created_at
            @patient_hiv_aids.opd_record_updated_date = Time.current
            @patient_hiv_aids.save
          elsif @ophthalmic_history.hiv_aids == "false"
            personal_history = "hiv_aids"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.cancer_tumor == "true"
            personal_history = "cancer_tumor"
            @patient_cancer_tumor = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @patient_cancer_tumor.name = personal_history
            @patient_cancer_tumor.duration = @ophthalmic_history.cancer_tumor_duration
            @patient_cancer_tumor.duration_unit = @ophthalmic_history.cancer_tumor_duration_unit
            @patient_cancer_tumor.opd_record_created_date = @opd_record.created_at
            @patient_cancer_tumor.opd_record_updated_date = Time.current
            @patient_cancer_tumor.save
          elsif @ophthalmic_history.cancer_tumor == "false"
            personal_history = "cancer_tumor"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.tuberculosis == "true"
            personal_history = "tuberculosis"
            @patient_tuberculosis = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @patient_tuberculosis.name = personal_history
            @patient_tuberculosis.duration = @ophthalmic_history.tuberculosis_duration
            @patient_tuberculosis.duration_unit = @ophthalmic_history.tuberculosis_duration_unit
            @patient_tuberculosis.opd_record_created_date = @opd_record.created_at
            @patient_tuberculosis.opd_record_updated_date = Time.current
            @patient_tuberculosis.save
          elsif @ophthalmic_history.tuberculosis == "false"
            personal_history = "tuberculosis"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.asthma == "true"
            personal_history = "asthma"
            @patient_asthma = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @patient_asthma.name = personal_history
            @patient_asthma.duration = @ophthalmic_history.asthma_duration
            @patient_asthma.duration_unit = @ophthalmic_history.asthma_duration_unit
            @patient_asthma.opd_record_created_date = @opd_record.created_at
            @patient_asthma.opd_record_updated_date = Time.current
            @patient_asthma.save
          elsif @ophthalmic_history.asthma == "false"
            personal_history = "asthma"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.cns_disorder_stroke == "true"
            personal_history = "cns_disorder_stroke"
            @patient_cns_disorder_stroke = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @patient_cns_disorder_stroke.name = personal_history
            @patient_cns_disorder_stroke.duration = @ophthalmic_history.cns_disorder_stroke_duration
            @patient_cns_disorder_stroke.duration_unit = @ophthalmic_history.cns_disorder_stroke_duration_unit
            @patient_cns_disorder_stroke.opd_record_created_date = @opd_record.created_at
            @patient_cns_disorder_stroke.opd_record_updated_date = Time.current
            @patient_cns_disorder_stroke.save
          elsif @ophthalmic_history.cns_disorder_stroke == "false"
            personal_history = "cns_disorder_stroke"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.hypothyroidism == "true"
            personal_history = "hypothyroidism"
            @patient_hypothyroidism = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @patient_hypothyroidism.name = personal_history
            @patient_hypothyroidism.duration = @ophthalmic_history.hypothyroidism_duration
            @patient_hypothyroidism.duration_unit = @ophthalmic_history.hypothyroidism_duration_unit
            @patient_hypothyroidism.opd_record_created_date = @opd_record.created_at
            @patient_hypothyroidism.opd_record_updated_date = Time.current
            @patient_hypothyroidism.save
          elsif @ophthalmic_history.hypothyroidism == "false"
            personal_history = "hypothyroidism"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.hyperthyroidism == "true"
            personal_history = "hyperthyroidism"
            @patient_hyperthyroidism = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @patient_hyperthyroidism.name = personal_history
            @patient_hyperthyroidism.duration = @ophthalmic_history.hyperthyroidism_duration
            @patient_hyperthyroidism.duration_unit = @ophthalmic_history.hyperthyroidism_duration_unit
            @patient_hyperthyroidism.opd_record_created_date = @opd_record.created_at
            @patient_hyperthyroidism.opd_record_updated_date = Time.current
            @patient_hyperthyroidism.save
          elsif @ophthalmic_history.hyperthyroidism == "false"
            personal_history = "hyperthyroidism"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.hepatitis_cirrhosis == "true"
            personal_history = "hepatitis_cirrhosis"
            @patient_hepatitis_cirrhosis = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @patient_hepatitis_cirrhosis.name = personal_history
            @patient_hepatitis_cirrhosis.duration = @ophthalmic_history.hepatitis_cirrhosis_duration
            @patient_hepatitis_cirrhosis.duration_unit = @ophthalmic_history.hepatitis_cirrhosis_duration_unit
            @patient_hepatitis_cirrhosis.opd_record_created_date = @opd_record.created_at
            @patient_hepatitis_cirrhosis.opd_record_updated_date = Time.current
            @patient_hepatitis_cirrhosis.save
          elsif @ophthalmic_history.hepatitis_cirrhosis == "false"
            personal_history = "hepatitis_cirrhosis"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.renal_disorder == "true"
            personal_history = "renal_disorder"
            @patient_renal_disorder = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @patient_renal_disorder.name = personal_history
            @patient_renal_disorder.duration = @ophthalmic_history.renal_disorder_duration
            @patient_renal_disorder.duration_unit = @ophthalmic_history.renal_disorder_duration_unit
            @patient_renal_disorder.opd_record_created_date = @opd_record.created_at
            @patient_renal_disorder.opd_record_updated_date = Time.current
            @patient_renal_disorder.save
          elsif @ophthalmic_history.renal_disorder == "false"
            personal_history = "renal_disorder"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.acidity == "true"
            personal_history = "acidity"
            @patient_acidity = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @patient_acidity.name = personal_history
            @patient_acidity.duration = @ophthalmic_history.acidity_duration
            @patient_acidity.duration_unit = @ophthalmic_history.acidity_duration_unit
            @patient_acidity.opd_record_created_date = @opd_record.created_at
            @patient_acidity.opd_record_updated_date = Time.current
            @patient_acidity.save
          elsif @ophthalmic_history.acidity == "false"
            personal_history = "acidity"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end

          if @ophthalmic_history.thyroid_disorder == "true"
            personal_history = "thyroid_disorder"
            @patient_thyroid_disorder = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @patient_thyroid_disorder.name = personal_history
            @patient_thyroid_disorder.duration = @ophthalmic_history.thyroid_disorder_duration
            @patient_thyroid_disorder.duration_unit = @ophthalmic_history.thyroid_disorder_duration_unit
            @patient_thyroid_disorder.opd_record_created_date = @opd_record.created_at
            @patient_thyroid_disorder.opd_record_updated_date = Time.current
            @patient_thyroid_disorder.save
          elsif @ophthalmic_history.thyroid_disorder == "false"
            personal_history = "thyroid_disorder"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end

          if @ophthalmic_history.on_insulin == "true"
            personal_history = "on_insulin"
            @patient_on_insulin = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @patient_on_insulin.name = personal_history
            @patient_on_insulin.duration = @ophthalmic_history.on_insulin_duration
            @patient_on_insulin.duration_unit = @ophthalmic_history.on_insulin_duration_unit
            @patient_on_insulin.opd_record_created_date = @opd_record.created_at
            @patient_on_insulin.opd_record_updated_date = Time.current
            @patient_on_insulin.save
          elsif @ophthalmic_history.on_insulin == "false"
            personal_history = "on_insulin"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.on_aspirin_blood_thinners == "true"
            personal_history = "on_aspirin_blood_thinners"
            @patient_on_aspirin_blood_thinners = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @patient_on_aspirin_blood_thinners.name = personal_history
            @patient_on_aspirin_blood_thinners.duration = @ophthalmic_history.on_aspirin_blood_thinners_duration
            @patient_on_aspirin_blood_thinners.duration_unit = @ophthalmic_history.on_aspirin_blood_thinners_duration_unit
            @patient_on_aspirin_blood_thinners.opd_record_created_date = @opd_record.created_at
            @patient_on_aspirin_blood_thinners.opd_record_updated_date = Time.current
            @patient_on_aspirin_blood_thinners.save
          elsif @ophthalmic_history.on_aspirin_blood_thinners == "false"
            personal_history = "on_aspirin_blood_thinners"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
          if @ophthalmic_history.consanguinity == "true"
            personal_history = "consanguinity"
            @patient_consanguinity = @opd_record.personal_history_records.find_by(name: personal_history) || @opd_record.personal_history_records.new
            if @opd_record.personal_histories.present?
              if !@opd_record.personal_histories.include?(personal_history)
                @opd_record.personal_histories = @opd_record.personal_histories + "," + personal_history
              end
            else
              @opd_record.personal_histories = personal_history
            end
            @patient_consanguinity.name = personal_history
            @patient_consanguinity.duration = @ophthalmic_history.consanguinity_duration
            @patient_consanguinity.duration_unit = @ophthalmic_history.consanguinity_duration_unit
            @patient_consanguinity.opd_record_created_date = @opd_record.created_at
            @patient_consanguinity.opd_record_updated_date = Time.current
            @patient_consanguinity.save
          elsif @ophthalmic_history.consanguinity == "false"
            personal_history = "consanguinity"
            @update = @opd_record.personal_history_records.find_by(name: personal_history)
            if @update.present?
              @complaints_list = @opd_record.personal_histories
              @complaint_array = @complaints_list.split(",")
              @complaint_array.delete(personal_history)
              @opd_record.personal_histories = @complaint_array.join(",")
              @opd_record.save
              @update.delete
            end
          end
        end
        @medical_history = @ophthalmic_history.medical_history_comment
        @family_history = @ophthalmic_history.family_history_comment
        @other_histories = @opd_record.other_history
        @other_histories.medical_history = @medical_history
        @other_histories.family_history = @family_history
        @other_histories.specialstatus = @patient.specialstatus
        @other_histories.opd_record_created_date = @opd_record.created_at
        @other_histories.opd_record_updated_date = Time.current
        @other_histories.save
        # end

        # allergies

        @allergies = @patient.patient_history.patientallergyhistory
        if @allergies.present?
          @opd_record.allergy_histories.delete_all
          @opd_record.drug_allergies = ""
          @opd_record.antimicrobial_agents = ""
          @opd_record.antifungal_agents = ""
          @opd_record.antiviral_agents = ""
          @opd_record.nsaids = ""
          @opd_record.eye_drops = ""
          @opd_record.food_allergies = ""
          @opd_record.contact_allergies = ""
          @opd_record.others_allergies = @allergies.others
          if @allergies.antimicrobialagents.present?
            if @opd_record.drug_allergies.present?
              if !@opd_record.drug_allergies.include?("antimicrobial_agents")
                @opd_record.drug_allergies = @opd_record.drug_allergies + "," + "antimicrobial_agents"
              end
            else
              @opd_record.drug_allergies = "antimicrobial_agents"
            end
            @allergies.antimicrobialagents.each do |agents|
              @old_allergies = @opd_record.allergy_histories.find_by(allergysnomedid: agents) || @opd_record.allergy_histories.new
              Global.send("ehrcommon").antimicrobialagents.each do |aller|
                if aller[:allergysnomedid] == agents
                  if @opd_record.antimicrobial_agents.present?
                    if !@opd_record.antimicrobial_agents.include?(aller[:allergyname])
                      @opd_record.antimicrobial_agents = @opd_record.antimicrobial_agents + "," + aller[:allergyname]
                    end
                  else
                    @opd_record.antimicrobial_agents = aller[:allergyname]
                  end
                  @old_allergies.name = aller[:allergyname]
                  @old_allergies.allergy_type = "drug_allergies"
                  @old_allergies.allergy_subtype = "antimicrobial_agents"
                  @old_allergies.allergysnomedid = aller[:allergysnomedid]
                  @old_allergies.opd_record_created_date = @opd_record.created_at
                  @old_allergies.opd_record_updated_date = Time.current
                  @old_allergies.save
                end
              end
            end
          end
          if @allergies.antifungalagents.present?
            if @opd_record.drug_allergies.present?
              if !@opd_record.drug_allergies.include?("antifungal_agents")
                @opd_record.drug_allergies = @opd_record.drug_allergies + "," + "antifungal_agents"
              end
            else
              @opd_record.drug_allergies = "antifungal_agents"
            end
            @allergies.antifungalagents.each do |agents|
              @old_allergies = @opd_record.allergy_histories.find_by(allergysnomedid: agents) || @opd_record.allergy_histories.new
              Global.send("ehrcommon").antifungalagents.each do |aller|
                if aller[:allergysnomedid] == agents
                  if @opd_record.antifungal_agents.present?
                    if !@opd_record.antifungal_agents.include?(aller[:allergyname])
                      @opd_record.antifungal_agents = @opd_record.antifungal_agents + "," + aller[:allergyname]
                    end
                  else
                    @opd_record.antifungal_agents = aller[:allergyname]
                  end
                  @old_allergies.name = aller[:allergyname]
                  @old_allergies.allergy_type = "drug_allergies"
                  @old_allergies.allergy_subtype = "antifungal_agents"
                  @old_allergies.allergysnomedid = aller[:allergysnomedid]
                  @old_allergies.opd_record_created_date = @opd_record.created_at
                  @old_allergies.opd_record_updated_date = Time.current
                  @old_allergies.save
                end
              end
            end
          end
          if @allergies.antiviralagents.present?
            if @opd_record.drug_allergies.present?
              if !@opd_record.drug_allergies.include?("antiviral_agents")
                @opd_record.drug_allergies = @opd_record.drug_allergies + "," + "antiviral_agents"
              end
            else
              @opd_record.drug_allergies = "antiviral_agents"
            end
            @allergies.antiviralagents.each do |agents|
              @old_allergies = @opd_record.allergy_histories.find_by(allergysnomedid: agents) || @opd_record.allergy_histories.new
              Global.send("ehrcommon").antiviralagents.each do |aller|
                if aller[:allergysnomedid] == agents
                  if @opd_record.antiviral_agents.present?
                    if !@opd_record.antiviral_agents.include?(aller[:allergyname])
                      @opd_record.antiviral_agents = @opd_record.antiviral_agents + "," + aller[:allergyname]
                    end
                  else
                    @opd_record.antiviral_agents = aller[:allergyname]
                  end
                  @old_allergies.allergy_type = "drug_allergies"
                  @old_allergies.allergy_subtype = "antiviral_agents"
                  @old_allergies.name = aller[:allergyname]
                  @old_allergies.allergysnomedid = aller[:allergysnomedid]
                  @old_allergies.opd_record_created_date = @opd_record.created_at
                  @old_allergies.opd_record_updated_date = Time.current
                  @old_allergies.save
                end
              end
            end
          end
          if @allergies.nsaids.present?
            if @opd_record.drug_allergies.present?
              if !@opd_record.drug_allergies.include?("nsaids")
                @opd_record.drug_allergies = @opd_record.drug_allergies + "," + "nsaids"
              end
            else
              @opd_record.drug_allergies = "nsaids"
            end
            @allergies.nsaids.each do |agents|
              @old_allergies = @opd_record.allergy_histories.find_by(allergysnomedid: agents) || @opd_record.allergy_histories.new
              Global.send("ehrcommon").nsaids.each do |aller|
                if aller[:allergysnomedid] == agents
                  if @opd_record.nsaids.present?
                    if !@opd_record.nsaids.include?(aller[:allergyname])
                      @opd_record.nsaids = @opd_record.nsaids + "," + aller[:allergyname]
                    end
                  else
                    @opd_record.nsaids = aller[:allergyname]
                  end
                  @old_allergies.name = aller[:allergyname]
                  @old_allergies.allergy_type = "drug_allergies"
                  @old_allergies.allergy_subtype = "nsaids"
                  @old_allergies.allergysnomedid = aller[:allergysnomedid]
                  @old_allergies.opd_record_created_date = @opd_record.created_at
                  @old_allergies.opd_record_updated_date = Time.current
                  @old_allergies.save
                end
              end
            end
          end
          if @allergies.eyedrops.present?
            if @opd_record.drug_allergies.present?
              if !@opd_record.drug_allergies.include?("eye_drops")
                @opd_record.drug_allergies = @opd_record.drug_allergies + "," + "eye_drops"
              end
            else
              @opd_record.drug_allergies = "eye_drops"
            end
            @allergies.eyedrops.each do |agents|
              @old_allergies = @opd_record.allergy_histories.find_by(allergysnomedid: agents) || @opd_record.allergy_histories.new
              Global.send("ehrcommon").eyedrops.each do |aller|
                if aller[:allergysnomedid] == agents
                  if @opd_record.eye_drops.present?
                    eye_allergy_name = @opd_record.eye_drops.split(",")
                    if !eye_allergy_name.include?(aller[:allergyname])
                      eye_allergy_name_s = eye_allergy_name.join(",")
                      @opd_record.eye_drops = eye_allergy_name_s + "," + aller[:allergyname]
                    end
                  else
                    @opd_record.eye_drops = aller[:allergyname]
                  end
                  @old_allergies.name = aller[:allergyname]
                  @old_allergies.allergy_type = "drug_allergies"
                  @old_allergies.allergy_subtype = "eye_drops"
                  @old_allergies.allergysnomedid = aller[:allergysnomedid]
                  @old_allergies.opd_record_created_date = @opd_record.created_at
                  @old_allergies.opd_record_updated_date = Time.current
                  @old_allergies.save
                end
              end
            end
          end
          if @allergies.contact.present?
            @allergies.contact.each do |agents|
              @old_allergies = @opd_record.allergy_histories.find_by(allergysnomedid: agents) || @opd_record.allergy_histories.new
              Global.send("ehrcommon").contact.each do |aller|
                if aller[:allergysnomedid] == agents
                  if @opd_record.contact_allergies.present?
                    if !@opd_record.contact_allergies.include?(aller[:allergyname])
                      @opd_record.contact_allergies = @opd_record.contact_allergies + "," + aller[:allergyname]
                    end
                  else
                    @opd_record.contact_allergies = aller[:allergyname]
                  end
                  @old_allergies.name = aller[:allergyname]
                  @old_allergies.allergy_type = "contact_allergies"
                  @old_allergies.allergy_subtype = ""
                  if aller[:allergyname] == "tegaderm"
                    @old_allergies.allergysnomedid = '419238010'
                  else
                    @old_allergies.allergysnomedid = aller[:allergysnomedid]
                  end
                  @old_allergies.opd_record_created_date = @opd_record.created_at
                  @old_allergies.opd_record_updated_date = Time.current
                  @old_allergies.save
                end
              end
            end
          end
          if @allergies.food.present?
            @allergies.food.each do |agents|
              @old_allergies = @opd_record.allergy_histories.find_by(allergysnomedid: agents) || @opd_record.allergy_histories.new
              Global.send("ehrcommon").food.each do |aller|
                if aller[:allergysnomedid] == agents
                  if @opd_record.food_allergies.present?
                    if !@opd_record.food_allergies.include?(aller[:allergyname])
                      @opd_record.food_allergies = @opd_record.food_allergies + "," + aller[:allergyname]
                    end
                  else
                    @opd_record.food_allergies = aller[:allergyname]
                  end
                  @old_allergies.name = aller[:allergyname]
                  @old_allergies.allergy_type = "food_allergies"
                  @old_allergies.allergy_subtype = ""
                  @old_allergies.allergysnomedid = aller[:allergysnomedid]
                  @old_allergies.opd_record_created_date = @opd_record.created_at
                  @old_allergies.opd_record_updated_date = Time.current
                  @old_allergies.save
                end
              end
            end
          end
        end
      end
      # Lans history
      @lens_history = @opd_record.lens_history
      @lens_history.lens_history_comment = @opd_record.lens_history_comment
      if @opd_record.profession == "true"
        @lens_history.profession = @opd_record.profession_box
      else
        @lens_history.profession = ""
      end

      if @opd_record.lens_needed == "true"
        @lens_history.lens_needed = @opd_record.lens_needed_box
      else
        @lens_history.lens_needed = ""
      end

      if @opd_record.wearing_hour == "true"
        @lens_history.present_wearing_hour = @opd_record.present_wearing_hour_box
      else
        @lens_history.present_wearing_hour = ""
      end

      if @opd_record.complaint_with_existing_lens == "true"
        @lens_history.complaint_with_existing_lens = @opd_record.complaint_with_existing_lens_box
      else
        @lens_history.complaint_with_existing_lens = ""
      end
      if @opd_record.hour_of_usage == "true"
        @lens_history.hour_of_using_lens = @opd_record.hour_of_using_lens
      else
        @lens_history.hour_of_using_lens = ""
      end
      if @opd_record.brand == "true"
        @lens_history.brand = @opd_record.brand_box
        @lens_history.brand_duration = @opd_record.brand_duration
        @lens_history.brand_duration_unit = @opd_record.brand_duration_unit
      else
        @lens_history.brand = ""
        @lens_history.brand = ""
        @lens_history.brand_duration = ""
        @lens_history.brand_duration_unit = ""
      end
      if @opd_record.comfort_level == "true"
        @lens_history.comfort_level_time = @opd_record.comfort_level_dropdown
      else
        @lens_history.comfort_level_time = ""
      end
      if @opd_record.lens_wearing == "true"
        @lens_history.lens_weraing_duration = @opd_record.lens_wearing_duration
        @lens_history.lens_weraing_duration_unit = @opd_record.lens_wearing_duration_unit
      else
        @lens_history.lens_weraing_duration = ""
        @lens_history.lens_weraing_duration_unit = ""
      end
      @lens_history.opd_record_created_date = @opd_record.created_at
      @lens_history.opd_record_updated_date = Time.current
      @lens_history.save

      # Paediatrics HIstory
      @paediatrics_history = @opd_record.paediatrics_history
      @paediatrics_history.antenatal_maternal_vaccination = @opd_record.antenatal_maternal_vaccination
      @paediatrics_history.antenatal_maternal_infection = @opd_record.antenatal_maternal_infection
      if @opd_record.natal_history_normal == "true"
        @paediatrics_history.natal_history_normal = @opd_record.natal_history_normal
      else
        @paediatrics_history.natal_history_normal = ""
      end
      if @opd_record.natal_history_forceps == "true"
        @paediatrics_history.natal_history_forceps = @opd_record.natal_history_forceps
      else
        @paediatrics_history.natal_history_forceps = ""
      end
      if @opd_record.natal_history_caesarean == "true"
        @paediatrics_history.natal_history_caesarean = @opd_record.natal_history_caesarean
      else
        @paediatrics_history.natal_history_caesarean = ""
      end
      @paediatrics_history.natal_birth_weight = @opd_record.natal_birth_weight
      @paediatrics_history.post_natal_history = @opd_record.post_natal_history
      @paediatrics_history.ho_vaccination = @opd_record.ho_vaccination
      @paediatrics_history.developmental_history = @opd_record.developmental_history
      @paediatrics_history.opd_record_created_date = @opd_record.created_at
      @paediatrics_history.opd_record_updated_date = Time.current
      @paediatrics_history.save
      @opd_record.is_migrated = true

    end
    @opd_record.save
  end
end
