class IpdService::Records
  def initialize(admission_id, record_id)
    @record_id = record_id
    @admission = Admission.find_by(id: admission_id)
    @department = Department.find_by(id: @admission.department_id)
  end

  def create
    @ipdrecord = Inpatient::IpdRecord.create(create_params)
  end

  def update
    find_admission_note
    find_ipd_record
    @admission_clinical_note = Inpatient::IpdRecord::AdmissionNote.unscoped.find_by(admission_id: @admission.id)
    @ipdrecord.update(update_params) if @ipdrecord.present?
  end

  def create_clinical_note
    find_ipd_record
    find_clinical_note
    @clinical_note = @ipdrecord.build_clinical_note(create_clinical_note_params)
    if @clinical_note.save!
      p "clinical note added"
    else
      p "clinical note not added for ipdrecord: #{@ipdrecord.id}"
    end
  end

  def update_clinical_note_history
    find_ipd_record
    find_clinical_note
    @new_clinical_note = @ipdrecord.clinical_note
    @old_clinical_note.record_histories.each do |history|
      history_attributes = history.attributes
      history_attributes[:id] = BSON::ObjectId.new
      @new_clinical_note.record_histories.create(history_attributes)
    end
  end

  def create_operative_note
    find_ipd_record
    find_operative_note
    @ipdrecord.operative_notes.destroy_all
    @operative_note = @ipdrecord.operative_notes.new(create_operative_note_params)
    @operative_note.save!
    time_calculation
    migrate_inventory_data
  end

  def update_operative_note_history
    find_ipd_record
    find_operative_note
    @new_operative_note = @ipdrecord.operative_notes[0]
    @old_operative_note.record_histories.each do |history|
      history_attributes = history.attributes
      history_attributes[:id] = BSON::ObjectId.new
      @new_operative_note.record_histories.create(history_attributes)
    end
  end

  def create_discharge_note
    find_ipd_record
    find_discharge_note
    @discharge_note = @ipdrecord.build_discharge_note(create_discharge_note_params)
    @discharge_note.save!
    migrate_medication_data
  end

  def update_discharge_note_history
    find_ipd_record
    find_discharge_note
    @new_discharge_note = @ipdrecord.discharge_note
    @old_discharge_note.record_histories.each do |history|
      history_attributes = history.attributes
      history_attributes[:id] = BSON::ObjectId.new
      @new_discharge_note.record_histories.create(history_attributes)
    end
  end

  def create_ward_note
    find_ipd_record
    find_ward_note
    @ward_note = @ipdrecord.ward_notes.new(create_ward_note_params)
    @ward_note.save
  end

  def update_ward_note_history
    find_ipd_record
    find_ward_note
    @new_ward_note = @ipdrecord.ward_notes[0]
    @old_ward_note.record_histories.each do |history|
      history_attributes = history.attributes
      history_attributes[:id] = BSON::ObjectId.new
      @new_ward_note.record_histories.create(history_attributes)
    end
  end

  private

  def create_params
    {
      patient_id: @admission.patient_id,
      admission_id: @admission.id,
      doctor_id: @admission.doctor,
      facility_id: @admission.facility_id,
      case_sheet_id: @admission.case_sheet_id,
      department_id: @admission.department_id,
      department: @department.try(:name),
      admissiondate: @admission.admissiondate || Date.current,
      admissiontime: @admission.admissiontime || Time.current,
      admissionreason: @admission.admissionreason,
      management_plan: @admission.managementplan,
      discharge_date: @admission.dischargedate,
      is_deleted: false,
      _type: nil
    }
  end

  def update_params
    {
      # update admission attributes
      doctor_id: @admission.doctor,
      facility_id: @admission.facility_id,
      case_sheet_id: @admission.case_sheet_id,
      admissiondate: @admission.admissiondate,
      admissiontime: @admission.admissiontime,
      admissionreason: @admission_note.admissionreason || @admission_clinical_note.try(:admissionreason),
      discharge_date: @admission_note.discharge_date || @admission_clinical_note.expected_discharge_date,
      management_plan: @admission.managementplan,
      department: @department.try(:name),
      # update admssion note attributes
      expected_stay: @admission_note.expected_stay || @admission_clinical_note.try(:expected_stay),
      expected_management: @admission_note.try(:expected_management) || @admission_clinical_note.try(:expected_management),
      complaint_date: @admission_note.try(:complaint_date),
      medico_legal_case: @admission_note.try(:medico_legal_case),
      medico_legal_details: @admission_note.try(:medico_legal_details),
      payment_type: @admission_note.try(:payment_type) || @admission_clinical_note.try(:ipd_payment_type),
      hospitalization_reason: @admission_note.try(:hospitalization_reason) || @admission_clinical_note.try(:hospitalization_reason),
      _type: nil
    }
  end

  def create_clinical_note_params
    {
      :note_date => @old_clinical_note.note_date,
      :note_time => @old_clinical_note.note_time,
      :note_created_at => (@old_clinical_note.note_created_at if @old_clinical_note.note_created_at.present?) || @old_clinical_note.created_at,
      :organisation_id => @old_clinical_note.organisation_id,
      :admission_id => @old_clinical_note.admission_id,
      :patient_id => @old_clinical_note.patient_id,
      :user_id => @old_clinical_note.user_id,
      :department => @old_clinical_note.department,
      :specalityid => @old_clinical_note.specalityid,
      :specalityname => @old_clinical_note.specalityname,
      :ward_id => @old_clinical_note.ward_id,
      :room_id => @old_clinical_note.room_id,
      :bed_id => @old_clinical_note.bed_id,
      :daycare => @old_clinical_note.daycare,
      :patient_name => @old_clinical_note.patient_name,
      :patient_age => @old_clinical_note.patient_age,
      :patient_gender => @old_clinical_note.patient_gender,
      :mr_no => @old_clinical_note.mr_no,
      :patient_identifier_id => @old_clinical_note.patient_identifier_id,
      :first_opd_visit => @old_clinical_note.first_opd_visit,
      :ipd_billing_category => @old_clinical_note.ipd_billing_category,
      :admin_comments => @old_clinical_note.try(:admin_comment) || @old_clinical_note.try(:procedure_planned),
      :r_hpi => @old_clinical_note.r_hpi,
      :r_refraction => @old_clinical_note.r_refraction,
      :l_refraction => @old_clinical_note.l_refraction,
      :r_iop => @old_clinical_note.r_iop,
      :l_iop => @old_clinical_note.l_iop,
      :r_appendages => @old_clinical_note.r_appendages,
      :l_appendages => @old_clinical_note.l_appendages,
      :r_anterior => @old_clinical_note.r_anterior,
      :l_anterior => @old_clinical_note.l_anterior,
      :r_posterior => @old_clinical_note.r_posterior,
      :l_posterior => @old_clinical_note.l_posterior,
      :r_eom => @old_clinical_note.r_eom,
      :l_eom => @old_clinical_note.l_eom,
      :airway_assesment => @old_clinical_note.airway_assesment,
      :airway_assesment_abnormal => @old_clinical_note.airway_assesment_abnormal,
      :breathing_assesment => @old_clinical_note.breathing_assesment,
      :breathing_assesment_abnormal => @old_clinical_note.breathing_assesment_abnormal,
      :pulse_assesment => @old_clinical_note.pulse_assesment,
      :pulse_assesment_abnormal => @old_clinical_note.pulse_assesment_abnormal,
      :bp_assesment => @old_clinical_note.bp_assesment,
      :bp_assesment_abnormal => @old_clinical_note.bp_assesment_abnormal,
      :pressure_ulcer_risk => @old_clinical_note.pressure_ulcer_risk,
      :risk_of_fall => @old_clinical_note.risk_of_fall,
      :vte_risk => @old_clinical_note.vte_risk,
      :general_pallor => @old_clinical_note.general_pallor,
      :general_icterus => @old_clinical_note.general_icterus,
      :general_cyanosis => @old_clinical_note.general_cyanosis,
      :resp_air_entry => @old_clinical_note.resp_air_entry,
      :resp_breath_sounds => @old_clinical_note.resp_breath_sounds,
      :resp_breath_sounds_abnormal => @old_clinical_note.resp_breath_sounds_abnormal,
      :resp_nail_bed_color => @old_clinical_note.resp_nail_bed_color,
      :resp_nail_bed_color_abnormal => @old_clinical_note.resp_nail_bed_color_abnormal,
      :cns_temperature => @old_clinical_note.cns_temperature,
      :cns_temperature_abnormal => @old_clinical_note.cns_temperature_abnormal,
      :cns_orientation => @old_clinical_note.cns_orientation,
      :cns_orientation_abnormal => @old_clinical_note.cns_orientation_abnormal,
      :cns_emotinal_status => @old_clinical_note.cns_emotinal_status,
      :cns_emotinal_status_abnormal => @old_clinical_note.cns_emotinal_status_abnormal,
      :cns_memory_intact => @old_clinical_note.cns_memory_intact,
      :cns_memory_intact_abnormal => @old_clinical_note.cns_memory_intact_abnormal,
      :cns_speech_status => @old_clinical_note.cns_speech_status,
      :cns_speech_status_abnormal => @old_clinical_note.cns_speech_status_abnormal,
      :cvs_heart_sounds_status => @old_clinical_note.cvs_heart_sounds_status,
      :cvs_heart_sounds_status_abnormal => @old_clinical_note.cvs_heart_sounds_status_abnormal,
      :cvs_palpable_pulses_intact => @old_clinical_note.cvs_palpable_pulses_intact,
      :cvs_palpable_pulses_intact_abnormal => @old_clinical_note.cvs_palpable_pulses_intact_abnormal,
      :cvs_peripheral_edema => @old_clinical_note.cvs_peripheral_edema,
      :cvs_calf_tenderness => @old_clinical_note.cvs_calf_tenderness,
      :gut_urine_output => @old_clinical_note.gut_urine_output,
      :gut_urine_output_abnormal => @old_clinical_note.gut_urine_output_abnormal,
      :gut_bladder_habits => @old_clinical_note.gut_bladder_habits,
      :gut_bladder_habits_abnormal => @old_clinical_note.gut_bladder_habits_abnormal,
      :git_abdomen => @old_clinical_note.git_abdomen,
      :git_bowel_movements => @old_clinical_note.git_bowel_movements,
      :git_bowel_movements_abnormal => @old_clinical_note.git_bowel_movements_abnormal,
      :ms_extreme_motion => @old_clinical_note.ms_extreme_motion,
      :ms_extreme_motion_abnormal => @old_clinical_note.ms_extreme_motion_abnormal,
      :ms_sensation => @old_clinical_note.ms_sensation,
      :ms_sensation_abnormal => @old_clinical_note.ms_sensation_abnormal,
      :skin_color => @old_clinical_note.skin_color,
      :skin_color_abnormal => @old_clinical_note.skin_color_abnormal,
      :skin_integrity => @old_clinical_note.skin_integrity,
      :skin_integrity_abnormal => @old_clinical_note.skin_integrity_abnormal,
      :history => @old_clinical_note.history,
      :examination => @old_clinical_note.examination,
      :diagnosis => @old_clinical_note.diagnosis,
      :procedurelist => @old_clinical_note.procedurelist,
      :investigations => @old_clinical_note.investigations,
      :investigation => @old_clinical_note.investigation,
      :general_clubbing => @old_clinical_note.general_clubbing,
      :general_edema => @old_clinical_note.general_edema,
      :general_rash => @old_clinical_note.general_rash,
      :general_white_oral_patch => @old_clinical_note.general_white_oral_patch,
      :general_lymphadenopathy => @old_clinical_note.general_lymphadenopathy

    }
  end

  def create_operative_note_params
    {
      :note_date => @old_operative_note.note_date,
      :note_time => @old_operative_note.note_time,
      :note_created_at => (@old_operative_note.note_created_at if @old_operative_note.note_created_at.present?) || @old_operative_note.created_at,
      :organisation_id => @old_operative_note.organisation_id,
      :admission_id => @old_operative_note.admission_id,
      :patient_id => @old_operative_note.patient_id,
      :user_id => @old_operative_note.user_id,
      :department => @old_operative_note.department,
      :specalityname => @old_operative_note.specalityname,
      :specalityid => @old_operative_note.specalityid,
      :ward_id => @old_operative_note.ward_id,
      :room_id => @old_operative_note.room_id,
      :bed_id => @old_operative_note.bed_id,
      :daycare => @old_operative_note.daycare,
      :patient_name => @old_operative_note.patient_name,
      :patient_age => @old_operative_note.patient_age,
      :patient_gender => @old_operative_note.patient_gender,
      :mr_no => @old_operative_note.mr_no,
      :patient_identifier_id => @old_operative_note.patient_identifier_id,
      :correct_patient => @old_operative_note.correct_patient,
      :correct_procedure => @old_operative_note.correct_procedure,
      :before_induction_valid_consent => @old_operative_note.before_induction_valid_consent,
      :site_marked => @old_operative_note.site_marked,
      :anesthesia_machine => @old_operative_note.anesthesia_machine,
      :tourniquet_drills_suction => @old_operative_note.tourniquet_drills_suction,
      :implants_checked => @old_operative_note.implants_checked,
      :patient_allergy => @old_operative_note.patient_allergy,
      :difficult_airway => @old_operative_note.difficult_airway,
      :confirm_team_listed => @old_operative_note.confirm_team_listed,
      :patient_checked => @old_operative_note.patient_checked,
      :valid_consent => @old_operative_note.valid_consent,
      :procedure_checked => @old_operative_note.procedure_checked,
      :site_checked_and_marked => @old_operative_note.site_checked_and_marked,
      :imaging_checked => @old_operative_note.imaging_checked,
      :antibiotic_prophylaxis_given => @old_operative_note.antibiotic_prophylaxis_given,
      :xray_safety_check => @old_operative_note.xray_safety_check,
      :otchecklist_comments => @old_operative_note.otchecklist_comments,
      :irrigation_solution => @old_operative_note.irrigation_solution,
      :irrigation_solution_batch_no => @old_operative_note.irrigation_solution_batch_no,
      :sutures => @old_operative_note.sutures,
      :sutures_batch_no => @old_operative_note.sutures_batch_no,
      :viscoelastic => @old_operative_note.viscoelastic,
      :viscoelastic_batch_no => @old_operative_note.viscoelastic_batch_no,
      :trypan_blue => @old_operative_note.trypan_blue,
      :trypan_blue_batch_no => @old_operative_note.trypan_blue_batch_no,
      :other_consumables => @old_operative_note.other_consumables,
      :implants => @old_operative_note.implants,
      :power_inventory => @old_operative_note.power_inventory,
      :surgeon => @old_operative_note.surgeon,
      :surgeon1 => @old_operative_note.surgeon1,
      :surgeon2 => @old_operative_note.surgeon2,
      :surgeon3 => @old_operative_note.surgeon3,
      :surgeon_assistant => @old_operative_note.surgeon_assistant,
      :surgeon_assistant1 => @old_operative_note.surgeon_assistant1,
      :surgeon_assistant2 => @old_operative_note.surgeon_assistant2,
      :surgeon_assistant3 => @old_operative_note.surgeon_assistant3,
      :anaesthetist => @old_operative_note.anaesthetist,
      :anaesthetist1 => @old_operative_note.anaesthetist1,
      :anaesthetist2 => @old_operative_note.anaesthetist2,
      :anaesthetist3 => @old_operative_note.anaesthetist3,
      :anesthetic_assistant => @old_operative_note.anesthetic_assistant,
      :anesthetic_assistant1 => @old_operative_note.anesthetic_assistant1,
      :anesthetic_assistant2 => @old_operative_note.anesthetic_assistant2,
      :anesthetic_assistant3 => @old_operative_note.anesthetic_assistant3,
      :circulating_nurse => @old_operative_note.circulating_nurse,
      :circulating_nurse1 => @old_operative_note.circulating_nurse1,
      :circulating_nurse2 => @old_operative_note.circulating_nurse2,
      :circulating_nurse3 => @old_operative_note.circulating_nurse3,
      :scrub_nurse => @old_operative_note.scrub_nurse,
      :scrub_nurse1 => @old_operative_note.scrub_nurse1,
      :scrub_nurse2 => @old_operative_note.scrub_nurse2,
      :scrub_nurse3 => @old_operative_note.scrub_nurse3,
      :other_staff => @old_operative_note.other_staff,
      :other_staff1 => @old_operative_note.other_staff1,
      :other_staff2 => @old_operative_note.other_staff2,
      :other_staff3 => @old_operative_note.other_staff3,
      :personnel_comments => @old_operative_note.personnel_comments,
      :surgerytype => @old_operative_note.surgerytype,
      :anesthesia => @old_operative_note.anesthesia,
      :diagnosis => @old_operative_note.diagnosis,
      :procedure_performed => @old_operative_note.procedure_performed,
      :patient_entry_time => @old_operative_note.patient_entry_time,
      :patient_exit_time => @old_operative_note.patient_exit_time,
      :anesthesia_start_time => @old_operative_note.anesthesia_start_time,
      :anesthesia_end_time => @old_operative_note.anesthesia_end_time,
      :surgery_start_time => @old_operative_note.surgery_start_time,
      :surgery_end_time => @old_operative_note.surgery_end_time,
      :complication => @old_operative_note.complication,
      :complication_comment => @old_operative_note.complication_comment,
      :implants_used => @old_operative_note.implants_used,
      :post_op_plan => @old_operative_note.post_op_plan,
      :procedure_note => @old_operative_note.procedure_note,
      :patient_position => @old_operative_note.patient_position,
      :position_aid => @old_operative_note.position_aid,
      :bed_attachments => @old_operative_note.bed_attachments,
      :other_equipments => @old_operative_note.other_equipments,
      :skin_preparation => @old_operative_note.skin_preparation,
      :theatre_diathermy => @old_operative_note.theatre_diathermy,
      :diathermy_type => @old_operative_note.diathermy_type,
      :diathermy_plate_site => @old_operative_note.diathermy_plate_site,
      :diathermy_applier => @old_operative_note.diathermy_applier,
      :theatre_tourniquet => @old_operative_note.theatre_tourniquet,
      :tourniquet_site => @old_operative_note.tourniquet_site,
      :tourniquet_pressure => @old_operative_note.tourniquet_pressure,
      :tourniquet_time => @old_operative_note.tourniquet_time,
      :theatre_biopsy => @old_operative_note.theatre_biopsy,
      :biopsy_type => @old_operative_note.biopsy_type,
      :biopsy_tests => @old_operative_note.biopsy_tests,
      :catheters_insitu => @old_operative_note.catheters_insitu,
      :closure => @old_operative_note.closure,
      :theatre_comments => @old_operative_note.theatre_comments,
      :surgerydate => @old_operative_note.surgerydate,
      :ot_note_inventory_comments => @old_operative_note.ot_note_inventory_comments,
      :device_comment => @old_operative_note.device_comment,
    }
  end

  def create_discharge_note_params
    {
      :note_date => @old_discharge_note.note_date,
      :note_time => @old_discharge_note.note_time,
      :note_created_at => (@old_discharge_note.note_created_at if @old_discharge_note.note_created_at.present?) || @old_discharge_note.created_at,
      :organisation_id => @old_discharge_note.organisation_id,
      :admission_id => @old_discharge_note.admission_id,
      :patient_id => @old_discharge_note.patient_id,
      :user_id => @old_discharge_note.user_id,
      :department => @old_discharge_note.department,
      :specalityname => @old_discharge_note.specalityname,
      :specalityid => @old_discharge_note.specalityid,
      :ward_id => @old_discharge_note.ward_id,
      :room_id => @old_discharge_note.room_id,
      :bed_id => @old_discharge_note.bed_id,
      :daycare => @old_discharge_note.daycare,
      :patient_name => @old_discharge_note.patient_name,
      :patient_age => @old_discharge_note.patient_age,
      :patient_gender => @old_discharge_note.patient_gender,
      :mr_no => @old_discharge_note.mr_no,
      :patient_identifier_id => @old_discharge_note.patient_identifier_id,
      :check_all => @old_discharge_note.check_all,
      :discharge_intimation => @old_discharge_note.discharge_intimation,
      :band_removed => @old_discharge_note.band_removed,
      :intracath_removed => @old_discharge_note.intracath_removed,
      :discharge_summary_given => @old_discharge_note.discharge_summary_given,
      :correct_dose_explained => @old_discharge_note.correct_dose_explained,
      :wound_dressing_needs => @old_discharge_note.wound_dressing_needs,
      :process_of_followup_explained => @old_discharge_note.process_of_followup_explained,
      :pending_reports_given => @old_discharge_note.pending_reports_given,
      :emergency_contact_explained => @old_discharge_note.emergency_contact_explained,
      :admission_date => @old_discharge_note.admission_date,
      :discharge_date => @old_discharge_note.discharge_date,
      :discharge_time => @old_discharge_note.discharge_time,
      :investigation_notes => @old_discharge_note.investigation_notes,
      :treatment_type => @old_discharge_note.treatment_type,
      :treatment_notes => @old_discharge_note.treatment_notes,
      :precautions => @old_discharge_note.precautions,
      :followup_date => @old_discharge_note.followup_date,
      :followup_time => @old_discharge_note.followup_time,
      :followup_doctor_id => @old_discharge_note.followup_doctor_id,
      :followup_facility => @old_discharge_note.followup_facility,
      :appointment_type_id => @old_discharge_note.appointment_type_id,
      :advicemanagementplan => @old_discharge_note.advicemanagementplan,
      :bookappointment => @old_discharge_note.bookappointment,
      :diagnosis => @old_discharge_note.diagnosis,
      :procedure => @old_discharge_note.read_attribute(:procedure),
      :patient_condition => @old_discharge_note.patient_condition
    }
  end

  def create_ward_note_params
    {
      :admission_id => @old_ward_note.admission_id,
      :organisation_id => @old_ward_note.organisation_id,
      :note_created_at => (@old_ward_note.note_created_at if @old_ward_note.note_created_at.present?) || @old_ward_note.created_at,
      :patient_id => @old_ward_note.patient_id,
      :user_id => @old_ward_note.user_id,
      :department => @old_ward_note.department,
      :specalityname => @old_ward_note.specalityname,
      :specalityid => @old_ward_note.specalityid,
      :ward_id => @old_ward_note.ward_id,
      :room_id => @old_ward_note.room_id,
      :bed_id => @old_ward_note.bed_id,
      :daycare => @old_ward_note.daycare,
      :patient_name => @old_ward_note.patient_name,
      :patient_age => @old_ward_note.patient_age,
      :patient_gender => @old_ward_note.patient_gender,
      :mr_no => @old_ward_note.mr_no,
      :patient_identifier_id => @old_ward_note.patient_identifier_id,
      :notetext => @old_ward_note.notetext,
      :anthropometryheight => @old_ward_note.anthropometryheight,
      :anthropometryweight => @old_ward_note.anthropometryweight,
      :anthropometrybmi => @old_ward_note.anthropometrybmi,
      :vitalsignstemperature => @old_ward_note.vitalsignstemperature,
      :vitalsignspulse => @old_ward_note.vitalsignspulse,
      :vitalsignsbp => @old_ward_note.vitalsignsbp,
      :vitalsignsrr => @old_ward_note.vitalsignsrr,
      :vitalsignsspo2 => @old_ward_note.vitalsignsspo2
    }
  end

  def migrate_inventory_data
    @old_operative_note.inventorymedication.each do |medication|
      medication_attributes = medication.attributes
      medication_attributes[:id] = BSON::ObjectId.new
      @operative_note.inventorymedication.create(medication_attributes)
    end

    @old_operative_note.inventoryconsumables.each do |consumables|
      consumables_attributes = consumables.attributes
      consumables_attributes[:id] = BSON::ObjectId.new
      @operative_note.inventoryconsumables.create(consumables_attributes)
    end

    @old_operative_note.inventorypack.each do |pack|
      pack_attributes = pack.attributes
      pack_attributes[:id] = BSON::ObjectId.new
      @operative_note.inventorypack.create(pack_attributes)
    end

    @old_operative_note.inventoryprep.each do |prep|
      prep_attributes = prep.attributes
      prep_attributes[:id] = BSON::ObjectId.new
      @operative_note.inventoryprep.create(prep_attributes)
    end

    @old_operative_note.inventorydressings.each do |dressings|
      dressings_attributes = dressings.attributes
      dressings_attributes[:id] = BSON::ObjectId.new
      @operative_note.inventorydressings.create(dressings_attributes)
    end

    @old_operative_note.inventoryinstrument.each do |instrument|
      instrument_attributes = instrument.attributes
      instrument_attributes[:id] = BSON::ObjectId.new
      @operative_note.inventoryinstrument.create(instrument_attributes)
    end

    @old_operative_note.inventoryimplants.each do |implants|
      implants_attributes = implants.attributes
      implants_attributes[:id] = BSON::ObjectId.new
      @operative_note.inventoryimplants.create(implants_attributes)
    end

    @old_operative_note.inventoryswabs.each do |swabs|
      swabs_attributes = swabs.attributes
      swabs_attributes[:id] = BSON::ObjectId.new
      @operative_note.inventoryswabs.create(swabs_attributes)
    end
  end

  def migrate_medication_data
    @old_discharge_note.treatmentmedication.each do |medication|
      medication_attributes = medication.attributes
      medication_attributes[:id] = BSON::ObjectId.new
      @discharge_note.treatmentmedication.create(medication_attributes)
    end
  end

  def find_ipd_record
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: @admission.id)
  end

  def find_admission_note
    @admission_note = Inpatient::IpdRecord::AdmissionNote.unscoped.find_by(id: @record_id)
  end

  def find_clinical_note
    @old_clinical_note = Inpatient::IpdRecord::ClinicalNote.unscoped.find_by(id: @record_id)
  end

  def find_operative_note
    @old_operative_note = Inpatient::IpdRecord::OperativeNote.unscoped.find_by(id: @record_id)
  end

  def find_discharge_note
    @old_discharge_note = Inpatient::IpdRecord::DischargeNote.unscoped.find_by(id: @record_id)
  end

  def find_ward_note
    @old_ward_note = Inpatient::IpdRecord::WardNote.unscoped.find_by(id: @record_id)
  end

  def time_calculation
    if @operative_note.patient_entry_time.present? && @operative_note.patient_exit_time.present?
      time_total_sec = @operative_note.patient_exit_time - @operative_note.patient_entry_time
      time_in_hours = (((time_total_sec) / 60) / 60).to_i
      time_in_minutes = (((time_total_sec) / 60).to_i) - (time_in_hours * 60)
      time_in_seconds = time_total_sec - ((((time_total_sec) / 60).to_i) * 60)
      time_to_save = time_in_hours.abs.to_s + "h " + time_in_minutes.abs.to_s + "m " + time_in_seconds.round.abs.to_s + "s"
      @operative_note.update_attributes(patient_entry_exit_time: time_to_save)
    end

    if @operative_note.anesthesia_start_time.present? && @operative_note.anesthesia_end_time.present?
      time_total_sec = @operative_note.anesthesia_end_time - @operative_note.anesthesia_start_time
      time_in_hours = (((time_total_sec) / 60) / 60).to_i
      time_in_minutes = (((time_total_sec) / 60).to_i) - (time_in_hours * 60)
      time_in_seconds = time_total_sec - ((((time_total_sec) / 60).to_i) * 60)
      time_to_save = time_in_hours.abs.to_s + "h " + time_in_minutes.abs.to_s + "m " + time_in_seconds.round.abs.to_s + "s"
      @operative_note.update_attributes(anesthesia_start_end_time: time_to_save)
    end

    if @operative_note.surgery_start_time.present? && @operative_note.surgery_end_time.present?
      time_total_sec = @operative_note.surgery_end_time - @operative_note.surgery_start_time
      time_in_hours = (((time_total_sec) / 60) / 60).to_i
      time_in_minutes = (((time_total_sec) / 60).to_i) - (time_in_hours * 60)
      time_in_seconds = time_total_sec - ((((time_total_sec) / 60).to_i) * 60)
      time_to_save = time_in_hours.abs.to_s + "h " + time_in_minutes.abs.to_s + "m " + time_in_seconds.round.abs.to_s + "s"
      @operative_note.update_attributes(surgery_start_end_time: time_to_save)
    end
  end

  # def handle_date_formats(field)
  #   if (@old_clinical_note.send(field).class == String and @old_clinical_note.send(field).size > 0)
  #     return Date.parse(@old_clinical_note.send(field))
  #   elsif (@old_clinical_note.send(field).class == String and @old_clinical_note.send(field).size == 0)
  #     return nil
  #   else
  #     return @old_clinical_note.send(field)
  #   end
  # end
end
