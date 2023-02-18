# 2  Metrics/AbcSize
# 2  Metrics/CyclomaticComplexity
# 2  Metrics/MethodLength
# 1  Metrics/ClassLength
# 1  Metrics/PerceivedComplexity
# --
# 8  Total
class PatientSummaryTimelinesController < ApplicationController
  layout 'loggedin'

  before_action :authorize_webview_session, only: [:index]
  before_action :authorize
  before_action :patient, only: [:index, :filter_main_content, :filter_timeline, :filter_uploads,
                                 :filter_investigations, :appointment_list_clone_record,
                                 :opd_invoices, :ipd_invoices, :show_more_timeline]
  before_action :print_settings, only: [:index, :filter_main_content, :show_more_timeline, :filter_timeline]
  before_action :occupation_name, only: [:index]
  before_action :set_organisation_setting, only: [:index, :filter_main_content, :filter_timeline, :show_more_timeline]

  def index
    @mode = params[:mode]
    # Redis for Storing Back History // request.format used to avoid REDIS Creation on Page Refresh
    key = "patient_summary_back_btn:#{current_user.id}"
    Redis::Master.new.set(key, params.to_json)
    Redis::Master.new.expireat(key, ((Date.current + 1).to_time + 2.hours).to_i)

    @back_params = JSON.parse(Redis::Master.new.get("patient_summary_back_btn:#{current_user.id}"))

    patient_asset = @patient.patientassets
    @patient_asset = patient_asset.count > 0 ? patient_asset.all[-1].asset_path_url : 'placeholder.png'

    initial_referral_types = PatientReferralType.includes(:referral_type, :sub_referral_type)
                                                .where(patient_id: @patient&.id, is_deleted: false)
                                                .order(created_at: :asc)
    @initial_referral_type = initial_referral_types[0]

    active_admission
    ipd_record = Inpatient::IpdRecord.find_by(admission_id: @admission_list_view.try(:admission_id))
    @pre_admission_note = ipd_record&.admission_note

    if current_user.role_ids.include? 158965000
      facility_id = current_facility.id

      @user_notes_templates = UserNotesTemplate.where(
        organisation_id: current_user.organisation_id, :specialty_id.in => current_user.specialty_ids,
        is_deleted: false,
        '$or' => [{ level: 'organisation' }, { facility_id: facility_id, level: 'facility' },
                  { user_id: current_user.id, level: 'user' }]
      ).order(level: :desc)
      @patient_certificates = UserNote.where(patient_id: @patient.id)
    end
    @patientid = @patient.id
    @adverse_events = AdverseEvent.where(patient_id: @patientid)
    @patient_note = PatientNote.where(patient_id: @patientid).order(created_at: :desc).limit(5)

    @counsellor_note = CounsellorNote.where(patient_id: params[:patient_id]).order(created_at: :desc).limit(5)

    @patient_card_enabled = @organisation_setting&.patient_card_enabled

    skipcount = 0

    @filter = @back_params['filter']
    if current_user.role_ids.any? { |ele| [2822900478, 159282002, 41904004].include?(ele) } # technician users
      get_content_query('Investigations')
    elsif current_user.role_ids.include?(46255001)
      get_content_query('Medications')
    elsif current_user.role_ids.include?(387619007)
      get_content_query('Optical')
    elsif current_user.role_ids.include?(573021946)
      get_content_query('Uploads')
    else
      @nabh_setting = NabhSetting.find_by(facility_id: current_facility.id)
      get_content_query( PatientSummaryHelpers::OutpatientHelper.default_active_tab(current_user).titleize )
      @patient_summary_timeline = PatientSummaryTimeline.collection.aggregate(timeline_query_params(nil, skipcount))
    end

    @org_specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])

    if @mode != 'tabview'
      # render index file
    else
      respond_to do |format|
        format.html { render 'patient_summary_timeline_index', layout: 'mobile_layout' }
      end
    end
  end

  def show_more_timeline
    @mode = params[:mode]
    @filter = params[:filter]
    if @filter == 'All' || @filter == 'Admission'
      active_admission
      @nabh_setting = NabhSetting.find_by(facility_id: current_facility.id)
    end
    @past_encounter_date = Date.parse(params[:past_encounter_date])
    skipcount = params[:timeline_data_count].to_i
    @patient_summary_timeline = PatientSummaryTimeline.collection.aggregate(timeline_query_params(@filter, skipcount))
  end

  def filter_main_content
    @mode = params[:mode]
    @filter = params[:filter]
    @title = params[:title]
    @investigation_state = params[:investigation_state]
    active_admission if @title == 'Timeline' && (@filter == 'All' || @filter == 'Admission')
    get_content_query(@title)
  end

  def filter_timeline
    @mode = params[:mode]
    @filter = params[:filter]
    skipcount = 0
    active_admission if @filter == 'All' || @filter == 'Admission'
    @patient_summary_timeline = PatientSummaryTimeline.collection.aggregate(timeline_query_params(@filter, skipcount))
  end

  def query_sub_event_timeline
    @mode = params[:mode]
    @query_id = params[:query_id]
    @id = params[:id]
    @patient_summary_timeline = PatientSummaryTimeline.where(query: { _id: @query_id }, :id.ne => @id)
                                                      .order(encounter_date_time: :desc)
    respond_to do |format|
      format.js { render '/patient_summary_timelines/timeline_details/query_sub_event_timeline.js.erb' }
    end
  end

  def filter_uploads
    @mode = params[:mode]
    @filter = params[:filter]
    @patient_uploads = PatientSummaryAssetUpload.where(upload_query_params(@filter)).order(reported_date: :desc)
  end

  def filter_investigations
    @mode = params[:mode]
    @filter = params[:filter]
    @investigation_state = params[:investigation_state]
    @counsellors = GetUsers.workflow_users_dropdown(current_facility.id, current_facility.specialty_ids, 499992366)

    @patient_investigation = Investigation::InvestigationDetail.where(investigation_query_params(@filter))
                                                               .order(advised_at: :desc)
    return unless @investigation_state.to_s.present?

    @patient_investigation = @patient_investigation.where(state: @investigation_state)
  end

  def opd_templates
    @appointment = Appointment.find_by(id: params[:appointment_id])
    @specialty_folder_name = TemplatesHelper.get_speciality_folder_name(@appointment.specialty_id)
    @mode = params[:mode]

    @organisations_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    return unless @organisations_setting.disable_opd_templates

    @enabled_templates = OpdRecordsHelper.enabled_templates(
      @organisations_setting, @appointment.patient_id, @appointment.appointmentdate, @appointment.specialty_id
    )
  end

  def ipd_templates
    @admission = Admission.find_by(id: params[:admission_id])
    ipd_record = Inpatient::IpdRecord.find_by(admission_id: @admission.id.to_s)
    @specialty_folder_name = TemplatesHelper.get_speciality_folder_name(@admission.specialty_id)
    @clinical_note = ipd_record.clinical_note
    @operative_notes = ipd_record.operative_notes
    @discharge_note = ipd_record.discharge_note
    @ward_notes = ipd_record.ward_notes
    @assessment = PatientAssessment.find_by(admission_id: @admission.id)
    @nursingrecords = NursingRecord.where(admission_id: @admission.id)
    @ot_check = OtChecklist.where(admission_id: @admission.id)
  end

  def appointment_list_clone_record
    @empty = 0
    @template_type = params[:template_type]
    @opd_record = OpdRecord.find_by(id: params[:opd_record_id])
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@opd_record.specalityid)
    @mode = params[:mode]
    @appointments = AppointmentListView.where(patient_id: @patient.id,
                                              :current_state.nin => ['Scheduled', 'Completed', 'Deleted'],
                                              :appointment_id.ne => @opd_record.appointmentid)
                                       .order(appointment_date: :desc)

    @organisations_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
  end

  def opd_invoices
    @appointment = Appointment.find_by(id: params[:appointment_id])
    @invoice_templates = InvoiceTemplate.where(facility_id: current_facility.id, version: 'v21.0')
    @opd_invoices = Invoice::Opd.where(patient_id: @patient.id, is_deleted: false).sort(created_at: :desc)
  end

  def ipd_invoices
    @admission = Admission.find_by(id: params[:admission_id])
    @tpa = @admission
    @invoice_templates = InvoiceTemplate.where(facility_id: current_facility.id, version: 'v21.0')
    @inv_ins_id = Invoice::Insurance.find_by(admission_id: @admission.id)
    @copayment = Copayment.find_by(admission_id: @admission.id)
    if @admission.insurance_status == 'Not Insured'
      @ipd_invoices = Invoice::Ipd.where(patient_id: @patient.id, is_deleted: false).sort(created_at: :desc)
    else
      @ins_invoice = Invoice::Insurance.where(patient_id: @patient.id)
    end
  end

  private

  def set_organisation_setting
    @organisation_setting = OrganisationsSetting.find_by(organisation_id: current_facility.organisation_id)
  end

  def patient
    @patient = Patient.find_by(id: params[:patient_id])
    @calculate_age = @patient.calculate_age
  end

  def occupation_name
    occupation_list = Global.send('occupation_list').send('sets')
    occupation_hash = occupation_list.pluck(:snomedcode, :name).to_h
    @occupation_name = occupation_hash[@patient&.occupation]
  end

  def active_admission
    state_array = ['Discharged', 'Deleted']
    @admission_list_view = AdmissionListView.find_by(patient_id: @patient.id, :current_state.nin => state_array)
    @completed_ots = OtSchedule.where(admission_id: @admission_list_view&.admission_id, operation_done: true)
    @all_ots = OtSchedule.where(admission_id: @admission_list_view&.admission_id, is_deleted: false)

    # Admission
    @admission_list_views = AdmissionListView.where(patient_id: @patient.id, :current_state.nin => state_array)
  end

  def get_content_query(title)
    case title
    when 'Timeline'
      @nabh_setting = NabhSetting.find_by(facility_id: current_facility.id)
      @patient_summary_timeline = PatientSummaryTimeline.collection.aggregate(timeline_query_params(@filter, 0))
    when 'Uploads'
      @filter = '560cc6f72b2e26135d000004' if current_user.role_ids.include? 573021946

      @patient_uploads = PatientSummaryAssetUpload.where(upload_query_params(@filter)).order(reported_date: :desc)
    when 'Bills'
      types = ['Invoice::Opd', 'Invoice::Ipd']
      @invoices = Invoice.where(:_type.in => types, patient_id: @patient.id.to_s, is_deleted: false)
      @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id)
    when 'Medications'
      @opd_record = OpdRecord.where(patientid: @patient.id.to_s).order(created_at: :desc)
      @admission = @patient.admissions.last
      if @admission
        ipd_record = Inpatient::IpdRecord.find_by(admission_id: @admission.id.to_s)
        @discharge_note = ipd_record&.discharge_note
      end
    when 'Optical'
      @optical = PatientOpticalPrescription.where(patient_id: @patient.id.to_s).order(created_at: :desc)
    when 'Investigations'
      @counsellors = User.where(facility_ids: current_facility.id, is_active: true, role_ids: 499992366)

      @patient_investigation = Investigation::InvestigationDetail.where(investigation_query_params(@filter))
                                                                 .order(advised_at: :desc)

      @patient_investigation.where(state: @investigation_state) if @investigation_state.to_s.present?
    when 'Procedures'
      @opd_record = OpdRecord.where(patientid: @patient.id.to_s).order(created_at: :desc)
    end
  end

  def timeline_query_params(filter, skipcount)
    if !filter.present? || filter == 'All'
      match1 = { '$match': { patient_id: @patient.id, is_deleted: false, is_active: true } }
    elsif filter == 'Legacy'
      legacy = { '$in': ['LegacyOpdClinicalNote', 'LegacyIpdClinicalNote'] }
      match1 = { '$match': { patient_id: @patient.id, is_deleted: false, is_active: true, primary_model: legacy } }
    elsif filter == 'Inpatient::IpdRecord'
      filter = { '$in': ['Inpatient::IpdRecord', 'Inpatient::NursingRecord'] }
      match1 = { '$match': { patient_id: @patient.id, is_deleted: false, is_active: true, primary_model: filter } }
    else
      match1 = { '$match': { patient_id: @patient.id, is_deleted: false, is_active: true, primary_model: filter } }
    end
    sort1 = { '$sort': { is_active: -1, encounter_date_time: -1 } }
    group1 = { '$group': { '_id': '$query._id', pst: { '$push': '$$ROOT' } } }
    sort2 = { '$sort': { 'pst.encounter_date_time': -1 } }

    skip = skipcount.to_i * 10

    limitquery = { '$limit': skip + 10 }
    skipquery = { '$skip': skip }

    [match1, sort1, group1, sort2, limitquery, skipquery]
  end

  def upload_query_params(filter = nil)
    if !filter.present? || filter == 'All'
      { patient_id: @patient.id, is_deleted: false }
    else
      { patient_id: @patient.id, parent_folder_id: filter, is_deleted: false }
    end
  end

  def investigation_query_params(filter = nil)
    if !filter.present? || filter == 'All'
      { patient_id: @patient.id, is_deleted: false }
    elsif filter == 'ophthal'
      { patient_id: @patient.id, is_deleted: false, _type: 'Investigation::Ophthal' }
    elsif filter == 'laboratory'
      { patient_id: @patient.id, is_deleted: false, _type: 'Investigation::Laboratory' }
    elsif filter == 'radiology'
      { patient_id: @patient.id, is_deleted: false, _type: 'Investigation::Radiology' }
    end
  end

  def print_settings
    organisation_id = current_user.organisation_id.to_s
    facility_id = current_facility.id.to_s
    department_ids = ['485396012', '486546481']

    @print_settings = PrintSetting.print_options(organisation_id, facility_id, department_ids)
  end
end
