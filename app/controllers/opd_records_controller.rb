# 105  Metrics/LineLength
# 19   Metrics/AbcSize
# 14   Style/IdenticalConditionalBranches
# 13   Metrics/MethodLength
# 9    Style/GuardClause
# 8    Metrics/BlockNesting
# 7    Security/Eval
# 6    Metrics/PerceivedComplexity
# 6    Style/ConditionalAssignment
# 6    Style/StringLiterals
# 5    Metrics/CyclomaticComplexity
# 4    Lint/UselessAssignment
# 3    Style/IfUnlessModifier
# 1    Lint/DuplicateMethods
# 1    Metrics/ClassLength
# 1    Metrics/ParameterLists
# 1    Style/EvalWithLocation
# --
# 209  Total
require 'date'
require 'time'
require 'open-uri'
require 'net/http'
require 'uri'

class OpdRecordsController < ApplicationController
  include TemplatesHelper
  include OpdRecordsHelper

  before_action :authorize_webview_session, only: [:new, :edit, :view_opd_summary]
  before_action :authorize
  before_action :setup_view_only_flag, only: [:new, :create, :edit, :update, :view_opd_summary]
  before_action :setup_print_only_flag, only: [:print_opd_record]
  before_action :print_settings, only: [:view_opd_summary, :create, :update, :replace_medication_instruction]
  before_action :inventry_store, only: [:new, :edit, :update]
  before_action :current_organisations_setting, only: [:new, :create, :edit, :update, :view_opd_summary, :print_opd_record]
  after_action :prepare_mis_job, only: [:create, :update]
  respond_to :js, :json, :html

  def new
    @mode = params[:mode] || params[:viewmode]
    @viewmode = params[:viewmode]
    @user_set_type = UsersLaboratoryList.where(user_id: @current_user.id, set_type: 440655000, is_deleted: false).pluck(:name, :id)
    @facility_set_type = FacilityLaboratoryList.where(facility_id: @current_facility.id, set_type: 440655000, is_deleted: false).pluck(:name, :id)
    @set_type = @user_set_type + @facility_set_type
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@appointment.specialty_id)
    @specalityid = @appointment.specialty_id.to_i
    @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
    @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)

    rules_file

    @case_sheet = CaseSheet.find_by(id: @appointment.case_sheet_id)

    organisations_setting = OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id))
    @disable_default_investigation =  organisations_setting.try(:disable_default_investigation)
    @disable_default_procedure =  organisations_setting.try(:disable_default_procedure)
    @disable_default_diagnosis =  organisations_setting.try(:disable_default_diagnosis)
    @disable_default_medication = organisations_setting.try(:disable_default_medicine)

    @facility_id = current_facility.id
    @date = Date.current
    @user = User.find_by(id: @consultant_id)
    @facilities = Common.new.fetch_facilities(user: @user)
    @nabh_setting = NabhSetting.find_by(facility_id: @facility_id)

    @referral_facilities = Common.new.fetch_referred_facilities(current_user: @current_user, facility_id: @current_facility)
    @referred_from_facility = [@current_facility]

    # referral doc for intra facility start
    @intra_referral_doctors = User.where(organisation_id: @current_user.organisation_id, facility_ids: @current_facility.id, role_ids: 158965000, specialty_ids: @appointment.specialty_id, is_active: true)

    # show appointments from AppointmentTypes
    @appointment_types = AppointmentType.where(facility_id: @facility_id, specialty_ids: @appointment.specialty_id, is_active: true)
    @sub_appointment_types = OrganisationAppointmentCategoryType.where(organisation_id: @current_user.organisation_id, specialty_ids: @appointment.specialty_id, is_active: true).order(created_at: :desc)
    # old code
    if @current_user.role_ids.include?(158965000) # in case of doctor
      @ophthal_laboratory_set = OphthalLaboratorySet.where(doctor_id: @current_user.id.to_s, is_active: true)
      @radiology_laboratory_set = RadiologyLaboratorySet.where(doctor_id: @current_user.id.to_s, specialty_id: @appointment.specialty_id.to_i, is_active: true)
    else
      @ophthal_laboratory_set = OphthalLaboratorySet.where(facility_id: @current_facility.id.to_s, doctor_id: nil, is_active: true)
      @radiology_laboratory_set = RadiologyLaboratorySet.where(facility_id: @current_facility.id.to_s, doctor_id: nil, specialty_id: @appointment.specialty_id.to_i, is_active: true)
    end

    @custom_radiology_investigations = CustomRadiologyInvestigation.where(facility_id: @current_facility.id, specialty_id: @appointment.specialty_id.to_i, is_deleted: false)

    @formbuttons = Global.ehrcommon.newepisode.formbuttons
    @savepath = Global.ehrcommon.newepisode.savepath

    if @clone_record == 'clone'
      set_clone_opd_record
    end

    TemplateOpdRecord.new(@patient, @opdrecord, @speciality_folder_name, @specalityid, @templatetype, @templateid, @appointment.specialty_id).new_record

    @post_operation = OtSchedule.where(patient_id: @patient.id, operation_done: true, is_deleted: false)
    unless @post_operation.empty?
      @post_operative_day = @post_operation.order_by(otdate: 'asc').last.otdate.strftime('%d/%m/%Y')
    end
    
    if @clone_record == 'clone'
      @edit_opd_link = 'edit_opd_records_' + @speciality_folder_name + '_note_path(@opdrecord.id,:opdrecordid=> @opdrecord.id, :patientid=> @opdrecord.patientid, :appointmentid=> @opdrecord.appointmentid, :templatetype=> @opdrecord.templatetype, :viewmode=> @viewmode)'
      
      redirect_to eval(@edit_opd_link), flash: { notice: 'Message' }
      #
      # redirect_to templates_edit_opd_record_path(:opdrecordid=> @opdrecord.id, :patientid=> @opdrecord.patientid, :appointmentid=> @opdrecord.appointmentid, :templatetype=> @opdrecord.templatetype),:flash => { :notice => "Message" }
    else
      respond_to do |format|
        format.html { render 'new', layout: 'mobile_layout' }
        format.js { render 'new', layout: false }
      end
    end
  end

  def create
    @case_sheet = CaseSheet.find_by(id: params[:opdrecord][:case_sheet_id])
    @mode = params[:mode_of_request]
    @viewmode = params[:viewmode]
    appointmentdate = @appointment.appointmentdate rescue nil
    appointmenttime = @appointment.start_time rescue nil
    @consultant = @appointment.consultant_id
    @user = User.find_by(id: @consultant)
    # Code for Follow Up from Advice Starts Here
    if record_params[:bookappointment] == 'true'
      if record_params[:advice_attributes][:opdfollowupdate] != '' && record_params[:advice_attributes][:opdfollowupdate].present?
        opdfollowupdate = Date.parse(record_params[:advice_attributes][:opdfollowupdate]).strftime('%d/%m/%Y')
        opdfollowuptime = record_params[:advice_attributes][:opdfollowuptime]
        @followup_date_time = Time.zone.parse(opdfollowuptime)
        @appointment_type_id = params[:appointment_type]
        @new_appointment = Appointment.new(appointmentdate: opdfollowupdate, start_time: @followup_date_time, end_time: @followup_date_time + 10.minutes, patient_id: @patient.id, appointment_type_id: record_params[:advice_attributes][:appointment_type_id], consultant_id: record_params[:advice_attributes][:appointment_doctor], user_id: @current_user.id, facility_id: record_params[:advice_attributes][:appointment_facility], departmenttype: params[:opdrecord][:encountertypeid], appointmentstatus: 416774000, display_id: CommonHelper.get_opd_record_identifier(@user), patient_name: @patient.fullname, organisation_id: @current_user.organisation_id, created_from: 'OpdRecord', case_sheet_id: @case_sheet.id, appointment_category_id: record_params[:advice_attributes][:appointment_category_id], specialty_id: record_params[:advice_attributes][:appointment_specialty_id], department_id: '485396012', appointmenttype: 'appointment')

        if @new_appointment.save
          @followupappointment_id = @new_appointment.id
          @temp_appointment = @new_appointment
          # get_daily_reports
          # Reports::Opd::Appointments.new(@new_appointment).call
          @new = true

          @case_sheet.add_to_set(appointment_ids: @new_appointment.id)

          if @current_user.try(:organisation_id).to_s == '57f1c8b7666d676c0c000002'
            ApiJobs::AppointmentDataJob.perform_later('create',@new_appointment.id.to_s, 'ideamed' )
          end

        else
          @followupappointment_id = ''
        end
      end
      record_params[:advice_attributes][:followupappointment_id] = @followupappointment_id
    end
    # Code for Follow Up from Advice Ends Here

    # Code for management plan advice.
    @patient_notes = record_params[:advicemanagementplan]
    @patient_notes_to_rec = record_params[:advicemanagementplantoreceptionist]
    # @patient_notes_to_rec = record_params[:management_personal_cmt]

    if @patient_notes_to_rec == 'true'
      @newnote = PatientNote.new
      @newnote.organisation_id = @current_user.organisation_id.to_s
      @newnote.user_id = @current_user.id.to_s
      @newnote.patient_id = @patient.id.to_s
      @newnote.comment = @patient_notes
      @newnote.created_by = record_params[:consultant_name]
      @newnote.save
    end
    # Code for management plan advice ends.
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@appointment.specialty_id)
    @specalityid = @appointment.specialty_id
    @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
    @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)

    @opdrecord = OpdRecord.new(record_params)
    @opdcomments = @opdrecord.opd_record_comments
    if @opdrecord.save
      @appointment.inc(opd_record_count: 1) # used for disabling not arrived in RHS
      @opdrecord.record_histories.create(user_id: @current_user.id, action: 'C', actiontime: Time.current, template_type: @templatetype)
      OpdRecordIdentifier.create(patient_id: @patient.id, organisation_id: @current_user.organisation_id, opd_record_org_id: CommonHelper.get_opd_record_identifier(@current_user))
      @opdrecordaudit = @opdrecord.opd_record_audits.create(user_id: session[:user_id], action: 'Save')
      @opdrecordattribute = @opdrecord.create_opd_record_attribute(recordcreateduser: session[:user_id], recordstatus: Global.opd.unapproved_opdrecord.status)
      @id = @opdrecord.advice_set_id

      if @opdrecord.specalityid == '309988001'
        if ['freeform', 'express', 'pmt', 'postop', 'refraction', 'ar_nct', 'vitalsign', 'biometry'].exclude?(@templatetype)
          Patients::HistoryService.call(@opdrecord, @current_user, @patient.id.to_s) # call  the history services
        end
      else
        if ['freeform', 'express', 'trauma', 'pmt', 'postop', 'ar_nct', 'vitalsign', 'biometry'].exclude?(@templatetype)
          Patients::HistoryService.call(@opdrecord, @current_user, @patient.id.to_s) # call  the history services
        end
      end
      if @opdrecord.treatmentmedication.present?
        @medication = 'true'
        @medication_groups = @opdrecord.treatmentmedication.group_by(&:status)
        CommunicationNotificationJob.perform_now('pharmacy_patient', @opdrecord.id.to_s, @opdrecord.class.to_s)
        CommunicationNotificationJob.perform_now('pharmacy_store', @opdrecord.id.to_s, @opdrecord.class.to_s)
      end
      if @id.present?
        @lcid_code = if @id.length == 2
                       'en'
                     else
                       AdviceSet.find_by(id: @opdrecord.advice_set_id).language_advice_subset.first.lcid_code
                     end
        @advice_set_language = if @id.length > 2
                                 AdviceSet.find_by(id: @id).language_advice_subset.pluck(:language, :lcid_code)
                               else
                                 [['English', 'en'], ['Hindi', 'hi'], ['Bengali', 'bn'], ['Kannada', 'kn'],
                                  ['Tamil', 'ta'], ['Telugu', 'te'], ['Gujarati', 'gu']]
                               end
        @language = [['English', 'en'], ['Hindi', 'hi'], ['Bengali', 'bn'], ['Kannada', 'kn'], ['Tamil', 'ta'],
                     ['Telugu', 'te'], ['Gujarati', 'gu']]
        if @id.present? && @opdrecord.treatmentmedication.present?
          @show_single_dropdown = true
          @combined_dropdown = if current_facility.country_id == 'VN_254'
                                 @advice_set_language & @language << ['Vietnamese', 'vi']
                               elsif current_facility.country_id == 'KH_039'
                                 @advice_set_language & @language << ['Vietnamese', 'vi'] << ["Khmer","kh"] << ["Chinese","ch"]
                               else
                                 @advice_set_language | @language
                               end
        else
          @show_single_dropdown = false
        end
      else
        @lcid_code = ''
      end
      if @opdrecord.advice.present?
        @followupappointment = Appointment.find_by(id: @opdrecord.advice.followupappointment_id.to_s)
      end

      rules_file

      # performed investigations
      performed_case_opd(@opdrecord, @case_sheet)
      # EOF get opd performed investigations which are not yet stored in case-sheet

      # For AppointmentPanel Soft Refresh
      @opd_templates = Global.send(@speciality_folder_name.to_s).send('opdtemplates')
      @appointment_opd_records = OpdRecord.where(appointmentid: @opdrecord.appointmentid.to_s)
      @old_records = PatientTimeline.where(patient_id: @patient.id.to_s, encountertype: 'OPD').not.where(appointment_id: @appointment.id.to_s).limit(3).order(encounterdate: :desc)
      @old_opd_records = OpdRecord.where(patientid: @patient.id.to_s, :appointmentid.ne => @appointment.id.to_s)
                                  .limit(3).order(created_at: :desc)
      @org_specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])
      get_opd_histories

      respond_to do |format|
        format.js { render 'create', layout: false }
        format.html { render 'create', layout: 'mobile_layout' }
      end

      unless @opdrecord.diagnosislist == [] || @opdrecord.diagnosislist.nil? || @opdrecord.diagnosislist == ''
        @opdrecord.diagnosislist.each do |diagnosislist|
          icd_diagnosis = eval(diagnosislist.icd_type).find_by(code: diagnosislist.icddiagnosiscode)

          if icd_diagnosis.present? && icd_diagnosis.has_laterality
            code = diagnosislist.icddiagnosiscode.first(-1)
            icd_name, code = get_parent_icd_name(diagnosislist, code)
          else
            code = diagnosislist.icddiagnosiscode
            icd_name = diagnosislist.diagnosisoriginalname
          end
          save_recent_icd(code, icd_name, @consultant, diagnosislist.icd_type, diagnosislist.specialty_id, diagnosislist.template_id)
        end
      end

      Patients::Summary::TimelineWorker.call(event_name: 'OPD_RECORD', sub_event_name: 'CREATED', opd_record_id: @opdrecord.id, user_id: @current_user.id, user_name: @current_user.fullname)
      if @new == true
        Patients::Summary::TimelineWorker.call(event_name: 'OPD_APPOINTMENT', sub_event_name: 'SCHEDULED', appointment_id: @new_appointment.id, user_id: @current_user.id, user_name: @current_user.fullname, workflow: @current_facility.clinical_workflow)
      end
      OpdRecordJob.perform_later(@opdrecord.id.to_s)
      DataForIpdJob.perform_later(@opdrecord.id.to_s)
      # Diagnosis Report Data Job
      MisJobs::Clinical::ExtractDiagnosesJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@opdrecord.id.to_s, "OPD", "opd_record_form")
      # Doctor Patient Referral Report Data Job
      MisJobs::Clinical::Opd::ExtractDoctorPatientReferralJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@opdrecord.id.to_s)

      # Procedure Data Job
      MisJobs::Clinical::PatientProcedureJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@appointment.case_sheet_id.to_s, @appointment.id.to_s, "appointment")
      if @opdrecord.specalityid == "309988001"
        object_config = {}
        object_config["class_name"] = "opd_records"
        object_config["method_name"] = "create"
        mandatory = {}
        mandatory["opdrecord_id"] = @opdrecord.id.to_s
        mandatory["patient_id"] = @patient.id.to_s
        optional = {}
        others = {}
        others["patient_lasik_status"] = params[:patient][:lasik_eligible].to_bool
        ProcessInBackgroundJob.set(queue: :urgent, wait_until: 0).perform_later(object_config, mandatory, optional, others)
      end
      # OrderJobs::AdvisedJob.set(wait_until: 10.seconds).perform_later(@case_sheet.id.to_s, current_user.id.to_s, current_facility.id.to_s)
    end
  end

  def edit
    @mode = params[:mode] || params[:viewmode]
    @viewmode = params[:viewmode]
    @user_set_type = UsersLaboratoryList.where(user_id: @current_user.id, set_type: 440655000, is_deleted: false).pluck(:name, :id)
    @facility_set_type = FacilityLaboratoryList.where(facility_id: @current_facility.id, set_type: 440655000, is_deleted: false).pluck(:name, :id)
    @set_type = @user_set_type + @facility_set_type
    @consultant_id = @appointment.try(:consultant_id)
    @user = User.find_by(id: @consultant_id)
    @date = @appointment.appointmentdate
    @facility_id = @appointment.facility_id
    @facilities = Common.new.fetch_facilities(user: @user)
    @nabh_setting = NabhSetting.find_by(facility_id: @facility_id)

    @case_sheet = CaseSheet.find_by(id: @opdrecord.case_sheet_id)

    organisations_setting = OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id))
    @disable_default_investigation =  organisations_setting.try(:disable_default_investigation)
    @disable_default_procedure =  organisations_setting.try(:disable_default_investigation)
    @disable_default_diagnosis =  organisations_setting.try(:disable_default_investigation)
    @disable_default_medication = organisations_setting.try(:disable_default_investigation)

    if @opdrecord.referred_to_facility.present?
      @referral_facilities = (Common.new.fetch_referred_facilities(current_user: @current_user, facility_id: @current_facility) + [Facility.find(@opdrecord.referred_to_facility)]).uniq # uniq :we are adding "referred to facility" if user from that facility see this but it get doubled in user from "referred from facility  (anoop)"
    else
      @referral_facilities = Common.new.fetch_referred_facilities(current_user: @current_user, facility_id: @current_facility)
    end

    # referral doc for intra facility start
    @referral_doctor = User.where(organisation_id: @current_user.organisation_id, role_ids: 158965000, is_active: true)
    @appointment_types = AppointmentType.where(facility_id: @appointment.facility_id, specialty_ids: @appointment.specialty_id, is_active: true)
    @appointment_types = AppointmentType.where(user_id: @consultant_id.to_s, specialty_ids: @appointment.specialty_id, is_active: true) unless @appointment_types.present?
    @sub_appointment_types = OrganisationAppointmentCategoryType.where(organisation_id: @current_user.organisation_id, specialty_ids: @appointment.specialty_id, is_active: true).order(created_at: :desc)
    @formbuttons = Global.ehrcommon.ongoingepisode.formbuttons
    @savepath = Global.ehrcommon.ongoingepisode.savepath
    @templatetype = params[:templatetype]
    appointmentdate = @appointment.appointmentdate rescue nil
    appointmenttime = @appointment.start_time rescue nil
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@opdrecord.specalityid)
    @specalityid = @opdrecord.specalityid.to_i
    @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
    @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)

    @opdrecordaudit = @opdrecord.opd_record_audits.create(user_id: session[:user_id], action: 'Edit')
    @post_operation = OtSchedule.where(patient_id: @patient.id, operation_done: true, is_deleted: false)
    @pharmacy_prescription = PatientPrescription.find_by(record_id: BSON::ObjectId(params[:id]),
                                                         patient_id: @patient.id)
    @optical_prescription = PatientOpticalPrescription.find_by(record_id: BSON::ObjectId(params[:id]),
                                                               patient_id: @patient.id)
    disabled_stores
    unless @post_operation.empty?
      @post_operative_day = @post_operation.order_by(otdate: 'asc').last.otdate.strftime('%d/%m/%Y')
    end

    # Laboratory Sets
    if @current_user.role_ids.include?(158965000)
      @ophthal_laboratory_set = OphthalLaboratorySet.where(doctor_id: @current_user.id.to_s, is_active: true)
      @radiology_laboratory_set = RadiologyLaboratorySet.where(doctor_id: @current_user.id.to_s, specialty_id: @appointment.specialty_id, is_active: true)
    else
      @ophthal_laboratory_set = OphthalLaboratorySet.where(facility_id: @current_facility.id.to_s, doctor_id: nil, is_active: true)
      @radiology_laboratory_set = RadiologyLaboratorySet.where(facility_id: @current_facility.id.to_s, doctor_id: nil, specialty_id: @appointment.specialty_id, is_active: true)
    end

    @custom_radiology_investigations = CustomRadiologyInvestigation.where(facility_id: @current_facility.id, specialty_id: @appointment.specialty_id, is_deleted: false)

    # intra facility referral section
    @intra_referral_doctors = User.where(organisation_id: @current_user.organisation_id, facility_ids: @current_facility.id, role_ids: 158965000, specialty_ids: @appointment.specialty_id, is_active: true)
    @org_specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])
    rules_file
    @no_pharmacy_store = @opdrecord.pharmacy_store_id.blank? && @opdrecord.treatmentmedication.present?
    respond_to do |format|
      format.html { render 'edit', layout: 'mobile_layout' }
      format.js { render 'edit', layout: false }
    end
  end

  def update
    @case_sheet = CaseSheet.find_by(id: params[:opdrecord][:case_sheet_id])

    @mode = params[:mode_of_request]
    @viewmode = params[:viewmode]
    if params[:opdrecord][:distalneurovasculardeficit].to_s == 'Absent'
      params[:opdrecord][:sensorydeficit] = ''
      params[:opdrecord][:motordeficit] = ''
      params[:opdrecord][:vascualardeficit] = ''
    end

    @consultant_id = @appointment.consultant_id
    @user = User.find_by(id: @consultant_id)

    # Code for Follow Up from Advice Starts Here
    # advice_followup_appointment(record_params)
    # Code for Follow Up from Advice Ends Here

    # Code for management plan advice.
    @patient_notes = record_params[:advicemanagementplan]
    @patient_notes_to_rec = record_params[:advicemanagementplantoreceptionist]
    # @patient_notes_to_rec = record_params[:management_personal_cmt]
    if @patient_notes_to_rec == 'true'
      @newnote = PatientNote.new
      @newnote.organisation_id = @current_user.organisation_id.to_s
      @newnote.user_id = @current_user.id.to_s
      @newnote.patient_id = @patient.id.to_s
      @newnote.comment = @patient_notes
      @newnote.created_by = @opdrecord.consultant_name
      @newnote.save
    end
    # Code for management plan advice ends.
    @opdcomments = @opdrecord.opd_record_comments

    # This needs to be done before updating(anoop)
    unless @opdrecord.diagnosislist == [] || @opdrecord.diagnosislist.nil? || @opdrecord.diagnosislist == ''
      @opdrecord.diagnosislist.each do |diagnosislist|
        icd_diagnosis = eval(diagnosislist.icd_type).find_by(code: diagnosislist.icddiagnosiscode)

        if icd_diagnosis.present? && icd_diagnosis.has_laterality
          code = diagnosislist.icddiagnosiscode.first(-1)
          get_diagnosis_code(diagnosislist, code)
        else
          code = diagnosislist.icddiagnosiscode
        end
        recent_icd = RecentIcd.find_by(code: code)
        recent_icd.update(counter: recent_icd.counter.to_i - 1) if recent_icd.present?
      end
    end

    # To cancel the appointment whose intra referral is removed.
    if record_params[:intra_facility_referral_removed_id] != ''
      deleted_referral_ids = record_params[:intra_facility_referral_removed_id].to_s.split(',')
      deleted_referral_ids.each do |ref_id|
        app = Appointment.find_by(intra_referral_id: ref_id)
        if app.present?
          app.update(appointmentstatus: 89925002)
          Patients::Summary::TimelineWorker.call(event_name: 'OPD_APPOINTMENT', sub_event_name: 'CANCELLED', appointment_id: app.id, user_id: @current_user.id, user_name: @current_user.fullname, workflow: @current_facility.clinical_workflow)
        end
      end
    end

    # To remove from referral list if inter referral is deleted
    if record_params[:inter_facility_referral_removed_id] != ''
      deleted_referral_ids = record_params[:inter_facility_referral_removed_id].to_s.split(',')
      deleted_referral_ids.each do |ref_id|
        opd_referral = OpdReferral.find_by(inter_facility_referral_id: ref_id)
        opd_referral.update(is_deleted: true) if opd_referral.present?
      end
    end
    if @opdrecord.created_at.to_date == Date.current
      @opdrecord.personal_history_records.delete_all
      @opdrecord.speciality_history_records.delete_all
      @opdrecord.allergy_histories.delete_all
    end
    begin
      if @opdrecord.update(record_params)
        @optical_prescription = PatientOpticalPrescription.find_by(record_id: @opdrecord.id, patient_id: @patient.id)
        if @opdrecord.optical_store_id.present? && @optical_prescription.present?
          if @opdrecord.optical_store_id != @optical_prescription&.store_id
            @optical_prescription.update(store_id: @opdrecord.optical_store_id)
          end
        end
        if @opdrecord.treatmentmedication.present?
          @medication = 'true'
          @medication_groups = @opdrecord.treatmentmedication.group_by(&:status)
        CommunicationNotificationJob.perform_now('pharmacy_patient', @opdrecord.id.to_s, @opdrecord.class.to_s)
        CommunicationNotificationJob.perform_now('pharmacy_store', @opdrecord.id.to_s, @opdrecord.class.to_s)
        end

        if params[:delete_postop_records] == 'true' && @opdrecord.templatetype == 'postop'
          @opdrecord.postoprecord.destroy_all
        end
        if @opdrecord.created_at.to_date == Date.current
          if @opdrecord.specalityid == '309988001'
            if ['freeform', 'express', 'pmt', 'postop', 'refraction', 'ar_nct', 'vitalsign', 'biometry'].exclude?(@templatetype)
              Patients::HistoryService.call(@opdrecord, current_user, @patient.id.to_s) # call  the history services
            end
          else
            if ['freeform', 'express', 'trauma', 'pmt', 'postop', 'ar_nct', 'vitalsign', 'biometry'].exclude?(@templatetype)
              Patients::HistoryService.call(@opdrecord, current_user, @patient.id.to_s) # call  the history services
            end
          end
        end
        @opdrecord.record_histories.create(user_id: current_user.id, action: 'U', actiontime: Time.current, template_type: @templatetype)
        @opdrecordaudit = @opdrecord.opd_record_audits.create(user_id: session[:user_id], action: 'Update')
        @users = User.where(specialty_ids: @appointment.specialty_id, :facility_ids.in => [@appointment.facility_id])

        # For AppointmentPanel Soft Refresh
        @opd_templates = Global.send(@opdrecord.specalityname.to_s).send('opdtemplates')
        @appointment_opd_records = OpdRecord.where(appointmentid: @opdrecord.appointmentid.to_s)
        @old_records = PatientTimeline.where(patient_id: @patient.id.to_s, encountertype: 'OPD').not.where(appointment_id: @appointment.id.to_s).limit(3).order(encounterdate: :desc)
        @old_opd_records = OpdRecord.where(patientid: @patient.id.to_s, :appointmentid.ne => @appointment.id.to_s)
                                    .limit(3).order(created_at: :desc)
        @id = @opdrecord.advice_set_id
        if @id.present?
          @lcid_code = if @id.length == 2
                         'en'
                       else
                         AdviceSet.find_by(id: @opdrecord.advice_set_id).language_advice_subset.first.lcid_code
                       end
          @advice_set_language = if @id.length > 2
                                   AdviceSet.find_by(id: @id).language_advice_subset.pluck(:language, :lcid_code)
                                 else
                                   [['English', 'en'], ['Hindi', 'hi'], ['Bengali', 'bn'], ['Kannada', 'kn'],
                                    ['Tamil', 'ta'], ['Telugu', 'te'], ['Gujarati', 'gu']]
                                 end
          @language = [['English', 'en'], ['Hindi', 'hi'], ['Bengali', 'bn'], ['Kannada', 'kn'], ['Tamil', 'ta'],
                       ['Telugu', 'te'], ['Gujarati', 'gu']]
          if @id.present? && @opdrecord.treatmentmedication.present?
            @show_single_dropdown = true
            @combined_dropdown = if current_facility.country_id == 'VN_254'
                                   @advice_set_language & @language << ['Vietnamese', 'vi']
                                 elsif current_facility.country_id == 'KH_039'
                                   @advice_set_language & @language << ['Vietnamese', 'vi'] << ["Khmer","kh"] << ["Chinese","ch"]
                                  else
                                   @advice_set_language | @language
                                 end
          else
            @show_single_dropdown = false
          end
        else
          @lcid_code = ''
        end

        @case_sheet = CaseSheet.find_by(id: @opdrecord.case_sheet_id)

        # Code for Follow Up from Advice Starts Here
        advice_followup_appointment(record_params)
        # Code for Follow Up from Advice Ends Here
        @org_specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])

        rules_file

        # performed ophthal-investigations
        performed_case_opd(@opdrecord, @case_sheet)
        # EOF get opd performed investigations which are not yet stored in case-sheet
        # get_opd_histories

        respond_to do |format|
          format.js { render 'update', layout: false }
          format.html { render 'update', layout: 'mobile_layout' }
        end

        unless @opdrecord.diagnosislist == [] || @opdrecord.diagnosislist.nil? || @opdrecord.diagnosislist == ''
          @opdrecord.diagnosislist.each do |diagnosislist|
            icd_diagnosis = eval(diagnosislist.icd_type).find_by(code: diagnosislist.icddiagnosiscode)

            if icd_diagnosis.present? && icd_diagnosis.has_laterality
              code = diagnosislist.icddiagnosiscode.first(-1)
              icd_name, code = get_parent_icd_name(diagnosislist, code)
            else
              code = diagnosislist.icddiagnosiscode
              icd_name = diagnosislist.diagnosisoriginalname
            end
            save_recent_icd(code, icd_name, @consultant_id, diagnosislist.icd_type, diagnosislist.specialty_id, diagnosislist.template_id)
          end
        end

        Patients::Summary::TimelineWorker.call(event_name: 'OPD_RECORD', sub_event_name: 'UPDATED', opd_record_id: @opdrecord.id, user_id: @current_user.id, user_name: @current_user.fullname)
        if @new == true
          Patients::Summary::TimelineWorker.call(event_name: 'OPD_APPOINTMENT', sub_event_name: 'SCHEDULED', appointment_id: @new_appointment.id, user_id: @current_user.id, user_name: @current_user.fullname, workflow: @current_facility.clinical_workflow)
        elsif @edit == true
          Patients::Summary::TimelineWorker.call(event_name: 'OPD_APPOINTMENT', sub_event_name: 'RESCHEDULED', appointment_id: @followupappointment_id, user_id: @current_user.id, user_name: @current_user.fullname, workflow: @current_facility.clinical_workflow)
        end
        OpdRecordJob.perform_later(@opdrecord.id.to_s)
        DataForIpdJob.perform_later(@opdrecord.id.to_s)
        # Diagnosis Report Data Job
        MisJobs::Clinical::ExtractDiagnosesJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@opdrecord.id.to_s, "OPD", "opd_record_form")
        # Doctor Patient Referral Report Data Job
        MisJobs::Clinical::Opd::ExtractDoctorPatientReferralJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@opdrecord.id.to_s)
        MisJobs::Clinical::Opd::DeleteDoctorPatientReferralJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@opdrecord.id.to_s)

        # Procedure Data Job
        MisJobs::Clinical::PatientProcedureJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@appointment.case_sheet_id.to_s, @appointment.id.to_s, "appointment")
        # OrderJobs::AdvisedJob.perform_later(@case_sheet.id.to_s, current_user.id.to_s, current_facility.id.to_s)
        if @opdrecord.specalityid == "309988001"
          object_config = {}
          object_config["class_name"] = "opd_records"
          object_config["method_name"] = "update"
          mandatory = {}
          mandatory["opdrecord_id"] = @opdrecord.id.to_s
          mandatory["patient_id"] = @patient.id.to_s
          optional = {}
          others = {}
          others["patient_lasik_status"] = params[:patient][:lasik_eligible].to_bool
          ProcessInBackgroundJob.set(queue: :urgent, wait_until: 0).perform_later(object_config, mandatory, optional, others)
        end
      end
    rescue NoMethodError
      # This is for assign_attributes issue
      raise unless Rails.env.production?
    end
    get_opd_histories
  end

  def view_opd_summary
    @mode = params[:mode]
    @viewmode = params[:viewmode]
    @language_flag = false
    @current_user = current_user
    @current_facility = current_facility
    @opdrecord = OpdRecord.find_by(id: params[:opdrecordid])
    # @opdrecord.created_at.strftime('%d%m%Y')
    @case_sheet = CaseSheet.find_by(id: @opdrecord.try(:case_sheet_id))
    @patient = Patient.find(params[:patientid])
    @opdcomments = @opdrecord.try(:opd_record_comments)
    @appointment = Appointment.find_by(id: @opdrecord.try(:appointmentid))
    @current_appointment = Appointment.find_by(id: params[:current_appointment])
    @last_appointment = AppointmentListView.where(patient_id: @opdrecord.try(:patientid), :appointment_date.lt => Date.current, :current_state.nin => ['Deleted', 'Scheduled']).order(appointment_date: :desc)[0]
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@opdrecord.specalityid)
    @templatetype = params[:templatetype]
    @id = @opdrecord.try(:advice_set_id)
    if @opdrecord.try(:treatmentmedication).present?
      @medication = 'true'
      @medication_groups = @opdrecord.treatmentmedication.group_by(&:status)
    end

    if @id.present?
      if @id.length == 2
        @lcid_code = 'en'
      else
        advice_set = AdviceSet.find_by(id: @opdrecord.try(:advice_set_id))
        @lcid_code = advice_set.present? ? advice_set.language_advice_subset.first.lcid_code : 'en'
      end
      if @id.length > 2
        @find_advice_set = AdviceSet.find_by(id: @opdrecord.try(:advice_set_id))
        @advice_set_language = if @find_advice_set.present?
                                 @find_advice_set.language_advice_subset.pluck(:language, :lcid_code)
                               else
                                 [['']]
                               end
      else
        @advice_set_language = [['English', 'en'], ['Hindi', 'hi'], ['Bengali', 'bn'], ['Kannada', 'kn'],
                                ['Tamil', 'ta'], ['Telugu', 'te'], ['Gujarati', 'gu']]
      end
      @language = [['English', 'en'], ['Hindi', 'hi'], ['Bengali', 'bn'], ['Kannada', 'kn'], ['Tamil', 'ta'],
                   ['Telugu', 'te'], ['Gujarati', 'gu']]
      if @opdrecord.try(:advice_set_id).present? && @opdrecord.try(:treatmentmedication).present?
        @show_single_dropdown = true
        @combined_dropdown = if current_facility.country_id == 'VN_254'
                               @advice_set_language & @language << ['Vietnamese', 'vi']
                             elsif current_facility.country_id == 'KH_039'
                               @advice_set_language & @language << ['Vietnamese', 'vi'] << ["Khmer","kh"] << ["Chinese","ch"]
                             else
                               @advice_set_language | @language
                             end
      else
        @show_single_dropdown = false
      end
    else
      @lcid_code = ''
    end
    if @appointment.try(:facility_id).present?
      @facility_id = @appointment.facility_id
      @nabh_setting = NabhSetting.find_by(facility_id: @facility_id)
    else
      @facility_id = @current_facility.id
      @nabh_setting = NabhSetting.find_by(facility_id: @facility_id)
    end
    @users = User.where(specialty_ids: @appointment.specialty_id, :facility_ids.in => [@facility_id])
    rules_file
    # get opd performed investigations which are not yet stored in case-sheet

    # performed ophthal-investigations
    performed_case_opd(@opdrecord, @case_sheet)
    # EOF get opd performed investigations which are not yet stored in case-sheet
    get_opd_histories

    respond_to do |format|
      format.html { render 'opd_summary_mob.html.erb', layout: 'mobile_layout' }
      format.js { render 'view_opd_summary', layout: false }
    end
  end

  def replace_advice_set
    @opdrecord = OpdRecord.find_by(id: params[:opdrecord])
    @appointment = Appointment.find_by(id: @opdrecord.appointmentid)
    @patient = Patient.find_by(id: @opdrecord.patientid)
    @advice_language = params[:advice_language]
    @appointment = Appointment.find_by(id: @opdrecord.appointmentid)
    @language_name = Language.find_by(lcid_code: @advice_language)
    @patient.update(primary_language: @language_name&.name)
    respond_to do |format|
      format.js { render 'replace_advice_set', layout: false }
    end
  end

  def replace_medication_instruction
    @opdrecord = OpdRecord.find_by(id: params[:opdrecord])
    @patient = Patient.find_by(id: @opdrecord.patientid)
    @appointment = Appointment.find_by(id: @opdrecord.appointmentid)
    @templatetype = @opdrecord.templatetype
    @specality = @opdrecord.specalityname
    @advice_language = params[:advice_language]
    @language_name = Language.find_by(lcid_code: @advice_language)
    @patient.update(primary_language: @language_name&.name)
    respond_to do |format|
      format.js { render 'replace_medication_instruction', layout: false }
    end
  end

  def download_pdf_opd_record
    @opdrecord = OpdRecord.find_by(id: params[:opdrecordid])
    @case_sheet = CaseSheet.find_by(id: @opdrecord.case_sheet_id)
    @appointment = Appointment.find(params[:appointmentid])
    @opdrecordaudit = @opdrecord.opd_record_audits.create(user_id: session[:user_id], action: 'Download')
    @patient = Patient.find(params[:patientid])
    @speciality_folder_name = params[:specality]
    @templatetype = params[:templatetype]
    # performed investigations
    performed_case_opd(@opdrecord, @case_sheet)
    # EOF get opd performed investigations which are not yet stored in case-sheet
    filename = "OpdSummary_#{@patient.fullname}_#{Date.current.strftime('%d-%B-%Y')}"
    respond_to do |format|
      format.pdf { render template: "opd_records/#{@speciality_folder_name}_notes/download/opd_summary_download", pdf: filename.to_s, layout: 'pdfgen', disposition: 'inline', margin: { bottom: 30 } }
    end
  end

  def print_blank_opd_record
    if params[:appointmentid].present? 
      @appointment = Appointment.find_by(id: params[:appointmentid])
      @consultant = User.where(id: @appointment.consultant_id).first
    end
    @patient = Patient.find(params[:patientid])
    @speciality_folder_name = params[:specality]
    @templatetype = params[:templatetype]
    @organisation = current_user.organisation
    @height = @organisation.letter_head_customisations[:header_height]
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    @sub_referral = SubReferralType.find_by(id: @referral.try(:sub_referral_type_id))
    @template_fields = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id).custom_template_header_options[:opd_settings][:templates][0].select{ |key, value| value == true }
    @fields_names = OrganisationSettingsHelper.get_data('opd_templates', @template_fields).keys
    @poi = PatientOtherIdentifier.find_by(patient_id: @patient.id)
    @patient_identifier = PatientIdentifier.find_by(patient_id: @patient.id.to_s).try(:patient_org_id)
    # setting_service = PrintSettingService.new(current_facility_id, current_user.id, 'OPD')
    if params['print_setting'].present?  
      @print_setting = PrintSetting.find_by(id: params['print_setting'])
      @print_settings = []
      @print_settings[0] = {"header_height"=> @print_setting.try(:header_height), "footer_height"=> @print_setting.try(:footer_height), "right_margin"=> @print_setting.try(:right_margin), "left_margin"=> @print_setting.try(:left_margin)}
    else
      if params[:appointmentid].present?
        setting_service = PrintSettingService.new(current_facility_id, @appointment.consultant_id.to_s, 'OPD')
      else
        setting_service = PrintSettingService.new(current_facility_id, current_user.id, 'OPD')
      end

      @print_settings = setting_service.select_print_setting
      @logo = @print_settings[1]
    end

    filename = "#{@patient.fullname}_#{Date.current.strftime('%d-%B-%Y')}"
    respond_to do |format|
      format.pdf { render template: "opd_records/#{@speciality_folder_name}_notes/download/blank_opd_summary_download", pdf: filename.to_s, layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 0, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def print_opd_record
    @current_facility = current_facility
    @language_flag = params[:language_flag]
    @opdrecord = OpdRecord.find(params[:opdrecordid])
    @case_sheet = CaseSheet.find_by(id: @opdrecord.case_sheet_id)
    @appointment = Appointment.find(params[:appointmentid])
    opd_clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
    @patient_exit_time = opd_clinical_workflow&.end_time&.in_time_zone(current_facility.time_zone)
    @opdrecordaudit = @opdrecord.opd_record_audits.create(user_id: session[:user_id], action: 'Print')
    @patient = Patient.find(params[:patientid])
    @speciality_folder_name = params[:specality]
    @templatetype = params[:templatetype]
    @organisation = current_user.organisation
    @advice_language = params[:advice_language]
    @user = User.find(@opdrecord.userid)
    @opdrecord.record_histories.create(user_id: current_user.id, action: 'P', actiontime: Time.current, template_type: @templatetype)
    @height = @organisation.letter_head_customisations[:header_height]

    setting_service = PrintSettingService.new(current_facility_id, @appointment.consultant_id.to_s, 'OPD')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]

    filename = if @templatetype == 'ophthalmic_report'
                 "OphthalmicReport_#{@patient.fullname}_#{Date.current.strftime('%d-%B-%Y')}"
               else
                 "OpdSummary_#{@patient.fullname}_#{Date.current.strftime('%d-%B-%Y')}"
               end
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])

    if @opdrecord.treatmentmedication.present?
      @medication = 'true'
      @medication_groups = @opdrecord.treatmentmedication.group_by(&:status)
    end

    @translated_language ||= @translated_language

    # performed investigations
    performed_case_opd(@opdrecord, @case_sheet)
    # EOF get opd performed investigations which are not yet stored in case-sheet

    if @language_flag == 'true'
      respond_to do |format|
        # format.html {render "templates/#{@speciality_folder_name}/print/opd_summary_print", :layout => "print"}
        format.pdf { render template: "opd_records/#{@speciality_folder_name}_notes/download/opd_summary_language_download", pdf: filename.to_s, layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 0, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_f * 10, right: @print_setting.try(:right_margin).to_f * 10, top: @print_setting.try(:header_height).to_f * 10, bottom: @print_setting.try(:footer_height).to_f * 10 } }
      end
    else
      respond_to do |format|
        # format.html {render "templates/#{@speciality_folder_name}/print/opd_summary_print", :layout => "print"}
        format.pdf { render template: "opd_records/#{@speciality_folder_name}_notes/download/opd_summary_download", pdf: filename.to_s, layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 0, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_f * 10, right: @print_setting.try(:right_margin).to_f * 10, top: @print_setting.try(:header_height).to_f * 10, bottom: @print_setting.try(:footer_height).to_f * 10 } }
      end
    end

    # Patients::Summary::TimelineWorker.call({event_name: "OPD_RECORD", sub_event_name: "PRINTED", opd_record_id: @opdrecord.id, user_id: current_user.id, user_name: current_user.fullname })
  end

  def print_contactlens_prescription
    @opdrecord = OpdRecord.find(params[:opdrecordid])
    @appointment = Appointment.find(params[:appointmentid])
    @opdrecordaudit = @opdrecord.opd_record_audits.create(user_id: session[:user_id], action: 'Print')
    @patient = Patient.find(params[:patientid])
    @speciality_folder_name = params[:specality]
    @templatetype = params[:templatetype]
    @organisation = current_user.organisation
    @user = User.find(@opdrecord.userid)
    @flag = 'print'
    filename = "OpdSummary_#{@patient.fullname}_#{Date.current.strftime('%d-%B-%Y')}"
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'Optical')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    respond_to do |format|
      # format.html {render "templates/#{@specalityfoldername}/print/opd_summary_print", :layout => "print"}
      format.pdf { render template: "opd_records/#{@speciality_folder_name}_notes/download/contactlens_opd_summary_download", pdf: filename.to_s, layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 0, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_f * 10, right: @print_setting.try(:right_margin).to_f * 10, top: @print_setting.try(:header_height).to_f * 10, bottom: @print_setting.try(:footer_height).to_f * 10 } }
    end
  end

  def print_glass_prescription
    @opdrecord = OpdRecord.find_by(id: params[:opdrecordid])
    @appointment = Appointment.find_by(id: params[:appointmentid])
    @opdrecordaudit = @opdrecord.opd_record_audits.create(user_id: session[:user_id], action: 'Print')
    @patient = Patient.find(params[:patientid])
    @speciality_folder_name = params[:specality]
    @templatetype = params[:templatetype]
    @organisation = current_user.organisation
    @user = User.find_by(id: @opdrecord.userid)
    @flag = 'view'
    filename = "OpdSummary_#{@patient.fullname}_#{Date.current.strftime('%d-%B-%Y')}"
    setting_service = PrintSettingService.new(current_facility_id, @appointment.consultant_id.to_s, 'Optical')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    @optical_file_name = params[:flag].present? & params[:flag]&.include?('intermediate') ? 'glasses_intermediate_prescriptions' : 'glassesprescriptions'
    @optical_prescription = PatientOpticalPrescription.find_by(id: params[:prescription_id])

    respond_to do |format|
      # format.html {render "templates/#{@specalityfoldername}/print/opd_summary_print", :layout => "print"}
      format.pdf { render template: "opd_records/#{@speciality_folder_name}_notes/download/glasses_opd_summary_download", pdf: filename.to_s, layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 0, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_f * 10, right: @print_setting.try(:right_margin).to_f * 10, top: @print_setting.try(:header_height).to_f * 10, bottom: @print_setting.try(:footer_height).to_f * 10 } }
    end
  end

  def print_medication
    @language_flag = params[:language_flag]
    @opdrecord = OpdRecord.find_by(id: params[:opdrecordid])
    @appointment = Appointment.find(params[:appointmentid])
    @opdrecordaudit = @opdrecord.opd_record_audits.create(user_id: session[:user_id], action: 'Print')
    @patient = Patient.find(params[:patientid])
    @speciality_folder_name = params[:specality]
    @templatetype = params[:templatetype]
    @advice_language = params[:advice_language]
    @organisation = current_user.organisation
    @user = User.find(@opdrecord.userid)
    filename = "OpdSummary_#{@patient.fullname}_#{Date.current.strftime('%d-%B-%Y')}"
    setting_service = PrintSettingService.new(current_facility_id, @appointment.consultant_id.to_s, 'Pharmacy')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])
    if @opdrecord.treatmentmedication.present?
      @medication = 'true'
      @medication_groups = @opdrecord.treatmentmedication.group_by(&:status)
    end
    if @language_flag == 'true'
      respond_to do |format|
        format.pdf { render template: "opd_records/#{@speciality_folder_name}_notes/download/medication_opd_summary_language_download", pdf: filename.to_s, layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 0, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_f * 10, right: @print_setting.try(:right_margin).to_f * 10, top: @print_setting.try(:header_height).to_f * 10, bottom: @print_setting.try(:footer_height).to_f * 10 } }
      end
    else
      respond_to do |format|
        # format.html {render "templates/#{@speciality_folder_name}/print/opd_summary_print", :layout => "print"}
        format.pdf { render template: "opd_records/#{@speciality_folder_name}_notes/download/medication_opd_summary_download", pdf: filename.to_s, layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 0, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_f * 10, right: @print_setting.try(:right_margin).to_f * 10, top: @print_setting.try(:header_height).to_f * 10, bottom: @print_setting.try(:footer_height).to_f * 10 } }
      end
    end
  end

   def print_squint
    @opdrecord = OpdRecord.find_by(id: params[:opdrecordid])
    @appointment = Appointment.find(params[:appointmentid])
    @opdrecordaudit = @opdrecord.opd_record_audits.create(user_id: session[:user_id], action: 'Print')
    @patient = Patient.find(params[:patientid])
    @speciality_folder_name = params[:specality]
    @templatetype = params[:templatetype]
    @advice_language = params[:advice_language]
    @organisation = current_user.organisation
    @user = User.find(@opdrecord.userid)
    filename = "OpdSummary_#{@patient.fullname}_#{Date.current.strftime('%d-%B-%Y')}"
    setting_service = PrintSettingService.new(current_facility_id, @appointment.consultant_id.to_s, 'OPD')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])

    respond_to do |format|
      # format.html {render "templates/#{@speciality_folder_name}/print/opd_summary_print", :layout => "print"}
      format.pdf { render template: "opd_records/#{@speciality_folder_name}_notes/download/squint_opd_summary_download", pdf: filename.to_s, layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 0, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_f * 10, right: @print_setting.try(:right_margin).to_f * 10, top: @print_setting.try(:header_height).to_f * 10, bottom: @print_setting.try(:footer_height).to_f * 10 } }
    end
  end


  def print_prescription_tagline_form
    @department = params[:department]
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id)
  end

  def print_prescription_tagline_save
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id)
    @department = params[:department]
    if @department == 'optical'
      @facility_setting.update(optical_print_tagline: params[:facility_setting][:tagline])
    else
      @facility_setting.update(pharmacy_print_tagline: params[:facility_setting][:tagline])
    end
  end

  def add_comment_opd_record
    @opdrecord = OpdRecord.find(params[:opdrecordid])
    @comment = params[:opdrecordcomment][:comment]
    if @comment.present?
      @opdrecordcommentsave = @opdrecord.opd_record_comments.create(comment: params[:opdrecordcomment][:comment], user_id: session[:user_id], doctorname: current_user.fullname, commenttime: Time.current, commentdate: Date.current)
    end
    @opdcomments = @opdrecord.opd_record_comments
    respond_to do |format|
      format.js { render 'opd_records/add_comment_opd_record', layout: false }
    end
  end

  def delete_comment_opd_record
    @opdrecord = OpdRecord.find(params[:opdrecordid])
    @opdcomments = @opdrecord.opd_record_comments.find(params[:id]).try(:delete)
    @opdcomments = @opdrecord.opd_record_comments
    respond_to do |format|
      format.js { render 'opd_records/add_comment_opd_record', layout: false }
    end
  end

  def fill_medication_data
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] } << 'Add a text Box'
    @medication_set = MedicationKit.find_by(id: params[:ajax][:medicationkitid])
    if @medication_set.present? && @medication_set.try(:data) != 'null'
      @specialty = @medication_set.specialty_id
      @medication_kit_data = JSON.parse(@medication_set.data) if @medication_set.try(:data) != 'null'
    else
      head :ok
    end
  end

  def fill_ipd_medication_data
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] } << 'Add a text Box'
    @medication_set = MedicationKit.find_by(id: params[:ajax][:medicationkitid])
    if @medication_set.present? && @medication_set.try(:data) != 'null'
      @medication_kit_data = JSON.parse(@medication_set.data) if @medication_set.try(:data) != 'null'
    else
      head :ok
    end
  end

  def fill_nursing_medication_data
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] } << 'Add a text Box'
    @medication_set = MedicationKit.find(params[:ajax][:medicationkitid])
    if @medication_set.present? && @medication_set.try(:data) != 'null'
      @medication_kit_data = JSON.parse(@medication_set.data) if @medication_set.try(:data) != 'null'
    else
      head :ok
    end
  end

  def registry
    @patient = Patient.find(params[:patientid])
    @registrytype = params[:registrytype]
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def functional_score
    @patient = Patient.find(params[:patientid])
    respond_to do |format|
      format.js {}
    end
  end

  def annontatetrauma
    @traumaparams_limb = params[:traumaparams][:limb]
    @traumaparams_side = params[:traumaparams][:side]
    respond_to do |format|
      format.html { render layout: false }
    end
  end

  def saveannontatetrauma
    @annotatedfields = params[:traumaannotate]
    respond_to do |format|
      format.js { render 'saveannontatetrauma', layout: false }
    end
  end

  # Brakeman :: cannot find anywhere in the product, so commenting
  def populate_proceduretype
    @speciality_folder_name = params[:ajax][:speciality_folder_name]
    @regionname = params[:ajax][:templatetype]
    @procedures = params[:ajax][:procedures]
    @counter = params[:ajax][:counter]
    @proceduretypes = Array[]
  #   @proceduretypes = Global.send("#{@speciality_folder_name}#{@regionname}#{@procedures}").send(@procedures.to_s).map { |proceduretype| proceduretype.map.with_index { |procedurehash, procedureindex| [2, 3].include?(procedureindex) ? Hash[procedurehash.each_slice(2).to_a] : procedurehash[1] } }
    respond_to do |format|
      format.js { render 'populate_proceduretype', layout: false }
    end
  end

  # Brakeman :: cannot find anywhere in the product, so commenting
  def populate_side_approach_procedures
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(params[:ajax][:speciality_id])
    @specalityid = params[:ajax][:speciality_id].to_i
    @templatetype = params[:ajax][:templatetype]
    @regionid = params[:ajax][:regionid]
    @proceduresides = Array[]
    @procedureapproachs = Array[]
    @procedures = Array[]
    @proceduresubqualifiers = Array[]
    
  #   @proceduresides = Global.send("#{@speciality_folder_name}#{@templatetype}procedures").send('side').map(&:values)
  #   @procedureapproachs = Global.send("#{@speciality_folder_name}#{@templatetype}procedures").send('approach').map(&:values)
  #   @procedures = Global.send("#{@speciality_folder_name}#{@templatetype}procedures").send('procedures').map(&:values)
  #   @proceduresubqualifiers = Global.send("#{@speciality_folder_name}#{@templatetype}procedures").send('proceduresubqualifier').map(&:values)
    respond_to do |format|
      format.json { render 'templates/orthopedics/populate_side_approach_procedures', layout: false }
    end
  end

  # Brakeman :: cannot find anywhere in the product, so commenting
  def populate_procedurename
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(params[:ajax][:speciality_id])
    @specalityid = params[:ajax][:speciality_id].to_i
    @templatetype = params[:ajax][:templatetype]
    @proceduretype = params[:ajax][:proceduretype]
    @regionfilename = params[:ajax][:regionfilename]
    @procedurenames = Array[]
  #   if Global.send("#{@speciality_folder_name}#{@regionfilename}procedures").try(@proceduretype.to_sym)
  #     @procedurenames = Global.send("#{@speciality_folder_name}#{@regionfilename}procedures").send(@proceduretype.to_sym).map(&:values)
  #   end
    respond_to do |format|
      if !@procedurenames.empty?
        format.json { render json: @procedurenames }
      else
        format.json { render json: @procedurenames }
      end
    end
  end

  # Brakeman :: cannot find anywhere in the product, so commenting
  def populate_procedurequalifier
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(params[:ajax][:speciality_id])
    @specalityid = params[:ajax][:speciality_id].to_i
    @templatetype = params[:ajax][:templatetype]
    @procedurename = params[:ajax][:procedurename]
    @regionfilename = params[:ajax][:regionfilename]
    @procedurequalifiers = Array[]
  #   if Global.send("#{@speciality_folder_name}#{@templatetype}procedures").try(@procedurename.to_sym)
  #     @procedurequalifiers = Global.send("#{@speciality_folder_name}#{@templatetype}procedures").send(@procedurename.to_sym).map(&:values)
  #   end
    respond_to do |format|
      if !@procedurequalifiers.empty?
        format.json { render json: @procedurequalifiers }
      else
        format.json { render json: @procedurequalifiers }
      end
    end
  end

  def populate_radiology_investigations
    radiology_investigations = RadiologyInvestigationData.where(specialty_id: params[:ajax][:speciality_id].to_i, template_id: params[:ajax][:templatetype].to_i)

    @xrayinvestigations = radiology_investigations.where(:investigation_type_id.in => [Global.ehrcommon.xray.id]).order_by(investigation_id: :asc)
    @ctmriinvestigations = radiology_investigations.where(:investigation_type_id.in => [Global.ehrcommon.mri.id, Global.ehrcommon.ct.id]).order_by(investigation_id: :asc)

    respond_to do |format|
      format.json { render 'opd_records/orthopedics_notes/populate_radiology_investigations', layout: false }
    end
  end

  def populate_topicd_list
    topicd_name = params[:ajax][:topicd_name]
    topicd_list = Array[]
    topicddiagnosis = TopIcdDiagnosis.find_by(name: topicd_name)
    topicd_list = topicddiagnosis.try(:list)
    respond_to do |format|
      if !topicd_list.empty?
        format.json { render json: topicd_list }
      else
        format.json { render json: topicd_list }
      end
    end
  end

  def populate_toportho_icd_list
    topicd_name = params[:ajax][:topicd_name]
    topicd_list = Array[]
    topicddiagnosis = TopOrthoIcdDiagnosis.find_by(name: topicd_name)
    topicd_list = topicddiagnosis.try(:list)

    respond_to do |format|
      if !topicd_list.empty?
        format.json { render json: topicd_list }
      else
        format.json { render json: topicd_list }
      end
    end
  end

  def populate_ophthal_investigations
    @ophthal_model =  if params[:ophthal_model] == 'CustomOphthalInvestigation'
                        'CustomOphthalInvestigation'
                      elsif params[:ophthal_model] == 'OphthalmologyInvestigationData'
                        'OphthalmologyInvestigationData'
                      end
    if @ophthal_model == 'CustomOphthalInvestigation'
      ophthal_investigations = CustomOphthalInvestigation.where(region: params[:ajax][:eyearea], organisation_id: current_user.organisation_id.to_s, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id.to_s, level: 'facility' }], is_deleted: false).pluck(:investigation_name, :investigation_id).sort_by!{ |i| i[0].downcase }
    elsif params[:ajax][:eyearea] == 'all_region' and @ophthal_model.present?
      ophthal_investigations = @ophthal_model.to_s.constantize.pluck(:investigation_name, :investigation_id).sort_by!{ |i| i[0].downcase }
    elsif @ophthal_model.present?
      ophthal_investigations = @ophthal_model.to_s.constantize.where(region: params[:ajax][:eyearea]).pluck(:investigation_name, :investigation_id).sort_by!{ |i| i[0].downcase }
    end
    # end

    respond_to do |format|
      if !ophthal_investigations.empty?
        format.json { render json: ophthal_investigations }
      else
        format.json { render json: ophthal_investigations }
      end
    end
  end

  def populate_ophthalprocedures
    @current_user = current_user
    if params[:procedure_type] == 'common_procedures'
      procedures = CommonProcedure.where(region: params[:region], speciality_id: params[:speciality_id]).pluck(:code, :name).sort_by!{ |p| p[1].downcase }
    elsif params[:procedure_type] == 'custom_common_procedures'
      procedures = (CustomCommonProcedure.where(region: params[:region], speciality_id: params[:speciality_id], organisation_id: @current_user.organisation_id.to_s, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id.to_s, level: 'facility' }], is_deleted: false).pluck(:code, :name, :procedure_type) + SynonymCommonProcedure.where(region: params[:region], organisation_id: @current_user.organisation_id.to_s, is_deleted: false).pluck(:code, :name, :procedure_type)).sort_by!{ |p| p[1].downcase }
    else
      procedures = TranslatedCommonProcedure.where(region: params[:region], speciality_id: params[:speciality_id], organisation_id: @current_user.organisation_id.to_s, is_deleted: false).pluck(:code, :display_name, :procedure_type).sort_by!{ |p| p[1].downcase }
    end

    respond_to do |format|
      if !procedures.empty?
        format.json { render json: procedures }
      else
        format.json { render json: procedures }
      end
    end
  end

  def user_templates
    respond_to do |format|
      format.js { render layout: 'loggedin' }
      format.html { render layout: 'loggedin' }
    end
  end

  def add_appendages_diagram
    @eyeside = params[:ajax][:eyeside]
    @patient_id = params[:ajax][:patient_id]
    @diagramtype = params[:ajax][:diagram_type]
    @a = Base64.strict_encode64(File.open(Rails.root.join('app', 'assets', 'images', 'ophthal_annotations', "appendages_#{@eyeside}.png").to_path, 'rb').read)
    respond_to do |format|
      format.js { render 'opd_records/ophthalmology_notes/js/add_appendages_diagram', layout: false }
    end
  end

  def save_appendages_diagram
    @eyeside = params[:ajax][:eyeside]
    params[:ajax] = convert_data_uri_to_upload(params[:ajax])
    @tempasset = PatientSummaryAssetUpload.new(diagram_params)
    @tempasset['parent_folder_id'] = '560cc6f72b2e26135d000007'
    @tempasset['is_folder'] = 'N'
    @tempasset['name'] = params[:ajax][:diagram_type]
    @tempasset['reported_date'] = Date.current
    @tempasset['reported_time'] = Time.current
    @tempasset['user_id'] = current_user.id.to_s
    if @tempasset.save
      respond_to do |format|
        format.js { render 'opd_records/ophthalmology_notes/js/save_appendages_diagram', layout: false }
      end
    end
  end

  def edit_appendages_diagram
    @eyeside = params[:eyeside]
    @tempasset = PatientSummaryAssetUpload.find_by(id: params[:temp_asset_id])
    if @tempasset.present?
      @a = Base64.strict_encode64(read_file_remote(@tempasset.asset_path_url.to_s))
      respond_to do |format|
        format.js { render 'opd_records/ophthalmology_notes/js/add_appendages_diagram', layout: false }
      end
    else
      redirect_to opd_records_discard_appendages_diagram_path(temp_asset_id: params[:temp_asset_id],
                                                              eyeside: params[:eyeside])
    end
  end

  def discard_appendages_diagram
    @eyeside = params[:eyeside]
    @tempasset = PatientSummaryAssetUpload.find_by(id: params[:temp_asset_id])
    if @tempasset.present?
      @patient_id = @tempasset.patient_id
      @tempasset.remove_asset_path!
      @tempasset.delete
    end
    respond_to do |format|
      format.js { render 'opd_records/ophthalmology_notes/js/discard_appendages_diagram', layout: false }
    end
  end

  def add_lens_diagram
    @eyeside = params[:ajax][:eyeside]
    @diagramtype = params[:ajax][:diagram_type]
    @patient_id = params[:ajax][:patient_id]
    @a = Base64.strict_encode64(File.open(Rails.root.join('app', 'assets', 'images', 'ophthal_annotations', "lens_#{@eyeside}.png").to_path, 'rb').read)
    respond_to do |format|
      format.js { render 'opd_records/ophthalmology_notes/js/add_lens_diagram', layout: false }
    end
  end

  def save_lens_diagram
    @eyeside = params[:ajax][:eyeside]
    params[:ajax] = convert_data_uri_to_upload(params[:ajax])
    @tempasset = PatientSummaryAssetUpload.new(diagram_params)
    @tempasset['parent_folder_id'] = '560cc6f72b2e26135d000007'
    @tempasset['is_folder'] = 'N'
    @tempasset['name'] = params[:ajax][:diagram_type]
    @tempasset['reported_date'] = Date.current
    @tempasset['reported_time'] = Time.current
    @tempasset['user_id'] = current_user.id.to_s
    if @tempasset.save
      respond_to do |format|
        format.js { render 'opd_records/ophthalmology_notes/js/save_lens_diagram', layout: false }
      end
    end
  end

  def edit_lens_diagram
    @eyeside = params[:eyeside]
    @tempasset = PatientSummaryAssetUpload.find_by(id: params[:temp_asset_id])
    if @tempasset.present?
      @a = Base64.strict_encode64(read_file_remote(@tempasset.asset_path_url.to_s))
      respond_to do |format|
        format.js { render 'opd_records/ophthalmology_notes/js/add_lens_diagram', layout: false }
      end
    else
      redirect_to opd_records_discard_lens_diagram_path(temp_asset_id: params[:temp_asset_id],
                                                        eyeside: params[:eyeside])
    end
  end

  def discard_lens_diagram
    @eyeside = params[:eyeside]
    @tempasset = PatientSummaryAssetUpload.find_by(id: params[:temp_asset_id])
    if @tempasset.present?
      @patient_id = @tempasset.patient_id
      @tempasset.remove_asset_path!
      @tempasset.delete
    end
    respond_to do |format|
      format.js { render 'opd_records/ophthalmology_notes/js/discard_lens_diagram', layout: false }
    end
  end

  def add_fundus_diagram
    @eyeside = params[:ajax][:eyeside]
    @diagramtype = params[:ajax][:diagram_type]
    @patient_id = params[:ajax][:patient_id]
    @a = Base64.strict_encode64(File.open(Rails.root.join('app', 'assets', 'images', 'ophthal_annotations', "fundus_#{@eyeside}.png").to_path, 'rb').read)
    respond_to do |format|
      format.js { render 'opd_records/ophthalmology_notes/js/add_fundus_diagram', layout: false }
    end
  end

  def save_fundus_diagram
    @eyeside = params[:ajax][:eyeside]
    params[:ajax] = convert_data_uri_to_upload(params[:ajax])
    @tempasset = PatientSummaryAssetUpload.new(diagram_params)
    @tempasset['parent_folder_id'] = '560cc6f72b2e26135d000007'
    @tempasset['is_folder'] = 'N'
    @tempasset['name'] = params[:ajax][:diagram_type]
    @tempasset['reported_date'] = Date.current
    @tempasset['reported_time'] = Time.current
    @tempasset['user_id'] = current_user.id.to_s
    if @tempasset.save
      respond_to do |format|
        format.js { render 'opd_records/ophthalmology_notes/js/save_fundus_diagram', layout: false }
      end
    end
  end

  def edit_fundus_diagram
    @eyeside = params[:eyeside]
    @tempasset = PatientSummaryAssetUpload.find_by(id: params[:temp_asset_id])
    if @tempasset.present?
      @a = Base64.strict_encode64(read_file_remote(@tempasset.asset_path_url.to_s))
      respond_to do |format|
        format.js { render 'opd_records/ophthalmology_notes/js/add_fundus_diagram', layout: false }
      end
    else
      redirect_to opd_records_discard_fundus_diagram_path(temp_asset_id: params[:temp_asset_id],
                                                          eyeside: params[:eyeside])
    end
  end

  def discard_fundus_diagram
    @eyeside = params[:eyeside]
    @tempasset = PatientSummaryAssetUpload.find_by(id: params[:temp_asset_id])
    if @tempasset.present?
      @patient_id = @tempasset.patient_id
      @tempasset.remove_asset_path!
      @tempasset.delete
    end
    respond_to do |format|
      format.js { render 'opd_records/ophthalmology_notes/js/discard_fundus_diagram', layout: false }
    end
  end

  def add_cornea_diagram
    @eyeside = params[:ajax][:eyeside]
    @patient_id = params[:ajax][:patient_id]
    @diagramtype = params[:ajax][:diagram_type]
    @a = Base64.strict_encode64(File.open(Rails.root.join('app', 'assets', 'images', 'ophthal_annotations', "cornea_#{@eyeside}.png").to_path, 'rb').read)
    respond_to do |format|
      format.js { render 'opd_records/ophthalmology_notes/js/add_cornea_diagram', layout: false }
    end
  end

  def save_cornea_diagram
    @eyeside = params[:ajax][:eyeside]
    params[:ajax] = convert_data_uri_to_upload(params[:ajax])
    @tempasset = PatientSummaryAssetUpload.new(diagram_params)
    @tempasset['parent_folder_id'] = '560cc6f72b2e26135d000007'
    @tempasset['is_folder'] = 'N'
    @tempasset['name'] = params[:ajax][:diagram_type]
    @tempasset['reported_date'] = Date.current
    @tempasset['reported_time'] = Time.current
    @tempasset['user_id'] = current_user.id.to_s
    if @tempasset.save
      respond_to do |format|
        format.js { render 'opd_records/ophthalmology_notes/js/save_cornea_diagram', layout: false }
      end
    end
  end

  def edit_cornea_diagram
    @eyeside = params[:eyeside]
    @tempasset = PatientSummaryAssetUpload.find_by(id: params[:temp_asset_id])
    if @tempasset.present?
      @a = Base64.strict_encode64(read_file_remote(@tempasset.asset_path_url.to_s))
      respond_to do |format|
        format.js { render 'opd_records/ophthalmology_notes/js/add_cornea_diagram', layout: false }
      end
    else
      redirect_to opd_records_discard_cornea_diagram_path(temp_asset_id: params[:temp_asset_id],
                                                          eyeside: params[:eyeside])
    end
  end

  def discard_cornea_diagram
    @eyeside = params[:eyeside]
    @tempasset = PatientSummaryAssetUpload.find_by(id: params[:temp_asset_id])
    if @tempasset.present?
      @patient_id = @tempasset.patient_id
      @tempasset.remove_asset_path!
      @tempasset.delete
    end
    respond_to do |format|
      format.js { render 'opd_records/ophthalmology_notes/js/discard_cornea_diagram', layout: false }
    end
  end

  def view_opd_diagram
    @eyeside = params[:eyeside]
    @diagram_type = params[:diagram_type]
    @tempasset = OpdRecord.find_by(id: params[:temp_asset_id])
    # @image_url_full = @eyeside + '_' + @diagram_type + '_diagram_full'
    @image_url_full = PatientSummaryAssetUpload.find_by(id: @tempasset.send("#{@eyeside}_#{@diagram_type}_temp_asset_id")).try(:asset_path)
    # @image = eval('@tempasset.send(@image_url_full)')
    @image = @image_url_full.to_s
    respond_to do |format|
      format.js { render 'opd_records/ophthalmology_notes/view_opd_diagram', layout: false }
    end
  end

  def add_cornea_slit_diagram
    @eyeside = params[:ajax][:eyeside]
    @patient_id = params[:ajax][:patient_id]
    @diagramtype = params[:ajax][:diagram_type]
    # @a = Base64.strict_encode64(File.open(Rails.root.join('app', 'assets', 'images', 'ophthal_annotations', 'corneaslit.png').to_path, 'rb').read)
    @a = Base64.strict_encode64(File.open(Rails.root.join("app", "assets", "images", "ophthal_annotations", "corneaslit_#{@eyeside}.png").to_path, 'rb').read)
    respond_to do |format|
      format.js { render 'opd_records/ophthalmology_notes/js/add_cornea_slit_diagram', layout: false }
    end
  end

  def save_cornea_slit_diagram
    @eyeside = params[:ajax][:eyeside]
    params[:ajax] = convert_data_uri_to_upload(params[:ajax])
    @tempasset = PatientSummaryAssetUpload.new(diagram_params)
    @tempasset['parent_folder_id'] = '560cc6f72b2e26135d000007'
    @tempasset['is_folder'] = 'N'
    @tempasset['name'] = params[:ajax][:diagram_type]
    @tempasset['reported_date'] = Date.current
    @tempasset['reported_time'] = Time.current
    @tempasset['user_id'] = current_user.id.to_s
    if @tempasset.save
      respond_to do |format|
        format.js { render 'opd_records/ophthalmology_notes/js/save_cornea_slit_diagram', layout: false }
      end
    end
  end

  def edit_cornea_slit_diagram
    @eyeside = params[:eyeside]
    @tempasset = PatientSummaryAssetUpload.find_by(id: params[:temp_asset_id])
    if @tempasset.present?
      @a = Base64.strict_encode64(read_file_remote(@tempasset.asset_path_url.to_s))
      respond_to do |format|
        format.js { render 'opd_records/ophthalmology_notes/js/add_cornea_slit_diagram', layout: false }
      end
    else
      redirect_to opd_records_discard_cornea_slit_diagram_path(temp_asset_id: params[:temp_asset_id],
                                                               eyeside: params[:eyeside])
    end
  end

  def discard_cornea_slit_diagram
    @eyeside = params[:eyeside]
    @tempasset = PatientSummaryAssetUpload.find_by(id: params[:temp_asset_id])
    if @tempasset.present?
      @patient_id = @tempasset.patient_id
      @tempasset.remove_asset_path!
      @tempasset.delete
    end
    respond_to do |format|
      format.js { render 'opd_records/ophthalmology_notes/js/discard_cornea_slit_diagram', layout: false }
    end
  end

  def print_flag
    opdrecord = OpdRecord.find_by(id: params[:ajax][:opd_record_id])
    opdrecord.update_attribute(:"#{params[:ajax][:flag_name]}", params[:ajax][:flag_value])

    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  def sign_off
    @current_user = current_user
    @opdrecord = OpdRecord.find_by(id: params[:opd_record_id])
    @opdrecord.update(sign_off: params[:status])
    @templatetype = @opdrecord.templatetype

    if params[:status] == 'true'
      Patients::Summary::TimelineWorker.call(event_name: 'OPD_RECORD', sub_event_name: 'SIGNEDOFF', opd_record_id: @opdrecord.id, user_id: current_user.id, user_name: current_user.fullname)
      @opdrecord.record_histories.create(user_id: current_user.id, action: 'S', actiontime: Time.current, template_type: @templatetype)
    else
      Patients::Summary::TimelineWorker.call(event_name: 'OPD_RECORD', sub_event_name: 'UNDOSIGNEDOFF', opd_record_id: @opdrecord.id, user_id: current_user.id, user_name: current_user.fullname)
      @opdrecord.record_histories.create(user_id: current_user.id, action: 'US', actiontime: Time.current, template_type: @templatetype)
    end
    get_opd_histories
    respond_to do |format|
      format.js {}
    end
  end

  def saved_procedure_note
    @procedurenote = ProcedureNote.find_by(id: params[:ajax][:procedure_note_id])
    @proceduretextstring = @procedurenote.proceduretext.to_s.html_safe.to_s
    respond_to do |format|
      format.js { render 'templates/ipd/common/saved_procedure_note', layout: false }
    end
  end

  def new_note
    @procedurenote = ProcedureNote.new(proceduretext: params[:ajax][:proceduretext])
    respond_to do |format|
      format.html { render 'templates/ipd/common/new_note', layout: false }
    end
  end

  def save_note
    @current_user = current_user
    params[:procedurenote][:organisation_id] = @current_user.organisation_id.to_s
    params[:procedurenote][:user_id] = @current_user.id.to_s
    params[:procedurenote][:level] = 'user'
    params[:procedurenote][:facility_id] = current_facility.id.to_s

    @procedurenote = ProcedureNote.new(save_procedurenote_params)
    if @procedurenote.save
      @procedurenotes = ProcedureNote.where(:organisation_id => @current_user.organisation_id, is_active: true, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id, level: 'facility' }, { user_id: @current_user.id, level: 'user' }])
      respond_to do |format|
        format.js { render 'templates/ipd/common/save_note', layout: false }
      end
    else
      respond_to do |format|
        format.js { "notice = new PNotify({ title: 'Warning', text: 'Procedure Note can not be saved without Procedure Name, Please try pesisting the form with valid data', type: 'warning' }); notice.get().click(function(){ notice.remove() });" }
      end
    end
  end

  def reload_note
    @procedurenotes = ProcedureNote.where(:organisation_id => current_user.organisation_id, is_active: true, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id, level: 'facility' }, { user_id: current_user.id, level: 'user' }])
    respond_to do |format|
      format.js { render 'templates/ipd/common/save_note', layout: false }
    end
  end

  # OPD
  def add_medication
    @counter = params[:ajax][:counter]
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] } << 'Add a text Box'
    respond_to do |format|
      format.js { render 'add_medication', layout: false }
    end
  end

  def add_post_op_record
    @counter = params[:ajax][:counter]
    respond_to do |format|
      format.js { render 'add_post_op_record', layout: false }
    end
  end

  def setup_view_only_flag
    @flag = 'view'
  end

  def setup_print_only_flag
    @flag = 'print'
  end

  def optoreading
    @flag = 'view'
    @opdrecord = OpdRecord.find_by(id: params[:optoreadingid])
    @patient = Patient.find_by(id: params[:patientid])
    @current_user = current_user
    @current_facility = current_facility
    respond_to do |format|
      format.html { render 'opd_records/ophthalmology_notes/opd_partials/past_optometrist_reading', layout: false }
    end
  end

  def delete_clone_record
    @opdrecord = OpdRecord.find_by(id: params[:id])
    @patienttimeline = PatientTimeline.find_by(record_id: @opdrecord.try(:id))

    @opdrecord&.delete if @patienttimeline.nil?
    respond_to do |format|
      format.js { render 'opd_records/delete_clone_record', layout: false }
    end
  end

  def append_ophthal_investigation
    @row_count = params[:row_count]
    @oph_inv = OphthalmologyInvestigationData.find_by(investigation_id: params[:investigation_id])
    @current_user = current_user
    @current_facility = current_facility
    @consultant = User.find_by(id: params[:consultant_id])
    @consultant = @current_user if @consultant.nil?

    if @oph_inv.present?
      respond_to do |format|
        format.js { render 'opd_records/append_ophthal_investigation', layout: false }
      end
    else
      head :ok
    end
  end

  def append_laboratory_investigation
    @row_count = params[:row_count]
    @laboratory_investigation = LaboratoryInvestigationData.find_by(loinc_code: params[:loinc_code], facility_id: current_facility.id)

    if @laboratory_investigation.present?
      respond_to do |format|
        format.js { render 'opd_records/append_laboratory_investigation', layout: false }
      end
    else
      head :ok
    end
  end

  def append_custom_ophthal_investigation
    @row_count = params[:row_count]
    @custom_oph_inv = CustomOphthalInvestigation.find_by(investigation_id: params[:investigation_id])
    @current_user = current_user
    @current_facility = current_facility
    @consultant = User.find_by(id: params[:consultant_id])
    @consultant = @current_user if @consultant.nil?

    if @custom_oph_inv.present?
      respond_to do |format|
        format.js { render 'opd_records/append_custom_ophthal_investigation', layout: false }
      end
    else
      head :ok
    end
  end

  def append_laboratory_investigation
    @row_count = params[:row_count]
    @laboratory_investigation = LaboratoryInvestigationData.find_by(loinc_code: params[:loinc_code], facility_id: current_facility.id)
    @current_user = current_user
    @current_facility = current_facility
    @consultant = User.find_by(id: params[:consultant_id])
    @consultant = @current_user if @consultant.nil?

    if @laboratory_investigation.present?
      respond_to do |format|
        format.js { render 'opd_records/append_laboratory_investigation', layout: false }
      end
    else
      head :ok
    end
  end

  def append_custom_laboratory_investigation
    @row_count = params[:row_count]
    @laboratory_investigation = LaboratoryInvestigationData.find_by(loinc_code: params[:loinc_code], facility_id: current_facility.id)
    @current_user = current_user
    @current_facility = current_facility
    @consultant = User.find_by(id: params[:consultant_id])
    @consultant = @current_user if @consultant.nil?

    if @laboratory_investigation.present?
      respond_to do |format|
        format.js { render 'opd_records/append_laboratory_investigation', layout: false }
      end
    else
      head :ok
    end
  end

  def append_radiology_investigation
    @row_count = params[:row_count]
    @radiology_type = params[:radiology_type]
    @radiology_investigation = RadiologyInvestigationData.find_by(investigation_id: params[:investigation_id].to_i)
    @current_user = current_user
    @current_facility = current_facility
    @consultant = User.find_by(id: params[:consultant_id])
    @consultant = @current_user if @consultant.nil?

    if @radiology_investigation.present?
      respond_to do |format|
        format.js { render 'opd_records/append_radiology_investigation', layout: false }
      end
    else
      head :ok
    end
  end

  def append_custom_radiology_investigation
    @row_count = params[:row_count]
    @custom_radiology_investigation = CustomRadiologyInvestigation.find_by(investigation_id: params[:investigation_id])
    @current_user = current_user
    @current_facility = current_facility
    @consultant = User.find_by(id: params[:consultant_id])
    @consultant = @current_user if @consultant.nil?

    if @custom_radiology_investigation.present?
      respond_to do |format|
        format.js { render 'opd_records/append_custom_radiology_investigation', layout: false }
      end
    else
      head :ok
    end
  end

  def append_ophthal_set
    @ophthal_laboratory_set = OphthalLaboratorySet.find_by(id: params[:id])
    @current_user = current_user
    @current_facility = current_facility
    @consultant = User.find_by(id: params[:consultant_id])
    @consultant = @current_user if @consultant.nil?

    @data = (JSON.parse(@ophthal_laboratory_set.try(:data)) if @ophthal_laboratory_set.present?) || {}
  end

  def append_laboratory_set
    @laboratory_set = UsersLaboratoryList.find_by(id: params[:id].to_s)
    @laboratory_set = FacilityLaboratoryList.find_by(id: params[:id].to_s) if @laboratory_set.nil?
    @current_user = current_user
    @current_facility = current_facility
    @consultant = User.find_by(id: params[:consultant_id])
    @consultant = @current_user if @consultant.nil?

    @data = (JSON.parse(@laboratory_set.try(:data)) if @laboratory_set.present?) || {}
  end

  def append_radiology_set
    @radiology_laboratory_set = RadiologyLaboratorySet.find_by(id: params[:id])
    @current_user = current_user
    @current_facility = current_facility
    @consultant = User.find_by(id: params[:consultant_id])
    @consultant = @current_user if @consultant.nil?

    @data = (JSON.parse(@radiology_laboratory_set.try(:data)) if @radiology_laboratory_set.present?) || {}
  end

  def user_medication_history
    specialty_name = 'ophthalmology'
    @specialty = '309988001'
    meds_history(params[:patientid], specialty_name)
    respond_to do |format|
      format.js { render '/opd_records/user_medication_history' }
    end
  end

  def ortho_user_medication_history
    specialty_name = 'orthopedics'
    meds_history(params[:patientid], specialty_name)
    respond_to do |format|
      format.js { render '/opd_records/ortho_user_medication_history' }
    end
  end

  def fill_medication_history
    params.permit(:ajax)
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] } << 'Add a text Box'
    @medication_kit_data = []
    if params['ajax'] && params['ajax']['med_history']
      @specialty = params['ajax']['specialty']
      # params['ajax']['med_history'].to_h.each_value do |v|
      params['ajax']['med_history'].to_enum.to_h.each_value do |v|
        meds = PatientPrescription.find_by(id: v['id']).medications.find { |m| m[:position] == v['position'] }
        meds['status'] = v['status']
        meds['btn_status'] = v['status'] == 'C' ? 'btn-info' : 'btn-warning'
        meds['row_status'] = v['status'] == 'C' ? '' : 'linethrough'
        @medication_kit_data << meds
      end
    end
    @medication_kit_data && @specialty || (head :ok)
  end

  def fill_ortho_medication_history
    params.permit(:ajax)
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] } << 'Add a text Box'
    @medication_kit_data = []
    if params['ajax'] && params['ajax']['med_history']
      params['ajax']['med_history'].to_enum.to_h.each_value do |v|
        meds = PatientPrescription.find_by(id: v['id']).medications.find { |m| m[:position] == v['position'] }
        meds['status'] = v['status']
        meds['btn_status'] = v['status'] == 'C' ? 'btn-info' : 'btn-warning'
        meds['row_status'] = v['status'] == 'C' ? '' : 'linethrough'
        meds['id'] = v['id']
        @medication_kit_data << meds
      end
    end
    @medication_kit_data || (head :ok)
    # render json: @medication_kit_data.to_json
  end

  def show_provisional_diagnosis_history
    get_provisional_diagnosis_history(params[:casesheet_id])
    @provisional_diagnosis_history ||= { message: 'Provisional Diagnosis Not Found', count: 0 }
  end

  def prepare_mis_job
    Mis::ClinicalReportsHelper.prepare_mis_job(@appointment.id.to_s) if @appointment.present?
  end

  private

  def set_clone_opd_record
    opd_record = OpdRecord.find_by(id: @clone_record_id)
    @opdrecord = opd_record.clone
    @opdrecord.created_at = Time.current.utc
    @opdrecord.updated_at = Time.current.utc
    @opdrecord.record_type = 'clone'
    @opdrecord.record_histories.delete_all
    @opdrecord.appointmentid = @appointment.id

    if ['optometrist', 'refraction', 'nursing', 'vitalsign', 'ar_nct', 'biometry'].exclude?(@opdrecord.templatetype)
      @opdrecord.advice.followupappointment_id = nil
      @opdrecord.advice.opdfollowupdate = nil
      @opdrecord.procedure = nil
      @opdrecord.no_procedure_advised = nil
      @opdrecord.diagnosislist = nil
      @opdrecord.is_provisional_diagnosis = nil
      @opdrecord.provisional_diagnosis = nil
      @opdrecord.ophthalinvestigationlist = nil
      @opdrecord.addedlaboratoryinvestigationlist = nil
      @opdrecord.investigationlist = nil
      @opdrecord.no_investigation_advised = nil
      @opdrecord.advice.opdfollowuptimeframe = nil
    end

    #Vital Signs
    @opdrecord = OpdRecords::CloningService.unset_vital_signs(@opdrecord)

    #Anthropometry
    @opdrecord.anthropometry_height = nil
    @opdrecord.anthropometry_weight = nil
    @opdrecord.anthropometry_bmi = nil
    @opdrecord.vital_signs_comments = nil

    #IOP
    @opdrecord.r_intraocularpressure = @opdrecord.l_intraocularpressure = nil
    @opdrecord.no_left_iop_advised = @opdrecord.no_right_iop_advised = nil
    @opdrecord.r_intraocularpressure_time = @opdrecord.l_intraocularpressure_time = nil
    @opdrecord.r_iop_method = @opdrecord.l_iop_method = nil
    @opdrecord.r_intraocularpressure_comments = @opdrecord.l_intraocularpressure_comments = nil
    
    if current_facility.country_id != "KH_039" && @opdrecord.specalityid == "309988001"   
      if ['ar_nct','nursing','vision'].exclude?(@opdrecord.templatetype)
        if params[:opdrecord_clinical_details_assessment].to_i == 0
          @opdrecord = OpdRecords::CloningService.unset_clinical_details_assessment(@opdrecord)
        end
        
        if params[:opdrecord_medications].to_i == 0
          @opdrecord = OpdRecords::CloningService.unset_medications(@opdrecord)
        end

        if params[:opdrecord_vision].to_i == 0
          @opdrecord = OpdRecords::CloningService.unset_vision(@opdrecord)
        end
        
        if params[:opdrecord_examination].to_i == 0
          @opdrecord = OpdRecords::CloningService.unset_examination(@opdrecord)
        end
        
        if params[:opdrecord_glasses_prescription].to_i == 0
          @opdrecord = OpdRecords::CloningService.unset_glass_prescription_values(@opdrecord)
        end

        if params[:opdrecord_refraction].to_i == 0
          @opdrecord = OpdRecords::CloningService.unset_refraction_values(@opdrecord,params[:opdrecord_glasses_prescription].to_i,params[:opdrecord_vision].to_i)
          if current_facility.country_id == "VN_254"
            @opdrecord.chiefcomplaint_comments = nil
          end
        end
      end
    end
    @opdrecord.save
  end

  def current_organisations_setting
    @organisations_setting = OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id))
  end

  def save_recent_icd(code, icd_name, doctor_id, icd_type, specialty_id, template_id)
    @presencerecenticd = RecentIcd.find_by(code: code)

    if @presencerecenticd.nil?
      @recent_icd = RecentIcd.new(code: code, icd_type: icd_type, originalname: icd_name, doctor: doctor_id, counter: 1, specialty_id: specialty_id, template_id: template_id)
      @recent_icd.save!
    else
      counter = @presencerecenticd.counter + 1
      @presencerecenticd.update(counter: counter)
      @presencerecenticd.save
    end
  end

  def save_procedurenote_params
    params.require(:procedurenote).permit(:name, :proceduretext, :organisation_id, :user_id, :level, :facility_id)
  end

  def record_params
    params.require(:opdrecord).permit!
  end

  def diagram_params
    params.require(:ajax).permit(:asset_path, :diagram_type, :eyeside, :patient_id, :is_deleted)
  end

  # Split up a data uri
  def split_base64(uri_str)
    if uri_str =~ /^data:(.*?);(.*?),(.*)$/
      uri = {}
      uri[:type] = Regexp.last_match(1) # "image/gif"
      uri[:encoder] = Regexp.last_match(2) # "base64"
      uri[:data] = Regexp.last_match(3) # data string
      uri[:extension] = Regexp.last_match(1).split('/')[1] # "gif"
      uri
    end
  end

  # Convert data uri to uploaded file. Expects object hash, eg: params[:post]
  def convert_data_uri_to_upload(obj_hash)
    if obj_hash[:asset_path_data].try(:match, /^data:(.*?);(.*?),(.*)$/)
      image_data = split_base64(obj_hash[:asset_path_data])
      image_data_string = image_data[:data]
      image_data_binary = Base64.decode64(image_data_string)

      temp_img_file = Tempfile.new('data_uri-upload')
      temp_img_file.binmode
      temp_img_file << image_data_binary
      temp_img_file.rewind

      img_params = { filename: "data-uri-img.#{image_data[:extension]}", type: image_data[:type], tempfile: temp_img_file }
      uploaded_file = ActionDispatch::Http::UploadedFile.new(img_params)

      obj_hash[:asset_path] = uploaded_file
      obj_hash.delete(:asset_path_data)
    end

    obj_hash
  end

  def read_file_remote(url)
    uri = URI(url)
    data = Net::HTTP.get_response(uri)
    data.body
  end

  def history_params
    # params.require(:patient).permit!
  end

  def advice_followup_appointment(record_params)
    if record_params[:bookappointment] == 'true'
      if record_params[:advice_attributes][:opdfollowupdate] != '' && record_params[:advice_attributes][:opdfollowupdate].present?
        advice = @opdrecord.advice

        opdfollowupdate = advice.opdfollowupdate
        @followup_date_time = advice.opdfollowuptime

        if advice.followupappointment_id.nil? || advice.followupappointment_id == ''

          # For worst case below code will handle error -anoop
          record_params[:advice_attributes][:appointment_type_id] = advice.appointment_type_id if record_params[:advice_attributes][:appointment_type_id].blank?

          @new_appointment = Appointment.new(appointmentdate: opdfollowupdate, start_time: @followup_date_time, end_time: @followup_date_time + 10.minutes, patient_id: @patient.id, appointment_type_id: advice.appointment_type_id, consultant_id: @consultant_id, user_id: @current_user.id, facility_id: advice.appointment_facility, departmenttype: record_params[:encountertypeid], appointmentstatus: 416774000, display_id: CommonHelper.get_opd_record_identifier(@user), patient_name: @patient.fullname, organisation_id: @current_user.organisation_id, created_from: 'OpdRecord', case_sheet_id: @case_sheet.id, appointment_category_id: advice.appointment_category_id, specialty_id: advice.appointment_specialty_id, department_id: '485396012', appointmenttype: 'appointment')

          if @new_appointment.save
            @followupappointment_id = @new_appointment.id
            @temp_appointment = @new_appointment
            @case_sheet.add_to_set(appointment_ids: @new_appointment.id)

            if @current_user.try(:organisation_id).to_s == '57f1c8b7666d676c0c000002'
              ApiJobs::AppointmentDataJob.perform_later('create',@new_appointment.id.to_s, 'ideamed' )
            end
          else
            @followupappointment_id = ''
          end
          @new = true
        else
          @followupappointment_id = advice.followupappointment_id
          @followupappointment = Appointment.find_by(id: @followupappointment_id)

          unless @followupappointment.nil?
            record_params[:advice_attributes][:appointment_type_id] = advice.appointment_type_id if record_params[:advice_attributes][:appointment_type_id].blank?

            past_appointment_type_id = @followupappointment.appointment_type_id
            past_appointment_category_type_id = @followupappointment.appointment_category_id
            past_appointment_facility = @followupappointment.facility_id
            past_appointment_specialty = @followupappointment.specialty_id
            past_appointment_date = @followupappointment.appointmentdate

            @new_appointment = @followupappointment.update(appointmentdate: opdfollowupdate, start_time: @followup_date_time, end_time: @followup_date_time + 10.minutes, facility_id: advice.appointment_facility, specialty_id: advice.appointment_specialty_id, appointment_type_id: advice.appointment_type_id, consultant_id: advice.appointment_doctor, appointment_category_id: advice.appointment_category_id, case_sheet_id: @case_sheet.id)

            if @current_user.try(:organisation_id).to_s == '57f1c8b7666d676c0c000002'
              ApiJobs::AppointmentDataJob.perform_later('update',@followupappointment.id.to_s, 'ideamed' )
            end

            # call appointment_type service update for analytics
            Analytics::Appointment::UpdateService.update_appointment_type_count(@followupappointment.id, past_appointment_type_id, past_appointment_facility, past_appointment_specialty, past_appointment_date)
            Analytics::Appointment::UpdateService.update_appointment_category_type_count(@followupappointment.id, past_appointment_category_type_id, past_appointment_facility, past_appointment_specialty, past_appointment_date)
          end

          @followup_workflow = OpdClinicalWorkflow.find_by(appointment_id: @followupappointment_id.to_s)
          @followup_workflow.update(appointmentdate: opdfollowupdate, facility_id: advice.appointment_facility, specialty_id: advice.appointment_specialty_id) if @followup_workflow.present?

          @edit = true
        end
      end

      record_params[:advice_attributes][:followupappointment_id] = @followupappointment_id
      @opdrecord.advice.update(record_params[:advice_attributes])
    end
  end

  def get_parent_icd_name(diagnosislist, code)
    if code.present?
      parent_icd = eval(diagnosislist.icd_type).find_by(code: code)
      if parent_icd.present?
        icd_name = parent_icd.originalname
      else
        code = code.first(-1)
        get_parent_icd_name(diagnosislist, code)
      end
    end

    [icd_name, code]
  end

  def get_diagnosis_code(diagnosislist, code)
    if code.present?
      icd_diagnosis = eval(diagnosislist.icd_type).find_by(code: code)
      if icd_diagnosis.present?
        code = code
      else
        code = code.first(-1)
        get_diagnosis_code(diagnosislist, code)
      end
    end

    code
  end

  def print_settings
    organisation_id = current_user.organisation_id.to_s
    facility_id = current_facility.id.to_s
    @print_settings = PrintSetting.print_options(organisation_id, facility_id, ['485396012'])
  end

  def meds_history(patient_id, specality_name)
    @patient = Patient.find_by(id: patient_id)
    @patient_prescriptions = PatientPrescription.where(reg_hosp_ids: current_user.organisation_id.to_s, patient_id: @patient.id.to_s, is_deleted: false, specalityname: specality_name).desc(:updated_at).to_a
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] }
  end

  def rules_file
    @rules_file = TemplatesHelper.defined_rules_files(@speciality_folder_name, @templatetype) rescue nil
    @cloneable_rules_file = TemplatesHelper.cloneable_rules_files(@speciality_folder_name, @templatetype) rescue nil
  end

  def inventry_store
    @pharmacy_stores_array = Inventory::Store.where(facility_id: current_facility&.id, is_active: true,
                                                    department_id: '284748001', is_disable: false).pluck(:name, :id)
    @optical_stores_array = Inventory::Store.where(facility_id: current_facility&.id, is_active: true,
                                                   department_id: '50121007', is_disable: false).pluck(:name, :id)
  end

  def performed_case_opd(opd_record, opd_case_sheet)
    # opthal investigations
    # @performed_ophthal = opd_case_sheet.ophthal_investigations.where(is_performed: true, record_id: opd_record.id.to_s)
    @performed_opd_ophthal = opd_record.ophthalinvestigationlist.where(is_performed: true)
    # EOF opthal investigations

    # laboratory investigations
    # @performed_laboratory = opd_case_sheet.laboratory_investigations.where(is_performed: true, record_id: opd_record.id.to_s)
    @performed_opd_laboratory = opd_record.addedlaboratoryinvestigationlist.where(is_performed: true)
    # EOF laboratory investigations

    # radiology investigations
    # @performed_radiology = opd_case_sheet.radiology_investigations.where(is_performed: true, record_id: opd_record.id.to_s)
    @performed_opd_radiology = opd_record.investigationlist.where(is_performed: true)
    # EOF radiology investigations
  end

  def params_for_diagnosis_job(options)
    #puts "ABC:- #{options[:opdrecord][:diagnosislist_attributes].to_h}"
    data = {}
    data["from_department"] = "OPD"
    data["from_department_id"] = 440655000
    data["diagnoses"] = options[:opdrecord][:diagnosislist_attributes].to_h
    data["provisional_diagnosis"] = options[:opdrecord][:provisional_diagnosis]
    data["diagnosiscomments"] = options[:opdrecord][:diagnosiscomments]
    data["patient_id"] = options[:opdrecord][:patientid]
    data["specality_id"] = options[:opdrecord][:specalityid]
    data["specality_name"] = options[:opdrecord][:specalityname]
    data["case_sheet_id"] = options[:opdrecord][:case_sheet_id]
    data["primary_model_id"] = options[:opdrecord][:opdrecordid]
    data["primary_model_name"] = "OpdRecord"
    data["created_from_form_id"] = 111
    data["created_from_form_name"] = "OPDRECORDFORM"
    return data
  end

  def disabled_stores
    @disabled_pharmacy = Inventory::Store.find_by(id: @opdrecord.pharmacy_store_id, is_disable: true)
    @disabled_optical = Inventory::Store.find_by(id: @opdrecord.optical_store_id, is_disable: true)
    @pharmacy_stores_array << [ @disabled_pharmacy.name, @disabled_pharmacy.id] if @disabled_pharmacy.present?
    if @disabled_optical.present? && @optical_prescription.present?
      @optical_stores_array << [ @disabled_optical.name, @disabled_optical.id ]
    end
    if @opdrecord.optical_store_id.blank? && @optical_stores_array.size > 0
      @optical_stores_array << ['', '']
    end
  end

  def get_opd_histories
    @opd_histories = @opdrecord.record_histories.where(:template_type => @templatetype)
  end

end
