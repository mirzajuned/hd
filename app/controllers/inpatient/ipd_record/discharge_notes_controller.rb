# 6   Metrics/MethodLength
# 4   Metrics/AbcSize
# 4   Naming/VariableNumber
# 1   Metrics/ClassLength
# 1   Metrics/CyclomaticComplexity
# 1   Metrics/LineLength
# 1   Metrics/PerceivedComplexity
# 1   Style/GuardClause
# --
# 19  Total Offenses Pending
class Inpatient::IpdRecord::DischargeNotesController < ApplicationController
  before_action :authorize
  before_action :find_ipd_record, only: [:new, :edit, :print, :show, :print, :print_flags]
  before_action :find_ipd_record_for_write, only: [:create, :update]
  before_action :discharge_note_form_params, only: [:new, :edit, :show]
  before_action :discharge_note, only: [:show, :edit, :update, :print, :print_flags]
  before_action :print_settings, only: [:show, :create, :update]
  before_action :inventory_store, only: [:new, :edit]

  def new
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] }
    @discharge_note = @ipdrecord.build_discharge_note
    @procedure = @ipdrecord.procedure.where(procedurestage: 'P')
    @diagnosislist = @ipdrecord.diagnosislist
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)
    @url = "/inpatient/ipd_record/discharge_note/#{@speciality_folder_name}_notes"
    @method = 'POST'
    @date = Date.current.midnight
    clinical_note_data
    images_params
    @record_history = @discharge_note.record_histories.new

    respond_to do |format|
      format.js { render 'inpatient/ipd_record/discharge_note/form' }
    end
  end

  def create
    @discharge_note = @ipdrecord.build_discharge_note

    @ipdrecord.update!(discharge_note_params)

    @ipdrecord.admission.inc(ipd_templates_count: 1)
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)

    discharge_note_view_params
    images_params
    create_followup_appointment
    clinical_note_data
    # operative_note
    # create_patient_assets
    operative_procedure_note

    @admission.update_attributes(admission_stage: 'pre_discharge')
    AdmissionsHelper.update_milestone(@admission, 'ready_for_discharge', 9, current_user.id)

    respond_to do |format|
      format.js { render 'inpatient/ipd_record/discharge_note/create' }
    end
    Patients::Summary::TimelineWorker.call(event_name: 'IPD_RECORD', sub_event_name: 'CREATED',
                                           ipd_record_id: @ipdrecord.id, user_id: current_user.id,
                                           user_name: current_user.fullname, ipdtemplatetype: 'Discharge Note')
    if @new == true
      Patients::Summary::TimelineWorker.call(event_name: 'OPD_APPOINTMENT', sub_event_name: 'SCHEDULED',
                                             appointment_id: @discharge_note.followup_appointment_id,
                                             user_id: current_user.id, user_name: current_user.fullname,
                                             workflow: current_facility.clinical_workflow)
    end
    IpdRecordJob.perform_later(@ipdrecord.id.to_s, @discharge_note.id.to_s, 'discharge_note')
  end

  def show
    discharge_note_view_params
    clinical_note_data
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)

    # operative_note
    respond_to do |format|
      format.js { render 'inpatient/ipd_record/discharge_note/show' }
    end
  end

  def edit
    @date = Date.current.midnight
    clinical_note_data
    images_params
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] }
    @procedure = @ipdrecord.procedure.where(procedurestage: 'P')
    @diagnosislist = @ipdrecord.diagnosislist
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)
    @pharmacy_prescription = PatientPrescription.find_by(record_id: BSON::ObjectId(@ipdrecord.id),
                                                         patient_id: @ipdrecord.patient_id)
    @record_history = @discharge_note.record_histories.new
    @method = 'PATCH'
    @url = "/inpatient/ipd_record/discharge_note/#{@speciality_folder_name}_notes/#{@ipdrecord.id}"
    @disabled_store = Inventory::Store.find_by(id: @discharge_note.store_id, is_disable: true)
    @stores_array << [ @disabled_store.name, @disabled_store.id ] if @disabled_store.present?
    @no_store = @discharge_note.store_id.blank? && @discharge_note.treatmentmedication.present?
    respond_to do |format|
      format.js { render 'inpatient/ipd_record/discharge_note/form' }
    end
  end

  def update
    @discharge_note = @ipdrecord.discharge_note
    @ipdrecord.update_attributes!(discharge_note_update_params)
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)

    discharge_note_view_params
    images_params
    create_followup_appointment
    clinical_note_data
    # operative_note
    # update_patient_assets
    operative_procedure_note

    respond_to do |format|
      format.js { render 'inpatient/ipd_record/discharge_note/update' }
    end

    Patients::Summary::TimelineWorker.call(event_name: 'IPD_RECORD', sub_event_name: 'UPDATED',
                                           ipd_record_id: @ipdrecord.id, user_id: current_user.id,
                                           user_name: current_user.fullname, ipdtemplatetype: 'Discharge Note')
    sub_event_name = if @new == true
                       'SCHEDULED'
                     elsif @edit == true
                       'RESCHEDULED'
                     end
    if sub_event_name.present?
      Patients::Summary::TimelineWorker.call(event_name: 'OPD_APPOINTMENT', sub_event_name: sub_event_name,
                                             appointment_id: @discharge_note.followup_appointment_id,
                                             user_id: current_user.id, user_name: current_user.fullname,
                                             workflow: current_facility.clinical_workflow)
    end
    IpdRecordJob.perform_later(@ipdrecord.id.to_s, @discharge_note.id.to_s, 'discharge_note')
  end

  def print_flags
    @discharge_note.update_attributes("#{params[:flag_name]}": params[:flag])
    render json: { "success": true }
  end

  def print
    @language_flag = params[:language_flag]
    @advice_language = params[:advice_language]
    @view = params[:view]
    @patient = Patient.find_by(id: @discharge_note.patient_id)
    @admission = Admission.find_by(id: @discharge_note.admission_id)
    @patient_exit_time = @admission&.dischargetime&.in_time_zone(current_facility.time_zone)
    @case_sheet = CaseSheet.find_by(id: @ipdrecord.case_sheet_id)
    @tpa = @admission
    @organisation = current_user.organisation
    @followup_doctor = User.find_by(id: @discharge_note.followup_doctor_id)
    @followup_facility = Facility.find_by(id: @discharge_note.followup_facility)
    clinical_note_data
    # operative_note
    operative_procedure_note
    @procedure = @ipdrecord.procedure.where(procedurestage: 'P')
    @diagnosislist = @ipdrecord.diagnosislist
    @discharge_note.record_histories.create(user_id: current_user.id, action: 'P', actiontime: Time.current, template_type: 'Discharge Note')
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      print_attributes(format, 'inpatient/ipd_record/discharge_note/print', '', @print_setting)
    end
  end

  private

  def discharge_note_form_params
    @current_user = current_user
    @current_facility = current_facility
    @admission = Admission.find_by(id: params[:admission_id])
    @tpa = @admission
    @patient = @admission.patient
    @patient_identifier_id = @patient.patient_identifier_id
    @patient_mrn = @patient.patient_mrn
    @age_gender = @patient.patient_age_gender
    @ots = OtSchedule.where(admission_id: @admission.id, operation_done: true, is_deleted: false).order(ottime: :desc)
    @user = User.where(:role_ids.in => [158965000], :facility_ids.in => [current_facility.id])[0]
    # Asset Upload
  end

  def images_params
    @image_before_surgery_1 = PatientSummaryAssetUpload.find_by(patient_id: @patient.id,
                                                                source: 'before_surgery_1',
                                                                ipdrecord_id: @discharge_note&.id)
    @image_before_surgery_2 = PatientSummaryAssetUpload.find_by(patient_id: @patient.id,
                                                                source: 'before_surgery_2',
                                                                ipdrecord_id: @discharge_note&.id)
    @image_after_surgery_1 = PatientSummaryAssetUpload.find_by(patient_id: @patient.id,
                                                               source: 'after_surgery_1',
                                                               ipdrecord_id: @discharge_note&.id)
    @image_after_surgery_2 = PatientSummaryAssetUpload.find_by(patient_id: @patient.id,
                                                               source: 'after_surgery_2',
                                                               ipdrecord_id: @discharge_note&.id)
  end

  def discharge_note_view_params
    @admission = Admission.find_by(id: @ipdrecord.admission_id)
    @patient = Patient.find_by(id: @ipdrecord.patient_id)
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @tpa = @admission
    @procedure = @ipdrecord.procedure.where(procedurestage: 'P')
    @diagnosislist = @ipdrecord.diagnosislist
  end

  def discharge_note_params
    params.require(:inpatient_ipd_record).permit(
      admission_attributes: [:id, :admissiondate, :dischargedate, :dischargetime],
      discharge_note_attributes: [
        :note_date, :print_procedure, :print_investigation, :note_time, :note_created_at, :organisation_id,
        :admission_id, :patient_id, :user_id, :department, :specalityname, :specalityid, :specialty_id, :ward_id,
        :room_id, :bed_id, :daycare, :patient_name, :patient_age, :patient_gender, :mr_no, :patient_identifier_id,
        :check_all, :discharge_intimation, :band_removed, :intracath_removed, :discharge_summary_given,
        :correct_dose_explained, :wound_dressing_needs, :process_of_followup_explained, :pending_reports_given,
        :emergency_contact_explained, :admission_date, :discharge_date, :discharge_time, :investigation_notes,
        :treatment_type, :treatment_notes, :precautions, :followup_date, :followup_time, :followup_doctor_id,
        :followup_facility, :appointment_category_id, :appointment_type_id, :advicemanagementplan, :bookappointment,
        :diagnosis, :procedure, :patient_condition, :procedure_code, :terms, :physiotherapy, :store_id, :store_name,
        :store_present, medicationsets: [], treatmentmedication_attributes: [
          :medicinename, :medicinetype, :medicinequantity, :medicinefrequency, :medicineduration, :taper_id,
          :medicinedurationoption, :eyeside, :medicineinstructions, :instruction, :pharmacy_item_id,
          :generic_display_name, :generic_display_ids, :medicine_from, :_destroy
        ], record_histories_attributes: [:user_id, :action, :actiontime, :template_type]
      ]
    )
  end

  def discharge_note_update_params
    params.require(:inpatient_ipd_record).permit(
      admission_attributes: [:id, :admissiondate, :dischargedate, :dischargetime],
      discharge_note_attributes: [
        :id, :print_procedure, :print_investigation, :note_date, :note_time, :note_created_at, :organisation_id,
        :admission_id, :patient_id, :user_id, :department, :specalityname, :specalityid, :specialty_id, :ward_id,
        :room_id, :bed_id, :daycare, :patient_name, :patient_age, :patient_gender, :mr_no, :patient_identifier_id,
        :check_all, :discharge_intimation, :band_removed, :intracath_removed, :discharge_summary_given,
        :correct_dose_explained, :wound_dressing_needs, :process_of_followup_explained, :pending_reports_given,
        :emergency_contact_explained, :admission_date, :discharge_date, :discharge_time, :investigation_notes,
        :treatment_type, :treatment_notes, :precautions, :followup_date, :followup_time, :followup_doctor_id,
        :followup_facility, :appointment_category_id, :appointment_type_id, :advicemanagementplan, :bookappointment,
        :diagnosis, :procedure, :patient_condition, :procedure_code, :terms, :physiotherapy, :store_id, :store_name,
        :store_present, medicationsets: [], treatmentmedication_attributes: [
          :id, :medicinename, :medicinetype, :medicinequantity, :instruction, :medicinefrequency, :medicineduration,
          :medicinedurationoption, :taper_id, :eyeside, :medicineinstructions, :pharmacy_item_id,
          :generic_display_name, :generic_display_ids, :medicine_from, :_destroy
        ], record_histories_attributes: [:user_id, :action, :actiontime, :template_type]
      ]
    )
  end

  def discharge_note
    @discharge_note = @ipdrecord.discharge_note
  end

  def clinical_note_data
    @clinical_note = @ipdrecord.clinical_note
    @clinical_note_investigation = @clinical_note.try(:investigations).to_s
  end

  def operative_note; end

  def create_followup_appointment
    @current_user = current_user
    if @discharge_note.bookappointment == 'true' && @discharge_note.followup_date != '' && !@discharge_note.followup_date.nil?
      @appointment_facility = @discharge_note.followup_facility || current_facility.id.to_s
      @appointment_type_id = @discharge_note.appointment_type_id

      @followup_time = Time.zone.parse("#{@discharge_note.try(:followup_date)} #{@discharge_note.followup_time}")
      @followup_date = Date.parse(@discharge_note.try(:followup_date))

      @appointment_type_id = params[:inpatient_ipd_record][:discharge_note_attributes][:appointment_type_id]
      @followup_doctor = User.find_by(id: @discharge_note.followup_doctor_id)
      @followup_facility = Facility.find_by(id: @discharge_note.followup_facility)
      if @discharge_note.followup_appointment_id.nil? || @discharge_note.followup_appointment_id == ''
        display_id = CommonHelper.get_opd_record_identifier(@current_user)
        @followupappointment = Appointment.new(organisation_id: @current_user.organisation_id,
                                               patient_id: @discharge_note.patient_id.to_s,
                                               department_id: '485396012', departmenttype: '440655000',
                                               facility_id: @appointment_facility, appointmentdate: @followup_date,
                                               start_time: @followup_time, consultant_id: @followup_doctor.id,
                                               appointment_type_id: @appointment_type_id,
                                               appointmentstatus: 416774000, ref_doc_name: '', ref_doc_place: '',
                                               user_id: @current_user.id, display_id: display_id,
                                               patient_name: @patient.fullname,
                                               specialty_id: @discharge_note.specialty_id,
                                               case_sheet_id: @case_sheet.id,
                                               appointment_category_id: @discharge_note.try(:appointment_category_id), appointmenttype: 'appointment')
        if @followupappointment.save!
          @discharge_note.update_attributes(followup_appointment_id: @followupappointment.id)
          @followupappointment.update(end_time: @followup_time + 10.minutes)

          # if @followupappointment.try(:organisation_id).to_s == '57f1c8b7666d676c0c000002'
          #   ApiJobs::AppointmentDataJob.perform_later('create',@followupappointment.id.to_s, 'ideamed' )
          # end
          @case_sheet.add_to_set(appointment_ids: @followupappointment.id)
        end

        @temp_appointment = @followupappointment
        @new = true
      else
        appointment = Appointment.find_by(id: @discharge_note.followup_appointment_id)
        appointment.update_attributes(appointmentdate: @followup_date,
                                      start_time: @followup_time,
                                      end_time: @followup_time + 10.minutes,
                                      consultant_id: @followup_doctor.id,
                                      appointment_type_id: @appointment_type_id,
                                      facility_id: @appointment_facility,
                                      specialty_id: @discharge_note.specialty_id,
                                      case_sheet_id: @case_sheet.id,
                                      appointment_category_id: @discharge_note.try(:appointment_category_id))

        @followup_workflow = OpdClinicalWorkflow.find_by(appointment_id: @discharge_note.followup_appointment_id.to_s)
        unless @followup_workflow.nil?
          doctors = @followup_workflow.consultant_ids << @followup_doctor.id.to_s
          @followup_workflow.update(appointmentdate: @followup_date, consultant_ids: doctors)

          # if appointment.try(:organisation_id).to_s == '57f1c8b7666d676c0c000002'
          #   ApiJobs::AppointmentDataJob.perform_later('update',appointment.id.to_s, 'ideamed' )
          # end

        end
        @edit = true
      end
    end
  end

  def operative_procedure_note
    if @operative_note.present? && @operative_note.procedure_note.present? && @operative_note.procedure_note != '<br>'
      @procedure_notes = @operative_note.procedure_note.html_safe
    else
      @procedure_notes = ''
    end
  end

  def find_ipd_record
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
  end

  def find_ipd_record_for_write
    admission_id = params[:inpatient_ipd_record][:discharge_note_attributes][:admission_id]
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: admission_id)
  end

  def print_settings
    organisation_id = current_user.organisation_id.to_s
    facility_id = current_facility.id.to_s
    @print_settings = PrintSetting.print_options(organisation_id, facility_id, ['486546481'])
  end

  def inventory_store
    @stores_array = Inventory::Store.where(facility_id: current_facility.id, is_active: true,
                                           department_id: '284748001', is_disable: false).pluck(:name, :id)
  end
end
