class Invoice::RefundPaymentsController < ApplicationController
  before_action :authorize
  before_action :set_refund_payment, only: [:show, :edit, :update, :print, :destroy, :refund, :print_refund]

  def index
    @refund_payments = RefundPayment.where(patient_id: params[:patient_id], refund_state: 'None', is_deleted: false)
  end

  def new
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @patient_id = params[:patient_id]
    @type = params[:type]
    @department_id, @department_name = department_details(@type)
    @refund_type = params[:refund_type]
    @is_canceled = (@refund_type == 'Cancellation') ? true : false
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)
    @is_first_refund = true
    if params[:advance_payment_id].present?
      @advance_payment_id = params[:advance_payment_id]
      @advance_payment = AdvancePayment.find_by(id: @advance_payment_id)
      @amount_remaining = @advance_payment.try(:amount_remaining)
    end

    if params[:invoice_id].present?
      @invoice_id = params[:invoice_id]
      @invoice = Invoice.find_by(id: @invoice_id)
      @payment_received_advance_val = @invoice.final_received_amount
      @amount_remaining = @payment_received_advance_val - @invoice.try(:refund_amount).try(:to_f)
      @is_first_refund = false if RefundPayment.where(invoice_id: @invoice_id).count > 0
    end

    @refund_payment = RefundPayment.new
  end

  def create
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    params[:refund_payment][:bkp_refund_display_id] = CommonHelper.get_refund_identifier(current_user)
    invoice_id = params[:refund_payment][:invoice_id]
    @invoice = Invoice.find_by(id: invoice_id) if invoice_id.present?
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)
    advance_payment_id = params[:refund_payment][:advance_payment_id]
    @advance_payment = AdvancePayment.find_by(id: advance_payment_id) if advance_payment_id.present?

    @refund_type = params[:refund_payment][:refund_type]
    @refund_payment = RefundPayment.new(refund_invoice_params)
    if @refund_payment.save
      # generate all the sequences for refund_payment
      refund_display_id = SequenceManagers::GenerateSequenceService.call('refund_payment', @refund_payment.id.to_s, {organisation_id: current_organisation['_id'].to_s, facility_id: current_facility['_id'].to_s, region_id: current_facility['region_master_id'].to_s, department_id: @refund_payment.department_id})
      @refund_payment.update(refund_display_id: refund_display_id)
      # EOF generate all the sequences for refund_payment
      @patient = Patient.find_by(id: @refund_payment.patient_id.to_s)
      print_settings(@refund_payment.type)

      InvoiceJobs::ManageCollectionDataJob.perform_later(@refund_payment.id.to_s, 'Refund')
      if @advance_payment.present?
        @type = @advance_payment.type.to_s.downcase
        if @refund_type == 'Cancellation'
          advance_payment_hash = {
            is_canceled: true, refund_amount: @refund_payment.amount, 
            refund_date: Time.current.strftime('%d/%m/%Y'),
            refund_time: Time.current.strftime('%I:%M %p, %d/%m/%Y'), is_refunded: true,
            refunded_by: current_user.try(:fullname), refunded_by_id: current_user.try(:id),
            refund_reason: @refund_payment.reason, canceled_by_id: current_user.id
          }
        else
          advance_payment_hash = {
            refund_amount: @refund_payment.amount, refund_date: Time.current.strftime('%d/%m/%Y'),
            refund_time: Time.current.strftime('%I:%M %p, %d/%m/%Y'), is_refunded: true,
            refunded_by: current_user.try(:fullname), refunded_by_id: current_user.try(:id),
            refund_reason: @refund_payment.reason
          }
        end
        @advance_payment.update(advance_payment_hash)
        InvoiceJobs::AdvancePaymentJob.perform_later(@advance_payment.id.to_s)
        @refund_payments = RefundPayment.where(advance_payment_id: @advance_payment.id)
        Patients::Summary::TimelineWorker.call(event_name: "#{@refund_payment.type.upcase}_ADVANCE", sub_event_name: 'REFUNDED', advance_payment_id: @advance_payment.id, user_id: current_user.id, user_name: current_user.fullname, encounter_type: @refund_payment.type.upcase.to_s)
      end

      if @invoice.present?
        @invoice_type = @invoice._type
        @type = @invoice_type.split('::')[1].to_s.downcase
        old_refund_amount = @invoice.try(:refund_amount).try(:to_f) || 0
        new_refund_amount = old_refund_amount + @refund_payment.amount
        if @refund_type == 'Cancellation'
          invoice_hash = {
            is_canceled: true, refund_amount: new_refund_amount, refund_date: Time.current.strftime('%d/%m/%Y'),
            refund_time: Time.current.strftime('%I:%M %p, %d/%m/%Y'), is_refunded: true,
            refunded_by: current_user.try(:fullname), refunded_by_id: current_user.try(:id),
            refund_reason: @refund_payment.reason, canceled_by_id: current_user.id
          }
          @invoice.payment_pending_breakups.update_all(is_canceled: true, cancel_date: Date.current, cancel_time: Time.current)
        else
          invoice_hash = {
            refund_amount: new_refund_amount, refund_date: Time.current.strftime('%d/%m/%Y'),
            refund_time: Time.current.strftime('%I:%M %p, %d/%m/%Y'), is_refunded: true,
            refunded_by: current_user.try(:fullname), refunded_by_id: current_user.try(:id),
            refund_reason: @refund_payment.reason
          }
        end
        @invoice.update(invoice_hash)
        Patients::Summary::TimelineWorker.call(event_name: "#{@refund_payment.type.upcase}_INVOICE", sub_event_name: 'REFUNDED', invoice_id: @invoice.id, user_id: current_user.id, user_name: current_user.fullname, encounter_type: @refund_payment.type.upcase.to_s)
        # Bill of material
        bill_of_materials = @invoice.services.where(entry_type: 'bill_of_material')
        unless bill_of_materials.empty?
          bill_of_materials.each do |bom|
            bill_of_material = Inpatient::BillOfMaterial.find_by(id: bom.description)
            bill_of_material.update(ipd_invoice_id: nil, is_billed: false, ipd_invoice_date: nil, ipd_invoice_time: nil)
          end
        end
        InvoiceJobs::ManageRevenueDataJob.perform_later(@invoice.id.to_s)
        @refund_payments = RefundPayment.where(invoice_id: @invoice.id)

        if @refund_payment.try(:type).to_s.upcase == "OPD"
          fetch_opd_assessment_data
        elsif @refund_payment.try(:type).to_s.upcase == "IPD"
          fetch_ipd_assessment_data
        end

      end
      InvoiceJobs::CancelReturnInvoiceJob.perform_later(@refund_payment.id.to_s, 'return', 'receipt')
      if @refund_payment.try(:department_id)  == '284748001'
        CommunicationNotificationJob.perform_now('pharmacy_bill_cancelled', @refund_payment.id.to_s, @refund_payment.class.to_s)
      elsif @refund_payment.try(:department_id) == '50121007'
        CommunicationNotificationJob.perform_now('optical_bill_cancelled', @refund_payment.id.to_s, @refund_payment.class.to_s)
      end
      respond_to do |format|
        format.js { render 'invoice/refund_payments/show' }
      end
    else
      render 'new'
    end
  end

  def show
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @patient = Patient.find_by(id: @refund_payment.patient_id)
    @invoice_id = @refund_payment.try(:invoice_id)
    @advance_payment_id = @refund_payment.try(:advance_payment_id)
    @invoice = Invoice.find_by(id: @invoice_id) if @invoice_id.present?
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)
    @advance_payment = AdvancePayment.find_by(id: @advance_payment_id) if @advance_payment_id.present?
    print_settings(@refund_payment.type)
  end

  def edit
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @patient_id = params[:patient_id]
    @type = params[:type]
    @refund_type = params[:refund_type]
    @is_canceled = (@refund_type == 'Cancellation') ? true : false
    @is_first_refund = true
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)
    if @refund_payment.department_id.present?
      @department_id = @refund_payment.department_id
      @department_name = @refund_payment.department_name
    else
      @department_id, @department_name = department_details(@refund_payment.type)
    end

    if params[:invoice_id].present?
      @invoice_id = params[:invoice_id]
      @invoice = Invoice.find_by(id: @invoice_id)
      @is_first_refund = false if RefundPayment.where(invoice_id: @invoice_id).count > 1
    end

    if params[:advance_payment_id].present?
      @advance_payment_id = params[:advance_payment_id]
      @advance_payment = AdvancePayment.find_by(id: @advance_payment_id)
    end
  end

  def update
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    invoice_id = params[:refund_payment][:invoice_id]
    @invoice = Invoice.find_by(id: invoice_id) if invoice_id.present?

    advance_payment_id = params[:refund_payment][:advance_payment_id]
    @advance_payment = AdvancePayment.find_by(id: advance_payment_id) if advance_payment_id.present?
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)
    @refund_type = params[:refund_payment][:refund_type]
    if @refund_payment.update_attributes(refund_invoice_params)
      @patient = Patient.find_by(id: @refund_payment.patient_id.to_s)
      print_settings(@refund_payment.type)
      InvoiceJobs::ManageCollectionDataJob.perform_later(@refund_payment.id.to_s, 'Refund')

      is_advance = false
      if @advance_payment.present?
        @type = @advance_payment.type.to_s.downcase

        if @refund_type == 'Cancellation'
          advance_payment_hash = {
            is_canceled: true, refund_amount: @refund_payment.amount, 
            refund_date: Time.current.strftime('%d/%m/%Y'),
            refund_time: Time.current.strftime('%I:%M %p, %d/%m/%Y'), is_refunded: true,
            refunded_by: current_user.try(:fullname), refunded_by_id: current_user.try(:id),
            refund_reason: @refund_payment.reason, canceled_by_id: current_user.id
          }
        else
          advance_payment_hash = {
            refund_amount: @refund_payment.amount, refund_date: Time.current.strftime('%d/%m/%Y'),
            refund_time: Time.current.strftime('%I:%M %p, %d/%m/%Y'), is_refunded: true,
            refunded_by: current_user.try(:fullname), refunded_by_id: current_user.try(:id),
            refund_reason: @refund_payment.reason
          }
        end
        @advance_payment.update(advance_payment_hash)
        InvoiceJobs::AdvancePaymentJob.perform_later(@advance_payment.id.to_s)
        @refund_payments = RefundPayment.where(advance_payment_id: @advance_payment.id)
      end

      if @invoice.present?
        @invoice_type = @invoice._type
        @type = @invoice_type.split('::')[1].to_s.downcase
        old_refund_amount = @invoice.try(:refund_amount).try(:to_f) || 0
        new_refund_amount = old_refund_amount + @refund_payment.amount
        if @refund_type == 'Cancellation'
          invoice_hash = {
            is_canceled: true, refund_amount: new_refund_amount, 
            refund_date: Time.current.strftime('%d/%m/%Y'),
            refund_time: Time.current.strftime('%I:%M %p, %d/%m/%Y'), is_refunded: true,
            refunded_by: current_user.try(:fullname), refunded_by_id: current_user.try(:id),
            refund_reason: @refund_payment.reason, canceled_by_id: current_user.id
          }
        else
          invoice_hash = {
            refund_amount: new_refund_amount, refund_date: Time.current.strftime('%d/%m/%Y'),
            refund_time: Time.current.strftime('%I:%M %p, %d/%m/%Y'), is_refunded: true,
            refunded_by: current_user.try(:fullname), refunded_by_id: current_user.try(:id),
            refund_reason: @refund_payment.reason
          }
        end

        @invoice.update(invoice_hash)

        Patients::Summary::TimelineWorker.call(event_name: "#{@refund_payment.type.upcase}_INVOICE", sub_event_name: 'REFUNDED', invoice_id: @invoice.id, user_id: current_user.id, user_name: current_user.fullname, encounter_type: @refund_payment.type.upcase.to_s)
        InvoiceJobs::ManageRevenueDataJob.perform_later(@invoice.id.to_s)
        @refund_payments = RefundPayment.where(invoice_id: @invoice.id)
      end
      InvoiceJobs::CancelReturnInvoiceJob.perform_later(@refund_payment.id.to_s, 'return', 'receipt')
      respond_to do |format|
        format.js { render 'invoice/refund_payments/show' }
      end
    else
      render 'edit'
    end
  end

  def print
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @organisation = current_user.organisation
    @patient = Patient.find_by(id: @refund_payment.patient_id)
    @user = User.find_by(id: @refund_payment.user_id)
    @invoice_id = @refund_payment.try(:invoice_id)
    @invoice = Invoice.find_by(id: @invoice_id) if @invoice_id.present?
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'Invoice')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    currency_symbol = (@refund_payment.currency_symbol || current_facility.currency_symbol)
    @locals = { mail_job: false, patient: @patient, appointment: @appointment, invoice: @invoice, refund_payment: @refund_payment, facility_setting: @facility_setting, flag: 'Invoice', invoice_setting: @invoice_setting, organisation_settings: @organisation_settings, currency_symbol: currency_symbol }
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])

    respond_to do |format|
      format.pdf { render template: 'invoice/refund_payments/print.pdf.erb', pdf: 'RefundPayment', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_i * 10, right: @print_setting.try(:right_margin).to_i * 10, top: @print_setting.try(:header_height).to_i * 10, bottom: @print_setting.try(:footer_height).to_i * 10 }, locals: @locals }
    end
  end

  def destroy
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @refund_payment.update(is_deleted: true, refund_state: 'Deleted')
  end

  private

  # department_details
  def department_details(type)
    department_id =
      if type == 'OPD' # 485396012
        '485396012'
      elsif type == 'IPD' # 486546481
        '486546481'
      elsif type == 'Pharmacy'
        '284748001'
      elsif type == 'Optical'
        '50121007'
      end
    department_name = department_id ? Department.find_by(id: department_id).try(:display_name) : nil
    [department_id, department_name]
  end

  def refund_invoice_params
    params.require(:refund_payment).permit(
      :type, :currency_symbol, :currency_id, :patient_id, :user_id, :facility_id, 
      :organisation_id, :reason, :mode_of_payment, :payment_date, :payment_time, :amount, 
      :amount_remaining, :cash, :card, :cheque_note, :transfer_note, :other_note, :cheque_date, 
      :card_number, :transfer_date, :bkp_refund_display_id, :refund_display_id, :specialty_id,
      :invoice_id, :invoice_received_amount, :invoice_total_amount, :bill_number, 
      :advance_display_id, :refund_type, :advance_total_amount, :advance_remaining_amount, 
      :advance_payment_id, :department_id, :department_name, :refund_payment_type, :store_id, 
      :canceled_by, :canceled_by_id, :is_canceled, :cancel_date, 
      :refunded_by, :refunded_by_id, :is_refunded, :refund_date, :refund_time, 
      :card_transaction_note, :paytm_transaction_id, :paytm_transaction_note, 
      :gpay_transaction_id, :gpay_transaction_note,
      :phonepe_transaction_id, :phonepe_transaction_note, :other_transaction_id
    )
  end

  def set_refund_payment
    @refund_payment = RefundPayment.find_by(id: params[:id])
  end

  def print_settings(type)
    organisation_id = current_user.organisation_id.to_s
    facility_id = current_facility.id.to_s
    department_id = type == 'OPD' ? ['485396012'] : ['486546481']
    @print_settings = PrintSetting.print_options(organisation_id, facility_id, department_id)
  end

  def fetch_opd_assessment_data
    case_sheet = CaseSheet.where(patient_id: @patient.id,:appointment_ids.in=> [@invoice.appointment_id.to_s])[0]

    if case_sheet.present?
      @visit_diagnoses = case_sheet.diagnoses.where(appointment_id: @invoice.appointment_id.to_s)
      @visit_ophthal_investigations = case_sheet.ophthal_investigations.where(appointment_id: @invoice.appointment_id.to_s,is_disabled: false)
      @visit_laboratory_investigations = case_sheet.laboratory_investigations.where(appointment_id: @invoice.appointment_id.to_s,is_disabled: false)
      @visit_radiology_investigations = case_sheet.radiology_investigations.where(appointment_id: @invoice.appointment_id.to_s,is_disabled: false)
    else
      @visit_diagnoses = nil
      @visit_ophthal_investigations = nil
      @visit_laboratory_investigations = nil
      @visit_radiology_investigations = nil
    end
  end


  def fetch_ipd_assessment_data
    @ipd_record = Inpatient::IpdRecord.where(admission_id: @invoice.admission_id.to_s)[0]

    @visit_diagnoses = @ipd_record.try(:diagnosislist)

    if @ipd_record.try(:procedure).present?
      @visit_procedures = @ipd_record.try(:procedure).where(is_performed: true)
    end

    # @visit_ophthal_investigations = @ipd_record.ophthal_investigations_list.where(is_disabled: false)
    # @visit_laboratory_investigations = @ipd_record.laboratory_investigations_list.where(is_disabled: false)
    # @visit_radiology_investigations = @ipd_record.radiology_investigations_list.where(is_disabled: false)
    @visit_ophthal_investigations = nil
    @visit_laboratory_investigations = nil
    @visit_radiology_investigations = nil
  end
end
