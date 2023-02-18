class Invoice::AdvancePaymentsController < ApplicationController
  before_action :authorize
  before_action :set_advance_payment, only: [:show, :edit, :update, :print, :destroy, :refund, :print_refund]

  def index
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @advance_payments = AdvancePayment.where(patient_id: params[:patient_id], advance_state: 'None', is_deleted: false)
  end

  def new
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @patient_id = params[:patient_id]
    @type = params[:type]
    @invoice = Invoice.find_by(id: params[:invoice_id])
    @inventory_order = Invoice::InventoryOrder.find_by(id: params[:order_id])
    @department_id, @department_name = department_details(@type)

    @advance_payment = AdvancePayment.new
  end

  def create
    if params[:advance_payment][:order_id].present?
      order_id = params[:advance_payment][:order_id]
      @inventory_order = Invoice::InventoryOrder.find_by(id: order_id)
      amount_remaining = @inventory_order.amount_remaining
      advance_amount = params[:advance_payment][:amount].to_f
      @advance_payment = (AdvancePayment.new(advance_invoice_params) if advance_amount <= amount_remaining)
    else
      @advance_payment = AdvancePayment.new(advance_invoice_params)
    end

    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    params[:advance_payment][:bkp_advance_display_id] = CommonHelper.get_advance_identifier(current_user)
    @advance_payment = AdvancePayment.new(advance_invoice_params)

    if @advance_payment.present? && @advance_payment.save
      # generate all the sequences for advance_payment
      advance_display_id = SequenceManagers::GenerateSequenceService.call(
        'advance_payment', @advance_payment.id.to_s, {organisation_id: current_organisation['_id'].to_s, facility_id:  current_facility['_id'].to_s, department_id: @advance_payment.department_id, region_id: current_facility['region_master_id'].to_s}
      )
      @advance_payment.update(advance_display_id: advance_display_id)
      # EOF generate all the sequences for advance_payment
      @patient = Patient.find_by(id: @advance_payment.patient_id.to_s)
      print_settings(@advance_payment.type)

      InvoiceJobs::ManageCollectionDataJob.perform_later(@advance_payment.id.to_s, 'Advance')
      if @advance_payment.store_id.present? && (@advance_payment.invoice_id.present? || @advance_payment.order_id.present?)
        invoice_id = @advance_payment.invoice_id.present? ? @advance_payment.invoice_id : @advance_payment.order_id
        type = @advance_payment.invoice_id.present? ? 'invoice' : 'order'
        Inventory::Transactions::CreateAdvancePaymentService.call(invoice_id, @advance_payment.id,
                                                                  current_user.fullname, @advance_payment.amount,
                                                                  'advance_against_order', type)
      end
      InvoiceJobs::AdvancePaymentJob.perform_later(@advance_payment.id.to_s)
      if @advance_payment.try(:department_id) == '284748001'
        CommunicationNotificationJob.perform_now('pharmacy_bill_creation', @advance_payment.id.to_s, @advance_payment.class.to_s)
      elsif @advance_payment.try(:department_id) == '50121007'
        CommunicationNotificationJob.perform_now('optical_order_placed', @advance_payment.id.to_s, @advance_payment.class.to_s)
      end
      respond_to do |format|
        if @advance_payment.store_id.present? && (@advance_payment.invoice_id.present? || @advance_payment.order_id.present?)
          if @advance_payment.invoice_id.present?
            @inventory_invoice = Invoice::InventoryInvoice.find_by(id: @advance_payment.invoice_id)
            @inventory_store = Inventory::Store.find_by(id: @inventory_invoice.store_id)
            @prescription = PatientOpticalPrescription.find_by(id: @inventory_invoice.prescription_id)
            @appointment = Appointment.find_by(id: @prescription.appointment_id) if @prescription.present?
            header_templates(@inventory_invoice)
            format.js { render 'invoice/inventory_invoices/print_preview.js.erb' }
          else
            @inventory_order = Invoice::InventoryOrder.find_by(id: @advance_payment.order_id)
            @inventory_store = Inventory::Store.find_by(id: @inventory_order.store_id)
            @prescription = PatientOpticalPrescription.find_by(id: @inventory_order.prescription_id)
            @appointment = Appointment.find_by(id: @prescription.appointment_id) if @prescription.present?
            header_templates(@inventory_order)
            format.js { render 'invoice/inventory_orders/print_preview.js.erb' }
          end
        else
          format.js { render 'invoice/advance_payments/show' }
        end
      end
      Patients::Summary::TimelineWorker.call(event_name: "#{@advance_payment.type.upcase}_ADVANCE", sub_event_name: 'CREATED', advance_payment_id: @advance_payment.id, user_id: current_user.id, user_name: current_user.fullname, encounter_type: @advance_payment.type, is_draft: false)
    else
      @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
      @patient_id = params[:advance_payment][:patient_id]
      @type = params[:advance_payment][:type]
      @invoice = Invoice.find_by(id: params[:advance_payment][:invoice_id])
      @inventory_order = Invoice::InventoryOrder.find_by(id: params[:advance_payment][:order_id])
      @department_id, @department_name = department_details(@type)

      @advance_payment = AdvancePayment.new
      render 'new'
    end
  end

  def show
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @patient = Patient.find_by(id: @advance_payment.patient_id)
    print_settings(@advance_payment.type)
  end

  def edit
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    if @advance_payment.department_id.present?
      @department_id = @advance_payment.department_id
      @department_name = @advance_payment.department_name
    else
      @department_id, @department_name = department_details(@advance_payment.type)
    end
  end

  def update
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    if @advance_payment.update_attributes(advance_invoice_params)
      @patient = Patient.find_by(id: @advance_payment.patient_id.to_s)
      print_settings(@advance_payment.type)
      InvoiceJobs::AdvancePaymentJob.perform_later(@advance_payment.id.to_s)
      InvoiceJobs::ManageCollectionDataJob.perform_later(@advance_payment.id.to_s, 'Advance')
      respond_to do |format|
        format.js { render 'invoice/advance_payments/show' }
      end
    else
      render 'edit'
    end
  end

  def print
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @organisation = current_user.organisation
    @patient = Patient.find_by(id: @advance_payment.patient_id)
    @user = User.find_by(id: @advance_payment.user_id)
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'Invoice')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    currency_symbol = (@advance_payment.currency_symbol || current_facility.currency_symbol)
    @locals = { mail_job: false, patient: @patient, appointment: @appointment, invoice: @invoice, refund_payment: @refund_payment, facility_setting: @facility_setting, flag: 'Invoice', invoice_setting: @invoice_setting, organisation_settings: @organisation_settings, currency_symbol: currency_symbol }
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])

    respond_to do |format|
      format.pdf { render template: 'invoice/advance_payments/print.pdf.erb', pdf: 'xyz', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_i * 10, right: @print_setting.try(:right_margin).to_i * 10, top: @print_setting.try(:header_height).to_i * 10, bottom: @print_setting.try(:footer_height).to_i * 10 }, locals: @locals }
    end
  end

  def destroy
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    InvoiceJobs::AdvancePaymentJob.perform_later(@advance_payment.id.to_s)
    @advance_payment.update(is_deleted: true, advance_state: 'Deleted')
  end

  def refund
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @patient = Patient.find_by(id: @advance_payment.patient_id)

    @refunded_amount = params[:refunded_amount]
    @advance_payment.advance_history = @advance_payment.try(:advance_history) || []
    advance_history = { type: 'Refunded', user_name: current_user.fullname,
                        amount: params[:refunded_amount], event_time: Time.current.strftime('%I:%M %p, %d/%m/%Y') }
    @advance_payment.advance_history << advance_history
    @advance_payment.amount_remaining = 0
    @advance_payment.advance_state = 'Settled'

    @advance_payment.save
    InvoiceJobs::AdvancePaymentJob.perform_later(@advance_payment.id.to_s)
  end

  def print_refund
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @organisation = current_user.organisation
    @patient = Patient.find_by(id: @advance_payment.patient_id)
    @user = User.find_by(id: @advance_payment.user_id)
    @refunded_amount = params[:refunded_amount]
    setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, 'Invoice')
    @print_settings = setting_service.select_print_setting
    @logo = @print_settings[1]
    currency_symbol = (@advance_payment.currency_symbol || current_facility.currency_symbol)
    @locals = { mail_job: false, patient: @patient, appointment: @appointment, invoice: @invoice, refund_payment: @refund_payment, facility_setting: @facility_setting, flag: 'Invoice', invoice_setting: @invoice_setting, organisation_settings: @organisation_settings, currency_symbol: currency_symbol }
    @print_setting = PrintSetting.find_by(id: params[:print_setting_id])

    respond_to do |format|
      format.pdf { render template: 'invoice/advance_payments/print_refund.pdf.erb', pdf: 'xyz', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_i * 10, right: @print_setting.try(:right_margin).to_i * 10, top: @print_setting.try(:header_height).to_i * 10, bottom: @print_setting.try(:footer_height).to_i * 10 }, locals: @locals }
    end
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

  def advance_invoice_params
    params.require(:advance_payment).permit(
      :type, :currency_symbol, :currency_id, :patient_id, :user_id, :facility_id, 
      :organisation_id, :reason, :mode_of_payment, :payment_date, :payment_time, :amount, 
      :amount_remaining, :cash, :card, :card_number, :card_transaction_note, 
      :paytm_transaction_id, :paytm_transaction_note, :gpay_transaction_id,
      :gpay_transaction_note, :phonepe_transaction_id, :phonepe_transaction_note, 
      :transfer_date, :transfer_note, :cheque_date, :cheque_note, :other_transaction_id, 
      :other_note, :bkp_advance_display_id, :advance_display_id, :specialty_id,
      :department_id, :department_name, :store_id, :invoice_id, :advance_type, :order_id
    )
  end

  def set_advance_payment
    @advance_payment = AdvancePayment.find_by(id: params[:id])
  end

  def print_settings(type)
    organisation_id = current_user.organisation_id.to_s
    facility_id = current_facility.id.to_s
    department_id = type == 'OPD' ? ['485396012'] : ['486546481']
    @print_settings = PrintSetting.print_options(organisation_id, facility_id, department_id)
  end

  def header_templates(inventory_order)
    template_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
                                            .custom_template_header_options["#{inventory_order.department_name&.downcase}_settings"]
    @mr_no = PatientOtherIdentifier.find_by(patient_id: inventory_order.patient_id).try(:mr_no)
    @template_fields = template_settings[:invoices][0].select { |_key, value| value == true }.keys if template_settings
  end
end
