# 4   Metrics/LineLength
# 3   Metrics/AbcSize
# 3   Metrics/CyclomaticComplexity
# 3   Metrics/MethodLength
# 2   Metrics/PerceivedComplexity
# 1   Metrics/ClassLength
# 1   Style/GuardClause
# --
# 17  Total Offenses Pending
class Inpatient::IpdRecord::OperativeNotesController < ApplicationController
  before_action :authorize
  before_action :find_ipd_record, only: [:new, :edit, :print, :show]
  before_action :find_ipd_record_for_write, only: [:create, :update]
  before_action :operative_note_form_params, only: [:new, :edit]
  before_action :operative_note, only: [:show, :edit, :print]
  before_action :operative_note_for_write, only: [:create, :update]
  before_action :procedure_form_data, only: [:new, :edit]
  before_action :clinical_note_data, only: [:new, :edit, :create, :update, :show, :print]
  before_action :print_settings, only: [:show, :create, :update]

  def new
    @operative_note = @ipdrecord.operative_notes.new
    @operative_note_counter = @ipdrecord.operative_notes.size
    @diagnosislist = @ipdrecord.diagnosislist
    # @inventorymedication = @operative_note.inventorymedication.new
    @advice = @operative_note.build_advice
    @theatre = OtRoom.where(facility_id: current_facility.id, is_deleted: false).pluck(:name)
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)
    @bill_of_materials = Inpatient::BillOfMaterial.where(admission_id: params[:admission_id],
                                                         patient_id: @ipdrecord.patient_id,
                                                         used_in_operative_note: false, is_canceled: false)
    @final_bom = @bill_of_materials.pluck(:id, :transaction_date, :transaction_time)
    @url = "/inpatient/ipd_record/operative_note/#{@speciality_folder_name}_notes"
    @method = 'POST'

    respond_to do |format|
      format.js { render 'inpatient/ipd_record/operative_note/form' }
    end
  end

  def create
    if params[:ipd_record] && params[:ipd_record][:procedure].present? && (params[:ipd_record][:procedure].to_unsafe_h.map { |_k, v| v[:is_performed] }.uniq == ['false'] || params[:ipd_record][:procedure].to_unsafe_h.map { |_k, v| v[:performed_by] if v[:is_performed] == 'true' }.include?(''))
      procedure_hash = params[:ipd_record][:procedure].to_unsafe_h
      if procedure_hash.map { |_k, v| v[:is_performed] }.uniq == ['false']
        message_text = 'Cannot create operative note without performed procedure'
      elsif procedure_hash.map { |_k, v| v[:performed_by] if v[:is_performed] == 'true' }.include?('')
        message_text = 'Please Select Doctor for performed Procedure'
      end
      js_notify = "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() }
                   notice = new PNotify({ title: 'Warning',
                                          text: '#{message_text}',
                                          type: 'warning' });
                   notice.get().click(function(){ notice.remove() });
                   $('.surgery-step').trigger('click');"
      respond_to do |format|
        format.js { render js: js_notify }
      end
    else
      @ipdrecord.update!(operative_note_params)

      @ipdrecord.admission.inc(ipd_templates_count: 1)
      # flash[:error] = @ipdrecord.errors.full_messages.to_sentence
      @operative_note = @ipdrecord.operative_notes[-1]
      @operative_note.record_histories.create(user_id: current_user.id, action: 'C',
                                              actiontime: Time.current, template_type: 'Operative Note')
      update_operative_note_id_in_procedure
      update_operative_note_id_in_complications
      time_calculation
      operative_note_view_params

      future_stages = ['pre_discharge', 'post_discharge']
      if future_stages.exclude?(@admission.admission_stage) && @ots.pluck(:operation_done).include?(true)
        @admission.update_attributes(admission_stage: 'post_operative')
      end

      # IpdRecord
      IpdRecords::UpdateService.call(@ipdrecord, @operative_note, params[:ipd_record]) if params[:ipd_record].present?
      IpdRecords::BillOfMaterialService.call(@ipdrecord, @operative_note, params[:ipd_record]) if params[:ipd_record].present?
      # Create/update complications in case-sheet
      IpdRecords::ComplicationService.call(@ipdrecord, @operative_note, params[:inpatient_ipd_record]) if params[:inpatient_ipd_record].present?
      @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)

      @bom_items = @ipdrecord.bill_of_material.where(operative_note_id: @operative_note.id, is_print: true)

      # save_procedures
      respond_to do |format|
        format.js { render 'inpatient/ipd_record/operative_note/create' }
      end
      Patients::Summary::TimelineWorker.call(event_name: 'IPD_RECORD', sub_event_name: 'CREATED',
                                             ipd_record_id: @ipdrecord.id, user_id: current_user.id,
                                             user_name: current_user.fullname, ipdtemplatetype: 'Operative Note',
                                             note_id: @operative_note.id)
      IpdRecordJob.perform_later(@ipdrecord.id.to_s, @operative_note.id.to_s, 'operative_note')

      # Procedure Data Job
      MisJobs::Clinical::PatientProcedureJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@ipdrecord.admission.case_sheet_id.to_s, @ipdrecord.admission.id.to_s, "admission")
    end
    if params[:ipd_record].present? && params[:ipd_record][:procedure].present?
      order_ids_performed = params[:ipd_record][:procedure].to_unsafe_h.map { |_k, v| v[:order_advised_id] if v[:is_performed] == 'true' }
      OrderJobs::PerformedJob.perform_later(order_ids_performed, true)
    end
  end

  def show
    operative_note_view_params
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)

    respond_to do |format|
      format.js { render 'inpatient/ipd_record/operative_note/show' }
    end
  end

  def edit
    @url = "/inpatient/ipd_record/operative_note/#{@speciality_folder_name}_notes/#{@ipdrecord.id}"
    @method = 'PATCH'
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)
    @theatre = OtRoom.where(facility_id: current_facility.id, is_deleted: false).pluck(:name)
    @bill_of_materials = Inpatient::BillOfMaterial.where(admission_id: params[:admission_id],
                                                         patient_id: @ipdrecord.patient_id,
                                                         used_in_operative_note: false, is_canceled: false)
    @selected_bom = @ipdrecord.bill_of_material.where(operative_note_id: @operative_note.id)
    if @selected_bom.present?
      bom = Inpatient::BillOfMaterial.where(id: @selected_bom[0].bom_id).pluck(:id, :transaction_date, :transaction_time)
      @final_bom = @bill_of_materials.pluck(:id, :transaction_date, :transaction_time) + bom
    else
      @final_bom = @bill_of_materials.pluck(:id, :transaction_date, :transaction_time)
    end

    # @bom_ids = @ipdrecord.operative_notes.pluck(:bill_of_material_id)
    respond_to do |format|
      format.js { render 'inpatient/ipd_record/operative_note/form' }
    end
  end

  def update
    if params[:ipd_record] && params[:ipd_record][:procedure].present? && (params[:ipd_record][:procedure].to_unsafe_h.map { |_k, v| v[:is_performed] }.uniq == ['false'] || params[:ipd_record][:procedure].to_unsafe_h.map { |_k, v| v[:performed_by] if v[:is_performed] == 'true' }.include?(''))
      procedure_hash = params[:ipd_record][:procedure].to_unsafe_h
      if procedure_hash.map { |_k, v| v[:is_performed] }.uniq == ['false']
        message_text = 'Cannot create operative note without performed procedure'
      elsif procedure_hash.map { |_k, v| v[:performed_by] if v[:is_performed] == 'true' }.include?('')
        message_text = 'Please Select Doctor for performed Procedure'
      end
      js_notify = "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() }
                   notice = new PNotify({ title: 'Warning',
                                          text: '#{message_text}',
                                          type: 'warning' });
                   notice.get().click(function(){ notice.remove() });
                   $('.surgery-step').trigger('click');"
      respond_to do |format|
        format.js { render js: js_notify }
      end
    else
      delete_inventory_data if @specialty_id == '309989009'

      @ipdrecord.update_attributes!(operative_note_update_params) # rescue nil

      @operative_note.record_histories.create(user_id: current_user.id, action: 'U',
                                              actiontime: Time.current, template_type: 'Operative Note')
      update_operative_note_id_in_procedure
      time_calculation
      operative_note_view_params
      if @operative_note.advice.advice_set_id.present? && @operative_note.advice.advice_set_id.length > 2
        @find_advice_set = AdviceSet.find_by(id: @operative_note.advice.advice_set_id)
        @advice_set_language = if @find_advice_set.present?
                                 AdviceSet.find_by(id: @operative_note.advice.advice_set_id)
                                          .language_advice_subset.pluck(:language, :lcid_code)
                               else
                                 [['']]
                               end
      else
        @advice_set_language = [['English', 'en'], ['Hindi', 'hi'], ['Bengali', 'bn'], ['Kannada', 'kn'],
                                ['Tamil', 'ta'], ['Telugu', 'te'], ['Gujarati', 'gu']]
      end

      IpdRecords::UpdateService.call(@ipdrecord, @operative_note, params[:ipd_record]) if params[:ipd_record].present?
      IpdRecords::BillOfMaterialService.call(@ipdrecord, @operative_note, params[:ipd_record]) if params[:ipd_record].present?
      @bom_items = @ipdrecord.bill_of_material.where(operative_note_id: @operative_note.id, is_print: true)
      # Create/update complications in case-sheet
      IpdRecords::ComplicationService.call(@ipdrecord, @operative_note, params[:inpatient_ipd_record]) if params[:inpatient_ipd_record].present?
      @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)
      # save_procedures
      respond_to do |format|
        format.js { render 'inpatient/ipd_record/operative_note/update' }
      end

      Patients::Summary::TimelineWorker.call(event_name: 'IPD_RECORD', sub_event_name: 'UPDATED',
                                             ipd_record_id: @ipdrecord.id, user_id: current_user.id,
                                             user_name: current_user.fullname, ipdtemplatetype: 'Operative Note', note_id: @operative_note.id)
      IpdRecordJob.perform_later(@ipdrecord.id.to_s, @operative_note.id.to_s, 'operative_note')
      # Procedure Data Job
      MisJobs::Clinical::PatientProcedureJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@ipdrecord.admission.case_sheet_id.to_s, @ipdrecord.admission.id.to_s, "admission")
      if params[:ipd_record].present?
        order_ids_performed = params[:ipd_record][:procedure].to_unsafe_h.map { |_k, v| v[:order_advised_id] if v[:is_performed] == 'true' }
        order_ids_to_advised = params[:ipd_record][:procedure].to_unsafe_h.map { |_k, v| v[:order_advised_id] if v[:is_performed] == 'false' }
        OrderJobs::PerformedJob.perform_later(order_ids_performed, true)
        OrderJobs::PerformedJob.perform_later(order_ids_to_advised, false)
      end
    end
  end

  def print
    @language_flag = params[:language_flag]
    @advice_language = params[:advice_language]
    @view = params[:view]
    @bom_items = @ipdrecord.bill_of_material.where(operative_note_id: @operative_note.id, is_print: true)
    @patient = Patient.find(@ipdrecord.patient_id)
    @admission = Admission.find(@ipdrecord.admission_id)
    @patient_exit_time = @admission&.dischargetime&.in_time_zone(current_facility.time_zone)
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)
    @tpa = @admission
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      print_attributes(format, 'inpatient/ipd_record/operative_note/print', '', @print_setting)
    end
  end

  private

  def operative_note_form_params
    @current_user = current_user
    @current_facility = current_facility
    @admission = Admission.find_by(id: params[:admission_id])
    @tpa = @admission
    @patient = @admission.patient
    @patient_identifier_id = @patient.patient_identifier_id
    @patient_mrn = @patient.patient_mrn
    @age_gender = @patient.patient_age_gender
  end

  def operative_note_view_params
    @admission = Admission.find_by(id: @ipdrecord.admission_id)
    @ots = OtSchedule.where(admission_id: @admission.id)
    @patient = Patient.find_by(id: @ipdrecord.patient_id)
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @tpa = @admission
    if @operative_note.present? && @operative_note.advice.advice_set_id.present? && @operative_note.advice.advice_set_id.length > 2
      @advice_set_language = AdviceSet.find_by(id: @operative_note.advice.advice_set_id).language_advice_subset
                                      .pluck(:language, :lcid_code)
    else
      @advice_set_language = [['English', 'en'], ['Hindi', 'hi'], ['Bengali', 'bn'], ['Kannada', 'kn'],
                              ['Tamil', 'ta'], ['Telugu', 'te'], ['Gujarati', 'gu']]
    end
  end

  def operative_note_params
    params.require(:inpatient_ipd_record).permit(operative_notes_attributes: [:note_date, :note_time, :note_created_at, :organisation_id, :admission_id, :patient_id, :user_id, :department, :specalityname, :specalityid, :ward_id, :room_id, :bed_id, :daycare, :patient_name, :patient_age, :patient_gender, :mr_no, :patient_identifier_id, :correct_patient, :correct_procedure, :before_induction_valid_consent, :site_marked, :anesthesia_machine, :tourniquet_drills_suction, :implants_checked, :patient_allergy, :difficult_airway, :confirm_team_listed, :patient_checked, :valid_consent, :procedure_checked, :site_checked_and_marked, :imaging_checked, :antibiotic_prophylaxis_given, :xray_safety_check, :otchecklist_comments, :irrigation_solution, :irrigation_solution_batch_no, :sutures, :sutures_batch_no, :viscoelastic, :viscoelastic_batch_no, :trypan_blue, :trypan_blue_batch_no, :other_consumables, :implants, :power_inventory, :surgeon, :surgeon1, :surgeon2, :surgeon3, :surgeon_assistant, :surgeon_assistant1, :surgeon_assistant2, :surgeon_assistant3, :anaesthetist, :anaesthetist1, :anaesthetist2, :anaesthetist3, :anesthetic_assistant, :anesthetic_assistant1, :anesthetic_assistant2, :anesthetic_assistant3, :circulating_nurse, :circulating_nurse1, :circulating_nurse2, :circulating_nurse3, :scrub_nurse, :scrub_nurse1, :scrub_nurse2, :scrub_nurse3, :other_staff, :other_staff1, :other_staff2, :other_staff3, :personnel_comments, :surgerytype, :anesthesia, :diagnosis, :procedure_performed, :patient_entry_time, :patient_exit_time, :anesthesia_start_time, :anesthesia_end_time, :surgery_start_time, :surgery_end_time, :complication, :complication_comment, :complication_add_by, :complication_update_by, :implants_used, :post_op_plan, :procedure_note, :patient_position, :position_aid, :bed_attachments, :other_equipments, :skin_preparation, :theatre_diathermy, :diathermy_type, :diathermy_plate_site, :diathermy_applier, :theatre_tourniquet, :tourniquet_site, :tourniquet_pressure, :tourniquet_time, :theatre_biopsy, :biopsy_type, :biopsy_tests, :catheters_insitu, :closure, :theatre_comments, :iol, :ot_note_inventory_comments, :theatre_name, :theatre_section, :case_no, :site, :capsulotomy, :iridectomy, :surgerydate, :device_comment, :bill_of_material_id, ot_note_procedures: [], devices: [], inventorymedication_attributes: inventory_create_attributes, inventoryconsumables_attributes: inventory_create_attributes, inventorypack_attributes: inventory_create_attributes, inventoryprep_attributes: inventory_create_attributes, inventorydressings_attributes: inventory_create_attributes, inventoryinstrument_attributes: inventory_create_attributes, inventoryimplants_attributes: inventory_create_attributes, inventoryswabs_attributes: inventory_create_attributes, advice_attributes: [:advice_content, :advice_set_id]], procedure_attributes: procedure_allowed_attributes, complications_attributes: complications_attributes)
  end

  def operative_note_update_params
    if params[:inpatient_ipd_record][:operative_notes_attributes]["0"][:devices].blank?
      params[:inpatient_ipd_record][:operative_notes_attributes]["0"][:devices] = []
    end
    if params[:inpatient_ipd_record][:operative_notes_attributes]["0"][:intracameral_medicines].blank?
      params[:inpatient_ipd_record][:operative_notes_attributes]["0"][:intracameral_medicines] = []
    end
    params.require(:inpatient_ipd_record).permit(operative_notes_attributes: [:id, :note_date, :note_time, :note_created_at, :organisation_id, :admission_id, :patient_id, :user_id, :department, :specalityname, :specalityid, :ward_id, :room_id, :bed_id, :daycare, :patient_name, :patient_age, :patient_gender, :mr_no, :patient_identifier_id, :correct_patient, :correct_procedure, :before_induction_valid_consent, :site_marked, :anesthesia_machine, :tourniquet_drills_suction, :implants_checked, :patient_allergy, :difficult_airway, :confirm_team_listed, :patient_checked, :valid_consent, :procedure_checked, :site_checked_and_marked, :imaging_checked, :antibiotic_prophylaxis_given, :xray_safety_check, :otchecklist_comments, :irrigation_solution, :irrigation_solution_batch_no, :sutures, :sutures_batch_no, :viscoelastic, :viscoelastic_batch_no, :trypan_blue, :trypan_blue_batch_no, :other_consumables, :implants, :power_inventory, :surgeon, :surgeon1, :surgeon2, :surgeon3, :surgeon_assistant, :surgeon_assistant1, :surgeon_assistant2, :surgeon_assistant3, :anaesthetist, :anaesthetist1, :anaesthetist2, :anaesthetist3, :anesthetic_assistant, :anesthetic_assistant1, :anesthetic_assistant2, :anesthetic_assistant3, :circulating_nurse, :circulating_nurse1, :circulating_nurse2, :circulating_nurse3, :scrub_nurse, :scrub_nurse1, :scrub_nurse2, :scrub_nurse3, :other_staff, :other_staff1, :other_staff2, :other_staff3, :personnel_comments, :surgerytype, :anesthesia, :diagnosis, :procedure_performed, :patient_entry_time, :patient_exit_time, :anesthesia_start_time, :anesthesia_end_time, :surgery_start_time, :surgery_end_time, :complication, :complication_comment, :complication_add_by, :complication_update_by, :implants_used, :post_op_plan, :procedure_note, :patient_position, :position_aid, :bed_attachments, :other_equipments, :skin_preparation, :theatre_diathermy, :diathermy_type, :diathermy_plate_site, :diathermy_applier, :theatre_tourniquet, :tourniquet_site, :tourniquet_pressure, :tourniquet_time, :theatre_biopsy, :biopsy_type, :biopsy_tests, :catheters_insitu, :closure, :theatre_comments, :iol, :surgerydate, :theatre_name, :theatre_section, :case_no, :site, :capsulotomy, :iridectomy, :ot_note_inventory_comments, :device_comment, :bill_of_material_id, ot_note_procedures: [], devices: [], inventorymedication_attributes: inventory_create_attributes, inventoryconsumables_attributes: inventory_create_attributes, inventorypack_attributes: inventory_create_attributes, inventoryprep_attributes: inventory_create_attributes, inventorydressings_attributes: inventory_create_attributes, inventoryinstrument_attributes: inventory_create_attributes, inventoryimplants_attributes: inventory_create_attributes, inventoryswabs_attributes: inventory_create_attributes, advice_attributes: [:id, :advice_content, :advice_set_id]], procedure_attributes: procedure_allowed_attributes, complications_attributes: complications_attributes)
  end

  def complications_params
    params.require(:ipd_record).permit(complications: [:id, :procedure_code, :procedure_id, :entered_by, :entered_by_id, :entered_at_facility, :entered_at_facility_id, :comment, :entered_datetime, :updated_datetime, :updated_by, :updated_by_id, :updated_at_facility, :updated_at_facility_id, :operative_note_id, :complication_name, :complication_original_side, :code, :ipd_record_id, :_destroy])
  end

  def inventory_create_attributes
    [:name, :quantity, :used, :remaining]
  end

  def procedure_attributes
    params.require(:inpatient_ipd_record).permit(procedure_attributes: [:_id, :procedurename, :procedurestage, :procedureside, :surgerydate, :procedure_type, :has_complications, :performed_date, :performed_time])
  end

  def clinical_note_data
    @clinical_note = @ipdrecord.clinical_note
    @diagnosislist = @ipdrecord.diagnosislist
  end

  def procedure_form_data
    @procedure = @ipdrecord.procedure.where(:operative_note_id.in => [nil, '', @operative_note.try(:id)])
  end

  def operative_note
    @operative_note = @ipdrecord.operative_notes.find_by(id: params[:id])
  end

  def operative_note_for_write
    operative_note_id = params[:inpatient_ipd_record][:operative_notes_attributes]['0'][:id]
    @operative_note = @ipdrecord.operative_notes.find_by(id: operative_note_id)
  end

  def delete_inventory_data
    @operative_note.inventorymedication.delete_all
    @operative_note.inventoryconsumables.delete_all
    @operative_note.inventorypack.delete_all
    @operative_note.inventoryprep.delete_all
    @operative_note.inventorydressings.delete_all
    @operative_note.inventoryinstrument.delete_all
    @operative_note.inventoryimplants.delete_all
    @operative_note.inventoryswabs.delete_all
  end

  def time_calculation
    if @operative_note.patient_entry_time.present? && @operative_note.patient_exit_time.present?
      time_total_sec = @operative_note.patient_exit_time - @operative_note.patient_entry_time
      time_in_hours = ((time_total_sec / 60) / 60).to_i
      time_in_minutes = (time_total_sec / 60).to_i - (time_in_hours * 60)
      time_in_seconds = time_total_sec - ((time_total_sec / 60).to_i * 60).round
      time_to_save = time_in_hours.abs.to_s + 'h ' + time_in_minutes.abs.to_s + 'm ' + time_in_seconds.abs.to_s + 's'
      @operative_note.update_attributes(patient_entry_exit_time: time_to_save)
    end

    if @operative_note.anesthesia_start_time.present? && @operative_note.anesthesia_end_time.present?
      time_total_sec = @operative_note.anesthesia_end_time - @operative_note.anesthesia_start_time
      time_in_hours = ((time_total_sec / 60) / 60).to_i
      time_in_minutes = (time_total_sec / 60).to_i - (time_in_hours * 60)
      time_in_seconds = time_total_sec - ((time_total_sec / 60).to_i * 60).round
      time_to_save = time_in_hours.abs.to_s + 'h ' + time_in_minutes.abs.to_s + 'm ' + time_in_seconds.abs.to_s + 's'
      @operative_note.update_attributes(anesthesia_start_end_time: time_to_save)
    end

    if @operative_note.surgery_start_time.present? && @operative_note.surgery_end_time.present?
      time_total_sec = @operative_note.surgery_end_time - @operative_note.surgery_start_time
      time_in_hours = ((time_total_sec / 60) / 60).to_i
      time_in_minutes = (time_total_sec / 60).to_i - (time_in_hours * 60)
      time_in_seconds = time_total_sec - ((time_total_sec / 60).to_i * 60).round
      time_to_save = time_in_hours.abs.to_s + 'h ' + time_in_minutes.abs.to_s + 'm ' + time_in_seconds.abs.to_s + 's'
      @operative_note.update_attributes(surgery_start_end_time: time_to_save)
    end
  end

  def find_ipd_record
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
  end

  def find_ipd_record_for_write
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:inpatient_ipd_record][:admission_id])
  end

  def update_operative_note_id_in_procedure
    @ipdrecord.procedure.each do |proc|
      if (proc.procedurestage == 'P') && proc.operative_note_id.blank?
        proc.update(operative_note_id: @operative_note.id)
      end
    end
  end

  def update_operative_note_id_in_complications
    @ipdrecord.complications.each do |complication|
      complication.update(operative_note_id: @operative_note.id)
    end
  end

  def print_settings
    organisation_id = current_user.organisation_id.to_s
    facility_id = current_facility.id.to_s
    @print_settings = PrintSetting.print_options(organisation_id, facility_id, ['486546481'])
  end

  def procedure_allowed_attributes
    [:id, :procedurestage, :procedure_type, :procedurename, :procedure_id, :procedure_performed, :procedureside, :procedurefullcode, :entered_by, :entered_by_id, :entered_at_facility, :entered_at_facility_id, :procedure_comment, :users_comment, :entered_datetime, :updated_datetime, :updated_by, :updated_by_id, :updated_at_facility, :updated_at_facility_id, :performed_by, :has_complications, :procedure_cnt, :performed_by_id, :performed_at_facility, :performed_at_facility_id, :performed_datetime, :performed_date, :performed_time, :operative_note_id, :_destroy, :complication_comment, :complication_comment_entered_by, :complication_comment_entered_by_id, :complication_comment_entered_at_facility, :complication_comment_entered_at_facility_id, :complication_comment_entered_datetime, :complication_comment_updated_by, :complication_comment_updated_by_id, :complication_comment_updated_at_facility, :complication_comment_updated_at_facility_id, :complication_comment_updated_datetime, :has_complication_created_by, :has_complication_created_by_id, :has_complication_created_by_datetime, :has_complication_removed_by, :has_complication_removed_by_id, :has_complication_removed_by_datetime]
  end

  def complications_attributes
    [:id, :procedure_code, :procedure_id, :entered_by, :entered_by_id, :entered_at_facility, :entered_at_facility_id, :comment, :entered_datetime, :updated_datetime, :updated_by, :updated_by_id, :updated_at_facility, :updated_at_facility_id, :operative_note_id, :complication_name, :complication_original_side, :code, :ipd_record_id, :_destroy, :is_deleted]
  end
end
