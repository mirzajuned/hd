class Investigation::InvestigationManagementsController < ApplicationController
  before_action :authorize
  before_action :authorize_onboard
  layout "loggedin"

  before_action :set_session_params, :role_restriction
  before_action :details_view_params, only: ['investigation_details', 'refresh_investigation', 'investigation_details_modal_view']

  def index
    @current_date = (Date.parse(params[:current_date]) if params[:current_date]) || Date.current
    @patient_id = params[:patient_id] || nil
    @investigation_queues = Investigation::Queue.where(facility_id: @current_facility.id).order(appointment_time: :desc)
    @investigation_queue = @investigation_queues.where(appointment_date: @current_date, is_deleted: false)
    @investigation_completed = @investigation_queues.where(status: 'completed', status_updated_at: @current_date)
    @investigation_pending = @investigation_queues.where(status: 'pending', :appointment_date.gte => @current_date - 7.days)
    @investigation_review = @investigation_queues.where(status: 'review', :appointment_date.gte => @current_date - 7.days)
    @department_id = params[:department_id] || @current_user.department_ids[0]
    organisation = Organisation.find_by(id: current_user.organisation_id)

    case @department_id
    when '309935007'
      investigation_type = 'ophthal'
    when '261904005'
      investigation_type = 'laboratory'
    when '309964003'
      investigation_type = 'radiology'
    end

    options = { investigation_type: investigation_type, my_queue: true }
    if organisation.workflow_waiting_disable || current_facility_setting.queue_management == false
      options = options.merge!(user_id: current_user.id)
    else
      options = options.merge!(:user_ids.in => [current_user.id.to_s])
    end
    @investigation_my_queue = @investigation_queue.where(options)
    @investigation_queue = @investigation_queue.where(investigation_type: investigation_type)
    @investigation_completed = @investigation_completed.where(investigation_type: investigation_type)
    @investigation_pending = @investigation_pending.where(investigation_type: investigation_type)
    @investigation_review = @investigation_review.where(investigation_type: investigation_type).limit(20)
  end

  def investigation_details
    patient_asset = @patient.patientassets
    if patient_asset.count > 0
      if patient_asset.last.asset_path_url.present?
        @patient_asset = patient_asset.all[-1].asset_path_url
      else
        @patient_asset = 'placeholder.png'
      end
    else
      @patient_asset =  'placeholder.png'
    end
    @patientid = @patient.id
    @patient_note = PatientNote.where(patient_id: @patientid).order(:created_at => :desc).limit(5)

    if @current_user.role_ids.include?(2822900478)
      @filter = 'ophthal'
    elsif @current_user.role_ids.include?(41904004)
      @filter = 'radiology'
    elsif @current_user.role_ids.include?(159282002)
      @filter = 'laboratory'
    end
    # Invoice Queries
    # @appointment = Appointment.find_by(id: params[:appointment_id])
    # if current_facility.show_finances
    #   if @appointment
    #     @invoices = Invoice::Opd.where(appointment_id: @appointment.id)
    #     @past_invoices = Invoice::Opd.where(patient_id: @patient.id)
    #     @invoice_templates = InvoiceTemplate.where(facility_id: current_facility.id, version: "v21.0")
    #     @advance = AdvancePayment.where(patient_id: @patient.id, type: "OPD", advance_state: "None")
    #   end
    # end
  end

  def refresh_investigation
  end

  def show_all_reports
    @template_ids = params[:template_ids]
    if @template_ids.nil?
      respond_to do |format|
        format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Warning', text: 'No Records Found', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end
    else
      @patient = Patient.find_by(id: params[:patient_id])
      @pat_org_id = PatientIdentifier.find_by(patient_id: @patient.id.to_s).try(:patient_org_id)
      @poi = PatientOtherIdentifier.find_by(patient_id: @patient.id.to_s)
      @patient_investigation = Investigation::InvestigationDetail.where(:investigation_record_id.in => @template_ids, is_deleted: false)
      # @type = Investigation::InvestigationDetails::DocumentType.new(investigation.id.to_s).get.constantize

      @lab_records = LabRecord.where(:id.in => @template_ids).order('created_at DESC')
      @lab_record_ids = @lab_records.pluck(:id).map(&:to_s)
      @lab_records = GroupBy::advised_and_performed @lab_records
      # lab_filter_collections
      @radio_records = RadiologyRecord.where(:id.in => @template_ids).order('created_at DESC')
      @radio_record_ids = @radio_records.pluck(:id).map(&:to_s)
      @radio_records = GroupBy::advised_and_performed @radio_records

      @ophthal_records = OphthalmologyRecord.where(:id.in => @template_ids).order('created_at DESC')
      @ophthal_record_ids = @ophthal_records.pluck(:id).map(&:to_s)
      @ophthal_records = GroupBy::advised_and_performed(@ophthal_records)
      @print_settings = PrintSetting.print_options(current_user.organisation_id.to_s, current_facility.id.to_s, ["309935007", "261904005", "309964003"])
    end
  end

  def search_investigation_lists
    @current_date = (Date.parse(params[:current_date]) if params[:current_date]) || Date.current
    @active_tab = params[:active_tab]
    @department = current_user_department
    @filter = params[:filter]
    if params[:q].present?
      @investigation_list = current_facility.investigation_queues.search(@current_date, @department, params[:q], @filter)
    end

    respond_to do |format|
      format.json {}
    end
  end

  def investigation_details_modal_view
    patient_asset = @patient.patientassets
    @patient_asset = (patient_asset.all[-1].asset_path_url if patient_asset.count > 0) || 'placeholder.png'
    @patientid = @patient.id
    @patient_note = PatientNote.where(patient_id: @patientid).order(:created_at => :desc).limit(15)
  end

  private

  def role_restriction
    role_check = ["309935007", "261904005", "309964003"]
    if @current_user.department_ids.any? { |ele| role_check.include? !(ele) }
      redirect_to root_path
    end
  end

  def set_session_params
    @current_user = current_user
    @current_facility = current_facility
  end

  def details_view_params
    @patient = Patient.find_by(id: params[:patient_id])
    @appointment = Appointment.find_by(id: params[:appointment_id])
    @current_date = Date.parse(params[:current_date]) if params[:current_date] || Date.current
    @doctors = User.where(facility_ids: current_facility.id.to_s, role_ids: 158965000)
    @counsellors = User.where(facility_ids: current_facility.id.to_s, is_active: true, role_ids: 499992366)
    @organisation = Organisation.find_by(id: current_user.organisation_id)

    @clinical_workflow_present = (true if @current_facility.clinical_workflow) || false
    if @clinical_workflow_present
      # QueueManagement
      @clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.try(:id).to_s)
      facility_id = current_facility.id
      @queue_management_present = current_facility_setting.queue_management
      primary_department_id = current_user.department_ids[0]
      is_primary_department = ['50121007', '284748001', '261904005', '309935007', '309964003'].include? primary_department_id
      is_department_role = ['ophthalmology_technician', 'radiologist', 'technician'].include? @clinical_workflow.state
      if @queue_management_present
        @stations = QueueManagement::Station.where(facility_id: facility_id, is_deleted: false)
        sub_station_options = if current_facility_setting&.user_set_station
                                { active_user_id: current_user.id, facility_id: facility_id, is_deleted: false }
                              else
                                { user_id: current_user.id, facility_id: facility_id, is_deleted: false }
                              end
        @user_station = QueueManagement::SubStation.find_by(sub_station_options)
        if @clinical_workflow.try(:user_id) == @current_user.id.to_s && @current_date == Date.current &&
          is_department_role && is_primary_department
          @stations_array = GetFacilities.current_facility_stations(facility_id)
        else
          @stations_array = []
        end
      end


      specialty_id = @appointment.specialty_id
      if @clinical_workflow.try(:user_id) == @current_user.id.to_s && @current_date == Date.current &&
        is_department_role && is_primary_department
        @dropdown_users = UsersDropdownHelper.create_opd(specialty_id, facility_id, current_facility_setting)
        @departments_array = DepartmentsDropdownHelper.create(specialty_id, current_user, facility_id)
      else
        @dropdown_users = []
        @departments_array = []
      end
      unless current_user.roles.pluck(:id).include? 499992366
        @dropdown_users.delete('tpa')
      end
      if @clinical_workflow.present?
        @clinical_workflow_timeline = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: @clinical_workflow.id).last_states.limit(5)
        @clinical_workflow_timeline_count = @clinical_workflow_timeline.count
        @clinical_workflow_timeline_second_last = @clinical_workflow_timeline.all[1] if @clinical_workflow_timeline_count > 1
        @clinical_workflow_timeline = @clinical_workflow_timeline.reverse
      end

      if @appointment.consultant_frozen
        @state_transition_consultant_id = @clinical_workflow.opd_clinical_workflow_state_transitions.where(to: 'consultant_id')
      end
    else
      @appointment_list_view = AppointmentListView.find_by(appointment_id: @appointment.try(:id))
      @clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
      @clinical_workflow_timeline = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: @clinical_workflow.id).last_states
      @clinical_workflow_timeline_count = @clinical_workflow_timeline.size
      @clinical_workflow_timeline = @clinical_workflow_timeline.reverse
    end

    # Lab Tests
    @patient_investigation = Investigation::InvestigationDetail.where(patient_id: @patient.id, is_deleted: false, '$or' => [{ :state.nin => ['removed'] }, { date_performed_at: @current_date }, { date_removed_at: @current_date }]).order(advised_at: :desc)

    @department_id = params[:department_id]

    if @department_id == "309935007"
      params[:inv_tab] = 'ophthal'
      @inv_ophthal = @patient_investigation.where(_type: 'Investigation::Ophthal')
    end

    if @department_id == "309964003"
      params[:inv_tab] = 'radiology'
      @inv_radiology = @patient_investigation.where(_type: 'Investigation::Radiology')
    end

    if @department_id == "261904005"
      params[:inv_tab] = 'laboratory'
      @inv_laboratory = @patient_investigation.where(_type: 'Investigation::Laboratory')
    end

    @investigation_present = (true if @patient_investigation.count > 0) || false
    @uploads = PatientSummaryAssetUpload.where(:investigation_detail_id.in => @patient_investigation.pluck(:id).map(&:to_s), is_deleted: false)
  end

  def current_user_department
    if @current_user.role_ids.include?(2822900478)
      return "ophthal"
    elsif @current_user.role_ids.include?(41904004)
      return "radiology"
    elsif @current_user.role_ids.include?(159282002)
      return "laboratory"
    end
  end

  def lab_filter_collections
    @filter_by = params[:filter_by].split(",").uniq if params[:filter_by]
    @advised_dates = []
    @advised_users = []
    @performed_dates = []
    @performed_users = []
    @lab_records.keys.each do |row|
      @advised_dates << row[0]
      @advised_users << [User.find_by(id: row[1]).fullname, row[1]]
      @performed_dates << row[2]
      @performed_users << [User.find_by(id: row[3]).fullname, row[3]]
    end
    @advised_users = @advised_users.uniq
    @advised_dates = @advised_dates.uniq
    @performed_dates = @performed_dates.uniq
    @performed_users = @performed_users.uniq
  end
end
