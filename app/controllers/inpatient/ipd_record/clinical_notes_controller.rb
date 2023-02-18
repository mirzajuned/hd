# 7   Metrics/MethodLength
# 4   Metrics/AbcSize
# 1   Metrics/ClassLength
# --
# 12  Total Offenses Pending
class Inpatient::IpdRecord::ClinicalNotesController < ApplicationController
  before_action :authorize
  before_action :clinical_note_form_params, only: [:new, :edit]
  before_action :find_ipd_record, :admission_note, only: [:new, :edit, :print, :show]
  before_action :find_ipd_record_for_write, only: [:create, :update]
  before_action :clinical_note, only: [:show, :edit, :update, :print]
  before_action :print_settings, only: [:show, :create, :update]
  before_action :current_organisations_setting, only: [:new, :create, :show, :edit, :update]

  def new
    @clinical_note = @ipdrecord.build_clinical_note
    @procedure = @ipdrecord.procedure
    @diagnosislist = @ipdrecord.diagnosislist
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)
    @ophthal_investigations = @ipdrecord.ophthal_investigations_list
    @radiology_investigations = @ipdrecord.radiology_investigations_list
    @laboratory_investigations = @ipdrecord.laboratory_investigations_list

    respond_to do |format|
      format.js { render 'inpatient/ipd_record/clinical_note/form' }
    end
  end

  def create
    @clinical_note = @ipdrecord.build_clinical_note
    params_ipd_record = params[:inpatient_ipd_record]
    params_ipd_record[:admission_attributes][:dischargedate] = params_ipd_record[:discharge_date]
    @ipdrecord.update(clinical_note_params)

    @ipdrecord.admission.inc(ipd_templates_count: 1)
    @clinical_note.record_histories.create(user_id: current_user.id, action: 'C',
                                           actiontime: Time.current, template_type: 'Clinical Note')
    clinical_note_view_params

    CaseSheet::CreateIpdRecordService.call(@patient, @ipdrecord, current_user, params[:case_sheet])
    IpdRecords::CreateService.call(@ipdrecord.admission, params[:case_sheet], 'Clinical Note')
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)

    Patients::HistoryService.call(@ipdrecord, current_user, @patient.id.to_s)
    # save_procedures
    # PatientJobs::PatientHistoryJob.perform_later(@patient.id.to_s)
    # procedure_diagnosis
    # Inpatient::Diagnosis.where(ipdrecord_id: @clinical_note.id).try(:destroy)
    # add_diagnosis(@clinical_note)
    respond_to do |format|
      format.js { render 'inpatient/ipd_record/clinical_note/create' }
    end
    Patients::Summary::TimelineWorker.call(event_name: 'IPD_RECORD', sub_event_name: 'CREATED',
                                           ipd_record_id: @ipdrecord.id, user_id: current_user.id,
                                           user_name: current_user.fullname, ipdtemplatetype: 'clinical_note')
    IpdRecordJob.perform_later(@ipdrecord.id.to_s, @clinical_note.id.to_s, 'clinical_note')

    # Diagnosis Report Data Job
    MisJobs::Clinical::ExtractDiagnosesJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@ipdrecord.admission.id.to_s, "IPD", "ipd_record_form")
    # Procedure Data Job
    MisJobs::Clinical::PatientProcedureJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@ipdrecord.admission.case_sheet_id.to_s, @ipdrecord.admission.id.to_s, "admission")
  end

  def show
    clinical_note_view_params
    procedure_diagnosis
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)
    respond_to do |format|
      format.js { render 'inpatient/ipd_record/clinical_note/show' }
    end
  end

  def edit
    @clinical_note = @ipdrecord.clinical_note
    @procedure = @ipdrecord.procedure
    @diagnosislist = @ipdrecord.diagnosislist
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)
    @ophthal_investigations = @ipdrecord.ophthal_investigations_list
    @radiology_investigations = @ipdrecord.radiology_investigations_list
    @laboratory_investigations = @ipdrecord.laboratory_investigations_list

    respond_to do |format|
      format.js { render 'inpatient/ipd_record/clinical_note/form' }
      format.html { render 'inpatient/ipd_record/clinical_note/form' }
    end
  end

  def update
    params_ipd_record = params[:inpatient_ipd_record]
    params_ipd_record[:admission_attributes][:dischargedate] = params_ipd_record[:discharge_date]
    @ipdrecord.personal_history_records.delete_all
    @ipdrecord.speciality_history_records.delete_all
    @ipdrecord.allergy_histories.delete_all

    @ipdrecord.update!(clinical_note_update_params)

    # Patients::HistoryService.call(@ipdrecord, current_user, @patient.id.to_s)
    @clinical_note.record_histories.create(user_id: current_user.id, action: 'U',
                                           actiontime: Time.current, template_type: 'Clinical Note')
    clinical_note_view_params

    Patients::HistoryService.call(@ipdrecord, current_user, @patient.id.to_s)
    # @patient.update_attributes(history_params)
    # PatientJobs::PatientHistoryJob.perform_later(@patient.id.to_s)

    CaseSheet::CreateIpdRecordService.call(@patient, @ipdrecord, current_user, params[:case_sheet])
    IpdRecords::CreateService.call(@ipdrecord.admission, params[:case_sheet], 'Clinical Note')
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)
    respond_to do |format|
      format.js { render 'inpatient/ipd_record/clinical_note/update' }
    end
    Patients::Summary::TimelineWorker.call(event_name: 'IPD_RECORD', sub_event_name: 'UPDATED',
                                           ipd_record_id: @ipdrecord.id, user_id: current_user.id,
                                           user_name: current_user.fullname, ipdtemplatetype: 'clinical_note')
    IpdRecordJob.perform_later(@ipdrecord.id.to_s, @clinical_note.id.to_s, 'clinical_note')

    # Diagnosis Report Data Job
    MisJobs::Clinical::ExtractDiagnosesJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@ipdrecord.admission.id.to_s, "IPD", "ipd_record_form")
    # Procedure Data Job
    MisJobs::Clinical::PatientProcedureJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@ipdrecord.admission.case_sheet_id.to_s, @ipdrecord.admission.id.to_s, "admission")
  end

  def print
    @view = params[:view]
    clinical_note_view_params
    @patient_exit_time = @admission&.dischargetime&.in_time_zone(current_facility.time_zone)

    @diagnosislist = @ipdrecord.diagnosislist
    @procedure = @ipdrecord.procedure
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      print_attributes(format, 'inpatient/ipd_record/clinical_note/print', '', @print_setting)
    end
  end

  private

  def current_organisations_setting
    @organisations_setting = OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id))
  end

  def clinical_note
    if @ipdrecord.present?
      @clinical_note = @ipdrecord.clinical_note
    else
      respond_to do |format|
        format.js do
          render inline: "notice = new PNotify({ title: 'Warning',
                                                 text: 'Record not found: Reloading the page ...',
                                                 type: 'warning' });
                          notice.get().click(function(){ notice.remove() });
                          location.reload();"
        end
      end
    end
  end

  def clinical_note_form_params
    @current_user = current_user
    @current_facility = current_facility
    @admission = Admission.find_by(id: params[:admission_id])
    @tpa = @admission
    @patient = @admission.patient
    @patient_identifier_id = @patient.patient_identifier_id
    @patient_mrn = @patient.patient_mrn
    @age_gender = @patient.patient_age_gender
  end

  def clinical_note_view_params
    @admission = Admission.find_by(id: @ipdrecord.admission_id)
    @patient = Patient.find_by(id: @ipdrecord.patient_id)
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @tpa = @admission
  end

  def procedure_diagnosis
    @procedures = Inpatient::Procedure.where(ipdrecord_id: @clinical_note.try(:id)).order('created_at DESC')
    @procedures_performed = @procedures.where(procedurestatus: 'Performed').order('created_at DESC')
    procedure_status_array = [{ procedurestatus: 'Advised' }, { procedurestatus: 'Pre-Operative' }]
    @procedures_advised = @procedures.where('$or' => procedure_status_array).order('created_at DESC')
    @pre_op_procedures = @procedures.where(procedurestatus: 'Pre-Operative')
    @opd_record_diagnosis = Inpatient::Diagnosis.where(ipdrecord_id: @clinical_note.try(:id)).order('created_at DESC')
  end

  def save_procedures
    @procedure_opd_record = params[:procedure]
    @procedure_opd_record&.each do |procedure|
      @procedure = Inpatient::Procedure.find_by(id: procedure[1]['id'])
      if @procedure.procedurestatus != 'Performed'
        if procedure[1]['status'] == 'Pre-Operative'
          @procedure.update_attributes(procedurestatus: 'Pre-Operative', surgerydate: procedure[1]['surgerydate'])
        elsif procedure[1]['status'] == 'Performed'
          @procedure.update_attributes(procedurestatus: 'Performed', surgerydate: procedure[1]['surgerydate'])
        elsif procedure[1]['status'].nil?
          @procedure.update_attributes(procedurestatus: 'Advised')
        end
      end
    end
    @procedure_ipd_record = params[:procedure_added]
    Inpatient::Procedure.where(ipdrecord_id: @clinical_note.id, :procedurestatus.nin => ['Performed']).destroy
    @procedure_ipd_record&.each do |procedure|
      Inpatient::Procedure.create(procedurename: procedure[1]['name'], procedurestatus: 'Pre-Operative',
                                  procedureid: procedure[1]['id'], procedureside: procedure[1]['side'],
                                  facility_id: @clinical_note.facility_id, ipdrecord_id: @clinical_note.id,
                                  ipdtemplatetype: @clinical_note.template_type, patient_id: @clinical_note.patient_id)
    end
  end

  def clinical_note_params
    params.require(:inpatient_ipd_record).permit!
    # params.require(:inpatient_ipd_record).permit(
    #   :expected_management, :expected_stay, :complaint_date, :discharge_date, :payment_type, :medico_legal_case,
    #   :medico_legal_details, :selected_opdrecord_id, :investigations,
    #   admission_attributes: [:admissionreason, :dischargedate], diagnosislist_attributes: diagnosis_attributes,
    #   procedure_attributes: procedure_attributes, clinical_note_attributes: clinical_note_attributes
    # )
  end

  def clinical_note_update_params
    params.require(:inpatient_ipd_record).permit!
    # params.require(:inpatient_ipd_record).permit(
    #   :admissionreason, :expected_management, :expected_stay, :complaint_date, :discharge_date, :ipd_payment_type,
    #   :medico_legal_case, :medico_legal_details, :selected_opdrecord_id, :investigations, :admin_comments,
    #   admission_attributes: [:admissionreason, :dischargedate], diagnosislist_attributes: diagnosis_update_attributes,
    #   procedure_attributes: procedure_update_attributes, clinical_note_attributes: clinical_note_update_attributes
    # )
  end

  def patientpersonalhistory_attributes
    [:id, :no_opthalmic_history_advised, :opthal_history_comment, :glaucoma, :glaucoma_duration, :glaucoma_duration_unit,
    :retinal_detachment, :retinal_detachment_duration, :retinal_detachment_duration_unit, :glasses, :glasses_duration,
    :glasses_duration_unit, :eye_disease, :eye_disease_duration, :eye_disease_duration_unit, :eye_surgery,
    :eye_surgery_duration, :eye_surgery_duration_unit, :uveitis, :uveitis_duration, :uveitis_duration_unit,
    :retinal_laser, :retinal_laser_duration, :retinal_laser_duration_unit, :history_comment, :diabetes,
    :no_systemic_history_advised, :diabetes_duration, :diabetes_duration_unit, :hypertension, :hypertension_duration,
    :hypertension_duration_unit, :alcoholism, :alcoholism_duration, :alcoholism_duration_unit, :smoking_tobacco,
    :smoking_tobacco_duration, :smoking_tobacco_duration_unit, :steroid_intake, :steroid_intake_duration,
    :steroid_intake_duration_unit, :drug_abuse, :drug_abuse_duration, :drug_abuse_duration_unit, :hiv_aids, :hiv_aids_duration,
    :hiv_aids_duration_unit, :cancer_tumor, :cancer_tumor_duration, :cancer_tumor_duration_unit, :cardiac_disorder,
    :cardiac_disorder_duration, :cardiac_disorder_duration_unit, :rheumatoid_arthritis,
    :rheumatoid_arthritis_duration, :rheumatoid_arthritis_duration_unit, :tuberculosis, :tuberculosis_duration,
    :tuberculosis_duration_unit, :asthma, :asthma_duration, :asthma_duration_unit, :cns_disorder_stroke,
    :cns_disorder_stroke_duration, :cns_disorder_stroke_duration_unit, :hypothyroidism, :hypothyroidism_duration,
    :hypothyroidism_duration_unit, :hyperthyroidism, :hyperthyroidism_duration, :hyperthyroidism_duration_unit,
    :hepatitis_cirrhosis, :hepatitis_cirrhosis_duration, :hepatitis_cirrhosis_duration_unit, :renal_disorder,
    :renal_disorder_duration, :renal_disorder_duration_unit, :acidity, :acidity_duration, :acidity_duration_unit,
    :on_insulin, :on_insulin_duration, :on_insulin_duration_unit, :consanguinity, :consanguinity_duration,
    :consanguinity_duration_unit, :on_aspirin_blood_thinners, :on_aspirin_blood_thinners_duration,
    :on_aspirin_blood_thinners_duration_unit, :medical_history_comment, :family_history_comment]
  end

  def patientallergyhistory_attributes
    [:id, :others, :no_allergy_advised, :drug_allergies_comment, :contact_allergies_comment, :food_allergies_comment, antimicrobialagents: [], antifungalagents: [], antiviralagents: [], nsaids: [],
    eyedrops: [], contact: [], food: []]
  end

  def clinical_note_attributes
    [:note_date, :note_time, :note_created_at, :organisation_id, :admission_id, :patient_id, :user_id, :department,
     :specalityid, :specalityname, :ward_id, :room_id, :bed_id, :daycare, :patient_name, :patient_age, :patient_gender,
     :mr_no, :patient_identifier_id, :first_opd_visit, :ipd_billing_category, :admin_comments, :r_hpi, :r_refraction,
     :l_refraction, :r_iop, :l_iop, :r_appendages, :l_appendages, :r_anterior, :l_anterior, :r_posterior, :l_posterior,
     :r_eom, :l_eom, :airway_assesment, :airway_assesment_abnormal, :breathing_assesment, :breathing_assesment_abnormal,
     :pulse_assesment, :pulse_assesment_abnormal, :bp_assesment, :bp_assesment_abnormal, :pressure_ulcer_risk,
     :risk_of_fall, :vte_risk, :general_pallor, :general_clubbing, :general_edema, :general_rash,
     :general_white_oral_patch, :general_lymphadenopathy, :general_icterus, :general_cyanosis, :resp_air_entry,
     :resp_breath_sounds, :resp_breath_sounds_abnormal, :resp_nail_bed_color, :resp_nail_bed_color_abnormal,
     :cns_temperature, :cns_temperature_abnormal, :cns_orientation, :cns_orientation_abnormal, :cns_emotinal_status,
     :cns_emotinal_status_abnormal, :cns_memory_intact, :cns_memory_intact_abnormal, :cns_speech_status,
     :cns_speech_status_abnormal, :cvs_heart_sounds_status, :cvs_heart_sounds_status_abnormal,
     :cvs_palpable_pulses_intact, :cvs_palpable_pulses_intact_abnormal, :cvs_peripheral_edema, :cvs_calf_tenderness,
     :gut_urine_output, :gut_urine_output_abnormal, :gut_bladder_habits, :gut_bladder_habits_abnormal, :git_abdomen,
     :git_bowel_movements, :git_bowel_movements_abnormal, :ms_extreme_motion, :ms_extreme_motion_abnormal,
     :ms_sensation, :ms_sensation_abnormal, :skin_color, :skin_color_abnormal, :skin_integrity,
     :skin_integrity_abnormal, :history, :examination, :diagnosis, :procedurelist, :investigation,
     :radiology_investigation, :laboratory_investigation]
  end

  def clinical_note_update_attributes
    [:id, :note_date, :note_time, :note_created_at, :organisation_id, :admission_id, :patient_id, :user_id, :department,
     :specalityid, :specalityname, :ward_id, :room_id, :bed_id, :daycare, :patient_name, :patient_age, :patient_gender,
     :mr_no, :patient_identifier_id, :first_opd_visit, :ipd_billing_category, :admin_comments, :r_hpi, :r_refraction,
     :l_refraction, :r_iop, :l_iop, :r_appendages, :l_appendages, :r_anterior, :l_anterior, :r_posterior, :l_posterior,
     :r_eom, :l_eom, :airway_assesment, :airway_assesment_abnormal, :breathing_assesment, :breathing_assesment_abnormal,
     :pulse_assesment, :pulse_assesment_abnormal, :bp_assesment, :bp_assesment_abnormal, :pressure_ulcer_risk,
     :risk_of_fall, :vte_risk, :general_pallor, :general_clubbing, :general_edema, :general_rash,
     :general_white_oral_patch, :general_lymphadenopathy, :general_icterus, :general_cyanosis, :resp_air_entry,
     :resp_breath_sounds, :resp_breath_sounds_abnormal, :resp_nail_bed_color, :resp_nail_bed_color_abnormal,
     :cns_temperature, :cns_temperature_abnormal, :cns_orientation, :cns_orientation_abnormal, :cns_emotinal_status,
     :cns_emotinal_status_abnormal, :cns_memory_intact, :cns_memory_intact_abnormal, :cns_speech_status,
     :cns_speech_status_abnormal, :cvs_heart_sounds_status, :cvs_heart_sounds_status_abnormal,
     :cvs_palpable_pulses_intact, :cvs_palpable_pulses_intact_abnormal, :cvs_peripheral_edema, :cvs_calf_tenderness,
     :gut_urine_output, :gut_urine_output_abnormal, :gut_bladder_habits, :gut_bladder_habits_abnormal, :git_abdomen,
     :git_bowel_movements, :git_bowel_movements_abnormal, :ms_extreme_motion, :ms_extreme_motion_abnormal,
     :ms_sensation, :ms_sensation_abnormal, :skin_color, :skin_color_abnormal, :skin_integrity,
     :skin_integrity_abnormal, :history, :examination, :diagnosis, :procedurelist, :investigation,
     :radiology_investigation, :laboratory_investigation]
  end

  def diagnosis_attributes
    [:diagnosisname, :diagnosisoriginalname, :icddiagnosiscode, :saperatedicddiagnosiscode, :icddiagnosiscodelength,
     :entered_by, :entered_by_id, :advised_by, :advised_by_id, :advised_at_facility, :advised_at_facility_id,
     :advised_datetime, :updated_by, :updated_by_id, :diagnosis_comment, :users_comment, :entry_datetime,
     :updated_datetime, :entered_at_facility, :entered_at_facility_id, :updated_at_facility, :updated_at_facility_id,
     :icd_type, :created_from, :_destroy]
  end

  def diagnosis_update_attributes
    [:id, :diagnosisname, :diagnosisoriginalname, :icddiagnosiscode, :saperatedicddiagnosiscode,
     :icddiagnosiscodelength, :entered_by, :entered_by_id, :updated_by, :updated_by_id, :diagnosis_comment,
     :users_comment, :entry_datetime, :updated_datetime, :entered_at_facility, :entered_at_facility_id, :advised_by,
     :advised_by_id, :advised_at_facility, :advised_at_facility_id, :advised_datetime, :updated_at_facility,
     :updated_at_facility_id, :icd_type, :created_from, :_destroy]
  end

  def procedure_attributes
    [:procedurestage, :procedurename, :procedure_id, :procedure_performed, :procedureside, :procedurefullcode,
     :entered_by, :entered_by_id, :entered_at_facility, :entered_at_facility_id, :advised_by, :advised_by_id,
     :advised_at_facility, :advised_at_facility_id, :advised_datetime, :procedure_comment, :users_comment,
     :entered_datetime, :updated_datetime, :updated_by, :updated_by_id, :updated_at_facility, :updated_at_facility_id,
     :procedure_type, :performed_by, :performed_by_id, :performed_at_facility, :performed_at_facility_id,
     :performed_datetime, :_destroy]
  end

  def procedure_update_attributes
    [:id, :procedurestage, :procedurename, :procedure_id, :procedure_performed, :procedureside, :procedurefullcode,
     :entered_by, :entered_by_id, :entered_at_facility, :entered_at_facility_id, :advised_by, :advised_by_id,
     :advised_at_facility, :advised_at_facility_id, :advised_datetime, :procedure_comment, :users_comment,
     :entered_datetime, :updated_datetime, :updated_by, :updated_by_id, :updated_at_facility, :updated_at_facility_id,
     :procedure_type, :performed_by, :performed_by_id, :performed_at_facility, :performed_at_facility_id,
     :performed_datetime, :_destroy]
  end

  def admission_note
    if @ipdrecord.present?
      @admission_note = @ipdrecord.admission_note
    else
      respond_to do |format|
        format.js do
          render inline: "notice = new PNotify({ title: 'Warning',
                                                 text: 'Record not found: Reloading the page ...',
                                                 type: 'warning' });
                          notice.get().click(function(){ notice.remove() });
                          location.reload();"
        end
      end
    end
  end

  def history_params
    # params.require(:patient).permit(
    #   :specialstatus,
    #   patient_history_attributes: [
    #     :id, patientpersonalhistory_attributes: patientpersonalhistory_attributes,
    #          patientallergyhistory_attributes: patientallergyhistory_attributes
    #   ]
    # )
  end

  def add_diagnosis(ipdrecord)
    if params[:opdrecord]
      diagnosis_attributes = params[:opdrecord][:diagnosislist_attributes]
      diagnosis_attributes&.values&.each do |dia_attr|
        old_diagnosis = Inpatient::Diagnosis.find_by(id: dia_attr['id'], ipdrecord_id: ipdrecord.id)
        if old_diagnosis
          old_diagnosis.update(ipdrecord_id: ipdrecord.id,
                               ipdtemplatetype: ipdrecord.template_type,
                               patient_id: @patient.id.to_s)
        else
          dia_attr[:ipdrecord_id] = ipdrecord.id
          dia_attr[:ipdtemplatetype] = ipdrecord.template_type
          dia_attr.delete('id')
          unlocked_params = ActiveSupport::HashWithIndifferentAccess.new(dia_attr)
          diagnosis = Inpatient::Diagnosis.create(unlocked_params)
          diagnosis.update(patient_id: @patient.id.to_s)
        end
      end
    end
    diagnosis_attributes_two = params[:diagnosislist_attributes]
    diagnosis_attributes_two&.values&.each do |dia|
      old_diagnosis = Inpatient::Diagnosis.find_by(id: dia['id'], ipdrecord_id: ipdrecord.id)
      if old_diagnosis
        old_diagnosis.update(ipdrecord_id: ipdrecord.id,
                             ipdtemplatetype: ipdrecord.template_type,
                             patient_id: @patient.id.to_s)
      else
        dia[:ipdrecord_id] = ipdrecord.id
        dia[:ipdtemplatetype] = ipdrecord.template_type
        dia.delete('id')
        punlocked_params = ActiveSupport::HashWithIndifferentAccess.new(dia)
        diagnosis2 = Inpatient::Diagnosis.create(punlocked_params)
        diagnosis2.update(patient_id: @patient.id.to_s)
      end
    end
  end

  def find_ipd_record
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
    if @ipdrecord.present?
    else
      respond_to do |format|
        format.js do
          render inline: "notice = new PNotify({ title: 'Warning',
                                                 text: 'Record not found: Reloading the page ...',
                                                 type: 'warning' });
                          notice.get().click(function(){ notice.remove() });
                          location.reload();"
        end
      end
    end
  end

  def find_ipd_record_for_write
    admission_id = params[:inpatient_ipd_record][:clinical_note_attributes][:admission_id]
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: admission_id)
    if @ipdrecord.present?
    else
      respond_to do |format|
        format.js do
          render inline: "notice = new PNotify({ title: 'Warning',
                                                 text: 'Record not found: Reloading the page ...',
                                                 type: 'warning' });
                          notice.get().click(function(){ notice.remove() });
                          location.reload();"
        end
      end
    end
  end

  def print_settings
    organisation_id = current_user.organisation_id.to_s
    facility_id = current_facility.id.to_s
    @print_settings = PrintSetting.print_options(organisation_id, facility_id, ['486546481'])
  end
end
