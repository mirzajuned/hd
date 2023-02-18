class OtsController < ApplicationController
  before_action :authorize
  before_action :ot_schedule, only: [:edit, :update, :link_ot, :unlink_ot, :update_ready_state]
  before_action :print_params, only: [:print_all_list, :print_scheduled_list, :print_admitted_list, :print_engaged_list, :print_completed_list]
  before_action :find_patient, only: [:new, :edit]
  before_action :find_admission, only: [:new, :edit]
  before_action :set_admission, only: [:update_ready_state]
  before_action :get_ot_form_values, only: [:edit]
  before_action :occupation_name, only: [:new, :edit]

  def new
    @patient_type = PatientType.where(is_active: true, organisation_id: current_user.organisation_id).pluck(:label, :id)
    @ot_schedules = OtSchedule.where(patient_id: @patient.id.to_s, is_deleted: false, is_engaged: false, operation_done: false).sort(ottime: :asc)
    @ot_schedule = OtSchedule.new
    get_ot_form_values
    # set_procedure_diagnosis_data_for_ot_schedule

    @organisation_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)

    @case_sheet = CaseSheet.find_by(id: params[:case_sheet_id])
    @case_sheets = CaseSheet.where(patient_id: params[:patient_id])
    @occupation_list = Global.send("occupation_list").send('sets').pluck(:name, :snomedcode)
  end

  def create
    # Create/Update Patient
    unless params[:ot_schedule][:specialty_id].present? || params[:ot_schedule][:surgeonname].present?
      respond_to do |format|
        format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'No Doctor or Specialty Selected', text: 'Please make sure you have selected Location, Doctor and Specialty', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end
    else
      unless params[:ot_schedule][:patient_id].present?
        @patient = Patients::CreateService.call(params, current_user, current_facility) # Call Patient CreateService
      else
        @patient = Patients::UpdateService.call(params[:ot_schedule][:patient_id], params, current_user) # Call Patient UpdateService
      end

      @calculate_age = @patient.calculate_age
      # Create New OT
      if @patient
        # Check Whether End Time is not Less than Start Time
        start_time, end_time = Time.zone.parse(params[:ot_schedule][:ottime]), Time.zone.parse(params[:ot_schedule][:otendtime])
        params[:ot_schedule][:otendtime] = start_time + 30.minutes if start_time > end_time

        params[:ot_schedule][:patient_id] = @patient.id.to_s
        params[:ot_schedule][:display_id] = CommonHelper::get_ipd_record_identifier(current_user)
        @ot_schedule = OtSchedule.new(ot_params)
        if @ot_schedule.save!
          update_procedures
          @admission_list_view = AdmissionListView.find_by(admission_id: @ot_schedule.admission_id)
          @ot_schedules = OtSchedule.where(patient_id: @patient.id.to_s, is_deleted: false)
          @existing_admission = Admission.find_by(patient_id: @patient.id, isdischarged: false, is_deleted: false)

          @admission_list_views = AdmissionListView.where(
            patient_id: @patient.id, :current_state.nin => ['Discharged', 'Deleted']
          )

          # CaseSheet
          CaseSheet::CreateOtScheduleService.call(@patient, @ot_schedule, params[:case_sheet])
          @case_sheet = CaseSheet.find_by(id: @ot_schedule.case_sheet_id)

          respond_to do |format|
            format.js { render 'ots/close' }
          end
          # get_daily_reports
          # Reports::Ipd::Ots.new(@ot_schedule).call
          Patients::Summary::TimelineWorker.call({ event_name: "IPD_OT", sub_event_name: "SCHEDULED", ot_id: @ot_schedule.id, user_id: current_user.id, user_name: current_user.fullname })

          IpdRecords::CreateService.call(@ot_schedule.admission, params[:case_sheet], "OtSchedule") if @ot_schedule.admission_id.present?
          # Procedure Data Job
          MisJobs::Clinical::PatientProcedureJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@ot_schedule.case_sheet_id.to_s, @ot_schedule.id.to_s, "ot_schedule")
        end
      end
    end
  end

  def edit
    # set_procedure_diagnosis_data_for_ot_schedule
  end

  def update
    start_time, end_time = Time.zone.parse(params[:ot_schedule][:ottime]), Time.zone.parse(params[:ot_schedule][:otendtime])
    params[:ot_schedule][:otendtime] = start_time + 30.minutes if start_time > end_time
    if @ot_schedule.update_attributes(ot_params)
      @patient = Patient.find_by(id: @ot_schedule.patient_id)
      @ot_schedules = OtSchedule.where(patient_id: @ot_schedule.patient.id.to_s, is_deleted: false)
      if @ot_schedule.admission_id
        if @ot_schedule.admission.patient_arrived
          @active_tab = "Admitted"
        else
          @active_tab = "Scheduled"
        end
      else
        @active_tab = "Scheduled"
      end

      @case_sheet = CaseSheet.find_by(id: @ot_schedule.case_sheet_id.to_s)

      @admission_list_views = AdmissionListView.where(
            patient_id: @patient.id, :current_state.nin => ['Discharged', 'Deleted']
          )

      respond_to do |format|
        format.js { render 'close' }
      end
      # get_daily_reports
      # Reports::Ipd::Ots.new(@ot_schedule).call
      Patients::Summary::TimelineWorker.call({ event_name: "IPD_OT", sub_event_name: "RESCHEDULED", ot_id: @ot_schedule.id, user_id: current_user.id, user_name: current_user.fullname })
      # Procedure Data Job
      MisJobs::Clinical::PatientProcedureJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@ot_schedule.case_sheet_id.to_s, @ot_schedule.id.to_s, "ot_schedule")
    else
      redirect_to 'edit'
    end
  end

  def check_ot_overlap
    start_time = Time.zone.parse(params[:start_date] + ' ' + params[:start_time])
    end_time = Time.zone.parse(params[:end_date] + ' ' + params[:end_time])
    options = { facility_id: params[:facility_id], otdate: params[:start_date],
                is_deleted: false, operation_done: false}
    otcount = 0
    ot_schedules = OtSchedule.where(options)
    ot_schedules.each do |ot_schedule|
      unless params[:ot_schedule_id] == ot_schedule[:id].to_s
        if ot_schedule[:surgeonname].to_s != params[:surgeon_id]
          if params[:theatreno].present? && ot_schedule[:theatreno].to_s == params[:theatreno].to_s
            if (ot_schedule.ottime..ot_schedule.otendtime).overlaps?(start_time..end_time)
              otcount += 1
            end
          end
        else
          if (ot_schedule.ottime..ot_schedule.otendtime).overlaps?(start_time..end_time)
            otcount += 1
          end
        end
      end
    end
    render json: otcount.to_json
  end

  def search_ot_list
    if params[:active_doctor]
      @active_doctor = params[:active_doctor]
    else
      if current_user.role_ids.include? 158965000
        @active_doctor = current_user.id.to_s
      end # else nil
    end
    @active_tab = params[:active_tab]
    @current_date = params[:current_date]

    available_specialties = Specialty.where(:id.in => current_user.specialty_ids & current_facility.specialty_ids)
    specialty = params[:specialty_id] == "all_specialties" ? available_specialties.pluck(:id) : [params[:specialty_id]]

    unless @active_doctor == "all" || @active_doctor == nil
      @ot_list = OtListView.where(facility_id: current_facility.id.to_s, :specialty_id.in => specialty, ot_date: @current_date, :patient_name => /#{Regexp.escape(params[:q])}/i).not.where(current_state: "Deleted")
    else
      @ot_list = OtListView.where(facility_id: current_facility.id.to_s, :specialty_id.in => specialty, ot_date: @current_date, :patient_name => /#{Regexp.escape(params[:q])}/i, operating_doctor_id: @active_doctor).not.where(current_state: "Deleted")
    end
    if params[:q].present?
      if @active_tab == "All"
        @ot_list
      else
        @ot_list = @ot_list.where(current_state: @active_tab)
      end
    end
  end

  def get_facility_specialties
    facility = Facility.find_by(id: params[:facility_id])
    specialties = Specialty.where(:id.in => facility.specialty_ids & current_user.specialty_ids)

    render :json => specialties.to_json
  end

  def get_users_from_specialty
    @facility = Facility.find_by(id: params[:facility_id])
    users = User.where(:facility_ids => params[:facility_id], role_ids: 158965000, specialty_ids: params[:specialty_id], is_active: true).pluck("fullname", "id")
    render json: users.to_json
  end

  def search_ot_rooms
    @facility = Facility.find_by(id: params[:facility_id])
    otrooms = OtRoom.where(facility_id: params[:facility_id], specialty_id: params[:specialty_id], is_deleted: false).pluck('name', 'id')
    render json: otrooms.to_json
  end

  def link_ot
    @admission = Admission.find_by(id: params[:admission_id])
    @old_case_sheet = CaseSheet.find_by(id: @ot_schedule.case_sheet_id)
    @case_sheet = CaseSheet.find_by(id: @admission.case_sheet_id)
    @active_tab = ("Admitted" if @admission.patient_arrived) || "Scheduled"
    @ot_schedule.update_attributes(admission_id: @admission.id, case_sheet_id: @case_sheet.id)

    @old_case_sheet.pull(ot_schedule_ids: @ot_schedule.id)
    @case_sheet.add_to_set(ot_schedule_ids: @ot_schedule.id)

    Patients::Summary::TimelineWorker.call({ event_name: "IPD_OT", sub_event_name: "LINKED", ot_id: @ot_schedule.id, user_id: current_user.id, user_name: current_user.fullname })
  end

  def unlink_ot
    @ot_schedule.update_attributes(admission_id: nil)
    Patients::Summary::TimelineWorker.call({ event_name: "IPD_OT", sub_event_name: "UNLINKED", ot_id: @ot_schedule.id, user_id: current_user.id, user_name: current_user.fullname })
  end

  def update_ready_state
    user_id = current_user.id
    facility_id = current_facility.id
    ot_id = @ot_schedule.id
    @dropdown_users = UsersDropdownHelper.create_ipd(@admission.specialty_id, facility_id)

    @milestones = @admission.admission_milestones
    position = params[:position].to_i
    if params[:value] == 'true'
      AdmissionsHelper.update_milestone(@admission, params[:state], position, user_id, ot_id)
    else
      @milestones.where(position: position, ot_id: ot_id).each(&:delete)
    end
    @ot_schedule.update_attributes("#{params[:state]}": params[:value])
    @admission.save! # HACK: This is written to update all documents which embeds admission_milestones
  end

  def print_all_list
    specialty_ids = current_user.specialty_ids & current_facility.specialty_ids
    @ot_list = OtListView.where(facility_id: @facility.id, ot_date: @current_date, :specialty_id.in => specialty_ids,
                                :current_state.ne => 'Deleted').order(ot_time: :desc)
    if current_user.has_role?(:doctor)
      @ot_list = @ot_list.where(operating_doctor_id: current_user.id.to_s)
    end
    @ot_ids = @ot_list.pluck(:ot_id)
    case_sheet_diagnosis
    case_sheet_procedures
    @opdrecord = OpdRecord.where(:patientid.in => @ot_list.pluck(:patient_id).map!(&:to_s)).not.where(templatetype: "optometrist")
    @type = "All"
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "all")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render :template => "ots/print_all_list", :pdf => "OtList", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, orientation: 'Landscape', :margin => { left: @print_settings[0]['left_margin'].to_f, right: @print_settings[0]['right_margin'].to_f, :top => @print_settings[0]['header_height'].to_f, :bottom => @print_settings[0]['footer_height'].to_f } }
    end
  end

  def print_scheduled_list
    specialty_ids = current_user.specialty_ids & current_facility.specialty_ids
    @ot_list = OtListView.where(facility_id: @facility.id, current_state: "Scheduled", ot_date: @current_date, :specialty_id.in => specialty_ids).order(ot_time: :desc)
    if current_user.has_role?(:doctor)
      @ot_list = @ot_list.where(operating_doctor_id: current_user.id.to_s)
    end
    @ot_ids = @ot_list.pluck(:ot_id)
    case_sheet_diagnosis
    case_sheet_procedures
    @opdrecord = OpdRecord.where(:patientid.in => @ot_list.pluck(:patient_id).map!(&:to_s)).not.where(templatetype: "optometrist")
    @type = "Scheduled"
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "all")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render :template => "ots/print_scheduled_list", :pdf => "OtList", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, orientation: 'Landscape', :margin => { left: @print_settings[0]['left_margin'].to_f, right: @print_settings[0]['right_margin'].to_f, :top => @print_settings[0]['header_height'].to_f, :bottom => @print_settings[0]['footer_height'].to_f } }
    end
  end

  def print_admitted_list
    specialty_ids = current_user.specialty_ids & current_facility.specialty_ids
    @ot_list = OtListView.where(facility_id: @facility.id, current_state: "Admitted", ot_date: @current_date, :specialty_id.in => specialty_ids).order(ot_time: :desc)
    if current_user.has_role?(:doctor)
      @ot_list = @ot_list.where(operating_doctor_id: current_user.id.to_s)
    end
    @ot_ids = @ot_list.pluck(:ot_id)
    case_sheet_diagnosis
    case_sheet_procedures
    @opdrecord = OpdRecord.where(:patientid.in => @ot_list.pluck(:patient_id).map!(&:to_s)).not.where(templatetype: "optometrist")
    @type = "Admitted"
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "all")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render :template => "ots/print_admitted_list", :pdf => "OtList", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, orientation: 'Landscape', :margin => { left: @print_settings[0]['left_margin'].to_f, right: @print_settings[0]['right_margin'].to_f, :top => @print_settings[0]['header_height'].to_f, :bottom => @print_settings[0]['footer_height'].to_f } }
    end
  end

  def print_engaged_list
    specialty_ids = current_user.specialty_ids & current_facility.specialty_ids
    @ot_list = OtListView.where(facility_id: @facility.id, current_state: "Engaged", ot_date: @current_date, :specialty_id.in => specialty_ids).order(ot_time: :desc)
    if current_user.has_role?(:doctor)
      @ot_list = @ot_list.where(operating_doctor_id: current_user.id.to_s)
    end
    @ot_ids = @ot_list.pluck(:ot_id)
    case_sheet_diagnosis
    case_sheet_procedures
    @opdrecord = OpdRecord.where(:patientid.in => @ot_list.pluck(:patient_id).map!(&:to_s)).not.where(templatetype: "optometrist")
    @type = "Engaged"
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "all")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render :template => "ots/print_engaged_list", :pdf => "OtList", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, orientation: 'Landscape', :margin => { left: @print_settings[0]['left_margin'].to_f, right: @print_settings[0]['right_margin'].to_f, :top => @print_settings[0]['header_height'].to_f, :bottom => @print_settings[0]['footer_height'].to_f } }
    end
  end

  def print_completed_list
    specialty_ids = current_user.specialty_ids & current_facility.specialty_ids
    @ot_list = OtListView.where(facility_id: @facility.id, current_state: "Completed", ot_date: @current_date, :specialty_id.in => specialty_ids).order(ot_time: :desc)
    if current_user.has_role?(:doctor)
      @ot_list = @ot_list.where(operating_doctor_id: current_user.id.to_s)
    end
    @ot_ids = @ot_list.pluck(:ot_id)
    case_sheet_diagnosis
    case_sheet_procedures
    @opdrecord = OpdRecord.where(:patientid.in => @ot_list.pluck(:patient_id).map!(&:to_s)).not.where(templatetype: "optometrist")
    @type = "Completed"
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "all")
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    respond_to do |format|
      format.pdf { render :template => "ots/print_completed_list", :pdf => "OtList", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, orientation: 'Landscape', :margin => { left: @print_settings[0]['left_margin'].to_f, right: @print_settings[0]['right_margin'].to_f, :top => @print_settings[0]['header_height'].to_f, :bottom => @print_settings[0]['footer_height'].to_f } }
    end
  end

  private

  def ot_params
    params.require(:ot_schedule).permit(:admission_id, :patient_id, :user_id, :specialty_id, :otdate, :ottime, :otenddate, :otendtime, :facility_id, :organisation_id, :surgeonname, :theatreno, :case_sheet_id)
  end

  def ot_schedule
    @ot_schedule = OtSchedule.find(params[:id])
  end

  def find_patient
    @patient = Patient.find_by(id: params[:patient_id]) || Patient.new
    @patient_location = Location.find_by(id: @patient.try(:location_id))
    @area_details = ['', '']
    if @patient_location.present?
      @area_details = @patient_location.area_managers.pluck(:area_name, :_id)
    end
  end

  def occupation_name
    occupation_list = Global.send("occupation_list").send('sets')
    occupation_hash = occupation_list.pluck(:snomedcode, :name).to_h
    @occupation_name = occupation_hash[@patient&.occupation]
  end

  def set_admission
    @admission = Admission.find_by(id: @ot_schedule.admission_id)
    @admission_list_view = AdmissionListView.find_by(admission_id: @admission.id)
  end

  def find_admission
    @admission = Admission.find_by(id: params[:admission_id])
  end

  def get_ot_form_values
    @current_date = @ot_schedule.otdate || Date.parse(params[:date]) || Date.current
    @current_time = @ot_schedule.ottime || Time.zone.parse(params[:time]) || Time.current
    @otenddate = @ot_schedule.otenddate || @current_date || Date.current
    @ot_end_time = @ot_schedule.otendtime || (@current_time + 30.minutes)
    @selected_facility = @ot_schedule.facility_id || params[:facility_id] || current_facility.id
    facility = Facility.find_by(id: @selected_facility)
    @available_specialties = Specialty.where(:id.in => facility.specialty_ids & current_user.specialty_ids).pluck(:name, :id).sort
    @selected_specialty = @ot_schedule.specialty_id || params[:specialty_id] || if @available_specialties.present? then @available_specialties.first[1] end || ""
    @available_doctors = User.where(facility_ids: @selected_facility, role_ids: 158965000, specialty_ids: @selected_specialty, is_active: true).pluck('fullname', 'id')
    @selected_doctor = @ot_schedule.surgeonname || params[:doctor_id] || (current_user.id if current_user.role_ids.include?(158965000) && current_user.facility_ids.map(&:to_s).include?(@selected_facility.to_s)) || User.where(role_ids: 158965000, facility_ids: @selected_facility, specialty_ids: @selected_specialty, is_active: true)[0]&.id
    @available_ots = OtRoom.where(facility_id: @selected_facility, specialty_id: @selected_specialty, is_deleted: false)
                           .pluck('name', 'id')
    @selected_ots = @ot_schedule.theatreno || params[:ot_room_id]
  end

  def set_procedure_diagnosis_data_for_ot_schedule # Not in Use
    if @admission.present?
      @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: @admission.id.to_s)
      @clinical_note = @ipdrecord.try(:clinical_note)
    end
    @last_opdrecord = OpdRecord.where(patientid: @patient.id.to_s).order('created_at DESC')[0]
    if @clinical_note.blank? && @last_opdrecord.blank?
      @performed_remaining = []
      @procedures = []
      @diagnosis = []
    elsif @ipdrecord.specialty_id == "309988001" && @clinical_note.present?
      @performed_remaining = @ipdrecord.procedure.where(procedurestage: "A")
      @procedures = @ipdrecord.procedure.where(procedurestage: "P")
      @diagnosis = @ipdrecord.diagnosislist
    elsif @ipdrecord.specialty_id == "309988001" && @clinical_note.blank?
      @performed_remaining = @last_opdrecord.procedure.where(procedurestage: "A")
      @procedures = @last_opdrecord.procedure.where(procedurestage: "P")
      @diagnosis = @last_opdrecord.diagnosislist
    elsif @ipdrecord.specialty_id == "309989009" && @clinical_note.present?
      @performed_remaining = @clinical_note.procedurelist
      @procedures = @clinical_note.try(:procedurelist) if @admission.present?
      @diagnosis = @clinical_note.try(:diagnosis) if @clinical_note.present?
    elsif @ipdrecord.specialty_id == "309989009" && @admission.blank?
      @performed_remaining = (@last_opdrecord.free_procedure if @last_opdrecord.templatetype == "freeform") || @last_opdrecord.procedure.where(procedurestage: "A")
      @procedures = (@last_opdrecord.free_procedure if @last_opdrecord.templatetype == "freeform") || @last_opdrecord.procedure.where(procedurestage: "P")
      @diagnosis = (@last_opdrecord.diagnosis if @last_opdrecord.templatetype == "freeform") || @last_opdrecord.diagnosislist
    end
  end

  def update_procedures
    if params[:procedure] && params[:procedure].count > 0
      params[:procedure].values.each do |procedure|
        @procedure = @ipdrecord.procedure.find_by(id: procedure["id"])
        @procedure.update(iol: procedure["iol"], iol_updated_at: Time.current, ot_schedule_id: @ot_schedule.id, :procedurestatus => procedure["status"], procedureside: procedure["side"], :surgerydate => procedure["surgerydate"])
      end
    end
  end

  def print_params
    @organisation = current_facility.organisation
    @facility = current_facility
    @ward = Ward.where(facility_id: current_facility.id)
    if params[:current_date].present?
      @current_date = Date.parse(params[:current_date])
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

  def case_sheet_diagnosis
    if @ot_ids.count > 0
      organisation_id = current_user.organisation_id
      @diagnoses = CaseSheet.where(organisation_id: organisation_id, :ot_schedule_ids.in => @ot_ids.map(&:to_s))
                            .map { |cs| { ot_schedule_ids: cs.ot_schedule_ids, diagnoses: cs.diagnoses } }
    else
      @diagnoses = {}
    end
  end
end
