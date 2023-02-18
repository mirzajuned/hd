class Inventory::Transaction::ReturnsController < ApplicationController
  include Inventory::ItemsHelper
  before_action :authorize, :verify_store
  before_action :download_report, only: [:item_wise_sale_return, :bill_wise_sale_return]

  def index
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @time_period = params[:time_period]
    fetch_transactions
  end

  def append_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_transactions
  end

  def filter_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_transactions
  end

  def append_lots
    @store_id = params[:store_id]
    @category = params[:item_type]
    fetch_lot_index
  end

  def filter_lots
    @store_id = params[:store_id]
    @category = params[:item_type]
    fetch_lot_index
  end

  def new_lot
    @lot = Inventory::Item::Lot.includes(:lot_units).find_by(id: params[:lot_id])
    @lot_units = @lot.lot_units
    @variant = Inventory::Item::Variant.find_by(id: @lot.variant_id)
    @item = Inventory::Item.find_by(id: @lot.item_id)
  end

  def add_lot
    if params[:is_lot_unit].present?
      lot_unit = Inventory::Item::LotUnit.find_by(id: params[:lot_id])
      lot_id = lot_unit.lot_id
    else
      lot_id = params[:lot_id]
    end
    if params[:embedded_item_id].present?
      items = Inventory::Transaction::Return.find_by(id: params[:transaction_id]).items
      items.find_by(id: params[:embedded_item_id]).delete
    end
    @lot = Inventory::Item::Lot.find_by(id: lot_id)
    @variant = Inventory::Item::Variant.find_by(id: @lot.variant_id)
    @item = Inventory::Item.find_by(id: @lot.item_id)
    @inventory_store = Inventory::Store.find_by(id: @item.store_id)
    if params[:item].present?
      lot_unit = params[:item].values.pluck(:lot_unit_id, :lot_unit_checked)
      @lot_units = check_lot_unit(lot_unit)
    elsif params[:is_lot_unit].present?
      @lot_units = [lot_unit.id.to_s]
    end
    @tax_group = TaxGroup.find(@lot.tax_group_id)
    @tax_rate_details = @tax_group.tax_rate_details.collect { |tax_rate| tax_rate.merge(type: TaxRate.find(tax_rate[:_id]).type) }

    @return_transaction = Inventory::Transaction::Return.build
  end

  def new
    @store_id = params[:store_id]
    @store = Inventory::Store.find(@store_id)
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @category = 'all_item'
    @patient = Patient.find_by(id: params[:patient_id])
    @lots = Inventory::Item::Lot.where(store_id: params[:store_id], stockable: true).is_active.limit(30)

    @return_transaction = Inventory::Transaction::Return.new
  end

  def create
    @store_id = params[:inventory_transaction_return][:store_id]
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @start_date = @end_date = params[:inventory_transaction_return][:return_date]
    bkp_return_bill_number = Invoice::InventoryReturnInvoicesHelper.increment_and_create_return_bill_number(
      @store_id, current_facility.id
    )
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @return_transaction = Inventory::Transaction::Return.new(return_transaction_params)
    @return_transaction.bkp_return_bill_number = bkp_return_bill_number
    @return_transaction.save!
    
    return_bill_number = SequenceManagers::GenerateSequenceService.call('return', @return_transaction.id.to_s, {organisation_id: current_organisation['_id'].to_s, facility_id: current_facility.id.to_s, region_id: current_facility.try(:region_master_id).to_s, department_id: @return_transaction.department_id.to_s})
    @return_transaction.update(return_bill_number: return_bill_number)
    reason = @return_transaction.note || 'Inventory Invoice Return'
    inventory_invoice = Invoice::InventoryInvoice.find_by(id: @return_transaction.invoice_id)
    if @inventory_store.department_id == '50121007'
      CommunicationNotificationJob.perform_now('optical_return', @return_transaction.id.to_s, @return_transaction.class.to_s) if inventory_invoice.nil?
    elsif @inventory_store.department_id == '284748001'
      CommunicationNotificationJob.perform_now('pharmacy_return', @return_transaction.id.to_s, @return_transaction.class.to_s) if inventory_invoice.nil?
    end
    if inventory_invoice&.department_id == '50121007' #optical
      prescription = PatientOpticalPrescription.find_by(id: inventory_invoice.prescription_id)
      CommunicationNotificationJob.perform_now('optical_return', inventory_invoice.id.to_s, inventory_invoice.class.to_s)
    elsif inventory_invoice&.department_id == '284748001' #pharmacy
      CommunicationNotificationJob.perform_now('pharmacy_return', inventory_invoice.id.to_s, inventory_invoice.class.to_s)
      prescription = PatientPrescription.find_by(id: inventory_invoice.prescription_id)
    end

    fetch_transactions
    if @return_transaction.return_type == 'return_against_invoice'
      if @inventory_store.department_id == '284748001'
        type = 'PHARMACY'
      elsif @inventory_store.department_id == '50121007'
        type = 'OPTICAL'
      end
      Patients::Summary::TimelineWorker.call(
        event_name: "#{type}_RETURN", sub_event_name: 'CREATED', invoice_id: @return_transaction.id,
        user_id: current_user.id, user_name: current_user.fullname, encounter_type: type.to_s
      )
    end
    @refund_payments = RefundPayment.where(patient_id: @return_transaction.patient_id, is_deleted: false,
                                           department_id: @return_transaction.department_id.to_s)
    if @return_transaction.invoice_id.present?
      InvoiceJobs::ManageRevenueDataJob.perform_later(@return_transaction.invoice_id.to_s)
    end
    InvoiceJobs::CancelReturnInvoiceJob.perform_later(@return_transaction.id.to_s, 'return', 'inventory')
    InvoiceJobs::ManageCollectionDataJob.perform_later(@return_transaction.id.to_s, 'Return')
    InventoryJobs::PrescriptionDataJob.perform_later(inventory_invoice.department_name.downcase, prescription.id.to_s) if prescription.present?
    # InventoryJobs::CreateRefundPaymentJob.perform_later(@return_transaction.id.to_s, reason, current_user.id.to_s, 'refund')
    Inventory::RefundPayments::CreateService.call(@return_transaction, reason, current_user, 'return')
    if params[:inventory_transaction_return][:return_type] == 'return_against_invoice'
      @inventory_invoice = Invoice::InventoryInvoice.find(@return_transaction.invoice_id)
      @state_transitions = Invoice::InventoryInvoiceStateTransition.where(inventory_invoice_id: @inventory_invoice.id)
      department_id = @inventory_invoice.department_id
      @patientid = @inventory_invoice.patient_id
      @inventory_invoices = Invoice::InventoryInvoice.where(patient_id: @patientid, department_id: "#{department_id}").order_by(created_at: :desc)
      @return_transactions = Inventory::Transaction::Return.where(patient_id: @patientid, department_id: "#{department_id}").order_by(created_at: :desc)
      @advance_payments = AdvancePayment.where(patient_id: @patientid, is_deleted: false, department_id: "#{department_id}")
      @refund_payments = RefundPayment.where(patient_id: @patientid, is_deleted: false, department_id: "#{department_id}")
      @prescription = PatientPrescription.find_by(id: @inventory_invoice.prescription_id)
      @appointment = Appointment.find_by(id: @prescription&.appointment_id)
      header_templates
      render 'print_preview'
    else
      render 'create'
    end
  end

  def show
    @return_transaction = Inventory::Transaction::Return.find(params[:id])
    @invoice = Invoice::InventoryInvoice.find_by(id: @return_transaction.invoice_id)
    @refund_payments = RefundPayment.where(patient_id: @return_transaction.patient_id, is_deleted: false, department_id: @return_transaction.department_id.to_s)
  end

  def delete
    show
  end

  def destroy
    user_name = current_user.fullname
    reason = params[:reason] || 'Invoice Refund'
    @return_transaction = Inventory::Transaction::Return.find(params[:id])
    @return_transaction.update(is_canceled: true, cancel_date: Date.current, canceled_by: user_name, refund_reason: reason)
    @start_date = @end_date = params[:date]
    @store_id = @return_transaction.store_id
    @from = params[:from]
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    fetch_transactions
    if @return_transaction.invoice_id.present?
      InvoiceJobs::ManageRevenueDataJob.perform_later(@return_transaction.invoice_id)
      InvoiceJobs::ManageCollectionDataJob.perform_later(@return_transaction.invoice_id, 'Bill')
      MisJobs::Finance::BillTypeJob.perform_later(@return_transaction.invoice_id)
    end
  end

  def items
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @store_id = params[:store_id]
    @return_transaction = Inventory::Transaction::Return.find(params[:id])
    Inventory::Transactions::Return::CreateService.call(@return_transaction.id.to_s, current_user.id.to_s) if
    @return_transaction.status == 'Pending'
    @stock_receive_note = Inventory::Transaction::StockReceiveNote.find_by(id: @return_transaction.srn_id)
    if @stock_receive_note.present?
      InventoryJobs::Transactions::UpdateStockReceiveNoteJob.perform_later(@stock_receive_note.id.to_s, current_user.id.to_s)
    end
    fetch_transactions
  end

  def free_invoice
    @store_id = params[:store_id]
    redirect_to patients_search_path(url: '/patients/new', url_store: '/inventory/transaction/returns/new',
                                     store_id: @store_id, modal: 'free-invoice-inventory-modal',
                                     show_patient: 'show_patient')
  end

  def print
    invoice_id = params[:invoice_id]
    page_size = params[:page_size]
    facility_id = current_facility.id
    @inventory_return_invoice = Inventory::Transaction::Return.find_by(id: invoice_id)
    @inventory_store = Inventory::Store.find_by(id: @inventory_return_invoice.store_id)
    @facility = Facility.find(facility_id)
    @patient_id = @inventory_return_invoice.patient_id
    @patient = Patient.find_by(id: @patient_id)
    @mr_no = PatientOtherIdentifier.find_by(patient_id: @patient_id).try(:mr_no)
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: @inventory_return_invoice.invoice_id)
    html_template = 'inventory/transaction/returns/print'

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

  def report
    options = { :facility_ids.in => [current_facility.id], is_active: true }
    @all_user = User.where(options.merge(:inventory_store_ids.in => [params[:store_id]])).pluck(:fullname, :id)
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @report_type = params[:report_type]
    @inventory_store = Inventory::Store.find(params[:store_id])
  end

  def bill_wise_sale_return
    @store_name = "#{@store.name} Sale Return Bill Wise Report"
    @time_period = "Detailed Sale Return Bill Wise Report For a Period of #{params[:start_date]} #{params[:start_time]} to #{params[:end_date]} #{params[:end_time]}"
    @data_array, @total_array, @headings = Inventory::Transactions::DownloadSaleReturnBillService.call(@options, params[:department_id], params[:user_id],current_facility, params[:gst_include])
    name_tail = params[:gst_include] == '0' ? 'bill_wise_Sales_Return_Report_Without_Tax_Breakup.xlsx' : 'bill_wise_Sales_Return_Report_With_Tax_Breakup.xlsx'
    @filename = "#{@store.name.squish&.titleize&.tr(' ', '_')}_#{Time.current.strftime('%d_%B_%Y')}_#{Time.current.try(:strftime, '%R:%S')}_#{@user.squish&.titleize&.tr(' ', '_')}_#{name_tail}"
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}.xlsx\"" }
    end
  end

  def item_wise_sale_return
    @store_name = "#{@store.name} Sale Return Item Wise Report"
    @time_period = "Detailed Sale Return Item Wise Report For a Period of #{params[:start_date]} #{params[:start_time]} to #{params[:end_date]} #{params[:end_time]}"
    @data_array, @total_array = Inventory::Transactions::DownloadSaleReturnItemService.call(@options, params[:user_id])
    @filename = "#{@store.name.squish&.titleize&.tr(' ', '_')}_#{Time.now.strftime('%d %B %Y')}_#{Time.now.try(:strftime, '%R:%S')}_#{@user.squish&.titleize&.tr(' ', '_')}_item_wise_sale_return_report"
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}.xlsx\"" }
    end
  end

  def return_invoice
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @return_transaction = Inventory::Transaction::Return.new
    fetch_patient_data
    @inventory_return_invoice = Invoice::InventoryInvoice.find(params[:id])
    # InvoiceJobs::CancelReturnInvoiceJob.perform_later(@return_transaction.id.to_s, 'return')
  end

  def filter_item
    @lot_unit_ids = params[:lot_unit_ids]&.split(',').flatten
    @lot_units = Inventory::Item::LotUnit.where(:id.in => @lot_unit_ids)
    @selected_lot_unit_ids = params[:selected_lot_unit_ids]&.split(',')&.flatten || []
  end

  def lot_unit_item
    @received_lot_units = params[:selected_lot_unit_ids]
    @lot_unit_ids = params[:lot_unit_ids]
  end

  private

  def return_transaction_params
    params.require(:inventory_transaction_return)
          .permit(
            :note, :transaction_date, :entry_type, :entered_by, :user_id, :store_name, :store_id, :total_cost,
            :return_charges, :return_amount, :facility_id, :organisation_id, :return_date, :patient_id, :recipient,
            :recipient_mobile, :department_name, :department_id, :patient_identifier, :invoice_id, :return_type,
            :mode_of_payment, :return_time, :currency_id, :currency_symbol, :specialty_id, :invoice_received_amount,
            :invoice_total_amount, :invoice_discount_percentage, :taxable_amount, :mode_of_payment,
            :card_number, :card_transaction_note, :paytm_transaction_id, :paytm_transaction_note,
            :gpay_transaction_id, :gpay_transaction_note, :phonepe_transaction_id,
            :phonepe_transaction_note, :transfer_date, :transfer_note, :cheque_date, :cheque_note,
            :other_transaction_id, :other_note,
            { tax_breakup: [:_id, :name, :amount, :tax_rate, :tax_type, :taxable_amount] },
            items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :variant_code, :item_id, :lot_id,
              :variant_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :_destroy,
              :search, :mark_up, :batch_no, :cost_price, :total_cost_price, :stock_package, :stock_subpackage,
              :stock_unit, :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :list_price, :tax_inclusive,
              :tax_rate, :tax_name, :tax_group_id, :mrp_pack_denomination, :list_price_pack_denomination,
              :self_batched, :lot_reference_id, :variant_reference_id, :item_reference_id, :vendor_name, :vendor_id,
              :expiry, :expiry_present, :total_cost, :unit_cost, :description, :store_id, :facility_id,
              :organisation_id, :unit_non_taxable_amount, :unit_taxable_amount, :is_verified, :model_no,
              :total_tax_amount, :discount_amount, :discount_display_amount, :sub_store_id, :sub_store_name, 
              { tax_group: [:_id, :name, :amount] }, { lot_unit_ids: [] }
            ]
          )
  end

  def fetch_transactions
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, note: /#{Regexp.escape(query)}/i }
    options[:return_date] = { :$gte => @start_date, :$lte => @end_date } if @start_date.present? && @end_date.present?
    @returns = Inventory::Transaction::Return.where(options).order_by(created_at: 'desc').skip(current_data_row)
                                             .limit(30)
  end

  def fetch_lot_index
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @store_id)
    @sub_stores = @inventory_store.sub_stores
    @search_type = params[:search_type]
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, stockable: true }
    if @category == 'out_stock'
      options = options.merge(stock: 0)
    elsif @category == 'all_item'
    else
      options = options.merge(category: @category)
    end

    if params[:search_type] == 'Barcode'
      lots = Inventory::Item::Lot.where(options).where(barcode_id: query).is_active.skip(current_data_row)
                                 .limit(30)
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

  def download_report
    @store = Inventory::Store.find(params[:store_id])
    @options = { store_id: params[:store_id], start_date: Time.parse(params['start_date'] + ' ' + params['start_time']),
                 end_date: Time.parse(params['end_date'] + ' ' + params['end_time']), user: params[:user_id] }
    @user = params[:user_id] == 'all_user' ? 'all_user' : User.find(params[:user_id]).fullname
    @address = @store.address
    @generate_on = "Generated On: #{Time.now.try(:strftime, '%R:%S')} | #{Time.now.strftime('%d %B %Y')} | #{Date.today.strftime('%A')}"
    @generate_by = "Generated By: #{@user&.titleize}"
  end

  def header_templates
    template_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
                           .custom_template_header_options["#{@inventory_invoice.department_name&.downcase}_settings"]
    @mr_no = PatientOtherIdentifier.find_by(patient_id: @inventory_invoice.patient_id).try(:mr_no)                       
    @template_fields = template_settings[:invoices][0].select { |_key, value| value == true }.keys  if template_settings   
  end

  def check_lot_unit(lot_unit)
    lot_unit_array = []
    lot_unit.each do |unit|
      if unit[1] == 'true'
        lot_unit_array << unit[0]
      end
    end
    lot_unit_array
  end
end
