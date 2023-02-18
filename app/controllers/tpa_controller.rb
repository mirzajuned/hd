# 3  Metrics/AbcSize
# 3  Metrics/MethodLength
# 1  Metrics/ClassLength
# 1  Metrics/CyclomaticComplexity
# 1  Metrics/PerceivedComplexity
# --
# 9  Total
class TpaController < ApplicationController
  layout 'loggedin'

  before_action :authorize
  before_action :set_user_facility
  before_action :find_tpa_workflow, only: [:change_state, :complete_tpa_workflow, :undo_tpa_state]
  after_action :update_workflows, only: [:change_state, :start_tpa_process, :end_tpa_process_save, :undo_tpa_process]

  def insurance_management
    @current_date = params[:current_date].present? ? Date.parse(params[:current_date]) : Date.current
    @active_tab = params[:active_tab]
    @tpa_id = params[:tpa_id]

    facility_id = @current_facility.id
    if current_facility.ipd_clinical_workflow
      options = { facility_id: facility_id.to_s, user_id: current_user.id,
                  '$or' => [
                    { current_state: 'Admitted' },
                    { current_state: 'Scheduled', admission_date: @current_date },
                    { current_state: 'Discharged', discharge_date: @current_date }
                  ] }
      @admission_list = AdmissionListView.where(options)
      admission_patient_ids = @admission_list.pluck(:patient_id).map(&:to_s)
    else
      @admission_list = []
      admission_patient_ids = []
    end

    @all_tpa_workflows = TpaInsuranceWorkflow.where(facility_id: facility_id,
                                                    organisation_id: @current_user.organisation_id, is_deleted: false)
                                             .order('created_at DESC')
    @my_queue_list = OpdClinicalWorkflow.where(appointmentdate: @current_date, facility_id: facility_id.to_s,
                                               :state.in => ['tpa_department', 'check_out', 'tpa'], department_id: 450368792,
                                               :patient_id.nin => admission_patient_ids, user_id: current_user.id)
                                        .order('start_time DESC')
    @all_list = @all_tpa_workflows.where(initiation_date: @current_date)
    tpa_states = ['pre_auth_approved', 'pre_auth_query', 'pre_auth_declined', 'pre_auth_final_approval']
    @in_process_list = @all_tpa_workflows.where(:state.in => tpa_states)
                                         .order('created_at DESC')
    @initiation_list = @all_list.where(state: 'pre_auth')
    @pending_payment_list = @all_list.where(state: 'tpa_final_payment')
    @payment_received_list = @all_list.where(state: 'tpa_payment_received')
    @rejected_list = @all_list.where(state: 'tpa_process_ended')
  end

  def tpa_details
    @current_date = params[:current_date]
    @active_tab = params[:active_tab]
    @tpa_id = params[:tpa_id]
    @patient_data = if params[:patient_class].to_s == 'AdmissionListView'
                      AdmissionListView.find_by(id: @tpa_id)
                    elsif params[:patient_class].to_s == 'TpaInsuranceWorkflow'
                      TpaInsuranceWorkflow.find_by(id: @tpa_id)
                    elsif params[:patient_class].to_s == 'OpdClinicalWorkflow'
                      OpdClinicalWorkflow.find_by(id: @tpa_id)
                    end
    if @patient_data
      @patient = Patient.find_by(id: @patient_data.patient_id)

      if params[:patient_class] == 'OpdClinicalWorkflow'
        @appointment = Appointment.find_by(id: @patient_data.appointment_id)
        @clinical_workflow_present = current_facility.clinical_workflow
        @clinical_workflow = @patient_data
        @clinical_workflow_timeline = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: @clinical_workflow.id).order_by('created_at ASC')
        @clinical_workflow_timeline_count = @clinical_workflow_timeline.size
      end

      # my-queue tab data details
      if @patient_data.class.to_s != 'TpaInsuranceWorkflow'
        @show_tpa_data = false
        tpa_options = if params[:patient_class] == 'AdmissionListView'
                        { admission_id: @patient_data.try(:admission_id), is_deleted: false }
                      else
                        { appointment_id: @patient_data.try(:appointment_id), is_deleted: false }
                      end
        @workflow = TpaInsuranceWorkflow.find_by(tpa_options)
      else
        @show_tpa_data = true
        @workflow = @patient_data
      end

      if @workflow.present?
        @tpa_workflow_present = true
        @admission = Admission.find_by(id: @workflow.admission_id)
        @admission_list_view = AdmissionListView.find_by(admission_id: @admission.try(:id))
        @courier_save = Inpatient::Insurance::Courier.find_by(admission_id: @admission.try(:id))
        @insurance_details = TpaInsurancePreAuthorizationForm.find_by(tpa_insurance_workflow_id: @workflow.id)
        @past_estimate_receipts = Invoice::InsuranceEstimate.where(tpa_insurance_workflow_id: @workflow.id,
                                                                   patient_id: @workflow.patient_id)
        @counsellor_record = CounsellorRecord.find_by(appointment_id: @workflow.appointment_id)
        @tpa_workflow_timeline = @workflow.tpa_insurance_workflow_state_transitions.last_states
      end

      # Workflow
      if current_facility.ipd_clinical_workflow && params[:patient_class] == 'AdmissionListView' && @workflow.present?
        specialty_id = @admission.specialty_id
        @dropdown_users = UsersDropdownHelper.create_ipd(specialty_id, current_facility.id)

        @state_transitions = @admission_list_view.admission_state_transitions
        @transition_users = User.where(:id.in => @state_transitions.pluck(:user_id))
                                .map { |user| { id: user.id, name: user.fullname, role_ids: user.role_ids } }
      end

      # case when patient_tpa_workflow is not linked to any admission
      unless @admission
        @unlinked_admission = Admission.find_by(patient_id: @patient.id, is_deleted: false, isdischarged: false)
      end

      patient_asset = @patient.patientassets
      @patient_identifier = PatientIdentifier.find_by(patient_id: @patient.id)
      @tpa_notes = TpaInsuranceNote.where(patient_id: @patient.id, tpa_insurance_workflow_id: @workflow.try(:id))
      @patient_asset = if patient_asset.count > 0
                         if patient_asset.last.asset_path_url.present?
                           patient_asset.all[-1].asset_path_url
                         else
                           'placeholder.png'
                         end
                       else
                         'placeholder.png'
                       end

      @patient_notes = PatientNote.where(patient_id: @patient.id).order(created_at: :desc).limit(5)
      @counsellor_notes = CounsellorNote.where(patient_id: @patient.id).order(created_at: :desc).limit(5)

      if @current_facility.show_finances
        if params[:patient_class] == 'AdmissionListView' || @patient_data.admission_id.present?
          @admission = Admission.find_by(id: @patient_data.admission_id)
          @invoices = Invoice::Ipd.where(admission_id: @admission.id)
          @past_invoices = Invoice::Ipd.where(patient_id: @patient.id)
        else
          @appointment = Appointment.find_by(id: @patient_data.appointment_id)
          @invoices = Invoice::Opd.where(appointment_id: @appointment.id)
          @past_invoices = Invoice::Opd.where(patient_id: @patient.id)
        end
        @patient_invoices = Invoice.where(:_type.in => ['Invoice::Opd', 'Invoice::Ipd'], patient_id: @patient.id.to_s, is_deleted: false)
        @invoice_templates = InvoiceTemplate.where(facility_id: @current_facility.id, version: 'v21.0')
        @advance_payments = AdvancePayment.where(patient_id: @patient.id, is_deleted: false,
                                                 :department_id.nin => ['50121007', '284748001'])
        @refund_payments = RefundPayment.where(patient_id: @patient.id, is_deleted: false,
                                               :department_id.nin => ['50121007', '284748001'])
        @cash_register_templates = CashRegisterTemplate.where(user_id: @current_user.id)
        @past_cash_registers = CashRegister.where(patient_id: @patient.id)
      end
    end

    respond_to do |format|
      format.js { render 'tpa/insurance/tpa_details' }
    end
  end

  def start_tpa_process
    if params[:model_class] == 'AdmissionListView'
      workflow = AdmissionListView.find_by(id: params[:workflow_id])
      @tpa_workflow = TpaInsuranceWorkflow.find_by(admission_id: workflow.admission_id, is_deleted: true)
    else
      workflow = OpdClinicalWorkflow.find_by(id: params[:workflow_id])
      @tpa_workflow = TpaInsuranceWorkflow.find_by(appointment_id: workflow.appointment_id, is_deleted: true)
    end

    if @tpa_workflow
      @tpa_workflow.update(is_deleted: false)
    else
      options = {
        is_deleted: false, patient_id: workflow.patient_id, tpa_user_id: current_user.id,
        facility_id: @current_facility.id, organisation_id: current_user.organisation.id, user_id: params[:to_user],
        patient_name: workflow&.patient_name, initiation_date: Date.current, start_time: Time.current,
        patient_age: workflow&.patient_age, patient_gender: workflow&.patient_gender
      }

      options = if params[:model_class] == 'AdmissionListView'
                  options.merge(
                    admission_id: workflow.admission_id, admission_date: workflow&.admission_date,
                    patient_identifier: workflow&.patient_display_id, patient_mrno: workflow&.patient_mr_no
                  )
                else
                  options.merge(
                    admission_id: params[:admission_id], appointment_id: workflow.appointment_id.to_s,
                    appointmentdate: workflow&.appointmentdate, patient_mobilenumber: workflow&.patient_mobilenumber,
                    appointment_type_label: workflow&.appointment_type_label,
                    appointment_type_color: workflow&.appointment_type_color,
                    patient_identifier: workflow&.patient_identifier, appointmentstatus: workflow&.appointmentstatus,
                    patient_mrno: workflow&.patient_mrno, patient_type: workflow&.patient_type,
                    patient_type_color: workflow&.patient_type_color, token_number: workflow&.try(:token_number)
                  )
                end
      @tpa_workflow = TpaInsuranceWorkflow.create(options)
    end

    respond_to do |format|
      format.js { render 'tpa/insurance/update_tpa_workflow' }
    end
  end

  def undo_tpa_process
    @tpa_workflow = TpaInsuranceWorkflow.find_by(id: params[:tpa_workflow_id])
    @tpa_workflow.update(is_deleted: true)
    @tpa_state = nil

    respond_to do |format|
      format.js { render 'tpa/insurance/update_tpa_workflow' }
    end
  end

  def end_tpa_process_form
    @tpa_workflow_id = params[:tpa_workflow_id]

    respond_to do |format|
      format.js { render 'tpa/insurance/end_tpa_process_form' }
    end
  end

  def end_tpa_process_save
    @tpa_workflow = TpaInsuranceWorkflow.find_by(id: params[:tpa_workflow_id])

    admission = Admission.find_by(id: @tpa_workflow.admission_id)
    admission&.update(insurance_status: 'tpa_process_ended', is_insured: 'No')

    @opd_workflow = OpdClinicalWorkflow.find_by(appointment_id: @tpa_workflow.appointment_id.to_s)
    @opd_workflow.update(tpa_admission_id: nil) if @opd_workflow.present?

    if @tpa_workflow.update(end_process_reason: params[:end_process_reason], admission_id: nil)
      @tpa_workflow.send('tpa_process_ended')
    end
    @tpa_state = @tpa_workflow.state

    respond_to do |format|
      format.js { render 'tpa/insurance/update_tpa_workflow' }
    end
  end

  def change_state
    @state = params[:state]
    if @state == 'pre_auth'
      @tpa_workflow&.send('pre_auth')
    elsif @state == 'pre_auth_query'
      @tpa_workflow&.send('pre_auth_query')
    elsif @state == 'tpa_final_payment'
      @tpa_workflow&.send('tpa_final_payment')
    elsif @state == 'pre_auth_final_approval'
      @tpa_workflow&.send('pre_auth_final_approval')
    elsif @state == 'tpa_payment_received'
      @tpa_workflow&.send('tpa_payment_received')
    elsif @state == 'pre_auth_approved'
      @tpa_workflow&.send('pre_auth_approved')
    elsif @state == 'pre_auth_declined'
      @tpa_workflow&.send('pre_auth_declined')
    # elsif @state == 'tpa_process_ended'
    #   @tpa_workflow&.send('tpa_process_ended')
    end
    # @tpa_workflow&.instance_eval(@state.to_s)

    if @tpa_workflow.admission_id.present?
      @admission = Admission.find_by(id: @tpa_workflow.admission_id)
      @admission.update(insurance_status: @tpa_workflow.state, is_insured: 'Yes')
      AdmissionsHelper.update_milestone(@admission, @state, 2, current_user.id)
    end
    @tpa_state = @tpa_workflow.state

    respond_to do |format|
      format.js { render 'tpa/insurance/update_tpa_workflow' }
    end
  end

  def undo_tpa_state
    if @tpa_workflow_timeline
      @to = @tpa_workflow_timeline.all[-1]
      @tpa_workflow.update_attributes(state: @to.from)
      @to.delete
    end

    respond_to do |format|
      format.js { render 'tpa/insurance/update_tpa_workflow' }
    end
  end

  private

  def set_user_facility
    @current_user = current_user
    @current_facility = current_facility
  end

  def find_tpa_workflow
    @current_user = current_user
    @tpa_workflow = TpaInsuranceWorkflow.find_by(id: params[:workflow_id])

    @tpa_workflow_present = true
    @tpa_workflow_timeline = @tpa_workflow&.tpa_insurance_workflow_state_transitions&.last_states
  end

  def update_workflows
    @opd_workflow = ::OpdClinicalWorkflow.find_by(appointment_id: @tpa_workflow.appointment_id.to_s)
    @opd_workflow&.update(tpa_state: @tpa_state)

    @counsellor_workflow = CounsellorWorkflow.find_by(appointment_id: @tpa_workflow.appointment_id.to_s)
    @counsellor_workflow&.update(tpa_state: @tpa_state)

    @admission_list_view = AdmissionListView.find_by(admission_id: @tpa_workflow.admission_id.to_s)
    @admission_list_view&.update(tpa_state: @tpa_state)
  end
end
