# 6   Metrics/AbcSize
# 6   Metrics/MethodLength
# 5   Metrics/CyclomaticComplexity
# 5   Metrics/PerceivedComplexity
# 1   Metrics/ClassLength
# --
# 23  Total
class InpatientsController < ApplicationController
  layout 'loggedin'

  before_action :authorize
  before_action :authorize_onboard
  before_action :ipd_clinical_workflow, only: [:admission_management, :admission_list, :admission_details,
                                               :ot_management, :ot_list, :ot_details]
  before_action :initial_params, only: [:admission_management, :admission_scheduler, :ot_management, :ot_scheduler]
  before_action :admission_list_params, only: [:admission_list]
  before_action :ot_list_params, only: [:ot_list]
  before_action :details_view_params, only: [:admission_details, :ot_details]
  before_action :ward_details_params, only: [:ward_details]
  before_action :occupation_name, only: [:admission_details, :ot_details]

  def admission_management; end

  def admission_list
    respond_to do |format|
      format.js { render 'inpatients/admission/sidebar_summary' }
    end
  end

  def admission_scheduler; end

  def admission_calendar_data
    doctor_id = params[:doctor_id]
    start_date = Date.parse(params[:start])
    date_range = start_date..(Date.parse(params[:end]) - 1)

    options = { facility_id: current_facility.id, :current_state.ne => 'Deleted',
                '$or' => [{ admission_date: date_range },
                          { discharge_date: date_range }] }

    options = options.merge(admitting_doctor_id: doctor_id) unless doctor_id == 'all' || doctor_id.blank?

    @admission_list = AdmissionListView.where(options)

    respond_to do |format|
      format.json { render 'inpatients/admission/admission_calendar_data' }
    end
  end

  def admission_details
    respond_to do |format|
      format.js { render 'inpatients/admission/admission_details' } # List
      format.html { render 'inpatients/admission/admission_details', layout: false } # Calendar
    end
  end

  def replace_medicine_language
    @ipdrecord = Inpatient::IpdRecord.find_by(id: params[:ipdrecord])
    @discharge_note = @ipdrecord.discharge_note
    @operative_note = @ipdrecord.operative_notes[0]
    @advice_language = params[:advice_language]

    @print_settings = PrintSetting.print_options(current_user.organisation_id.to_s, current_facility.id.to_s,
                                                 ['486546481', '284748001'])
  end

  def replace_advice_language
    @ipdrecord = Inpatient::IpdRecord.find_by(id: params[:ipdrecord])
    @operative_note = @ipdrecord.operative_notes.find_by(id: params[:operative_note_id])
    @advice_language = params[:advice_language]
  end

  def ot_management; end

  def ot_list
    respond_to do |format|
      format.js { render 'inpatients/ot/sidebar_summary' }
    end
  end

  def ot_scheduler; end

  def ot_calendar_data
    doctor_id = params[:doctor_id]
    date_range = Date.parse(params[:start])..(Date.parse(params[:end]) - 1)

    options = { facility_id: current_facility.id, ot_date: date_range }
    options = options.merge(operating_doctor_id: doctor_id) unless doctor_id == 'all' || doctor_id.blank?

    @ot_list = OtListView.where(options).sort(ottime: :desc)

    respond_to do |format|
      format.json { render 'inpatients/ot/ot_calendar_data' }
    end
  end

  def ot_details
    respond_to do |format|
      format.js { render 'inpatients/ot/ot_details' } # List
      format.html { render 'inpatients/ot/ot_details', layout: false } # Calendar
    end
  end

  def ward_management
    @wards = Ward.includes(:rooms).where(facility_id: current_facility.id.to_s)
  end

  def ot_summary
    options = { facility_id: current_facility.id.to_s, :theatre_number.nin => [nil, ''] }

    options = options.merge(theatre_number: params[:ot_name]) if params[:ot_name].present?
    options = if params[:status].present?
                options.merge(current_state: params[:status])
              else
                options.merge(:current_state.ne => 'Deleted')
              end
    options = if params[:ot_date].present?
                options.merge(ot_date: Date.parse(params[:ot_date]))
              else
                options.merge(ot_date: Date.current)
              end
    options = options.merge(specialty_id: params[:specialty]) if params[:specialty].present?
    options = options.merge(patient_gender: params[:patient_gender]) if params[:patient_gender].present?
    options = options.merge(operating_doctor_id: params[:surgeon_name]) if params[:surgeon_name].present?

    age_year = params[:age_years]
    if age_year.present?
      if age_year.to_i > 0
        age = "#{age_year.to_i} Years"
        options = options.merge(patient_age: /^#{age}/i)
      else
        options = options.merge(patient_age: /month/i)
      end
    end

    ot_list_views = OtListView.where(options)
    @ot_list_views = ot_list_views.group_by(&:theatre_number)
    @ot_ids = ot_list_views.pluck(:ot_id)

    case_sheet_procedures
  end

  def ot_summary_filter
    ot_list_view = OtListView.where(facility_id: current_facility.id.to_s, :theatre_number.nin => [nil, ''],
                                    :current_state.ne => 'Deleted')
    @ot_rooms = ot_list_view.pluck(:theatre_number, :theatre_name).uniq
    @all_status = ot_list_view.pluck(:current_state).uniq
    @specialties = Specialty.where(:id.in => current_facility.specialty_ids).pluck(:id, :name)
    @surgeon_name = User.where(facility_ids: current_facility.id.to_s, role_ids: 158965000).pluck(:fullname, :id)
  end

  def ot_summary_details
    @ot_list_views = OtListView.where(theatre_number: params[:id], ot_date: Date.current,
                                      :current_state.ne => 'Deleted')
    @ot_ids = @ot_list_views.pluck(:ot_id)

    case_sheet_procedures
  end

  def print_ot_details
    @ot_list_views = OtListView.where(theatre_number: params[:id], ot_date: Date.current,
                                      :current_state.ne => 'Deleted')
    @ot_ids = @ot_list_views.pluck(:ot_id)

    case_sheet_procedures

    respond_to do |format|
      format.pdf do
        render template: 'inpatients/print_ot_details', pdf: 'OT Summary', layout: 'pdfgen.html.erb',
               viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true,
               show_as_html: params[:debug].present?, orientation: 'Landscape',
               header: { spacing: 4 }, footer: { spacing: 10 },
               margin: { left: 10, right: 10, top: 10, bottom: 10 }
      end
    end
  end

  def download_ot_details
    @ot_list_views = OtListView.where(theatre_number: params[:id], ot_date: Date.current,
                                      :current_state.ne => 'Deleted')
    @ot_ids = @ot_list_views.pluck(:ot_id)

    case_sheet_procedures

    respond_to do |format|
      format.xls {}
    end
  end

  def ward_details
    respond_to do |format|
      format.html { render 'inpatients/ward/ward_details', layout: false }
    end
  end

  private

  def initial_params
    @current_user = current_user
    @current_date = params[:current_date].present? ? Date.parse(params[:current_date]) : Date.current

    specialty_ids = if current_user.role_ids.include?(573021946)
                      current_facility.specialty_ids
                    else
                      @current_user.specialty_ids & current_facility.specialty_ids
                    end
    @available_specialties = Specialty.where(:id.in => specialty_ids)
    @selected_specialty = params[:specialty_id] || 'all_specialties'
    specialty_ids = @selected_specialty == 'all_specialties' ? @available_specialties.pluck(:id) : [@selected_specialty]
    facility_id = current_facility.id.to_s

    if @clinical_workflow && params[:action] == 'admission_management'
      dropdown_roles = [['159561009', 'receptionist'], ['106292003', 'nurse'], ['158965000', 'doctor'],
                        ['499992366', 'counsellor'], ['573021946', 'tpa']]
      user_roles = User.where(facility_ids: facility_id).pluck(:role_ids).flatten.uniq
      @users = {}
      dropdown_roles.each do |role|
        if user_roles.include?(role[0].to_i)
          @users[role[1]] = GetUsers.workflow_users_dropdown(facility_id, specialty_ids, role[0])
        end
      end
    else
      @users = { 'doctor' => GetUsers.workflow_users_dropdown(facility_id, specialty_ids, '158965000') }
    end

    @active_user = params[:active_user] || (@clinical_workflow ? @current_user.id.to_s : 'all')

    @active_tab = if params[:action] == 'ot_management'
                    params[:active_tab] || 'All'
                  else
                    params[:active_tab] || (@clinical_workflow ? 'MyQueue' : 'Admitted')
                  end
    @admission_id = params[:admission_id]
    @ot_id = params[:ot_id]
    @users_list = params[:users_list] || 'in'

    if params[:action] == 'ot_management'
      @ot_rooms = OtRoom.where(facility_id: facility_id, :specialty_id.in => specialty_ids, is_deleted: false)
      @selected_ot_room = @ot_rooms.find_by(id: params[:ot_rooms_dropdown_id])&.name || 'All OTs'
      @ot_rooms_hash =  @ot_rooms.map { |otroom| { id: otroom.id.to_s, name: otroom.name } }
    end

    @wards = Ward.where(facility_id: facility_id)
  end

  def admission_list_params
    @current_date = params[:current_date].present? ? Date.parse(params[:current_date]) : Date.current
    @active_user = params[:active_user] || @current_user.id.to_s
    specialty_ids = if current_user.role_ids.include?(573021946)
                      current_facility.specialty_ids
                    else
                      current_user.specialty_ids & current_facility.specialty_ids
                    end
    @available_specialties = Specialty.where(:id.in => specialty_ids)

    specialty_id = if params[:specialty_id] == 'all_specialties'
                     @available_specialties.pluck(:id)
                   else
                     [params[:specialty_id]]
                   end

    # Load all concerned Admissions
    @current_facility = current_facility
    @scheduled_count = @current_facility.admission_schedule_list_length
    admission_date = if @current_date == Date.current
                       @scheduled_count.days.ago.to_date..Date.current
                     else
                       @current_date
                     end

    options = { facility_id: @current_facility.id.to_s, :specialty_id.in => specialty_id,
                '$or' => [
                  { current_state: 'Admitted' },
                  { current_state: 'Scheduled', admission_date: admission_date },
                  { current_state: 'Discharged', discharge_date: @current_date }
                ] }
    if ['all', nil].exclude?(@active_user) && !@clinical_workflow
      options = options.merge(admitting_doctor_id: @active_user)
    end

    @admission_list = AdmissionListView.where(options).order(admission_date: :desc)

    get_patient_params(@admission_list.pluck(:patient_id))

    if @clinical_workflow
      @my_queue_list = if @active_user == 'all'
                         @admission_list.where.not(sm_state: 'scheduled')
                       else
                         @admission_list.where(user_id: @active_user).where.not(sm_state: 'scheduled')
                       end
    end

    # Bifercate List per tab
    @scheduled_list = @admission_list.where(current_state: 'Scheduled')
    @admitted_list = @admission_list.where(current_state: 'Admitted')
    @current_admitted_list = @admission_list.where(current_state: 'Admitted', admission_date: @current_date)
    @discharged_list = @admission_list.where(current_state: 'Discharged').order(discharge_date: :desc)

    # Get active admission & tab
    if @admission_list.find_by(admission_id: params[:admission_id]).nil?
      @admission_id = @scheduled_list[0].admission_id.to_s if @scheduled_list.count > 0
    else
      @admission_id = params[:admission_id].to_s
    end

    @active_tab = params[:active_tab].present? ? params[:active_tab] : 'Admitted'
    @users_list = params[:users_list]
  end

  def ot_list_params
    @current_date = params[:current_date].present? ? Date.parse(params[:current_date]) : Date.current
    @active_user = params[:active_user] || @current_user.id.to_s
    specialty_ids = if current_user.role_ids.include?(573021946)
                      current_facility.specialty_ids
                    else
                      current_user.specialty_ids & current_facility.specialty_ids
                    end
    @available_specialties = Specialty.where(:id.in => specialty_ids)

    specialty = params[:specialty_id] == 'all_specialties' ? @available_specialties.pluck(:id) : [params[:specialty_id]]
    options = { facility_id: current_facility.id.to_s, :specialty_id.in => specialty,
                ot_date: @current_date, :current_state.ne => 'Deleted' }

    options = options.merge(operating_doctor_id: @active_user) if ['all', nil].exclude?(@active_user)

    if params[:ot_rooms_dropdown_id].present? && params[:ot_rooms_dropdown_id] != 'All OTs'
      options = options.merge(theatre_number: params[:ot_rooms_dropdown_id])
    end

    @ot_list = OtListView.where(options)

    get_patient_params(@ot_list.pluck(:patient_id))

    # Bifercate List per tab
    @all_list = @ot_list.order(ot_time: :asc)
    @scheduled_list = @ot_list.where(current_state: 'Scheduled').order(ot_time: :asc)
    @admitted_list = @ot_list.where(current_state: 'Admitted').order(ot_time: :asc)
    @engaged_list = @ot_list.where(current_state: 'Engaged').order(ot_time: :asc)
    @completed_list = @ot_list.where(current_state: 'Completed').order(ot_time: :asc)

    # Get active ot & tab
    if @ot_list.find_by(ot_id: params[:ot_id]).nil?
      @ot_id = @admitted_list[0].ot_id.to_s if @admitted_list.count > 0
    else
      @ot_id = params[:ot_id].to_s
    end
    @active_tab = params[:active_tab] || 'All'
    @users_list = params[:users_list]

    @ot_rooms = OtRoom.where(facility_id: current_facility.id, :specialty_id.in => specialty_ids, is_deleted: false)
    @ot_rooms_hash = @ot_rooms.map { |otroom| { id: otroom.id.to_s, name: otroom.name } }
  end

  def details_view_params
    @current_user = current_user
    @current_date = params[:current_date]
    if params[:admission_id]
      admission_id = params[:admission_id]
      admission_options = { id: admission_id }
    else
      @ot = OtSchedule.find_by(id: params[:ot_id])
      return if @ot.is_deleted

      admission_id = @ot.admission_id
      admission_options = if admission_id
                            { id: admission_id }
                          else
                            { patient_id: @ot.patient_id, isdischarged: false, is_deleted: false }
                          end
      @ot_room = OtRoom.find_by(id: @ot.theatreno)
      @doctor = User.find_by(id: @ot.surgeonname)
    end

    @admission = Admission.find_by(admission_options)
    return if @admission&.is_deleted

    @patient = Patient.find_by(id: @admission&.patient_id || @ot&.patient_id)
    @patientid = @patient.id
    @referral = PatientReferralType.find_by(patient_id: @patient.id)
    # Admission
    @admission_list_views = AdmissionListView.where(
      patient_id: @patient.id, :current_state.nin => ['Discharged', 'Deleted']
    )

    @existing_admission = Admission.find_by(
      :id.ne => @admission&.id, patient_id: @patient.id, isdischarged: false, is_deleted: false, patient_arrived: true
    )

    # PatientDetails
    organisation_setting = OrganisationsSetting.find_by(organisation_id: current_facility.organisation_id)
    @patient_card_enabled = organisation_setting.try(:patient_card_enabled)
    @calculate_age = @patient.calculate_age
    @initial_referral_type = PatientReferralType.includes(:referral_type, :sub_referral_type)
                                                .where(patient_id: @patient.try(:id), is_deleted: false)
                                                .order(created_at: :asc)[0]

    # CaseSheet
    @case_sheet = CaseSheet.find_by(id: @admission&.case_sheet_id || @ot&.case_sheet_id)

    # OtList
    options = { patient_id: @patient.id.to_s, is_deleted: false }
    options = options.merge(admission_id: @admission&.id) if params[:action] == 'admission_details'
    @ot_schedules = OtSchedule.where(options)
    @ot_list_views = OtListView.where(:ot_id.in => @ot_schedules.pluck(:id))
                               .map { |olv| { ot_id: olv.ot_id, state: olv.current_state } }

    # Patient Note
    @patient_note = PatientNote.where(patient_id: @patient.id).order(created_at: :desc).limit(5)

    if admission_id
      specialty_id = @admission&.specialty_id

      @engaged_time = []
      @engage_ots = @admission.ot_schedules.where(is_engaged: true)
      @engage_ots.each do |engaged|
        @engaged_time << engaged.ottime.strftime('%I:%M %p on %b %d,%Y')
      end
      @completed_ots = @admission.ot_schedules.where(operation_done: true)

      # Admission Actions
      @admission_list_view = AdmissionListView.find_by(admission_id: @admission.id)
      @completed_ots = @admission.ot_schedules.where(operation_done: true)

      # Workflow
      if @clinical_workflow
        # specialty_id = @admission.specialty_id
        @dropdown_users = UsersDropdownHelper.create_ipd(specialty_id, current_facility.id)
        # @dropdown_users = UsersDropdownHelper.create(specialty_id, current_user.id, current_facility.id, 'ipd')
        @state_transitions = @admission_list_view.admission_state_transitions
        @transition_users = User.where(:id.in => @state_transitions.pluck(:user_id))
                                .map { |user| { id: user.id, name: user.fullname, role_ids: user.role_ids } }
      end

      # Finances
      if current_facility.show_finances
        @patient_invoices = Invoice.where(:_type.in => ['Invoice::Opd', 'Invoice::Ipd'], patient_id: @patient.id.to_s, is_deleted: false)
        @invoices = Invoice.where(admission_id: @admission.id.to_s)
        @invoice_templates = InvoiceTemplate.where(facility_id: current_facility.id, department_id: '486546481',
                                                   specialty_id: specialty_id, version: 'v21.0', is_active: true)
        @past_invoices = Invoice::Ipd.where(patient_id: @patient.id)
        @advance_payments = AdvancePayment.where(patient_id: @patient.id, is_deleted: false,
                                                 :department_id.nin => ['50121007', '284748001'])
        @refund_payments = RefundPayment.where(patient_id: @patient.id, is_deleted: false,
                                               :department_id.nin => ['50121007', '284748001'])
      end
 
      # AdmissionDetails
      @tpa_workflow = TpaInsuranceWorkflow.find_by(admission_id: @admission.id)
      @custom_consents = CustomConsent.where(organisation_id: current_user.organisation_id)
      @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: @admission.id)
      @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@admission.try(:specialty_id))
      @clinical_note = @ipdrecord.try(:clinical_note)
      @operative_note = @ipdrecord.try(:operative_notes)
      @discharge_note = @ipdrecord.try(:discharge_note)
      @ward_notes = @ipdrecord.try(:ward_notes)
      @assessment = PatientAssessment.find_by(admission_id: @admission.id)
      @nursingrecords = NursingRecord.where(admission_id: @admission.id)
      @ot_check = OtChecklist.where(admission_id: @admission.id)
      @counsellor_records = CounsellorRecord.where(case_sheet_id: @case_sheet.id.to_s).order(created_at: :desc)
      # Insurance Details
      @courier_save = Inpatient::Insurance::Courier.find_by(admission_id: @admission.id)
      @insurance_assets = PatientSummaryAssetUpload.where(parent_folder_id: '560cc6f72b2e26135d000004',
                                                          patient_id: @admission.patient.id, is_deleted: false)

      # Adverse Events
      @adverse_events = AdverseEvent.where(patient_id: @patient.id)
      @inventory_stores = Inventory::Store.where(facility_id: current_facility_id, is_active: true, department_id: '384748001', is_disable: false)
      @bill_of_material = Inpatient::BillOfMaterial.where(facility_id: current_facility_id, admission_id: @admission.id,
                                                          patient_id: @admission.patient.id, is_canceled: false)
    else
      # OT Details w/o Admission
      @admission_case_sheet = @admission.try(:case_sheet)
    end
  end

  def ward_details_params
    @room = Room.find_by(id: params[:room_id])

    admissions = Admission.where(facility_id: current_facility.id.to_s, isdischarged: false, is_deleted: false)
    @admission_fields = admissions.map do |admission|
      { id: admission.id.to_s, patient_id: admission.patient_id.to_s, doctor: admission.doctor.to_s,
        room_id: admission.room_id.to_s, bed_id: admission.bed_id.to_s, admission_date: admission.admissiondate,
        specialty_id: admission.specialty_id }
    end

    patients = PatientSearch.where(:patient_id.in => @admission_fields.map { |admission| admission[:patient_id] })
    @patient_fields = patients.map do |patient|
      { id: patient.patient_id.to_s, patient_name: patient.patient_name,
        patient_identifier_id: patient.patient_identifier_id, mr_no: patient.mr_no }
    end

    users = User.where(:id.in => @admission_fields.map { |admission| admission[:doctor] })
    @user_fields = users.map { |user| { id: user.id.to_s, fullname: user.fullname } }

    admission_ids = @admission_fields.map { |admission| admission[:id] }
    ward_notes = Inpatient::IpdRecord.where(:admission_id.in => admission_ids, :ward_notes.ne => [])
    @ward_notes_count = ward_notes.pluck(:admission).map(&:to_s).group_by(&:itself).transform_values(&:count)
  end

  def occupation_name
    occupation_list = Global.send('occupation_list').send('sets')
    occupation_hash = occupation_list.pluck(:snomedcode, :name).to_h
    @occupation_name = occupation_hash[@patient&.occupation]
  end

  def get_patient_params(patient_ids)
    patients = Patient.where(:id.in => patient_ids)
    @patient_fields = patients.map do |patient|
      age_year, age_month = patient.calculate_age(true)
      title_content = ''
      title_content += 'One Eyed' if patient.one_eyed == 'Yes'
      age_in_months = (age_year.to_i * 12) + age_month.to_i
      if age_year.present? && (49...960).exclude?(age_in_months)
        title_content += ' | ' if patient.one_eyed == 'Yes'
        title_content += age_year < 4 ? 'Baby' : 'Old Age'
      end
      bang = !title_content.empty?
      { id: patient.id, bang: bang, title: title_content }
    end
  end

  def case_sheet_procedures
    if @ot_ids.count > 0
      organisation_id = current_user.organisation_id
      @case_sheets = CaseSheet.where(organisation_id: organisation_id, :ot_schedule_ids.in => @ot_ids.map(&:to_s))
                              .map { |cs| { ot_schedule_ids: cs.ot_schedule_ids, procedures: cs.procedures } }
    else
      @case_sheets = {}
    end
  end

  def ipd_clinical_workflow
    @clinical_workflow = current_facility.ipd_clinical_workflow
  end
end
