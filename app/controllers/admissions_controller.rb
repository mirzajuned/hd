# 40  Metrics/LineLength
# 12  Metrics/AbcSize
# 7   Metrics/BlockNesting
# 7   Metrics/MethodLength
# 6   Naming/AccessorMethodName
# 6   Style/GuardClause
# 4   Metrics/CyclomaticComplexity
# 4   Metrics/PerceivedComplexity
# 1   Metrics/ClassLength
# --
# 87  Total
class AdmissionsController < ApplicationController
  before_action :authorize
  before_action :find_admission, only: [:edit, :update, :destroy, :patient_arrived, :cancel_discharge,
                                        :mark_not_arrived, :assign_bed, :unassign_bed, :save_bed, :reschedule,
                                        :update_ready_state]
  before_action :print_params, only: [:print_admission_list, :print_scheduled_list, :print_admitted_list,
                                      :print_discharged_list]
  before_action :find_patient, only: [:new]
  before_action :get_admission_form_values, only: [:edit]
  before_action :occupation_name, only: [:new]

  def new
    @current_insurances = PatientInsurance.where(patient_id: @patient.id)
    @patient_type = PatientType.where(is_active: true, organisation_id: current_user.organisation_id).pluck(:label, :id)

    @scheduled_ots = OtSchedule.where(patient_id: @patient.id.to_s, is_deleted: false, admission_id: nil)
    @admission = Admission.new
    get_admission_form_values

    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id, contact_group_type: 'tpa')
    @tpa_contact = @contact_groups.find_by(name: 'TPA')
    @insurance_contact = @contact_groups.find_by(name: 'Insurance')

    @contacts = Contact.where(is_deleted: false, organisation_id: current_user.organisation_id)
    @tpa_contacts = @contacts.where(contact_group_id: @tpa_contact.try(:id))
    @insurance_contacts = @contacts.where(contact_group_id: @insurance_contact.try(:id))

    @organisation_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)

    @case_sheet = CaseSheet.find_by(id: params[:case_sheet_id])
    @case_sheets = CaseSheet.where(patient_id: params[:patient_id], specialty_id: @selected_specialty)
    @occupation_list = Global.send('occupation_list').send('sets').pluck(:name, :snomedcode)
  end

  def create
    # Create/Update Patient
    if params[:admission][:doctor].present? && params[:admission][:specialty_id].present?
      if params[:admission][:patient_id].present?
        @patient = Patients::UpdateService.call(params[:admission][:patient_id], params, current_user) # Call Patient UpdateService
      else
        @patient = Patients::CreateService.call(params, current_user, current_facility) # Call Patient CreateService
      end

      @calculate_age = @patient.calculate_age
      # Create New Admission
      if @patient
        @admission = Admission::CreateService.call(params[:admission], current_user, @patient, false)

        if @admission.valid?
          # @admission_list_view = AdmissionListView.find_by(admission_id: @admission.id)

          # StateMachine Logic
          # user_role = current_user.primary_role
          # if ['receptionist', 'nurse', 'doctor', 'counsellor', 'tpa'].include?(user_role)
            # admitting_user_id = current_user.id
            # @admission_list_view.send("assign_to_#{user_role}", current_user.id, 'user', '')
          # else
            # admitting_user_id = @admission.doctor
            # @admission_list_view.send('assign_to_doctor', @admission.doctor, 'user', '')
          # end
          communication_notification_trigger
          facility_id = @admission.facility_id
          specialty_id = @admission.specialty_id
          # AdmissionListViewsHelper.update_redis_counter(facility_id, specialty_id, admitting_user_id, 'inc')

          @wards = Ward.where(facility_id: @admission.facility_id.to_s)
          # Link Ots Created w/o AdmissionID
          link_ots if params[:otschedule]

          # creating new Patient Insurance record
          unless params[:admission][:patient_insurance_id].present?
            if params[:admission][:is_insured] == 'Yes'
              @insurance = PatientInsurance.new(patient_insurance_params)
              @admission.update(patient_insurance_id: @insurance.id) if @insurance.save
            end
          end

          # CaseSheet
          CaseSheet::CreateAdmissionService.call(@patient, @admission, params[:case_sheet], current_user.id.to_s, current_facility.id.to_s)

          # Admissions
          @admission_list_views = AdmissionListView.where(
            patient_id: @patient.id, :current_state.nin => ['Discharged', 'Deleted']
          )

          respond_to do |format|
            if @wards.count > 0
              format.js { render 'admissions/assign_bed_redirect' }
            else
              format.js { render 'admissions/close' }
            end
          end
          # Reports::Ipd::Admissions.call(@admission)
          Patients::Summary::TimelineWorker.call(event_name: 'IPD_ADMISSION', sub_event_name: 'SCHEDULED', admission_id: @admission.id, user_id: current_user.id, user_name: current_user.fullname)

          # IpdRecord
          IpdRecords::CreateService.call(@admission, params[:case_sheet], 'Admission')

          # Diagnosis Report Data Job
          MisJobs::Clinical::ExtractDiagnosesJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@admission.id.to_s, "IPD", "admission_form")
          # Procedure Data Job
          MisJobs::Clinical::PatientProcedureJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@admission.case_sheet_id.to_s, @admission.id.to_s, "admission")
        end
      end
    else
      respond_to do |format|
        format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'No Doctor or Specialty Selected', text: 'Please make sure you have selected Location, Doctor and Specialty', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end
    end
  end

  def edit
    # Get Min Discharge Date
    @ots = OtSchedule.where(admission_id: @admission.id, operation_done: true, is_deleted: false).order(ottime: :desc)
    @min_date = (@ots[0].otdate.strftime('%d/%m/%Y') if @ots.count > 0) || @admission.admissiondate.strftime('%d/%m/%Y')

    @patient = @admission.patient
    @patient_location = Location.find_by(id: @patient.try(:location_id))
    @area_details = ['', '']
    if @patient_location.present?
      @area_details = @patient_location.area_managers.pluck(:area_name, :_id)
    end
  end

  def update
    # Check Whether Discharge DateTime is Not Less Than Admission DateTime
    if params[:admission][:dischargedate].present? && params[:admission][:dischargetime].present?
      admissiontime = Time.zone.parse(params[:admission][:admissiontime])
      dischargetime = Time.zone.parse(params[:admission][:dischargetime])
      params[:admission][:dischargedate] = params[:admission][:admissiondate] if admissiontime > dischargetime
      params[:admission][:dischargetime] = params[:admission][:admissiontime] if admissiontime > dischargetime
    end

    params[:admission][:patient_id] = @admission.patient_id.to_s

    past_facility_id = @admission.facility_id
    past_specialty_id = @admission.specialty_id
    past_admissiondate = @admission.admissiondate

    if @admission.update_attributes(admission_params)
      @patient = @admission.patient

      update_ipd_record_specialty
      respond_to do |format|
        format.js { render 'close' }
      end

      Analytics::Admission::UpdateService.update_admission_created_count(@admission.id, past_facility_id, past_admissiondate, past_specialty_id)
      # Report code commented because outdated
      # Reports::Ipd::Admissions.call(@admission)
      Patients::Summary::TimelineWorker.call(event_name: 'IPD_ADMISSION', sub_event_name: 'EDITED', admission_id: @admission.id, user_id: current_user.id, user_name: current_user.fullname)

      # Diagnosis Report Data Job
      MisJobs::Clinical::ExtractDiagnosesJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@admission.id.to_s, "IPD", "admission_form")
      # Procedure Data Job
      MisJobs::Clinical::PatientProcedureJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@admission.case_sheet_id.to_s, @admission.id.to_s, "admission")
      # Whatsapptrigger reschedule 
      CommunicationNotificationJob.perform_now('admission_rescheduled', @admission.id.to_s, @admission.class.to_s)
    else
      redirect_to 'edit'
    end
  end

  def destroy
    ward = Ward.find_by(id: @admission.ward_id)
    if ward.present?
      ward&.update_attributes(in_use: false)
      room = ward.rooms.find_by(id: @admission.room_id)
      if room.present?
        room.update_attributes(in_use: false)
        bed = room.beds.find_by(id: @admission.bed_id)
        bed&.update_attributes(in_use: false, status: 78848005)
      end
    end

    @admission.update_attributes(is_deleted: true, bed_id: nil, room_id: nil, ward_id: nil)

    ipd_record = Inpatient::IpdRecord.unscoped.find_by(admission_id: @admission.id)
    ipd_record_procedures = ipd_record.try(:procedure)
    case_sheet = CaseSheet.find_by(id: @admission.case_sheet_id)
    case_sheet_procedures = case_sheet.procedures

    ipd_record_procedures.try(:delete_all)
    if ipd_record.present?
      if case_sheet_procedures.present?
        case_sheet_procedures.where(ipd_record_id: ipd_record.id ).each do |procedure|
          # Update IPD fields in Procedure
          procedure[:ipd_procedure_ids] = procedure.ipd_procedure_ids.except(ipd_record.id.to_s)
          procedure[:ipd_record_id] = nil
          procedure[:admission_id] = nil
          procedure[:is_performed] = false
          procedure[:flow_in_ipd] = false
          procedure.save
        end
        case_sheet.save
      end
    end

    @tpa_workflow = TpaInsuranceWorkflow.find_by(admission_id: @admission.id)
    update_doctor_counsellor_list if @tpa_workflow

    @admission_list_view.reload
    # Delete all OT Linked to the admission
    OtSchedule.where(admission_id: @admission.id).try(:each) do |ot|
      ot.update(is_deleted: true)
    end
    @patient = @admission.patient
    CommunicationNotificationJob.perform_now('admission_cancelled', @admission.id.to_s, @admission.class.to_s)
    respond_to do |format|
      # Temporary Reload
      format.js { render 'close' }
    end

    Patients::Summary::TimelineWorker.call(event_name: 'IPD_ADMISSION', sub_event_name: 'CANCELLED', admission_id: @admission.id, user_id: current_user.id, user_name: current_user.fullname)
  end

  def search_admission_list
    available_specialties = Specialty.where(:id.in => current_user.specialty_ids & current_facility.specialty_ids)
    specialty = params[:specialty_id] == 'all_specialties' ? available_specialties.pluck(:id) : [params[:specialty_id]]

    @scheduled_count = current_facility.admission_schedule_list_length
    if params[:active_doctor]
      @active_doctor = params[:active_doctor]
    elsif current_user.role_ids.include? 158965000
      @active_doctor = current_user.id.to_s
    end
    @active_tab = params[:active_tab]
    @current_date = params[:current_date]
    if @active_doctor == 'all' || @active_doctor.nil?
      @admission_list = AdmissionListView.where(facility_id: current_facility.id.to_s, :specialty_id.in => specialty)
    else
      @admission_list = AdmissionListView.where(facility_id: current_facility.id.to_s, :specialty_id.in => specialty, admitting_doctor_id: @active_doctor)
    end
    if params[:q].present?
      if @active_tab == 'Admitted'
        @admission_list = @admission_list.where(current_state: @active_tab, patient_name: /#{Regexp.escape(params[:q])}/i)
      elsif @active_tab == 'Discharged'
        @admission_list = @admission_list.where(current_state: @active_tab, patient_name: /#{Regexp.escape(params[:q])}/i, discharge_date: @current_date)
      elsif @active_tab == 'AdmittedNow'
        @admission_list = @admission_list.where(current_state: 'Admitted', patient_name: /#{Regexp.escape(params[:q])}/i, admission_date: Date.parse(@current_date))
      elsif @active_tab == 'Scheduled'
        @admission_list = @admission_list.where(current_state: 'Scheduled', patient_name: /#{Regexp.escape(params[:q])}/i, admission_date: @scheduled_count.days.ago.to_date..Date.current)
      end
    end
  end

  def get_specialty_case_sheets
    case_sheets = CaseSheet.where(patient_id: params[:patient_id], specialty_id: params[:specialty_id]).pluck(:id, :case_id, :case_name, :start_date)

    render json: case_sheets
  end

  def get_facility_specialties
    facility = Facility.find_by(id: params[:facility_id])

    if facility.specialty_ids.include?(params[:selected_specialty_id]) && current_user.specialty_ids.include?(params[:selected_specialty_id]) || params[:action_type] == 'new'
      specialties = Specialty.where(:id.in => facility.specialty_ids & current_user.specialty_ids)
    else
      specialties = ''
    end

    render json: specialties.to_json
  end

  def get_users_from_specialty
    @facility = Facility.find_by(id: params[:facility_id])
    users = User.where(facility_ids: params[:facility_id], role_ids: 158965000, specialty_ids: params[:specialty_id], is_active: true).pluck('fullname', 'id')
    render json: users.to_json
  end

  def cancel_discharge
    discharged_milestone = @admission.admission_milestones.find_by(position: 10)
    discharged_milestone&.delete
    if @admission.update_attributes(isdischarged: false, admission_stage: 'pre_discharge')
      case_sheet = CaseSheet.find_by(id: @admission.case_sheet_id)
      case_sheet.update(active_admission_id: @admission.id) if case_sheet.present?

      AdmissionListViews::UndoStateService.call(@admission_list_view)

      render json: { "success": true }
    end
    pst = PatientSummaryTimeline.where(event_name: 'IPD ADMISSION', sub_event_name: 'DISCHARGED', query: { _id: @admission.id.to_s })
    pst.delete_all if pst.count > 0
    PatientSummaryTimeline.where(query: { _id: @admission.id.to_s }).order(created_at: :desc)[0].update(is_active: true)
  end

  def mark_not_arrived
    @admission.admission_milestones.where(:label.nin => ['admission_scheduled', 'ready_for_admission']).delete_all
    @admission.update_attributes(patient_arrived: false, ready_for_ot: false, admission_stage: 'pre_admission')

    render json: { "success": true }

    pst = PatientSummaryTimeline.where(event_name: 'IPD ADMISSION', sub_event_name: 'ADMITTED', query: { _id: @admission.id.to_s })
    pst.delete_all if pst.count > 0
    PatientSummaryTimeline.where(query: { _id: @admission.id.to_s }).order(created_at: :desc)[0].update(is_active: true)

    Analytics::CreateService.call(@admission.id.to_s, @admission.doctor.to_s, @admission.facility_id.to_s, 'not_admitted')
  end

  def assign_bed
    @wards = Ward.where(facility_id: @admission.facility_id)
    @bed = Room.find_by(id: @admission.room_id).beds.find_by(id: @admission.bed_id) unless @admission.daycare
  end

  def get_rooms_from_ward
    @rooms = Room.where(ward_id: params[:ward_id]).pluck('name', 'id')
    render json: @rooms.to_json
  end

  def get_beds_from_room
    @beds = Room.find_by(id: params[:room_id]).beds.where(status: 78848005).order(code: :asc).pluck('name', 'id', 'code', 'price', 'status')
    render json: @beds.to_json
  end

  def save_bed
    existing_ward_id = @admission.ward_id
    existing_room_id = @admission.room_id
    existing_bed_id = @admission.bed_id

    if @admission.update_attributes!(admission_params)

      # Update Exisiting Bed Attributes
      existing_ward = Ward.find_by(id: existing_ward_id)
      if existing_ward.present?
        existing_ward&.update_attributes(in_use: false)
        existing_room = existing_ward.rooms.find_by(id: existing_room_id)
        if existing_room.present?
          existing_room.update_attributes(in_use: false)
          existing_bed = existing_room.beds.find_by(id: existing_bed_id)
          existing_bed&.update_attributes(in_use: false, status: 78848005)
        end
      end

      # Update New Bed Attributes
      new_ward = Ward.find_by(id: @admission.ward_id)
      if new_ward.present?
        new_ward&.update_attributes(in_use: true)
        new_room = new_ward.rooms.find_by(id: @admission.room_id)
        if new_room.present?
          new_room.update_attributes(in_use: true)
          new_bed = new_room.beds.find_by(id: @admission.bed_id)
          new_bed&.update_attributes(in_use: true, status: 1669000)
        end
      end

      # After Update
      @bed_details = "#{new_bed&.code}(#{new_ward&.name}/#{new_room&.name})"
    end
  end

  def unassign_bed
    existing_ward_id = @admission.ward_id
    existing_room_id = @admission.room_id
    existing_bed_id = @admission.bed_id

    @admission.update_attributes(bed_id: nil, room_id: nil, ward_id: nil, daycare: true)

    # Update Exisiting Bed Attributes
    existing_ward = Ward.find_by(id: existing_ward_id)
    if existing_ward.present?
      existing_ward&.update_attributes(in_use: false)
      existing_room = existing_ward.rooms.find_by(id: existing_room_id)
      if existing_room.present?
        existing_room.update_attributes(in_use: false)
        existing_bed = existing_room.beds.find_by(id: existing_bed_id)
        existing_bed&.update_attributes(in_use: false, status: 78848005)
      end
    end
  end

  def reschedule
    if @admission.update_attributes(admissiondate: Date.parse(params[:new_admission_time]), admissiontime: params[:new_admission_time])
      render json: { "success": true }

      Patients::Summary::TimelineWorker.call(event_name: 'IPD_ADMISSION', sub_event_name: 'EDITED', admission_id: @admission.id, user_id: current_user.id, user_name: current_user.fullname)
    end
  end

  def update_ready_state
    user_id = current_user.id
    facility_id = current_facility.id
    @dropdown_users = UsersDropdownHelper.create_ipd(@admission.specialty_id, facility_id)

    @milestones = @admission.admission_milestones
    position = params[:position].to_i
    if params[:value] == 'true'
      AdmissionsHelper.update_milestone(@admission, params[:state], position, user_id, params[:ot_id])
    else
      milestone = @milestones.find_by(position: position, :ot_id.in => [params[:ot_id], nil])
      milestone&.delete
    end
    if params[:state] == 'ready_for_admission'
      @admission_list_view = AdmissionListView.find_by(admission_id: @admission.id)

      #StateMachine Logic
      if params[:value] == 'true'
        user_role = current_user.primary_role
        if ['receptionist', 'nurse', 'doctor', 'counsellor', 'tpa'].include?(user_role)
          admitting_user_id = current_user.id
          @admission_list_view.send("assign_to_#{user_role}", current_user.id, 'user', '')
        else
          admitting_user_id = @admission.doctor
          @admission_list_view.send('assign_to_doctor', @admission.doctor, 'user', '')
        end
  
        facility_id = @admission.facility_id
        specialty_id = @admission.specialty_id
        AdmissionListViewsHelper.update_redis_counter(facility_id, specialty_id, admitting_user_id, 'inc')
      else
        @admission_list_view.admission_state_transitions.where(from: "scheduled").destroy_all
        @admission_list_view.update(sm_state: 'scheduled')
      end
    end
    @admission.update("#{params[:state]}": params[:value])

    # PatientIdentifier and reg_ fields updation
    patient = Patient.find_by(id: @admission.patient_id)
    if patient.try(:reg_status) == false
      patient.update(reg_status: true, reg_date: Date.current, reg_time: Time.current, reg_facility_id: @admission.facility_id.to_s)
      create_patient_identifier(patient, current_user)
      create_patient_search(patient)
    end
    # EOF PatientIdentifier and reg_ fields updation
  end

  def print_admission_list
    specialty_ids = current_user.specialty_ids & current_facility.specialty_ids
    @admission_list = AdmissionListView.where(facility_id: @facility.id, current_state: 'Admitted', :specialty_id.in => specialty_ids).order(admission_date: :desc)
    if current_user.role_ids.include?(158965000)
      @admission_list = @admission_list.where(admitting_doctor_id: current_user.id.to_s)
    end
    # @opdrecord = OpdRecord.where(:patientid.in => @admission_list.pluck(:patient_id).map!(&:to_s)).not.where(templatetype: "optometrist")
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]

    respond_to do |format|
      format.pdf { render template: 'admissions/print_admission_list', pdf: 'AdmissionList', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, orientation: 'Landscape', margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def print_scheduled_list
    specialty_ids = current_user.specialty_ids & current_facility.specialty_ids
    @admission_list = AdmissionListView.where(facility_id: @facility.id, admission_date: @current_date, current_state: 'Scheduled', :specialty_id.in => specialty_ids).order(admission_date: :desc)
    if current_user.role_ids.include?(158965000)
      @admission_list = @admission_list.where(admitting_doctor_id: current_user.id.to_s)
    end
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    # @opdrecord = OpdRecord.where(:patientid.in => @admission_list.pluck(:patient_id).map!(&:to_s)).not.where(templatetype: "optometrist")
    respond_to do |format|
      format.pdf { render template: 'admissions/print_scheduled_list', pdf: 'AdmissionList', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, orientation: 'Landscape', margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def print_admitted_list
    specialty_ids = current_user.specialty_ids & current_facility.specialty_ids
    @admission_list = AdmissionListView.where(facility_id: @facility.id, admission_date: @current_date, current_state: 'Admitted', :specialty_id.in => specialty_ids).order(admission_date: :desc)
    if current_user.role_ids.include?(158965000)
      @admission_list = @admission_list.where(admitting_doctor_id: current_user.id.to_s)
    end
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    # @opdrecord = OpdRecord.where(:patientid.in => @admission_list.pluck(:patient_id).map!(&:to_s)).not.where(templatetype: "optometrist")
    respond_to do |format|
      format.pdf { render template: 'admissions/print_admitted_list', pdf: 'AdmissionList', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, orientation: 'Landscape', margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  def print_discharged_list
    specialty_ids = current_user.specialty_ids & current_facility.specialty_ids
    @admission_list = AdmissionListView.where(facility_id: @facility.id, discharge_date: @current_date, current_state: 'Discharged', :specialty_id.in => specialty_ids).order(discharge_date: :desc)
    if current_user.role_ids.include?(158965000)
      @admission_list = @admission_list.where(admitting_doctor_id: current_user.id.to_s)
    end
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'all')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    # @opdrecord = OpdRecord.where(:patientid.in => @admission_list.pluck(:patient_id).map!(&:to_s)).not.where(templatetype: "optometrist")
    respond_to do |format|
      format.pdf { render template: 'admissions/print_discharged_list', pdf: 'AdmissionList', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, orientation: 'Landscape', margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
    end
    # orientation: 'Landscape',
  end

  def user_time_slot_check
    organisation_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    user_time_slot = UserTimeSlot.find_by(user_id: params[:doctor_id])

    if organisation_setting.time_slots_enabled && user_time_slot
      options = { department_id: params[:department_id], facility_id: params[:facility_id] }

      ipd_sessions = user_time_slot.sessions.where(options)
      ipd_exception_sessions = user_time_slot.exception_sessions.where(options)

      ipd_slots_present = (ipd_sessions.count > 0 || ipd_exception_sessions.count > 0)
    else
      ipd_slots_present = false
    end

    render json: ipd_slots_present
  end

  def calendar_time_slot
    @facilities = Facility.where(:organisation_id => params['organisation_id'], is_active: true).sort(name: :asc)
    @user_time_slot = UserTimeSlot.includes(:user).find_by(user_id: params[:doctor_id])
    @specialty_id = params['specialty_id']
    options = { department_id: params[:department_id], facility_id: params[:facility_id] }
    @users = User.includes(:user_time_slot).where(role_ids: 158965000, :facility_ids.in => [params['facility_id']],  specialty_ids: @specialty_id, is_active: true).filter { |user| ((user.user_time_slot.present? && user.user_time_slot.sessions.where(options).count > 0) || (user.user_time_slot.present? && user.user_time_slot.exception_sessions.where(options).count > 0))}.pluck('fullname', 'id')
    @selected_facility = params['facility_id']
    @selected_user = params['doctor_id']
  end

  def validate
    patient_id = params[:patient_id]
    admission_id = params[:admission_id]

    if patient_id && params[:admission]
      admissiondate = Date.parse(params[:admission][:admissiondate]) rescue nil
      admission = Admission.find_by(
        :id.ne => admission_id, admissiondate: admissiondate, patient_id: patient_id, is_deleted: false
      )

      # Raise error if admission present
      render json: !admission.present?
    else
      render json: true
    end
  end

  def get_calendar_duration
    @user_time_slot = UserTimeSlot.includes(:user).find_by(user_id: params[:user_id])
    time_duration = @user_time_slot&.calendar_duration || 0
    id = @user_time_slot&.id.to_s || ''
    render json: { time_duration: time_duration, id: id}.to_json
  end

  def get_ipd_slot_users
    
    options = { department_id: params[:department_id], facility_id: params[:facility_id] }
    @users = User.includes(:user_time_slot).where(role_ids: 158965000, :facility_ids.in => [params['facility_id']],  specialty_ids: params['specialty_id'], is_active: true).filter { |user| ((user.user_time_slot.present? && user.user_time_slot.sessions.where(options).count > 0) || (user.user_time_slot.present? && user.user_time_slot.exception_sessions.where(options).count > 0))}.pluck('fullname', 'id')
    render json: @users
  end

  private

  def admission_params
    params.require(:admission).permit(
      :admissionreason, :admission_type, :managementplan, :admissiondate, :admissiontime, :dischargedate,
      :patient_arrived, :insurance_status, :facility_id, :specialty_id, :doctor, :doctor_1, :doctor_2,
      :doctor_3, :anesthesia, :ward_id, :room_id, :bed_id, :daycare,
      :patient_id, :user_id, :organisation_id, :department_id, :dischargetime, :display_id, :case_sheet_id,
      :insurance_selected_id, :admission_hospitalisation_type, :is_insured, :admission_hospitalization_type,
      :patient_insurance_id, :insurance_name, :insurance_id, :insurance_address, :insurance_email,
      :insurance_contact_no, :insurance_contact_person, :tpa_name, :tpa_contact_id, :tpa_contact_no,
      :tpa_contact_person, :tpa_address, :tpa_email, :patient_contact_person, :insurance_policy_no,
      :insurance_policy_expiry_date, :insurance_type, :company_name, :employee_id, :comment, :patient_id,
      :insurance_status, :bracket_amount, :document_passport, :document_aadharcard, :document_electioncard,
      :document_insurancecard, :document_employeecard, :document_drivinglicense, :document_others, :document_tpa_form,
      :sum_insured, :insurance_comments, :insurance_contact_id, :document_passport, :document_aadharcard,
      :document_electioncard, :document_insurancecard, :document_government_id, :document_vss, :document_employeecard,
      :document_drivinglicense, :document_others, :document_tpa_form, :document_patient_cancelled_cheque,
      :reporting_date, :reporting_time, admission_milestones_attributes: [:id, :label, :user_id, :position]
    )
  end

  # def tpa_params
  # params.require(:tpa).permit(:admission_id ,:is_insured, :hospitalization_type, :insurance_name, :insurance_id, :insurance_address, :insurance_email, :insurance_contact_no, :insurance_contact_person, :tpa_name, :tpa_contact_id, :tpa_contact_no, :tpa_contact_person, :tpa_address, :tpa_email, :insurance_policy_no, :insurance_type, :company_name, :employee_id, :comment, :patient_id, :admission_id, :insurance_status, :bracket_amount, :document_passport, :document_aadharcard, :document_electioncard, :document_insurancecard, :document_employeecard, :document_drivinglicense, :document_others, :document_tpa_form)
  # end

  def patient_insurance_params
    params.require(:admission).permit(:patient_id, :organisation_id, :facility_id, :insurance_name, :insurance_address, :insurance_email, :insurance_contact_no, :insurance_contact_person, :insurance_policy_no, :insurance_policy_expiry_date, :insurance_status, :admission_id, :insurance_contact_id)
  end

  def find_admission
    @admission = Admission.find(params[:id])
    @admission_list_view = AdmissionListView.find_by(admission_id: @admission.id)
  end

  def find_patient
    @camp_patient = CampPatient.find_by(id: params[:camp_patient_id])

    if params[:patient_origin].present?
      if @camp_patient.converted == true
        @patient = Patient.find_by(id: @camp_patient.patient_id)
      else
        make_patient_from_camp_patient
      end
    else
      @patient = Patient.find_by(id: params[:patient_id]) || Patient.new
    end
    @patient_location = Location.find_by(id: @patient.try(:location_id))
    @area_details = ['', '']
    if @patient_location.present?
      @area_details = @patient_location.area_managers.pluck(:area_name, :_id)
    end
  end

  def make_patient_from_camp_patient
    camp_patient = @camp_patient
    get_age_data
    @patient = Patient.new(
      address_1: camp_patient.address1,
      address_2: camp_patient.address2,
      age: camp_patient.age.to_i,
      dob: camp_patient.dob,
      dob_day: @dob_day,
      dob_month: @dob_month,
      dob_year: @dob_year,
      fullname: camp_patient.fullname,
      firstname: camp_patient.fullname,
      gender: camp_patient.gender,
      mobilenumber: camp_patient.phone_number,
      city: camp_patient.city,
      district: camp_patient.district,
      commune: camp_patient.commune,
      camp_patient_identifier: camp_patient.camp_patient_identifier
    ) || Patient.new
  end

  def get_age_data
    @camp_patient.age.present? && @camp_patient.dob.blank?
    @dob_day = Date.current.day
    @dob_year = Date.current.year - @camp_patient.age.to_i
    @dob_month = Date.current.month
    @is_approx_dob = true
  end

  def occupation_name
    if @patient.occupation.present?
      occupation_list = Global.send('occupation_list').send('sets')
      occupation_hash = occupation_list.find { |x| x[:snomedcode] == @patient&.occupation }
      @occupation_name = occupation_hash.present? ? occupation_hash[:name] : @patient.occupation
    end
  end

  def get_admission_form_values
    @current_date = @admission.admissiondate || Date.parse(params[:date]) || Date.current
    if params[:action] == 'new'
      if params[:time].present?
        @current_time = Time.zone.parse(params[:time]) || Time.current
      else
        @current_time = Time.current
      end
    else
      @current_time = @admission.admissiontime || Time.zone.parse(params[:time]) || Time.current
    end
    @discharge_date = @admission.dischargedate # || Date.parse(params[:date]) || Date.current
    @discharge_time = @admission.dischargetime # || Time.zone.parse(params[:time]) || Time.current
    @selected_facility = @admission.facility_id || params[:facility_id] || current_facility.id

    facility = Facility.find_by(id: @selected_facility)

    final_specialties = facility.specialty_ids & current_user.specialty_ids
    unless final_specialties.present?
      final_specialties = facility.specialty_ids
    end # finding final_specialties of selected facility if no specialty present. for eg -> TPA case
    @available_specialties = Specialty.where(:id.in => final_specialties).pluck(:name, :id).sort
    @selected_specialty = @admission.specialty_id || params[:specialty_id] || if @available_specialties.present? then @available_specialties.first[1] end || ''

    @available_doctors = User.where(facility_ids: @selected_facility, role_ids: 158965000, specialty_ids: @selected_specialty, is_active: true).pluck('fullname', 'id')
    @selected_doctor = @admission.doctor || params[:doctor_id] || (if current_user.role_ids.include?(158965000) && current_user.facility_ids.map(&:to_s).include?(@selected_facility.to_s)
                                                                     current_user.id
                                                                   end) || User.where(role_ids: 158965000, facility_ids: @selected_facility, specialty_ids: @selected_specialty, is_active: true)[0]&.id
  end

  def update_admission_time
    @hours = if params[:meridian] == 'AM'
               if params[:hour] == '12'
                 0
               else
                 params[:hour].to_i
               end
             elsif params[:hour] == '12'
               params[:hour].to_i
             else
               params[:hour].to_i + 12
             end
    @minutes = params[:minute].to_i
    @date = params[:admission][:admissiondate].split('/')[0]
    @month = params[:admission][:admissiondate].split('/')[1]
    @year = params[:admission][:admissiondate].split('/')[2]
    @admissiontime = Time.new(@year, @month, @date, @hours, @minutes, 0)
  end

  def link_ots
    params[:otschedule].to_unsafe_h.each.with_index do |ot, _i|
      if ot[1][:decider] == 'Link'
        OtSchedule.find_by(id: ot[1][:id]).update_attributes(admission_id: @admission.id)
      elsif ot[1][:decider] == 'Delete'
        OtSchedule.find_by(id: ot[1][:id]).update_attributes(is_deleted: true, admission_id: @admission.id)
      end
    end
  end

  def print_params
    @organisation = current_facility.organisation
    @facility = current_facility
    @ward = Ward.where(facility_id: current_facility.id)
    @current_date = Date.parse(params[:current_date]) if params[:current_date].present?
  end

  def update_doctor_counsellor_list
    @tpa_workflow.workflow_deleted
    @tpa_workflow.update_attributes(admission_id: nil)
    if @tpa_workflow.appointment_id.present?
      @opd_workflow = OpdClinicalWorkflow.find_by(appointment_id: @tpa_workflow.appointment_id.to_s)
      @opd_workflow&.update(tpa_state: 'Admission Deleted', tpa_admission_id: nil)
      @counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: @tpa_workflow.appointment_id.to_s)
      @counsellor_workflow&.update(tpa_state: 'Admission Deleted')
    end
  end

  def update_ipd_record_specialty
    ipd_record = Inpatient::IpdRecord.find_by(admission_id: @admission.id)
    if ipd_record
      ipd_record.update(specialty_id: @admission.specialty_id) if ipd_record.specialty_id != @admission.specialty_id
    end
  end

  def create_patient_identifier(patient, current_user)
    patient_identifier = PatientIdentifier.create!(patient_id: patient.id, organisation_id: current_user.organisation_id, bkp_patient_org_id: CommonHelper.get_patient_org_identifier(current_user))
    patient_org_id = SequenceManagers::GenerateSequenceService.call('patient', patient.id.to_s, {organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id.to_s,  region_id: current_facility.try(:region_master_id).to_s})
      patient_identifier.update(patient_org_id: patient_org_id)
  end
  # EOF create_patient_identifier

  def create_patient_search(patient)
    patient_name = "#{patient.firstname} #{patient.middlename} #{patient.lastname}".strip
    patient_name_search = patient_name.tr('^A-Za-z0-9', '').downcase
    mobile_number = patient.mobilenumber
    mr_no = patient.patient_mrn
    mr_no_search = mr_no.to_s.tr('^A-Za-z0-9', '') # .split("").map {|x| x[/\d+/]}.join("")
    reg_hosp_ids = patient.reg_hosp_ids
    patient_identifier_id = patient.patient_identifier_id
    patient_identifier_id_search = patient_identifier_id.to_s.split('').map { |x| x[/\d+/] }.join('')

    search = "#{mobile_number} #{mr_no_search} #{patient_identifier_id_search} #{patient_name}"
    search += "#{mr_no_search} #{mobile_number} #{patient_name} #{patient_identifier_id_search}"
    search += "#{patient_identifier_id_search} #{patient_name} #{mobile_number} #{mr_no_search}"
    search += "#{patient_name} #{patient_identifier_id_search} #{mr_no_search} #{mobile_number}"

    PatientSearch.create(search: search.downcase, patient_id: patient.id, 
                        patient_name: patient_name, mobile_number: mobile_number, 
                        mr_no: patient.patient_mrn, 
                        patient_identifier_id: patient_identifier_id, 
                        reg_hosp_ids: reg_hosp_ids, 
                        patient_identifier_id_search: patient_identifier_id_search,
                        mr_no_search: mr_no_search.downcase, 
                        patient_name_search: patient_name_search)
  end
  # EOF create_patient_search

  def communication_notification_trigger
    if @admission.admission_hospitalisation_type == "emergency" || @admission.admission_hospitalisation_type == "same_day"
      CommunicationNotificationJob.perform_now('same_day_or_emergency', @admission.id.to_s, @admission.class.to_s)
    elsif @admission.admission_hospitalisation_type == "planned"
      CommunicationNotificationJob.perform_now('planned_admission', @admission.id.to_s, @admission.class.to_s)
    end
  end
end
