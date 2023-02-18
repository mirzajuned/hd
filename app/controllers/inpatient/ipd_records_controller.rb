# 3  Metrics/AbcSize
# 3  Metrics/MethodLength
# 1  Metrics/ClassLength
# --
# 7  Total
class Inpatient::IpdRecordsController < ApplicationController
  include IpdRecordHelper
  before_action :authorize
  before_action :print_settings, only: [:show_all_notes]

  # In Use - All Notes
  def show_all_notes
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@admission.try(:specialty_id))
    @case_sheet = CaseSheet.find_by(id: @admission.try(:case_sheet_id))
    @tpa = @admission
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
    @assessment = PatientAssessment.find_by(admission_id: params[:admission_id])
    @clinical_note = @ipdrecord.try(:clinical_note)
    @discharge_note = @ipdrecord.try(:discharge_note)
    @procedure = @ipdrecord.try(:procedure).present? ? @ipdrecord.procedure.where(procedurestage: 'P') : nil
    @diagnosislist = @ipdrecord.try(:diagnosislist)
    @all_nursing_records = NursingRecord.where(admission_id: @admission.try(:id))
    @all_operative_notes = @ipdrecord.try(:operative_notes)
    @specialty_id = @admission.try(:specialty_id)
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
  end

  # In Use - All Notes
  def print_all_notes
    @language_flag = params[:language_flag]
    @advice_language = params[:advice_language]
    @organisation = current_user.organisation
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    @patient_exit_time = @admission&.dischargetime&.in_time_zone(current_facility.time_zone)
    @case_sheet = CaseSheet.find_by(id: @admission.case_sheet_id)
    @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: @admission.id)
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@admission.specialty_id)
    @tpa = @admission
    @clinical_note = @ipdrecord.clinical_note
    # @operative_note_ids = @ipdrecord.procedure.where(:operative_note_id.nin => ["",nil]).pluck(:operative_note_id)
    # @operative_notes = @ipdrecord.operative_notes.find(@operative_note_ids)
    @all_operative_notes = @ipdrecord.operative_notes
    @discharge_note = @ipdrecord.discharge_note
    @procedure = @ipdrecord.procedure.where(procedurestage: 'P')
    @diagnosislist = @ipdrecord.diagnosislist
    @all_nursing_records = NursingRecord.where(admission_id: @admission.id)
    @view = params[:view]
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      print_attributes(format, 'inpatient/ipd_records/print_all_notes', '', @print_setting)
    end
  end

  # In Use - Operative Note
  def current_time
    @current_time = Time.current
    render json: @current_time
  end

  # In Use - Operative Consent
  def consent_note
    @patient = Patient.find_by(id: params[:patient_id])
    @calculate_age = @patient.calculate_age
    @admission = Admission.find_by(id: params[:admission_id])
    @specialty_folder_name = TemplatesHelper.get_speciality_folder_name(@admission.specialty_id)

    respond_to do |format|
      format.js { render 'inpatient/ipd_consents/operative/common/consent_note' }
    end
  end

  # In Use - Operative Consent
  def load_consent
    service_id = params[:surgery_id]
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    @specialty_folder_name = TemplatesHelper.get_speciality_folder_name(@admission.specialty_id)
    @erb = Global.send('ipd').send("#{@specialty_folder_name}_consent")[service_id.to_s]['erb']

    respond_to do |format|
      format.js { render 'inpatient/ipd_consents/operative/common/load_consent' }
    end
  end

  # In Use - Operative Consent
  def print_consent
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = Admission.find_by(id: params[:admission_id])
    @organisation = current_user.organisation
    @specialty_folder_name = TemplatesHelper.get_speciality_folder_name(@admission.specialty_id)
    if params[:surgery_id].present? && params[:surgery_id] != 'undefined'
      @erb = Global.send('ipd').send("#{@specialty_folder_name}_consent")[params[:surgery_id]]['erb'] + '.html.erb'
      setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, 'IPD')
      @print_settings = setting_service.select_print_setting
      @logo = @print_settings[1]

      respond_to do |format|
        format.pdf do
          render template: 'inpatient/ipd_consents/operative/common/print_consent',
                 pdf: '',
                 layout: 'pdfgen.html.erb',
                 viewport_size: '1280x1024',
                 page_size: 'A4',
                 disable_smart_shrinking: true,
                 show_as_html: params[:debug].present?,
                 header: { spacing: 4,
                           html: { template: 'layouts/pdf-header.html' } },
                 footer: { html: { template: 'layouts/pdf-footer.html' },
                           spacing: 10 },
                 margin: { top: @print_settings[0]['header_height'].to_i * 10,
                           bottom: 40 }
        end
      end
    else
      head :ok
    end
  end

  # In Use - Operative Note
  def search_sugery_personnel
    @results_name = Inpatient::SurgeryPersonnel.where(name: /#{Regexp.escape(params[:q])}/i,
                                                      :specialty_id.in => current_user.specialty_ids,
                                                      :organisation_id.in => [nil, current_user.organisation_id.to_s])
  end

  # Used by Add Medication - Discharge Note
  def ipdaddmedication
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] }
    @medication_instruction_set << 'Add a text Box'
    @counter = params[:ajax][:counter]
    respond_to do |format|
      format.js { render '/inpatient/ipd_record/ipdaddmedication', layout: false }
    end
  end

  # load complications on click of procedure
  def complication_procedure
    @ipdrecord = Inpatient::IpdRecord.find_by(id: params[:ajax][:ipd_record_id]) rescue nil
    @operative_note = @ipdrecord.operative_notes.find_by(id: params[:ajax][:operative_note_id]) rescue nil if @ipdrecord
    @procedure = @ipdrecord.procedure.find_by(id: params[:ajax][:procedure_id]) rescue nil if @ipdrecord
    @procedure_count = params[:ajax][:procedure_count]
    # render json: {ipdrecord: @ipdrecord, operative_note: @operative_note, procedure: @procedure}
    respond_to do |format|
      format.js { render '/inpatient/ipd_record/complication_procedure', layout: false }
    end
  rescue => e
    @logger.error("=== Error while getting complications for the procedure === #{e.inspect}")
  end
  # EOF load complications on click of procedure

  # remove complications of procedure
  def remove_complication_procedure
    ipdrecord = Inpatient::IpdRecord.find_by(id: params[:ajax][:ipd_record_id])
    procedure = ipdrecord.procedure.find_by(id: params[:ajax][:procedure_id])
    procedure.has_complications = 'No'
    procedure.complication_comment = ''
    procedure.complication_comment_entered_by = ''
    procedure.complication_comment_entered_by_id = ''
    procedure.complication_comment_entered_at_facility = ''
    procedure.complication_comment_entered_at_facility_id = ''
    procedure.complication_comment_entered_datetime = ''
    procedure.complication_comment_updated_by = ''
    procedure.complication_comment_updated_by_id = ''
    procedure.complication_comment_updated_at_facility = ''
    procedure.complication_comment_updated_at_facility_id = ''
    procedure.complication_comment_updated_datetime = ''
    procedure.has_complication_created_by = ''
    procedure.has_complication_created_by_id = ''
    procedure.has_complication_created_by_datetime = ''
    procedure.has_complication_removed_by = ''
    procedure.has_complication_removed_by_id = ''
    procedure.has_complication_removed_by_datetime = ''
    procedure.save!
    ipdrecord.complications.where(procedure_id: procedure.id).destroy_all
    render json: { ipdrecord: ipdrecord }
  rescue => e
    @logger.error("=== Error while getting complications for uncheck procedure === #{e.inspect}")
  end
  # EOF remove complications of procedure

  # remove complications of procedure
  def remove_complication_procedures
    ipdrecord = Inpatient::IpdRecord.find_by(id: params[:ajax][:ipd_record_id])
    # operative_note = ipdrecord.operative_notes.find_by(id: params[:ajax][:operative_note_id])

    procedures = ipdrecord.procedure.where(performed_note_id: params[:ajax][:operative_note_id])
    procedures.each do |procedure|
      procedure.has_complications = 'No'
      procedure.complication_comment = ''
      procedure.complication_comment_entered_by = ''
      procedure.complication_comment_entered_by_id = ''
      procedure.complication_comment_entered_at_facility = ''
      procedure.complication_comment_entered_at_facility_id = ''
      procedure.complication_comment_entered_datetime = ''
      procedure.complication_comment_updated_by = ''
      procedure.complication_comment_updated_by_id = ''
      procedure.complication_comment_updated_at_facility = ''
      procedure.complication_comment_updated_at_facility_id = ''
      procedure.complication_comment_updated_datetime = ''
      procedure.has_complication_created_by = ''
      procedure.has_complication_created_by_id = ''
      procedure.has_complication_created_by_datetime = ''
      procedure.has_complication_removed_by = ''
      procedure.has_complication_removed_by_id = ''
      procedure.has_complication_removed_by_datetime = ''
      procedure.save!
      ipdrecord.complications.where(procedure_id: procedure.id).destroy_all
    end

    render json: { ipdrecord: ipdrecord }
  rescue => e
    @logger.error("=== Error while getting complications on click of no === #{e.inspect}")
  end
  # EOF remove complications of procedure

  def user_time_slot_check
    organisation_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    user_time_slot = UserTimeSlot.find_by(user_id: params[:doctor_id])
    if organisation_setting.time_slots_enabled && user_time_slot
      options = { department_id: params[:department_id], facility_id: params[:facility_id] }

      opd_sessions = user_time_slot.sessions.where(options)
      opd_exception_sessions = user_time_slot.exception_sessions.where(options)

      opd_slots_present = (opd_sessions.count > 0 || opd_exception_sessions.count > 0)
    else
      opd_slots_present = false
    end

    render json: opd_slots_present
  end

  private

  # In Use - show_all_notes
  def print_settings
    organisation_id = current_user.organisation_id.to_s
    facility_id = current_facility.id.to_s
    @print_settings = PrintSetting.print_options(organisation_id, facility_id, ['486546481'])
  end
end
