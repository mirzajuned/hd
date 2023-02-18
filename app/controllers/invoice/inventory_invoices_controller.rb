class Invoice::InventoryInvoicesController < ApplicationController
  before_action :authorize, :verify_store
  before_action :last_search_by, only: [:new]
  include ActionView::Helpers::NumberHelper
  include Invoice::InventoryInvoicesHelper
  include MedicineCountHelper

  def index
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @start_date = params[:start_date].present? ? DateTime.parse(params[:start_date]).strftime('%d/%m/%Y') : Date.current
    @end_date =  params[:start_date].present? ? DateTime.parse(params[:end_date]).strftime('%d/%m/%Y') : Date.current
    @time_period = params[:time_period]
    @fitter_name = params[:fitter_name]
    @fitter_id = params[:fitter_id] || 'all'
    @state_name = params[:state_name] || 'all'
    @sort_by = params[:sort_by].present? ? params[:sort_by] : 'newest_first'
    @home_delivery = params[:home_delivery] || 'all'
    @pending_bills_count = Invoice::InventoryInvoice.where(store_id: @store_id, payment_completed: false,
                                                           invoice_type: 'credit', is_deleted: false).count
    fetch_invoices
  end

  def append_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @fitter_id = params[:fitter_id]
    @state_name = params[:state_name]
    @sort_by = params[:sort_by].present? ? params[:sort_by] : 'newest_first'
    @home_delivery = params[:home_delivery] || 'all'
    fetch_invoices
  end

  def filter_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @fitter_id = params[:fitter_id]
    @state_name = params[:state_name]
    @sort_by = params[:sort_by].present? ? params[:sort_by] : 'newest_first'
    @home_delivery = params[:home_delivery] || 'all'
    fetch_invoices
  end

  def confirm_disable
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: params[:id])
    @inventory_store = Inventory::Store.find_by(id: @inventory_invoice.store_id)
    header_templates
  end

  def disable
    user_name = current_user.fullname
    reason = params[:reason] || 'Invoice Refund'
    data = {mode_of_payment: params[:mode_of_payment], transaction_id: params[:transaction_id], transaction_note: params[:transaction_note] }
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: params[:id])
    @inventory_store = Inventory::Store.find_by(id: @inventory_invoice.store_id)
    @store_id = @inventory_store&.id
    unless @inventory_invoice.is_canceled
      @inventory_order = Invoice::InventoryOrder.find_by(id: @inventory_invoice.order_id)
      @inventory_order.update!(is_invoice_cancelled: true, invoice_cancelled_on: Time.current)
      @inventory_invoice.update(is_canceled: true, cancel_date: Date.current, canceled_by: user_name, refund_reason: reason, canceled_by_id: current_user.id)
      @start_date = @end_date = params[:date]
      # Inventory::Transactions::Sale::CreateService.call(@inventory_invoice.id.to_s, current_user.id.to_s,
      #                                                   user_name, reason)
      @from = params[:from]
      # @return_transaction = Inventory::Transactions::CreateReturnService.call(@inventory_invoice.id.to_s, current_user.id.to_s, user_name, 'invoice')
      @return_transaction = Inventory::Transactions::CreateReturnService.call(@inventory_invoice.id.to_s, current_user.id.to_s, user_name, 'invoice', data)
      patient_summary('CANCELLED')
      if @inventory_invoice.department_id == '50121007' # optical
        prescription = PatientOpticalPrescription.find_by(id: @inventory_invoice.prescription_id)
        CommunicationNotificationJob.perform_now('optical_bill_cancelled', @inventory_order.id.to_s, @inventory_order.class.to_s)
      elsif @inventory_invoice.department_id == '284748001' # pharmacy
        CommunicationNotificationJob.perform_now('pharmacy_bill_cancelled', @inventory_order.id.to_s, @inventory_order.class.to_s)
        prescription = PatientPrescription.find_by(id: @inventory_invoice.prescription_id)
      end
      InvoiceJobs::ManageCollectionDataJob.perform_later(@return_transaction.id.to_s, 'Return')
      Analytics::Financial::FinancialJob.perform_later(@inventory_invoice.id.to_s,
                                                       @inventory_invoice.try(:department_name))
      InvoiceJobs::ManageRevenueDataJob.perform_later(@inventory_invoice.id.to_s)
      InvoiceJobs::CancelReturnInvoiceJob.perform_later(@return_transaction.id.to_s, 'return', 'inventory')
      MisJobs::Finance::InvoiceServiceJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@inventory_invoice.id.to_s)
      if prescription.present?
        InventoryJobs::PrescriptionDataJob.perform_later(
          @inventory_invoice.department_name.downcase, prescription.id.to_s
        )
      end
      Inventory::RefundPayments::CreateService.call(@return_transaction, reason, current_user, 'return', data)
    end
    fetch_invoices
    header_templates
  end

  def show
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: params[:id])
    @state_transitions = Invoice::InventoryInvoiceStateTransition.where(inventory_invoice_id: @inventory_invoice.id)
    @return_transaction = Inventory::Transaction::Return.find_by(invoice_id: params[:id])
    fetch_all_invoices
    header_templates
    @from = 'show'
  end

  def show_modal
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: params[:id])
    @return_transaction = Inventory::Transaction::Return.find_by(invoice_id: params[:id])
    @state_transitions = Invoice::InventoryInvoiceStateTransition.where(inventory_invoice_id: @inventory_invoice.id)
    @inventory_store = Inventory::Store.find_by(id: @inventory_invoice.store_id)
    header_templates
    respond_to do |format|
      format.js { render 'invoice/inventory_invoices/show_modal' }
    end
  end

  def show_modal_refund
    @return_transaction = Inventory::Transaction::Return.find_by(id: params[:id])
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: @return_transaction.invoice_id)
  end

  def filter_sale
    @store_id = params[:store_id]
    @department_id = params[:department_id]
  end

  def transaction_report
    options = { :facility_ids.in => [current_facility.id], is_active: true }
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @all_user = User.where(options.merge(:inventory_store_ids.in => [params[:store_id]])).pluck(:fullname, :id)
  end

  def download_data
    @department_id = params[:department_id]
    options = { store_id: params[:store_id] }
    fitter_id = params[:fitter_id]
    state_name = params[:state_name]
    user_id = params[:user_id]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @user_name = if user_id.present? && user_id != 'all_user'
                   User.find(user_id).fullname
                 else
                   'All Users'
                 end
    options = options.merge(fitter_id: fitter_id) if fitter_id.present? && fitter_id != 'all'
    options = options.merge(state_name: state_name) if state_name.present? && state_name != 'all'
    options = options.merge(user_id: user_id) if user_id.present? && user_id != 'all_user'
    options[:start_date] = if params[:start_date].present?
                             Date.parse(params[:start_date])
                           else
                             Date.current - 30.days
                           end
    options[:end_date] = if params[:end_date].present?
                           Date.parse(params[:end_date])
                         else
                           Date.current
                         end
    @data_array, @summary = Inventory::Transactions::DownloadInvoiceService.call(options, @department_id, current_facility, params[:gst_include])
    name_tail = params[:gst_include] == '0' ? 'bill_wise_Sales_Report_Without_Tax_Breakup.xlsx' : 'bill_wise_Sales_Report_With_Tax_Breakup.xlsx'
    @filename = "#{@inventory_store&.name.squish&.titleize&.tr(' ', '_')}_#{Time.current.strftime('%d_%B_%Y')}_#{Time.current.try(:strftime, '%R:%S')}_#{@user_name.squish&.titleize&.tr(' ', '_')}_#{name_tail}"
    @description = filter_details
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}\"" }
    end
  end

  def new
    @current_facility_id = current_facility.id.to_s
    @current_organisation_id = current_user.organisation_id.to_s

    @invoice_setting = InvoiceSetting.find_by(organisation_id: @current_organisation_id)
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @sub_stores = @inventory_store.sub_stores
    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id).pluck(:name, :id)
    fetch_patient_data
    @currency = Currency.find_by(id: current_facility.currency_id.to_s)

    department_id = @inventory_store.department_id

    @fitter = Inventory::Fitter.where(store_id: @inventory_store).pluck(:name, :id)
    @advance_payments = AdvancePayment.where(patient_id: params[:patient_id], advance_state: 'None',
                                             is_deleted: false, is_refunded: false, department_id: department_id.to_s)
    if params[:prescription_id].present?
      if department_id == '50121007'
        @patient_prescription = PatientOpticalPrescription.find_by(id: params[:prescription_id])
      elsif department_id == '284748001'
        @patient_prescription = PatientPrescription.find_by(id: params[:prescription_id])
      end
    end

    @medication_groups = begin
                           @patient_prescription.medications.group_by { |d| d[:status] }
                         rescue StandardError
                           nil
                         end

    @print_settings = PrintSetting.print_options(@current_organisation_id, @current_facility_id,
                                                 [department_id])

    @inventory_invoice = Invoice::InventoryInvoice.new

    @inventory_invoice.items.build
    @category = 'all_item'
    @lots = Inventory::Item::Lot.where(store_id: params[:store_id], :stock.gte => 1, stockable: true)
                                .is_active.limit(30)
    respond_to do |format|
      format.js {}
    end
  end

  def create
    total_amount = check_invoice_remaining_amount(params)
    @inventory_order = Invoice::InventoryOrder.find_by(id: params[:invoice_inventory_invoice][:order_id])
    @invoice_id = @inventory_order.invoice_id
    @store_id = params[:invoice_inventory_invoice][:store_id]
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @start_date = @end_date = DateTime.parse(params[:invoice_inventory_invoice][:checkout_date]).strftime('%d/%m/%Y')
    @action_from = params[:invoice_inventory_invoice][:action_from]
    if total_amount == @inventory_order.amount_remaining&.round(2) && @invoice_id.nil?
      @prescription_id = @inventory_order.prescription_id
      bkp_bill_number = Invoice::InventoryInvoicesHelper.increment_and_create_bill_number(
        @store_id, current_facility.id
      )
      @inventory_invoice = Invoice::InventoryInvoice.new(@inventory_order.attributes.except(:_id, :state_transitions, :order_number, :_type))
      @inventory_invoice.order_id = @inventory_order.id
      @inventory_invoice.bkp_bill_number = bkp_bill_number
      if @inventory_invoice.save!
        @invoice_id = @inventory_invoice.id
        bill_number = SequenceManagers::GenerateSequenceService.call(
          'invoice', @inventory_invoice.id.to_s, { organisation_id: current_organisation['_id'].to_s, facility_id: current_facility['_id'].to_s, region_id: current_facility['region_master_id'].to_s, department_id: @inventory_invoice.department_id }
        )
        @inventory_invoice.update(bill_number: bill_number)
        Invoice::CreateBillNumberService.call(@inventory_invoice)
        Invoice::UpdateBillStateService.call(@inventory_invoice.id.to_s)

        if params[:invoice_inventory_invoice][:advance_payment_breakups_attributes].present?
          params[:invoice_inventory_invoice][:advance_payment_breakups_attributes].values.each do |advance_payment_breakup|
            if advance_payment_breakup['amount'].to_f > 0
              Inventory::Transactions::CreateAdvancePaymentService.call(
                @inventory_invoice.id.to_s, advance_payment_breakup['advance_payment_id'], current_user.fullname,
                advance_payment_breakup['amount'], 'advance_against_patient', 'invoice'
              )
            end
          end
        end
        if params[:invoice_inventory_invoice][:payment_received_breakups_attributes].present?
          params[:invoice_inventory_invoice][:payment_received_breakups_attributes].values.each do |payment_received_breakup|
            Inventory::Transactions::CreateReceivedPaymentService.call(@inventory_invoice.id.to_s, current_user, payment_received_breakup, 'invoice') if payment_received_breakup['amount'].present? && payment_received_breakup['amount'].to_f > 0
          end
        end

        fetch_invoices
        # Advance Logic
        @inventory_invoice.advance_payment_breakups.each do |advance_payment_breakup|
          advance_payment = AdvancePayment.find_by(id: advance_payment_breakup.advance_payment_id, :amount_remaining.gt => 0)
          next unless advance_payment.present?

          advance_payment.amount_remaining = advance_payment.amount_remaining - advance_payment_breakup.amount
          advance_payment.advance_state = ('Settled' if advance_payment.amount_remaining == 0) || 'None'
          advance_payment.advance_history = advance_payment.try(:advance_history) || []
          advance_history = {
            advance_payment_breakup_id: advance_payment_breakup.id.to_s, invoice_id: @inventory_invoice.id.to_s,
            invoice_type: 'Optical', type: 'Adjusted', user_name: current_user.fullname,
            amount: advance_payment_breakup.amount, event_time: Time.current.strftime('%I:%M %p, %d/%m/%Y'),
            bill_number: @inventory_invoice.bill_number
          }
          advance_payment.advance_history << advance_history

          advance_payment.save
          InvoiceJobs::AdvancePaymentJob.perform_later(advance_payment.id.to_s)
        end
        @inventory_order.update(is_invoice_created: true, invoice_created_on: Time.current,
                                invoice_created_by: current_user.id, invoice_id: @inventory_invoice.id)
        patient_summary('CREATED')
        InventoryJobs::Transactions::InvoiceJob.perform_later(@inventory_invoice.id.to_s, current_user.id.to_s)
        Analytics::Financial::FinancialJob.perform_later(@inventory_invoice.id.to_s,
                                                         @inventory_invoice.try(:department_name))
        TaxCalculationJob.perform_later(@inventory_invoice.id.to_s, 'tax_collected_details')
        if @inventory_invoice.present?
          Analytics::Financial::InventoryPaymentModeJob.perform_later(@inventory_invoice.id.to_s)
        end
        InvoiceJobs::ManageRevenueDataJob.perform_later(@inventory_invoice.id.to_s)
        InvoiceJobs::ManageCollectionDataJob.perform_later(@inventory_invoice.id.to_s, 'Bill')
        MisJobs::Finance::BillTypeJob.perform_later(@inventory_invoice.id.to_s)
        MisJobs::Finance::InvoiceServiceJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@inventory_invoice.id.to_s)
        if @inventory_invoice.department_id == '284748001' && @prescription_id.present?
          Analytics::Conversion::PharmacyPrescriptionJob.perform_later(@prescription_id.to_s, current_user.id.to_s,
                                                                       'Pharmacy')
          InventoryJobs::PrescriptionDataJob.perform_later('pharmacy', @prescription_id.to_s)
        elsif @inventory_invoice.department_id == '50121007' && @prescription_id.present?
          Analytics::Conversion::OpticalPrescriptionJob.perform_later(@prescription_id.to_s, current_user.id.to_s,
                                                                      'Optical')
          InventoryJobs::PrescriptionDataJob.perform_later('optical', @prescription_id.to_s)
        end
      end
    end
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: @invoice_id) if @invoice_id.present?
    @inventory_invoice = @inventory_invoice.present? ? @inventory_invoice : Invoice::InventoryInvoice.new
    srn = Inventory::Transaction::StockReceiveNote.find_by(id: @inventory_invoice.srn_id)
    srn.update!(status: 'completed') if srn.present?
    @inventory_invoice.reload
    CommunicationNotificationJob.perform_now('optical_bill_creation', @inventory_order.id.to_s, @inventory_order.class.to_s)
    header_templates
    respond_to do |format|
      if @action_from == 'order'
        format.js { render 'invoice/inventory_orders/index.js.erb' }
      else
        format.js { render 'invoice/inventory_invoices/index.js.erb' }
      end
    end
  end

  def print_preview
    if params[:from].present?
      @inventory_invoice = Invoice::InventoryInvoice.find_by(id: params[:id])
      @inventory_order = Invoice::InventoryOrder.find_by(invoice_id: @inventory_invoice.id)
    else
      @inventory_invoice = Invoice::InventoryInvoice.find_by(prescription_id: params[:prescription_id])
      if @inventory_invoice.department_id == '284748001'
        @prescription = PatientPrescription.find_by(id: params[:prescription_id])
      elsif @inventory_invoice.department_id == '50121007'
        @prescription = PatientOpticalPrescription.find_by(id: params[:prescription_id])
      end
      @appointment = Appointment.find_by(id: @prescription.appointment_id)
    end
    @inventory_store = Inventory::Store.find_by(id: @inventory_invoice.store_id)
    header_templates
  end

  def print
    invoice_id = params[:invoice_id]
    page_size = params[:page_size]
    facility_id = current_facility.id
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: invoice_id)
    @inventory_store = Inventory::Store.find_by(id: @inventory_invoice.store_id)
    @facility = Facility.find(facility_id)
    @patient_id = @inventory_invoice.patient_id
    @patient = Patient.find_by(id: @patient_id)
    @mr_no = PatientOtherIdentifier.find_by(patient_id: @patient_id).try(:mr_no)
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
    # html_template = if @inventory_invoice.tax_enabled
    #                   'invoice/inventory_invoices/department/pharmacy_invoices/print_invoice_tax_enabled'
    #                 else
    #                   'invoice/inventories/department/pharmacy_invoices/print_invoice_tax_disabled'
    #                 end

    html_template = 'invoice/inventory_invoices/print'
    @print_setting = true
    if page_size == 'A5'
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/pdfgen.html.erb',
             viewport_size: '1280x1024', page_size: 'A4', show_as_html: params[:debug].present?,
             footer: { right: '[page] of [topage]' }, locals: { mail_job: false }
    else
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/pdfgen.html.erb',
             viewport_size: '1280x1024', page_size: 'A4', orientation: 'Portrait',
             show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' },
             locals: { mail_job: false }
    end
  end

  def add_lot
    @lot = Inventory::Item::Lot.find_by(id: params[:lot_id])
    @variant = Inventory::Item::Variant.find_by(id: @lot.variant_id)
    @item = Inventory::Item.find_by(id: @lot.item_id)

    @inventory_invoice = Invoice::InventoryInvoice.build
    @tax_group = TaxGroup.find(@lot.tax_group_id)
    @tax_rate_details = @tax_group.tax_rate_details.collect { |tax_rate| tax_rate.merge(type: TaxRate.find(tax_rate[:_id]).type) }
  end

  def append_lots
    @store_id = params[:store_id]
    @category = params[:item_type]
    @search_type = params[:search_type]
    fetch_lot_index
  end

  def filter_lots
    @store_id = params[:store_id]
    @category = params[:item_type]
    @search_type = params[:search_type]
    fetch_lot_index
  end

  def free_invoice
    @store_id = params[:store_id]
    redirect_to patients_search_path(url: '/patients/new', url_store: '/invoice/inventory_invoices/new',
                                     store_id: @store_id, modal: 'free-invoice-inventory-modal')
  end

  def searchpatientresultfocus
    @patient = Patient.find(params[:searchresultfocus][:patientid])
    @patient_ident = PatientOtherIdentifier.find_by(patient_id: params[:searchresultfocus][:patientid])
    respond_to do |format|
      format.js {}
    end
  end

  def searchpatientresultselect
    @patient = Patient.find(params[:searchresultselect][:patientid])
    @patient_ident = PatientOtherIdentifier.find_by(patient_id: params[:searchresultselect][:patientid])
    respond_to do |format|
      format.js {}
    end
  end

  def proceed_free_invoice
    @patienttype = params[:patienttype]
    @store_id = params[:store_id]

    if @patienttype == 'Fresh'
      name = params[:name]
      mr_no = params[:mr_no]
      mobile_no = params[:mobile_no]
      age = params[:age]
      address = params[:address]
      organisation = current_user.organisation

      hg_patient = Patient.new(fullname: name, age: age, mobilenumber: mobile_no.to_s, address_1: address.to_s, reg_hosp_ids: [organisation.id.to_s])

      patsplit = name.split(' ')
      if patsplit.count == 1
        hg_patient.firstname = patsplit[0]
      elsif patsplit.count == 2
        if patsplit[0].capitalize == 'Mr.' || patsplit[0].capitalize == 'Mr' || patsplit[0].capitalize == 'Mrs' || patsplit[0].capitalize == 'Mrs.' || patsplit[0].capitalize == 'Dr.' || patsplit[0].capitalize == 'Dr'
          hg_patient.firstname = patsplit.join(' ')
        else
          hg_patient.firstname = patsplit[0]
          hg_patient.lastname = patsplit[1]
        end
      elsif patsplit.count > 2
        hg_patient.lastname = patsplit[patsplit.count - 1]
        patsplit.delete_at(patsplit.count - 1)
        hg_patient.firstname = patsplit.join(' ')
      end

      if hg_patient.save!
        PatientIdentifier.create(patient_id: hg_patient.id, organisation_id: organisation.id.to_s, patient_org_id: CommonHelper.get_patient_org_identifier(current_user))
        attrs = { :patient_id => hg_patient.id, 'patientpersonalhistory_attributes' => { problems: [], 'flag' => 1 }, 'patientallergyhistory_attributes' => { flag: 1, antimicrobialagents: [], nsaids: [], antifungalagents: [], antiviralagents: [], contact: [], food: [], eyedrops: [], others: '' } }
        PatientHistory.create(attrs)

        unless mr_no == ''
          patient_other_identifier = PatientOtherIdentifier.new
          patient_other_identifier.mr_no = mr_no
          patient_other_identifier.patient_id = hg_patient.id
          patient_other_identifier.organisation_id = current_user.organisation.id
          patient_other_identifier.facility_id = current_facility.id
          patient_other_identifier.save
        end

      end
      @patient_id = hg_patient.id

    elsif @patienttype == 'Followup'
      @patient_id = params[:patient_id]
    end

    if @patient_id.present?
      redirect_to "/invoice/inventory_invoices/new?patient_id=#{@patient_id}&&store_id=#{@store_id}"
    else
      respond_to do |format|
        format.js { render js: "notice = new PNotify({ title: 'Error', text: 'Please fill the patient data correctly', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end

      #   render :nothing => true
    end
  end

  def review_order
    if params[:action_from] == 'inventory_invoice'
      @inventory_invoice = Invoice::InventoryInvoice.find_by(id: params[:id])
      @inventory_order = Invoice::InventoryOrder.find_by(invoice_id: @inventory_invoice.id)
    else
      @inventory_invoice = Invoice::InventoryInvoice.new
      @inventory_order = Invoice::InventoryOrder.find_by(id: params[:id])
    end
    @inventory_store = Inventory::Store.find_by(id: @inventory_order.store_id)
    @currency = Currency.find_by(id: current_facility.currency_id.to_s)
    @current_facility_id = current_facility.id.to_s
    @current_organisation_id = current_user.organisation_id.to_s
    @invoice_setting = InvoiceSetting.find_by(organisation_id: @current_organisation_id)
    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id).pluck(:name, :id)
    fetch_patient_data

    @advance_payments = AdvancePayment.where(patient_id: @inventory_order.patient_id, is_deleted: false,
                                             is_refunded: false, department_id: '50121007')
    if @inventory_order.prescription_id.present?
      if @inventory_order.department_id == '50121007'
        @patient_prescription = PatientOpticalPrescription.find_by(id: @inventory_order.prescription_id)
      elsif @inventory_order.department_id == '284748001'
        @patient_prescription = PatientPrescription.find_by(id: @inventory_order.prescription_id)
      end
      @print_settings = PrintSetting.print_options(@current_user.organisation_id.to_s, current_facility_id,
                                                   [@inventory_order.department_id])
    end
  end

  def update
    @invoice_id = params[:id]
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: params[:id])
    total_amount = check_invoice_remaining_amount(params)
    if total_amount == @inventory_invoice.amount_remaining.to_f
      if params[:invoice_inventory_invoice][:advance_payment_breakups_attributes].present?
        params[:invoice_inventory_invoice][:advance_payment_breakups_attributes].values.each do |advance_payment_breakup|
          next unless advance_payment_breakup['amount'].to_f > 0

          Inventory::Transactions::CreateAdvancePaymentService.call(
            @invoice_id, advance_payment_breakup['advance_payment_id'], current_user.fullname,
            advance_payment_breakup['amount'], 'advance_against_patient', 'invoice'
          )
        end
      end
      if params[:invoice_inventory_invoice][:payment_received_breakups_attributes].present?
        params[:invoice_inventory_invoice][:payment_received_breakups_attributes].values.each do |payment_received_breakup|
          if payment_received_breakup['amount'].present? && payment_received_breakup['amount'].to_f > 0
            Inventory::Transactions::CreateReceivedPaymentService.call(@invoice_id, current_user, payment_received_breakup, 'invoice')
          end
        end
      end
      patient_summary('UPDATED')
      if @inventory_invoice.department_id == '50121007' # optical
        prescription = PatientOpticalPrescription.find_by(id: @inventory_invoice.prescription_id)
      elsif @inventory_invoice.department_id == '284748001' # pharmacy
        prescription = PatientPrescription.find_by(id: @inventory_invoice.prescription_id)
      end
      InvoiceJobs::ManageRevenueDataJob.perform_later(@inventory_invoice.id.to_s)
      InvoiceJobs::ManageCollectionDataJob.perform_later(@inventory_invoice.id.to_s, 'Bill')
      MisJobs::Finance::BillTypeJob.perform_later(@inventory_invoice.id.to_s)
      MisJobs::Finance::InvoiceServiceJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@inventory_invoice.id.to_s)
      if prescription.present?
        InventoryJobs::PrescriptionDataJob.perform_later(@inventory_invoice.department_name.downcase, prescription.id.to_s)
      end
    end
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: params[:id])
    @state_transitions = Invoice::InventoryInvoiceStateTransition.where(inventory_invoice_id: @inventory_invoice.id)
    update_inventory_order
    fetch_all_invoices
    header_templates
  end

  def create_new_payment_breakup(params); end

  def change_state
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: params[:id])
    @state_transitions = Invoice::InventoryInvoiceStateTransition.where(inventory_invoice_id: @inventory_invoice.id)
    @inventory_store = Inventory::Store.find_by(id: @inventory_invoice.store_id)
    from = @inventory_invoice.state
    to = params[:to].to_s
    unless from == to
      @inventory_invoice.update(delivery_date: Time.current, delivered: true) if to == 'delivered'
      @inventory_invoice.send(from + '_to_' + to)
      if @inventory_invoice.department_id == '50121007' # optical
        prescription = PatientOpticalPrescription.find_by(id: @inventory_invoice.prescription_id)
      elsif @inventory_invoice.department_id == '284748001' # pharmacy
        prescription = PatientPrescription.find_by(id: @inventory_invoice.prescription_id)
      end
      if to == 'delivered'
        InvoiceJobs::ManageRevenueDataJob.perform_later(@inventory_invoice.id.to_s)
        InvoiceJobs::ManageCollectionDataJob.perform_later(@inventory_invoice.id.to_s, 'Bill')
        MisJobs::Finance::InvoiceServiceJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@inventory_invoice.id.to_s)
      end

      if prescription.present?
        InventoryJobs::PrescriptionDataJob.perform_later(@inventory_invoice.department_name.downcase, prescription.id.to_s)
      end
    end
    fetch_all_invoices
    header_templates
  end

  def undo_state
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: params[:id])
    @state_transitions = Invoice::InventoryInvoiceStateTransition.where(inventory_invoice_id: @inventory_invoice.id)
    last_state = @state_transitions.last_states[0]
    secondlast_state = @state_transitions.last_states[1]

    if secondlast_state.present?
      last_state.delete
      secondlast_state&.update(transition_end: nil)
      @inventory_invoice.update(department_id: secondlast_state&.department_id, store_id: secondlast_state&.store_id,
                                state: secondlast_state&.to, delivery_date: secondlast_state&.delivery_date)
    end
    fetch_all_invoices
    header_templates
  end

  def edit_delivery_date
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: params[:id])
  end

  def save_delivery_date
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: params[:id])
    @state_transitions = Invoice::InventoryInvoiceStateTransition.where(inventory_invoice_id: @inventory_invoice.id)
    fetch_all_invoices
    header_templates
    date = @inventory_invoice.estimated_delivery_date&.strftime('%d/%m/%Y')
    new_date = params[:new_delivery_date]
    time = Time.now.try(:strftime, '%R:%S')
    date_time = Time.current
    @inventory_invoice.update(last_estimated_delivery_date: date_time, last_date_change_user: current_user.fullname,
                              estimated_delivery_date: new_date, delivery_date_change_reason: params[:reason])
  end

  def payment_received_details
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @invoice = Invoice.find_by(id: params[:id])
  end

  def settle_invoice
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: params[:id])
    @payer_masters = PayerMaster.includes(:contact_group).where(facility_id: current_facility.id, is_active: true)
  end

  # def settled_invoice
  #   @inventory_invoice = Invoice::InventoryInvoice.find_by(id: params[:id])
  #   @inventory_invoice.payment_pending = params[:settle_invoice][:payment_pending]
  #   @inventory_invoice.payment_received = @inventory_invoice.payment_received + params[:settle_invoice][:payment_received].to_f
  #   params[:settle_invoice][:payment_received_breakups].to_unsafe_h.each do |_k, payment_received|
  #     next unless payment_received[:settle_amount].to_f > 0

  #     payment_pending_breakup = @inventory_invoice.payment_pending_breakups.find_by(id: payment_received[:payment_pending_id])
  #     next unless payment_pending_breakup.present?

  #     payment_received_breakups_new = @inventory_invoice.payment_received_breakups.
  #                                     new(payment_received.except(:payment_pending_id, :settle_amount))
  #     payment_received_breakups_new[:amount] = payment_received[:settle_amount]
  #     # to generate for receipt_id for each txn
  #     Invoice::CreateBillNumberService.call(@inventory_invoice)
  #     payment_received_breakups_new.save!
  #     # Payment Pending Document
  #     if payment_received[:settle_amount].to_f != payment_received[:amount].to_f
  #       amount_remaining = payment_received[:amount].to_f - payment_received[:settle_amount].to_f
  #       payment_pending_breakup.update(amount: amount_remaining, date: Date.current, time: Time.current.utc)
  #     elsif payment_received[:settle_amount].to_f == payment_received[:amount].to_f
  #       payment_pending_breakup.delete
  #     end
  #   end
  #   if @inventory_invoice.save
  #     InvoiceJobs::ManageRevenueDataJob.perform_later(@inventory_invoice.id.to_s)
  #     InvoiceJobs::ManageCollectionDataJob.perform_later(@inventory_invoice.id.to_s, 'Bill')
  #   end
  #   @inventory_store = Inventory::Store.find_by(id: @inventory_invoice.store_id)
  #   header_templates
  # end

  def settled_invoice
    @inventory_invoice = Invoice.find_by(id: params[:id])
    @inventory_order = Invoice::InventoryOrder.find_by(id: @inventory_invoice.order_id)
    amount = params[:settle_invoice][:payment_received_breakups].to_unsafe_h.values.pluck(:amount_received).map(&:to_f).sum
    payment_pending = @inventory_invoice.payment_pending
    if amount <= payment_pending
      @patient = Patient.find_by(id: @inventory_invoice.patient_id)
      @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id).pluck(:name, :id)
      @inventory_invoice_type = @inventory_invoice._type
      @type = @inventory_invoice_type.split('::')[1].to_s&.underscore&.downcase
      @store_id = params[:store_id]

      @inventory_invoice.payment_pending = payment_pending - amount
      @inventory_invoice.payment_received = @inventory_invoice.payment_received + params[:settle_invoice][:payment_received].to_f

      @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)

      invoice_payment_pending = 0
      invoice_amount_received = 0
      currency_id = (@inventory_invoice.currency_id || current_facility.currency_id)
      currency_symbol = (@inventory_invoice.currency_symbol || current_facility.currency_symbol)
      params[:settle_invoice][:payment_received_breakups].to_unsafe_h.each do |_k, payment_received|
        # next unless payment_received[:settle_amount].to_f > 0
        total_amount_received = payment_received[:amount_received].to_f + payment_received[:tax_deducted].to_f + payment_received[:payer_difference].to_f + payment_received[:other_revenue_spilage].to_f
        next unless total_amount_received > 0

        invoice_amount_received += payment_received[:amount_received].to_f

        payment_pending_breakup = @inventory_invoice.payment_pending_breakups.find_by(id: payment_received[:payment_pending_id])
        next unless payment_pending_breakup.present?

        # Payment Received Document
        payment_received_breakups_new = @inventory_invoice.payment_received_breakups.new
        # payment_received_breakups_new[:amount] = payment_received[:settle_amount]
        payment_received_breakups_new[:amount] = total_amount_received.round(2)
        payment_received_breakups_new[:date] = payment_received[:date]
        payment_received_breakups_new[:time] = payment_received[:time]
        payment_received_breakups_new[:received_by] = payment_received[:received_by]
        payment_received_breakups_new[:received_from] = payment_received[:received_from]
        payment_received_breakups_new[:mode_of_payment] = payment_received[:mode_of_payment]
        payment_received_breakups_new[:cash] = payment_received[:cash]
        payment_received_breakups_new[:card] = payment_received[:card]
        payment_received_breakups_new[:card_number] = payment_received[:card_number]
        payment_received_breakups_new[:card_transaction_note] = payment_received[:card_transaction_note]
        payment_received_breakups_new[:paytm_transaction_id] = payment_received[:paytm_transaction_id]
        payment_received_breakups_new[:paytm_transaction_note] = payment_received[:paytm_transaction_note]
        payment_received_breakups_new[:gpay_transaction_id] = payment_received[:gpay_transaction_id]
        payment_received_breakups_new[:gpay_transaction_note] = payment_received[:gpay_transaction_note]
        payment_received_breakups_new[:phonepe_transaction_id] = payment_received[:phonepe_transaction_id]
        payment_received_breakups_new[:phonepe_transaction_note] = payment_received[:phonepe_transaction_note]
        payment_received_breakups_new[:transfer_date] = payment_received[:transfer_date]
        payment_received_breakups_new[:transfer_note] = payment_received[:transfer_note]
        payment_received_breakups_new[:cheque_date] = payment_received[:cheque_date]
        payment_received_breakups_new[:cheque_note] = payment_received[:cheque_note]
        payment_received_breakups_new[:other_transaction_id] = payment_received[:other_transaction_id]
        payment_received_breakups_new[:other_note] = payment_received[:other_note]
        payment_received_breakups_new[:is_settled] = payment_received[:is_settled]
        payment_received_breakups_new[:amount_received] = payment_received[:amount_received].to_f.round(2)
        payment_received_breakups_new[:has_tax_deducted] = payment_received[:has_tax_deducted]
        payment_received_breakups_new[:tax_deducted] = payment_received[:tax_deducted].to_f.round(2)
        payment_received_breakups_new[:has_payer_difference] = payment_received[:has_payer_difference]
        payment_received_breakups_new[:payer_difference] = payment_received[:payer_difference].to_f.round(2)
        payment_received_breakups_new[:has_other_revenue_spilage] = payment_received[:has_other_revenue_spilage]
        payment_received_breakups_new[:other_revenue_spilage] = payment_received[:other_revenue_spilage].to_f.round(2)
        payment_received_breakups_new[:internal_comment] = payment_received[:internal_comment]
        payment_received_breakups_new[:currency_id] = currency_symbol
        payment_received_breakups_new[:currency_symbol] = currency_symbol
        # to generate for receipt_id for each txn
        Invoice::CreateBillNumberService.call(@inventory_invoice)
        payment_received_breakups_new.save!
        # Payment Pending Document
        if total_amount_received != payment_pending
          amount_remaining = (payment_pending - total_amount_received).round(2)
          payment_pending_breakup.update(amount: amount_remaining, date: Date.current, time: Time.current.utc)
          invoice_payment_pending += amount_remaining
        elsif total_amount_received == payment_pending
          payment_pending_breakup.delete
        end
      end
      @inventory_invoice.amount_received = (@inventory_invoice.amount_received.to_f + invoice_amount_received).round(2)
      # @inventory_invoice.payment_pending = invoice_payment_pending.round(2)

      if @inventory_invoice.save
        CommunicationNotificationJob.perform_now('pharmacy_bill_creation', @inventory_order.id.to_s, @inventory_order.class.to_s)
        @inventory_order.update!(amount_received: @inventory_invoice.amount_received, payment_pending: @inventory_invoice.payment_pending) if @inventory_order.present?
        @refund_payments = RefundPayment.where(invoice_id: @inventory_invoice.id)

        @inventory_invoices = if @inventory_invoice_type.present?
                                Invoice.where(facility_id: current_facility.id.to_s, payment_completed: false, _type: @inventory_invoice, is_deleted: false)
                              else
                                Invoice.where(facility_id: current_facility.id.to_s, payment_completed: false, is_deleted: false)
                    end
        InvoiceJobs::ManageRevenueDataJob.perform_later(@inventory_invoice.id.to_s)
        InvoiceJobs::ManageCollectionDataJob.perform_later(@inventory_invoice.id.to_s, 'Bill')
        MisJobs::Finance::ItemWiseBillTypeJob.perform_later(@inventory_invoice.id.to_s)
      end
    end
    header_templates
  end

  def print_receipt
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: params[:id])

    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id)

    @payment_received = @inventory_invoice.payment_received_breakups.find_by(id: params[:payment_received_id])
    @refund_payments = RefundPayment.where(invoice_id: @inventory_invoice.id)
    @receiving_user = User.find_by(id: @payment_received.received_by)

    @organisation_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    if @payment_received.received_from.to_s == @inventory_invoice.patient_id.to_s
      @received_from = @inventory_invoice.patient.fullname
    else
      @payer_master = PayerMaster.find_by(id: @payment_received.received_from.to_s)
      @received_from = @payer_master.try(:display_name).to_s.titleize + ' - ' + @payer_master.contact_group.name.to_s.titleize
    end
    @patient = Patient.find_by(id: @inventory_invoice.patient_id)

    header_templates

    currency_symbol = (@inventory_invoice.currency_symbol || current_facility.currency_symbol)
    @locals = { mail_job: false, patient: @patient, appointment: @appointment, invoice: @inventory_invoice, refund_payment: @refund_payment, facility_setting: @facility_setting, flag: 'Invoice', invoice_setting: @invoice_setting, organisation_settings: @organisation_settings, currency_symbol: currency_symbol }
    respond_to do |format|
      format.pdf { render template: 'invoice/inventory_invoices/receipt.pdf.erb', pdf: 'xyz', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_i * 10, right: @print_setting.try(:right_margin).to_i * 10, top: @print_setting.try(:header_height).to_i * 10, bottom: @print_setting.try(:footer_height).to_i * 10 }, locals: @locals }
    end
  end

  private

  def inventory_invoice_params
    params.require(:invoice_inventory_invoice)
          .permit(
            :tax_enabled, :currency_symbol, :currency_id, :specialty_id, :prescription_id, :patient_identifier,
            :recipient, :recipient_mobile, :doctor_name, :patient_id, { tax_group: [:_id, :name, :amount] },
            :additional_discount, :services_discount, :total_discount, :additional_discount_comment,
            :mode_of_payment, :non_taxable_amount, :taxable_amount, :fresh_booking,
            :comments, { tax_breakup: [:_id, :name, :amount, :tax_rate, :tax_type, :taxable_amount] },
            :total, :advance_payment, :advance_taken, :amount_remaining, :invoice_payment_type, :payment_received,
            :payment_pending, :net_amount, :department_name, :department_id, :user_id, :store_id, :facility_id,
            :organisation_id, :estimated_delivery_date, :delivery_date, :order_date, :estimated_ready_date,
            :fitting_required, :fitter_id, :current_status, :delivered, :fitter_name, :checkout_date, :entered_by,
            :order_date_time, :search_type, :payer_master_id, :invoice_type, :contact_group_id, :payment_pending,
            :patient_mrn, :insurer_group_id, :insurer_id, :amount_received, :home_delivery,
            items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :variant_code, :item_id, :variant_id,
              :lot_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :search, :mark_up,
              :batch_no, :cost_price, :total_cost_price, :stock_package, :stock_subpackage, :stock_unit,
              :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :list_price, :mrp_pack_denomination,
              :batch_no, :list_price_pack_denomination, :self_batched, :expiry, :expiry_present, :quantity,
              :unit_non_taxable_amount, :unit_taxable_amount, :tax_rate, { tax_group: [:_id, :name, :amount] },
              :tax_group_id, :tax_inclusive, :taxable_amount, :non_taxable_amount, :total_list_price, :total_cost,
              :unit_cost, :description, :store_id, :facility_id, :organisation_id, :_destroy, :model_no, :sub_store_id,
              :sub_store_name
            ],
            payment_received_breakups_attributes: [
              :amount, :currency_symbol, :currency_id, :date, :time, :received_by, :received_from, :mode_of_payment,
              :cash, :card, :card_number, :card_transaction_note, :cheque_date, :cheque_note, :transfer_date, :transfer_note, :other_note,
              :paytm_transaction_id, :paytm_transaction_note, :gpay_transaction_id, :gpay_transaction_note,
              :phonepe_transaction_id, :phonepe_transaction_note, :is_settled, :amount_received,
              :has_tax_deducted, :tax_deducted, :has_payer_difference,
              :payer_difference, :has_other_revenue_spilage,
              :other_revenue_spilage, :internal_comment
            ],
            advance_payment_breakups_attributes: [
              :advance_payment_id, :advance_display_id, :reason, :mode_of_payment, :advance_date, :date, :advance_time,
              :time, :advance_amount, :amount, :currency_symbol, :currency_id, :cash, :card, :card_number, :card_transaction_note,
              :card_transaction_note, :paytm_transaction_id, :paytm_transaction_note, :gpay_transaction_id,
              :gpay_transaction_note, :phonepe_transaction_id, :phonepe_transaction_note, :transfer_date,
              :transfer_note, :cheque_date, :cheque_note, :other_transaction_id, :other_note
            ],
            payment_pending_breakups_attributes: [:amount, :currency_symbol, :currency_id, :received_from, :date, :time],
            pending_advance_payments_attributes: [
              :type, :currency_symbol, :currency_id, :patient_id, :user_id, :facility_id, :organisation_id, :reason,
              :mode_of_payment, :payment_date, :payment_time, :amount, :cash, :card, :card_number,
              :card_transaction_note, :paytm_transaction_id, :paytm_transaction_note, :gpay_transaction_id,
              :gpay_transaction_note, :phonepe_transaction_id, :phonepe_transaction_note, :transfer_date, :transfer_note,
              :cheque_date, :cheque_note, :other_transaction_id, :other_note, :advance_display_id, :specialty_id,
              :store_id, :id, :advance_type, :user_full_name
            ]
          )
  end

  def fetch_lot_index
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @store_id)
    @sub_stores = @inventory_store.sub_stores
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, :stock.gte => 1, stockable: true }
    if @category == 'out_stock'
      options = options.merge(stock: 0)
    elsif @category == 'all_item'
    else
      options = options.merge(category: @category)
    end

    if params[:search_type] == 'Barcode'
      lots = if query.present?
               Inventory::Item::Lot.where(options).where(barcode_id: query).is_active.skip(current_data_row)
                                   .limit(30)
             else
               Inventory::Item::Lot.where(options).is_active.skip(current_data_row)
                                   .limit(30)
             end
      variant = Inventory::Item::Variant.find_by(barcode_id: query)
      variant_lots = Inventory::Item::Lot.where(options).where(variant_id: variant.id).is_active if variant.present?
      item = Inventory::Item.find_by(barcode_id: query)
      master_lots = Inventory::Item::Lot.where(options).where(item_id: item.id).is_active if item.present?
      @lots = if lots.present?
                lots
              elsif variant.present? && !variant_lots.empty?
                variant_lots
              elsif item.present? && !master_lots.empty?
                master_lots
              else
                lots
              end
    elsif params[:search_type] == 'GenericName'
      @lots = Inventory::Item::Lot.where(options).where(generic_display_name: /#{Regexp.escape(query)}/i).is_active
                                  .skip(current_data_row).limit(30)
    else
      @lots = Inventory::Item::Lot.where(options).where(search: /#{Regexp.escape(query)}/i).is_active
                                  .skip(current_data_row).limit(30)
    end
  end

  def fetch_patient_data
    patient_id = params[:patient_id]
    @patient = Patient.find_by(id: patient_id)
    @patient_idn = PatientIdentifier.find_by(patient_id: patient_id)
    @patient_o_idn = PatientOtherIdentifier.find_by(patient_id: patient_id)
  end

  def fetch_invoices
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { is_deleted: false, store_id: @store_id, recipient: /#{Regexp.escape(query)}/i }
    options = options.merge(fitter_id: @fitter_id) if @fitter_id.present? && @fitter_id != 'all'
    options = options.merge(home_delivery: @home_delivery) if @home_delivery.present? && @home_delivery != 'all'
    if @state_name.present? && @state_name != 'all' && @state_name != 'cancelled'
      options = options.merge(state: @state_name)
    end
    options = options.merge(is_canceled: true) if @state_name.present? && @state_name == 'cancelled'
    @fitters = Inventory::Fitter.where(store_id: @store_id).pluck(:name, :id)
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    # if params[:invoice_type] == "all_item"
    # elsif params[:invoice_type] == "advance_pending"
    #   options = options.merge(payment_completed: false, advance_taken: true)
    # elsif params[:invoice_type] == "advance_completed"
    #   options = options.merge(payment_completed: true, advance_taken: true)
    # end
    options[:order_date] = { :$gte => @start_date, :$lte => @end_date } if @start_date.present? && @end_date.present?
    if @action_from == 'order'
      @inventory_orders = Invoice::InventoryOrder.where(options).send(@sort_by || 'newest_first')
                                                 .skip(current_data_row).limit(30)
    else
      @inventory_invoices = Invoice::InventoryInvoice.where(options).send(@sort_by || 'newest_first')
                                                     .skip(current_data_row).limit(30)
    end
  end

  def fetch_all_invoices
    department_id = @inventory_invoice.department_id
    @patientid = @inventory_invoice.patient_id
    @inventory_invoices = Invoice::InventoryInvoice.where(patient_id: @patientid, department_id: department_id.to_s, is_deleted: false).order_by(created_at: :desc)
    @return_transactions = Inventory::Transaction::Return.where(patient_id: @patientid, department_id: department_id.to_s).order_by(created_at: :desc)
    @advance_payments = AdvancePayment.where(patient_id: @patientid, is_deleted: false, department_id: department_id.to_s)
    @refund_payments = RefundPayment.where(patient_id: @patientid, is_deleted: false, department_id: department_id.to_s)
    @prescription = PatientPrescription.find_by(id: @inventory_invoice.prescription_id)
    @appointment = Appointment.find_by(id: @prescription&.appointment_id)
    @inventory_store = Inventory::Store.find_by(id: @inventory_invoice.store_id)
  end

  def patient_summary(sub_event_name)
    @inventory_store = Inventory::Store.find_by(id: @inventory_invoice.store_id)
    if @inventory_store.department_id == '284748001'
      type = 'PHARMACY'
    elsif @inventory_store.department_id == '50121007'
      type = 'OPTICAL'
    end
    Patients::Summary::TimelineWorker.call(
      event_name: "#{type}_INVOICE", sub_event_name: sub_event_name, invoice_id: @inventory_invoice.id,
      user_id: current_user.id, user_name: current_user.fullname, encounter_type: type.to_s
    )
  end

  def last_search_by
    @search_by = Invoice::InventoryInvoice.last_search_by(current_user.id.to_s, current_facility.id.to_s, params[:store_id])
  end

  def filter_details
    {
      'Address:': @inventory_store.address,
      "Bill Wise Sales Report For a Period of #{params[:start_date]} 12:00 AM to #{params[:end_date]} 11:59 PM": '',
      'Generated On:': "#{Time.current.try(:strftime, '%R:%S')} | #{Time.current.strftime('%d %B %Y')} | #{Date.today.strftime('%A')}",
      'Generated By:': @user_name
    }
  end

  def header_templates
    template_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
                                            .custom_template_header_options["#{@inventory_invoice.department_name&.downcase}_settings"]
    @mr_no = PatientOtherIdentifier.find_by(patient_id: @inventory_invoice.patient_id).try(:mr_no)
    if template_settings
      @template_active_headers = template_settings[:invoices][0].select { |_key, value| value == true }
      @template_fields = @template_active_headers.keys
    end
  end

  def check_invoice_remaining_amount(params)
    if params[:invoice_inventory_invoice][:advance_payment_breakups_attributes].present?
      advance_amount = params[:invoice_inventory_invoice][:advance_payment_breakups_attributes].values.pluck(:amount).map(&:to_f).sum
    else
      advance_amount = 0.0
    end
    if params[:invoice_inventory_invoice][:payment_received_breakups_attributes].present?
      payment_received_amount = params[:invoice_inventory_invoice][:payment_received_breakups_attributes].values.pluck(:amount).map(&:to_f).sum
    else
      payment_received_amount = 0.0
    end
    advance_amount + payment_received_amount
  end

  def update_inventory_order
    inventory_order = Invoice::InventoryOrder.find_by(invoice_id: @inventory_invoice.id)
    inventory_order.update(
      payment_received: @inventory_invoice.payment_received, payment_pending: @inventory_invoice.payment_pending,
      amount_remaining: @inventory_invoice.amount_remaining, advance_payment: @inventory_invoice.advance_payment,
      payment_completed: @inventory_invoice.payment_completed,
      payment_completed_date: @inventory_invoice.payment_completed_date
    )
  end
end
