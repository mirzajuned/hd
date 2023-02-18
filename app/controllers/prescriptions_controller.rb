class PrescriptionsController < ApplicationController
  before_action :authorize
  before_action :authorize_onboard
  layout 'loggedin'
  require 'spreadsheet'
  # require "invoice/inventory/department_invoice"

  # before_action :
  # , only: [:pharmacy_management]
  # before_action :validate_user_optical, only: [:optical_management]
  before_action :conversion_report_initial_params, only: [:show_pharmacy_conversion_report,
                                                          :show_optical_conversion_report]
  before_action :print_settings_pharmacy, only: [:pharmacy_details]
  before_action :print_settings_optical, only: [:optical_details]
  before_action :set_organisation, only: [:pharmacy_details, :optical_details, :pharmacy_management, :optical_management]
  before_action :set_facility_setting, only: [:pharmacy_details, :optical_details, :pharmacy_management, :optical_management]

  def pharmacy_management
    # In Use
    @inventory_stores = Inventory::Store.where(facility_id: current_facility_id, :user_ids.in => [current_user.id],
                                               is_active: true)
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])

    redirect_to '/inventory/stores/284748001' if @inventory_store.blank?
    @current_date = params[:current_date].present? ? Date.parse(params[:current_date]) : Date.current
    @active_tab = params[:active_tab]
    @prescription_id = params[:prescription_id]

    # Queues
    end_of_day = @current_date.strftime('%d/%m/%Y') + ' 23:59:59'
    @all_prescriptions = PatientPrescription.where(encounterdate: @current_date..Time.zone.parse(end_of_day),
                                                   facility_id: current_facility.id, is_deleted: false,
                                                   store_id: params[:store_id]).order('created_at DESC')
    options = { my_queue: true }
    if @organisation.workflow_waiting_disable || @facility_setting.queue_management == false
      options = options.merge!(user_id: current_user.id)
    else
      options = options.merge!(:user_ids.in => [current_user.id.to_s])
    end
    @my_queue_prescriptions = @all_prescriptions.where(options).order('created_at DESC')
    @converted_prescriptions = @all_prescriptions.where(converted: 'true').order('created_at DESC')
    @not_converted_prescriptions = @all_prescriptions.where(converted: 'false').order('created_at DESC')

    get_patient_params(@all_prescriptions.pluck(:patient_id))
  end

  def optical_management
    # In Use
    @inventory_stores = Inventory::Store.where(facility_id: current_facility_id, :user_ids.in => [current_user.id],
                                               is_active: true)
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    redirect_to '/inventory/stores/50121007' if @inventory_store.blank?
    @current_date = params[:current_date].present? ? Date.parse(params[:current_date]) : Date.current

    @active_tab = params[:active_tab]
    @prescription_id = params[:prescription_id]

    # Queues
    store_id = params[:store_id]
    end_of_day = @current_date.strftime('%d/%m/%Y') + ' 23:59:59'
    @all_prescriptions = PatientOpticalPrescription.where(encounterdate: @current_date..Time.zone.parse(end_of_day),
                                                          facility_id: current_facility.id, store_id: store_id,
                                                          :advise_glasses.in => [nil, 'advise'])
                                                   .order('created_at DESC')
    options = { my_queue: true }
    if @organisation.workflow_waiting_disable || @facility_setting.queue_management == false
      options = options.merge!(user_id: current_user.id)
    else
      options = options.merge!(:user_ids.in => [current_user.id.to_s])
    end
    @my_queue_prescriptions = @all_prescriptions.where(options).order('created_at DESC')
    @converted_prescriptions = @all_prescriptions.where(encounterdate: @current_date..Time.zone.parse(end_of_day),
                                                        converted: 'true', facility_id: current_facility.id)
                                                 .order('created_at DESC')
    @not_converted_prescriptions = @all_prescriptions.where(encounterdate: @current_date..Time.zone.parse(end_of_day),
                                                            converted: 'false', facility_id: current_facility.id)
                                                     .order('created_at DESC')

    get_patient_params(@all_prescriptions.pluck(:patient_id))
  end

  def pharmacy_details
    # In Use
    @current_date = Date.parse(params[:current_date]) if params[:current_date] || Date.current
    @prescription = PatientPrescription.find_by(id: params[:prescription_id])

    @translated_language ||= @translated_language

    @medication_groups = begin
                           @prescription.medications.group_by { |d| d[:status].to_s }
                         rescue StandardError
                           nil
                         end

    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @appointment_id = @prescription.appointment_id
    @advice_language = params[:advice_language]
    @appointment = Appointment.find_by(id: @appointment_id.to_s)
    @patient = Patient.find_by(id: @prescription.patient_id)
    @patient_other_identifier = PatientOtherIdentifier.find_by(patient_id: @prescription.patient_id)
    @patient_identifier = PatientIdentifier.find_by(patient_id: @prescription.patient_id)
    @patientid = @patient.id
    @patient_note = PatientNote.where(patient_id: @patientid).order(created_at: :desc).limit(5)
    @initial_referral_type = PatientReferralType.includes(:referral_type, :sub_referral_type).where(patient_id: @patient.try(:id), is_deleted: false).order(created_at: :asc)[0]
    patient_asset = @patient.patientassets
    @advice_set_language = @advice_language
    @patient_invoices = @patient.invoices
    @org_specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])
    @inventory_invoices = Invoice::InventoryInvoice.where(patient_id: @patient.id, department_id: '284748001', is_deleted: false).order_by(created_at: :desc)
    @invoices = @inventory_invoices
    @current_date_last_invoice = @inventory_invoices.where(order_date: params[:current_date]).first
    @return_transactions = Inventory::Transaction::Return.where(patient_id: @patient.id, department_id: '284748001').order_by(created_at: :desc)
    @advance_payments = AdvancePayment.where(patient_id: @patient.id, is_deleted: false, department_id: '284748001')
    @refund_payments = RefundPayment.where(patient_id: @patient.id, is_deleted: false, department_id: '284748001')
    # Age Calculation
    @calculate_age = @patient.calculate_age

    @clinical_workflow_present = (true if current_facility.clinical_workflow) || false
    if @appointment.present?
      @patient_referral_type = PatientReferralType.find_by(appointment_id: @appointment.id, is_deleted: false)
      if @clinical_workflow_present
        # QueueManagement
        @clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
        facility_id = current_facility.id
        @queue_management_present = current_facility_setting.queue_management
        if @queue_management_present
          @stations = QueueManagement::Station.where(facility_id: facility_id, is_deleted: false)
          sub_station_options = if current_facility_setting&.user_set_station
                                  { active_user_id: current_user.id, facility_id: facility_id, is_deleted: false }
                                else
                                  { user_id: current_user.id, facility_id: facility_id, is_deleted: false }
                                end
          @user_station = QueueManagement::SubStation.find_by(sub_station_options)
          sent_to_station_dropdown
          # @stations_array = GetFacilities.current_facility_stations(facility_id)
        end

        @clinical_workflow_timeline = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: @clinical_workflow.id).last_states.limit(5)
        @clinical_workflow_timeline_count = @clinical_workflow_timeline.count
        @clinical_workflow_timeline_second_last = @clinical_workflow_timeline.all[1] if @clinical_workflow_timeline.count > 1
        @clinical_workflow_timeline = @clinical_workflow_timeline.reverse

        @specialty_id = @appointment.specialty_id
        sent_to_users_dropdown

        if @appointment.consultant_frozen
          @state_transition_consultant_id = @clinical_workflow.opd_clinical_workflow_state_transitions.where(to: 'consultant_id')
        end
      else
        @appointment_list_view = AppointmentListView.find_by(appointment_id: @appointment.id)
        @clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
        @clinical_workflow_timeline = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: @clinical_workflow.id).last_states
        @clinical_workflow_timeline_count = @clinical_workflow_timeline.size
        @clinical_workflow_timeline = @clinical_workflow_timeline.reverse
      end
    end
    @patient_asset = if patient_asset.count > 0
                       if patient_asset.last.asset_path_url.present?
                         patient_asset.all[-1].asset_path_url
                       else
                         'placeholder.png'
                       end
                     else
                       'placeholder.png'
                     end
    respond_to do |format|
      format.js { render '/prescriptions/pharmacy/pharmacy_details.js.erb' }
    end
  end

  def optical_details # In Use
    @current_date = Date.parse(params[:current_date]) if params[:current_date] || Date.current
    @prescription = PatientOpticalPrescription.find_by(id: params[:prescription_id])
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @org_specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])
    # Error Handling incase prescription is deleted via opdrecord and optical screen is not refreshed.
    if @prescription.blank?
      respond_to do |format|
        format.js { render inline: "notice = new PNotify({ title: 'Warning', text: 'Record not found: Reloading the page ...', type: 'warning' }); notice.get().click(function(){ notice.remove() }); location.reload();" }
      end

    else
      @appointment_id = @prescription.appointment_id
      @appointment = Appointment.find_by(id: @appointment_id.to_s)
      @patient = Patient.find_by(id: @prescription.patient_id)
      @patient_other_identifier = PatientOtherIdentifier.find_by(patient_id: @prescription.patient_id)
      @patient_identifier = PatientIdentifier.find_by(patient_id: @prescription.patient_id)
      @patientid = @patient.id
      @patient_note = PatientNote.where(patient_id: @patientid).order(created_at: :desc).limit(5)
      @initial_referral_type = PatientReferralType.includes(:referral_type, :sub_referral_type).where(patient_id: @patient.try(:id), is_deleted: false).order(created_at: :asc)[0]
      @patient_referral_type = PatientReferralType.find_by(appointment_id: @appointment.id, is_deleted: false)
      patient_asset = @patient.patientassets
      @inventory_invoices = Invoice::InventoryInvoice.where(patient_id: @patient.id, department_id: '50121007', is_deleted: false).order_by(created_at: :desc)
      @invoices = @inventory_invoices
      @current_date_last_invoice = @inventory_invoices.where(order_date: params[:current_date]).first
      @return_transactions = Inventory::Transaction::Return.where(patient_id: @patient.id, department_id: '50121007').order_by(created_at: :desc)
      @advance_payments = AdvancePayment.where(patient_id: @patient.id, is_deleted: false, department_id: '50121007')
      @refund_payments = RefundPayment.where(patient_id: @patient.id, is_deleted: false, department_id: '50121007')
      # Age Calculation
      @calculate_age = @patient.calculate_age

      @clinical_workflow_present = (true if current_facility.clinical_workflow) || false
      if @clinical_workflow_present
        # QueueManagement
        @clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
        facility_id = current_facility.id
        @queue_management_present = current_facility_setting.queue_management
        if @queue_management_present
          @stations = QueueManagement::Station.where(facility_id: facility_id, is_deleted: false)
          sub_station_options = if current_facility_setting&.user_set_station
                                  { active_user_id: current_user.id, facility_id: facility_id, is_deleted: false }
                                else
                                  { user_id: current_user.id, facility_id: facility_id, is_deleted: false }
                                end
          @user_station = QueueManagement::SubStation.find_by(sub_station_options)
          sent_to_station_dropdown
          # @stations_array = GetFacilities.current_facility_stations(facility_id)
        end

        @clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
        @clinical_workflow_timeline = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: @clinical_workflow.id).last_states.limit(5)
        @clinical_workflow_timeline_count = @clinical_workflow_timeline.count
        @clinical_workflow_timeline_second_last = @clinical_workflow_timeline.all[1] if @clinical_workflow_timeline.count > 1
        @clinical_workflow_timeline = @clinical_workflow_timeline.reverse

        @specialty_id = @appointment.specialty_id
        sent_to_users_dropdown

        if @appointment.consultant_frozen
          @state_transition_consultant_id = @clinical_workflow.opd_clinical_workflow_state_transitions.where(to: 'consultant_id')
        end
      else
        @appointment_list_view = AppointmentListView.find_by(appointment_id: @appointment.id)
        @clinical_workflow = OpdClinicalWorkflow.find_by(appointment_id: @appointment.id.to_s)
        @clinical_workflow_timeline = OpdClinicalWorkflowStateTransition.where(opd_clinical_workflow_id: @clinical_workflow.id).last_states
        @clinical_workflow_timeline_count = @clinical_workflow_timeline.size
        @clinical_workflow_timeline = @clinical_workflow_timeline.reverse
      end

      @patient_asset = if patient_asset.count > 0
                         if patient_asset.last.asset_path_url.present?
                           patient_asset.all[-1].asset_path_url
                         else
                           'placeholder.png'
                         end
                       else
                         'placeholder.png'
                       end
      respond_to do |format|
        format.js { render '/prescriptions/optical/optical_details.js.erb' }
      end

    end
  end

  def pharmacy_mark_converted_form
    @state = params[:state]
    @prescription = PatientPrescription.find_by(id: params[:prescription_id])
    @prescription.update(mark_patient_visited: true)
    @users = User.where(facility_ids: current_facility.id, :role_ids.in => [46255001])

    respond_to do |format|
      format.js { render '/prescriptions/pharmacy/pharmacy_details/mark_converted_form.js.erb' }
    end
  end

  def pharmacy_patient_converted # In Use
    @prescription = PatientPrescription.find_by(id: params[:prescription_id])
    pharmacy_patient_converted = if params[:pharmacy_patient_converted] == 'true'
                                  true
                                 elsif params[:pharmacy_patient_converted] == 'false'
                                  false
                                 elsif params[:pharmacy_patient_converted] == nil
                                  nil
                                 else
                                  params[:pharmacy_patient_converted]
                                 end

    # params[:patient_prescription][:converted] = params[:pharmacy_patient_converted]
    params[:patient_prescription][:converted] = pharmacy_patient_converted
    params[:patient_prescription][:encounterdate] = Time.current
    params[:patient_prescription][:converted_date] = Date.current
    params[:patient_prescription][:converted_datetime] = Time.current
    @pres_prev_state = @prescription.converted
    @prescription.update(pharmacy_converted_update_params)
    if params[:pharmacy_patient_converted] == 'true' || params[:pharmacy_patient_converted] == true
      Analytics::Conversion::PharmacyPrescriptionJob.perform_later(params[:prescription_id].to_s, current_user.id.to_s, 'ClinicalTrue')
    elsif params[:pharmacy_patient_converted] == 'false' || params[:pharmacy_patient_converted] == false
      Analytics::Conversion::PharmacyPrescriptionJob.perform_later(params[:prescription_id].to_s, current_user.id.to_s, 'ClinicalFalse', @pres_prev_state)
    end
    InventoryJobs::PrescriptionDataJob.perform_later('pharmacy', @prescription.id.to_s)
  end

  def optical_mark_converted_form
    @state = params[:state]
    @prescription = PatientOpticalPrescription.find_by(id: params[:prescription_id])
    @prescription.update(mark_patient_visited: true)
    @users = User.where(facility_ids: current_facility, :role_ids.in => [387619007])

    respond_to do |format|
      format.js { render '/prescriptions/optical/optical_details/mark_converted_form.js.erb' }
    end
  end

  def optical_patient_converted # In Use
    @converted = params[:optical_patient_converted]
    not_converted_to_converted = params[:patient_optical_prescription][:not_converted_to_converted]
    if @converted == 'true'
      @prescription = PatientOpticalPrescription.find_by(id: params[:prescription_id])
      converted_by =  params[:patient_optical_prescription][:mark_converted_by] if params[:patient_optical_prescription].present?
      # @prescription.update(converted: 'true', encounterdate: Time.current, mark_converted_by: converted_by)
      @prescription.update(converted: true, encounterdate: Time.current, mark_converted_by: converted_by,
                           converted_date: Date.current, converted_datetime: Time.current,
                           not_converted_to_converted: not_converted_to_converted)
      Analytics::Conversion::OpticalPrescriptionJob.perform_later(params[:prescription_id].to_s, current_user.id.to_s, 'ClinicalTrue')
      InventoryJobs::PrescriptionDataJob.perform_later('optical', @prescription.id.to_s)
    elsif @converted == 'false'
      if  params[:patient_optical_prescription][:reason_one] == 'true' || params[:patient_optical_prescription][:reason_two] == 'true' || params[:patient_optical_prescription][:reason_three] == 'true' || params[:patient_optical_prescription][:reason_four] == 'true' || params[:patient_optical_prescription][:reason_five] == 'true' || params[:patient_optical_prescription][:reason_six] == 'true' || params[:patient_optical_prescription][:reason_seven] == 'true' || params[:patient_optical_prescription][:reason_eight] == 'true' || params[:patient_optical_prescription][:optical_comment].present?
        @prescription = PatientOpticalPrescription.find_by(id: params[:prescription_id])
        @pres_prev_state = @prescription.converted
        # @prescription.update(comment_flag: 'true', converted: 'false', encounterdate: Time.current, mark_converted_by: params[:patient_optical_prescription][:mark_converted_by])
        @prescription.update(comment_flag: 'true', converted: false, encounterdate: Time.current,
                             mark_converted_by: params[:patient_optical_prescription][:mark_converted_by],
                             converted_date: Date.current, converted_datetime: Time.current,
                             not_converted_to_converted: not_converted_to_converted)
        @prescription.update(optical_reason_params)
        Analytics::Conversion::OpticalPrescriptionJob.perform_later(params[:prescription_id].to_s, current_user.id.to_s, 'ClinicalFalse', @pres_prev_state)
        InventoryJobs::PrescriptionDataJob.perform_later('optical', @prescription.id.to_s)
      else
        respond_to do |format|
          format.js { render js: "$('.reason_required_validation').show()" }
        end
      end
    end
  end

  def show_pharmacy_conversion_report
    finding_conversion_reports

    respond_to do |format|
      format.js { render '/prescriptions/pharmacy/show_conversion_report.js.erb' }
    end
  end

  def show_optical_conversion_report
    finding_conversion_reports

    respond_to do |format|
      format.js { render '/prescriptions/optical/show_conversion_report.js.erb' }
    end
  end

  def download_conversion_report
    @facility = current_facility.name
    @current_time = Time.current.strftime('%d%m%y_%I%M%P')
    @filename = "#{@facility}_conversion_report_#{@current_time}.xls"
    conversion_report_initial_params
    finding_conversion_reports

    respond_to do |format|
      format.xls { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}\"" }
    end
  end

  def search_patient # In Use
    r_query = params[:q].to_s
    @filter = params[:filter]
    # @patientlist = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, search: /#{r_query}/i).limit(15)
    if @filter == 'Returning'
      if params[:type] == 'optical'
        @prescriptions = PatientOpticalPrescription.where(facility_id: current_facility.id, search: /#{Regexp.escape(r_query)}/i).order('created_at DESC').limit(15)
      elsif params[:type] == 'pharmacy'
        @prescriptions = PatientPrescription.where(facility_id: current_facility.id, search: /#{Regexp.escape(r_query)}/i).order('created_at DESC').limit(15)
      end
    elsif @filter == 'Active'
      if params[:type] == 'optical'
        @prescriptions = PatientOpticalPrescription.where(facility_id: current_facility.id, encounterdate: Time.zone.parse(params[:current_date])..Time.zone.parse(params[:current_date] + ' 23:59:59'), search: /#{Regexp.escape(r_query)}/i).order('start_time DESC').limit(15)
      elsif params[:type] == 'pharmacy'
        @prescriptions = PatientPrescription.where(facility_id: current_facility.id, encounterdate: Time.zone.parse(params[:current_date])..Time.zone.parse(params[:current_date] + ' 23:59:59'), search: /#{Regexp.escape(r_query)}/i).order('start_time DESC').limit(15)
      end
    end
  end

  def pharmacy # In Use for Redirecting to New URL
    # prescription(PatientPrescription)
    redirect_to prescriptions_pharmacy_management_path
  end

  def optical # In Use for Redirecting to New URL
    # prescription(PatientOpticalPrescription)
    redirect_to prescriptions_optical_management_path
  end

  private

  def sent_to_station_dropdown
    primary_department_id = current_user.department_ids[0]
    is_primary_department = ['50121007', '284748001'].include? primary_department_id
    is_department_role = ['pharmacist', 'optician'].include? @clinical_workflow.state
    if @clinical_workflow.try(:user_id) == @current_user.id.to_s && @current_date == Date.current &&
       is_department_role && is_primary_department
      @stations_array = GetFacilities.current_facility_stations(current_facility.id)
    else
      @stations_array = []
    end
  end

  def sent_to_users_dropdown
    primary_department_id = current_user.department_ids[0]
    is_primary_department = ['50121007', '284748001'].include? primary_department_id
    is_department_role = ['pharmacist', 'optician'].include? @clinical_workflow.state
    if @clinical_workflow.try(:user_id) == @current_user.id.to_s && @current_date == Date.current &&
       is_department_role && is_primary_department
      @dropdown_users = UsersDropdownHelper.create_opd(@specialty_id, current_facility.id, current_facility_setting)
      @departments_array = DepartmentsDropdownHelper.create(@specialty_id, current_user, current_facility.id)
    else
      @dropdown_users = []
      @departments_array = []
    end
    unless current_user.roles.pluck(:id).include? 499992366
      @dropdown_users.delete('tpa')
    end
  end

  def pharmacy_converted_update_params
    params.require(:patient_prescription).permit(:mark_converted_by, :converted, :pharmacy_comment, :encounterdate, :converted_date, :converted_datetime, :not_converted_to_converted)
  end

  def optical_reason_params # In Use
    params.require(:patient_optical_prescription).permit(:reason_one, :reason_two, :reason_three, :reason_four, :reason_five, :reason_six, :reason_seven, :reason_eight, :reason_nine, :optical_comment)
  end

  # def validate_user_pharmacy
  #   if [159282002, 387619007].include?(current_user.role_ids[0])
  #     redirect_to root_url
  #   elsif current_user.role_ids.include?(46255001) && current_facility.show_finances
  #     redirect_to '/inventory/stores/284748001'
  #   end
  # end
  #
  # def validate_user_optical
  #   if [159282002, 46255001].include?(current_user.role_ids[0])
  #     redirect_to root_url
  #   elsif current_user.role_ids.include?(387619007) && current_facility.show_finances && current_facility.organisation_id.to_s != '57f1c8b7666d676c0c000002'
  #     redirect_to '/inventory/stores/50121007'
  #   end
  # end

  def conversion_report_initial_params
    if params[:start_date].present? && params[:end_date]
      @start_date = Date.parse(params[:start_date]).in_time_zone('UTC')
      @end_date = Date.parse(params[:end_date]).in_time_zone('UTC')
    else
      @start_date = Date.current.in_time_zone('UTC')
      @end_date = Date.current.in_time_zone('UTC')
    end

    @start_date = @start_date.beginning_of_day
    @end_date = @end_date.end_of_day
  end

  def finding_conversion_reports
    @inventory_name = params[:inv_name]
    if @inventory_name == 'pharmacy'
      @search_in = 'PatientPrescription'
    elsif @inventory_name == 'optical'
      @search_in = 'PatientOpticalPrescription'
    end

    @all_prescriptions_data = eval(@search_in).where(encounterdate: @start_date..@end_date).group_by { |data| data.encounterdate.strftime('%d/%m/%Y') }.each_with_object({}) { |(key, value), main_set| main_set[key] = value.group_by(&:doctor) }

    if @all_prescriptions_data.count > 0
      @prescription_array = []
      @all_prescriptions_data.each do |key, value|
        value.each do |doc_id, data|
          converted = data.map { |x| x[:converted] }
          count = converted.group_by(&:itself).map { |doc_id, data| [doc_id, data.count] }.to_h
          @prescription_array << [key, doc_id, data.count, count['true'].to_i, count['false'].to_i, count[nil].to_i]
        end
      end
    end
  end

  def print_settings_pharmacy
    @print_settings = PrintSetting.print_options(current_user.organisation_id.to_s, current_facility.id.to_s, ['284748001'])
  end

  def print_settings_optical
    @print_settings = PrintSetting.print_options(current_user.organisation_id.to_s, current_facility.id.to_s, ['50121007'])
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

  def set_organisation
    @organisation = Organisation.find_by(id: current_user.organisation_id)
  end

  def set_facility_setting
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id)
  end
end
