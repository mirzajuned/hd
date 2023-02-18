class Invoice::InventoryOrdersController < ApplicationController
  before_action :authorize, :verify_store
  before_action :last_search_by, only: [:new]
  include ActionView::Helpers::NumberHelper
  include Invoice::InventoryInvoicesHelper
  include MedicineCountHelper

  def index
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @start_date = DateTime.parse(params[:start_date]).strftime('%d/%m/%Y')
    @end_date =  DateTime.parse(params[:end_date]).strftime('%d/%m/%Y')
    @time_period = params[:time_period]
    @fitter_name = params[:fitter_name]
    @fitter_id = params[:fitter_id] || 'all'
    @state_name = params[:state_name] || 'all'
    @sort_by = params[:sort_by].present? ? params[:sort_by] : 'newest_first'
    @home_delivery = params[:home_delivery] || 'all'
    @pending_bills_count = Invoice::InventoryOrder.where(store_id: @store_id, payment_completed: false,
                                                         invoice_type: 'credit', is_deleted: false).count
    fetch_orders
  end

  def append_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @fitter_id = params[:fitter_id]
    @state_name = params[:state_name]
    @sort_by = params[:sort_by].present? ? params[:sort_by] : 'newest_first'
    @home_delivery = params[:home_delivery] || 'all'
    fetch_orders
  end

  def filter_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @fitter_id = params[:fitter_id]
    @state_name = params[:state_name]
    @sort_by = params[:sort_by].present? ? params[:sort_by] : 'newest_first'
    @home_delivery = params[:home_delivery] || 'all'
    fetch_orders
  end

  def new
    @current_facility_id = current_facility.id.to_s
    @current_organisation_id = current_user.organisation_id.to_s
    category_ids = Inventory::Store.find_by(id: params[:store_id])&.category_ids
    @vendors = Inventory::Vendor.where(:category_ids.in => category_ids, is_deleted: false)
    @invoice_setting = InvoiceSetting.find_by(organisation_id: @current_organisation_id)
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id).pluck(:name, :id)
    fetch_patient_data
    @currency = Currency.find_by(id: current_facility.currency_id.to_s)

    @department_id = @inventory_store.department_id

    @fitters = Inventory::Fitter.where(:store_ids.in => [@inventory_store.id&.to_s], is_deleted: false, is_disable: false).pluck(:name, :id)
    @advance_payments = AdvancePayment.where(patient_id: params[:patient_id], advance_state: 'None',
                                             is_deleted: false, is_refunded: false, department_id: @department_id.to_s)
    if params[:prescription_id].present?
      if @department_id == '50121007'
        @patient_prescription = PatientOpticalPrescription.find_by(id: params[:prescription_id])
      elsif @department_id == '284748001'
        @patient_prescription = PatientPrescription.find_by(id: params[:prescription_id])
      end
    end

    @medication_groups = begin
                           @patient_prescription.medications.group_by { |d| d[:status] }
                         rescue StandardError
                           nil
                         end

    @print_settings = PrintSetting.print_options(@current_organisation_id, @current_facility_id,
                                                 [@department_id])

    @inventory_order = Invoice::InventoryOrder.new

    @inventory_order.items.build
    @category = 'all_item'
    @lots = Inventory::Item::Lot.where(store_id: params[:store_id], :available_stock.gt => 0.0, stockable: true)
                                .is_active.limit(30)   
    if params[:vendor_id].present?                                                     
      @items = Inventory::Item.where(vendor_id: params[:vendor_id], store_id: params[:store_id], stockable: false)
                              .is_active.limit(30)
    else
      @items = []
    end
    respond_to do |format|
      format.js {}
    end
  end

  def create
    @store_id = params[:invoice_inventory_order][:store_id]
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @start_date = @end_date = params[:invoice_inventory_order][:checkout_date]
    bkp_order_number = Invoice::InventoryInvoicesHelper.increment_and_create_order_number(
      current_organisation['_id'].to_s, true
    )
    @prescription_id = params[:invoice_inventory_order][:prescription_id]
    @department_id = params[:invoice_inventory_order][:department_id]
    if @prescription_id.present?
      if @department_id == '284748001'
        @prescription = PatientPrescription.find_by(id: @prescription_id)
      else
        @prescription = PatientOpticalPrescription.find_by(id: @prescription_id)
      end
      if @prescription.converted && params[:invoice_inventory_order][:re_converted] == 'false'
        @order_id = @prescription.order_id
      else
        @inventory_order = Invoice::InventoryOrder.new(inventory_order_params)
      end
    else
      @inventory_order = Invoice::InventoryOrder.new(inventory_order_params)
    end
    if @inventory_order.present?
      @inventory_order.total_offer = @inventory_order.try(:offer_on_bill)
      srn_params = params[:invoice_inventory_order][:items_attributes].values.pluck(:srn_required)
      if srn_params.include? 'true'
        @inventory_order.srn_required = true
        @inventory_order.srn_pending = true
        @inventory_order.srn_status = 'pending'
        @inventory_order.requisition_required = true
        @inventory_order.requisition_pending = true
      end
      if current_facility.country_id != 'KH_039'
        @inventory_order.doctor_name = params[:invoice_inventory_order][:consultant_name]
      end
      @inventory_order.bkp_order_number = bkp_order_number
      # @inventory_order.order_number = bkp_order_number
      if current_facility.country_id != 'KH_039'
        @inventory_order.doctor_name = params[:invoice_inventory_order][:consultant_name]
      end
      @inventory_order.order_date_time = params[:invoice_inventory_order][:order_date_time] || Time.current
      @inventory_order.order_date = params[:invoice_inventory_order][:order_date] || Date.current
      if @inventory_order.invoice_type == 'cash'
        @inventory_order.payment_pending = params[:invoice_inventory_order][:amount_remaining].to_f
      else
        @inventory_order.payment_pending += params[:invoice_inventory_order][:amount_remaining].to_f
      end
      @negative_items = @inventory_order.items.negative_stock_items
      if @negative_items.blank?
        if @inventory_order.save!
          order_number = SequenceManagers::GenerateSequenceService.call(
            'sales_order', @inventory_order.id.to_s, { organisation_id: current_organisation['_id'].to_s, facility_id: current_facility['_id'].to_s, region_id: current_facility['region_master_id'].to_s, department_id: @inventory_order.department_id, store_id: @store_id }
          )
          @inventory_order.update(order_number: order_number)
          # Inventory::Transactions::History::BlockedLot::CreateService.call(@inventory_order)
          Invoice::CreateOrderNumberService.call(@inventory_order)
          Invoice::UpdateOrderStateService.call(@inventory_order.id.to_s)
          if @inventory_order.pending_advance_payments_attributes.present?
            Invoice::CreatePendingAdvanceService.call(@inventory_order, 'order')
          end
          if @department_id == '284748001'
            if params[:invoice_inventory_order][:prescription_id].blank?
              CommunicationNotificationJob.perform_now('pharmacy_patient', @inventory_order.id.to_s, @inventory_order.class.to_s)
              CommunicationNotificationJob.perform_now('pharmacy_store', @inventory_order.id.to_s, @inventory_order.class.to_s)
            end
            CommunicationNotificationJob.perform_now('pharmacy_order_placed', @inventory_order.id.to_s, @inventory_order.class.to_s)
          else
            CommunicationNotificationJob.perform_now('optical_order_placed', @inventory_order.id.to_s, @inventory_order.class.to_s)
          end
          from = @inventory_order.state
          if @inventory_order.fitting_required == true
            to = 'fitting'
          elsif @inventory_order.delivered == true
            to = 'delivered'
          end
          @inventory_order.send(from + '_to_' + to) if to.present?
          @prescription_id = params[:invoice_inventory_order][:prescription_id]
          if @prescription_id.present?
            @department_id = params[:invoice_inventory_order][:department_id]
            if @department_id == '284748001'

              @prescription = PatientPrescription.find_by(id: @prescription_id)
              @pres_prev_state = @prescription.converted
              # @prescription.update(mark_converted_by: current_user.id.to_s, converted: 'true',
              #                      pharmacy_comment: params[:invoice_inventory_order][:note],
              #                      encounterdate: Time.current)
              @prescription.update(mark_converted_by: current_user.id.to_s, converted: true,
                                   pharmacy_comment: params[:invoice_inventory_order][:note],
                                   encounterdate: Time.current, converted_date: Date.current,
                                   converted_datetime: Time.current, mark_patient_visited: true,
                                   order_id: @inventory_order.id, not_converted_to_converted: params[:invoice_inventory_order][:not_converted_to_converted])
            elsif @department_id == '50121007'
              @prescription = PatientOpticalPrescription.find_by(id: @prescription_id)
              @appointment = Appointment.find_by(id: @prescription.appointment_id)
              order_count = @prescription.order_count.to_i + 1
              re_converted = order_count > 1
              @prescription.update(mark_converted_by: current_user.id.to_s, converted: true, mark_patient_visited: true,
                                   encounterdate: Time.current, converted_date: Date.current, order_count: order_count,
                                   converted_datetime: Time.current, re_converted: re_converted,
                                   order_id: @inventory_order.id, not_converted_to_converted: params[:invoice_inventory_order][:not_converted_to_converted])
            end
          else
            fetch_orders
          end
          # Advance Logic

          @inventory_order.advance_payment_breakups.each do |advance_payment_breakup|
            advance_payment = AdvancePayment.find_by(id: advance_payment_breakup.advance_payment_id)
            next unless advance_payment.present?

            advance_payment.amount_remaining = advance_payment.amount_remaining - advance_payment_breakup.amount
            advance_payment.advance_state = ('Settled' if advance_payment.amount_remaining == 0) || 'None'
            advance_payment.advance_history = advance_payment.try(:advance_history) || []
            advance_history = {
              advance_payment_breakup_id: advance_payment_breakup.id.to_s, order_id: @inventory_order.id.to_s,
              invoice_type: 'Optical', type: 'Adjusted', user_name: current_user.fullname,
              amount: advance_payment_breakup.amount, event_time: Time.current.strftime('%I:%M %p, %d/%m/%Y'),
              order_number: @inventory_order.order_number
            }
            advance_payment.advance_history << advance_history

            advance_payment.save
            # InvoiceJobs::AdvancePaymentJob.perform_later(advance_payment.id.to_s)
          end
          Inventory::Transactions::History::BlockedLot::CreateService.call(@inventory_order) if @inventory_order.present?
          if @inventory_order.delivered
            @inventory_invoice_id = Invoice::CreateInventoryInvoiceService.call(@inventory_order.id.to_s, current_user.id.to_s, current_facility['region_master_id'].to_s)
            InventoryJobs::Transactions::InvoiceJob.perform_later(@inventory_invoice_id.to_s, current_user.id.to_s)
            patient_summary('CREATED')
            Analytics::Financial::FinancialJob.perform_later(@inventory_invoice_id.to_s,
                                                             @inventory_order.try(:department_name))
            TaxCalculationJob.perform_later(@inventory_invoice_id.to_s, 'tax_collected_details')
            if @inventory_order.present?
              Analytics::Financial::InventoryPaymentModeJob.perform_later(@inventory_invoice_id.to_s)
            end
            InvoiceJobs::ManageRevenueDataJob.perform_later(@inventory_invoice_id.to_s)
            InvoiceJobs::ManageCollectionDataJob.perform_later(@inventory_invoice_id.to_s, 'Bill')
            MisJobs::Finance::BillTypeJob.perform_later(@inventory_invoice_id.to_s)
            MisJobs::Finance::InvoiceServiceJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now)
                                               .perform_later(@inventory_invoice_id.to_s)
            if @inventory_order.department_id == '284748001' && @prescription_id.present?
              Analytics::Conversion::PharmacyPrescriptionJob.perform_later(@prescription_id.to_s, current_user.id.to_s,
                                                                           'Pharmacy')
              InventoryJobs::PrescriptionDataJob.perform_later('pharmacy', @prescription_id.to_s)
            elsif @inventory_order.department_id == '50121007' && @prescription_id.present?
              Analytics::Conversion::OpticalPrescriptionJob.perform_later(@prescription_id.to_s, current_user.id.to_s,
                                                                          'Optical')
              InventoryJobs::PrescriptionDataJob.perform_later('optical', @prescription_id.to_s)
            end
          end
          if @inventory_order.department_id == '50121007' && @prescription_id.present?
            update_optical_prescription
          end
          # if params[:invoice_inventory_order][:items_attributes].values.pluck(:item_created_from).include? 'sale_order'
          if @inventory_order.srn_required && current_facility.description_comment
            InventoryJobs::Transactions::CreateStockReceiveNoteJob.perform_later(@inventory_order.id.to_s, current_user.id.to_s)
          end
        end
      else
        @inventory_store = Inventory::Store.find_by(id: @store_id)
        @category = 'all_item'
        @lots = Inventory::Item::Lot.where(store_id: @store_id, :stock.gte => 1, stockable: true).is_active.limit(30)
        @errors = ['The stock is unavailable', 'Please make sure the item quatity is not more than available stock']
        render '/inventory/transaction/adjustments/item_stock_validation.js.erb'
      end
    end
    OfferManagerJobs::ManageOfferCountJob.perform_later(@inventory_order.offer_manager_id.to_s) if @inventory_order&.try(:offer_manager_id).present?
    @inventory_order = Invoice::InventoryOrder.find_by(id: @order_id) if @order_id.present?
    header_templates
    @inventory_order.reload
    CommunicationNotificationJob.perform_now('optical_fitting', @inventory_order.id.to_s, @inventory_order.class.to_s) if @department_id == '50121007' && @inventory_order.fitting_required == true
    CommunicationNotificationJob.perform_now('optical_bill_creation', @inventory_order.id.to_s, @inventory_order.class.to_s) if @inventory_order.delivered == true && @department_id == '50121007'
    CommunicationNotificationJob.perform_now('optical_delivered', @inventory_order.id.to_s, @inventory_order.class.to_s) if @inventory_order.delivered == true && @department_id == '50121007'
    CommunicationNotificationJob.perform_now('pharmacy_bill_creation', @inventory_order.id.to_s, @inventory_order.class.to_s) if @department_id == '284748001'
  end

  def show
    @inventory_order = Invoice::InventoryOrder.find_by(id: params[:id])
    @state_transitions = Invoice::InventoryOrderStateTransition.where(inventory_order_id: @inventory_order.id)
    @return_transaction = Inventory::Transaction::Return.find_by(invoice_id: params[:id])
    @is_srn_lot_created = true
    @items = @inventory_order.items.where(requisition_required: true)
    @items.each do |item|
      lots = Inventory::Item::Lot.where(item_id: item.item_id, optical_order_id: @inventory_order.id, :available_stock.gte => 1)
      total_available_stock = lots.pluck(:available_stock).sum
      if lots.present? && item.quantity <= total_available_stock
        @is_srn_lot_created = true
      else
        @is_srn_lot_created = false
        break
      end
    end
    fetch_all_orders
    header_templates
    @from = 'show'
  end

  def show_modal
    @inventory_order = Invoice::InventoryOrder.find_by(id: params[:id])
    @return_transaction = Inventory::Transaction::Return.find_by(invoice_id: params[:id])
    @state_transitions = Invoice::InventoryOrderStateTransition.where(inventory_order_id: @inventory_order.id)
    @inventory_store = Inventory::Store.find_by(id: @inventory_order.store_id)
    @stock_receive_note = Inventory::Transaction::StockReceiveNote.find_by(order_id: @inventory_order.id)
    header_templates
    respond_to do |format|
      format.js { render 'invoice/inventory_orders/show_modal' }
    end
  end

  def show_modal_refund
    @return_transaction = Inventory::Transaction::Return.find_by(id: params[:id])
    @inventory_order = Invoice::InventoryOrder.find_by(id: @return_transaction.invoice_id)
  end

  def free_invoice
    @store_id = params[:store_id]
    redirect_to patients_search_path(url: '/patients/new', url_store: '/invoice/inventory_orders/new',
                                     store_id: @store_id, modal: 'free-invoice-inventory-modal')
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
      lot_id = lot_unit&.lot_id
    else
      lot_id = params[:lot_id]
    end
    return unless lot_id.present?

    if params[:embedded_item_id].present?
      items = Invoice::InventoryOrder.find_by(id: params[:transaction_id]).items
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
    @tax_group = TaxGroup.find_by(id: @lot.tax_group_id)
    # @tax_rate_details = @tax_group.tax_rate_details.collect { |tax_rate| tax_rate.merge(type: TaxRate.find(tax_rate[:_id]).type) }
    @tax_rate_details = @tax_group.tax_rate_details.collect { |tax_rate| tax_rate.merge(type: TaxRate.find(tax_rate[:_id]).type, gst_type: @tax_group.name) }

    @inventory_order = Invoice::InventoryOrder.build
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

  def add_item
    @item = Inventory::Item.find_by(id: params[:item_id])
    @inventory_store = Inventory::Store.find_by(id: @item.store_id)
    @inventory_order = Invoice::InventoryOrder.build
    @tax_group = TaxGroup.find(@item.tax_group_id)
    @variant = Inventory::Item::Variant.find_by(item_id: @item.id)
    @tax_rate_details = @tax_group.tax_rate_details.collect { |tax_rate| tax_rate.merge(type: TaxRate.find(tax_rate[:_id]).type, gst_type: @tax_group.name) }
  end

  def print_preview
    if params[:from].present?
      @inventory_order = Invoice::InventoryOrder.find_by(id: params[:id])
    else
      @inventory_order = Invoice::InventoryOrder.find_by(prescription_id: params[:prescription_id])
      if @inventory_order.department_id == '284748001'
        @prescription = PatientPrescription.find_by(id: params[:prescription_id])
      elsif @inventory_order.department_id == '50121007'
        @prescription = PatientOpticalPrescription.find_by(id: params[:prescription_id])
      end
      @appointment = Appointment.find_by(id: @prescription.appointment_id)
    end
    @inventory_store = Inventory::Store.find_by(id: @inventory_order.store_id)
    header_templates
  end

  def review_order
    @inventory_order = Invoice::InventoryOrder.find_by(id: params[:id])
    @inventory_store = Inventory::Store.find_by(id: @inventory_order.store_id)
    @patient = Patient.find_by(id: @inventory_order.patient_id)
    @currency = Currency.find_by(id: current_facility.currency_id.to_s)
    @advance_payments = AdvancePayment.where(patient_id: @inventory_order.patient_id, is_deleted: false,
                                             is_refunded: false, department_id: '50121007')
    return unless @inventory_order.prescription_id.present?

    if @inventory_order.department_id == '50121007'
      @patient_prescription = PatientOpticalPrescription.find_by(id: @inventory_order.prescription_id)
    elsif @inventory_order.department_id == '284748001'
      @patient_prescription = PatientPrescription.find_by(id: @inventory_order.prescription_id)
    end
    @print_settings = PrintSetting.print_options(@current_user.organisation_id.to_s, current_facility_id,
                                                 [@inventory_order.department_id])
  end

  def change_state
    @inventory_order = Invoice::InventoryOrder.find_by(id: params[:id])
    @state_transitions = Invoice::InventoryOrderStateTransition.where(inventory_order_id: @inventory_order.id)
    @inventory_store = Inventory::Store.find_by(id: @inventory_order.store_id)
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: @inventory_order.invoice_id)
    from = @inventory_order.state
    to = params[:to].to_s
    unless from == to
      @inventory_order.update(delivery_date: Time.current, delivered: true) if to == 'delivered'
      @inventory_order.send(from + '_to_' + to) if (from + '_to_' + to) != 'fitting_to_delivered'
      if @inventory_order.department_id == '50121007' # optical
        prescription = PatientOpticalPrescription.find_by(id: @inventory_order.prescription_id)
      elsif @inventory_order.department_id == '284748001' # pharmacy
        prescription = PatientPrescription.find_by(id: @inventory_order.prescription_id)
      end
      if to == 'delivered' && @inventory_invoice.present?
        @inventory_invoice.update(delivery_date: Time.current, delivered: true)
        InvoiceJobs::ManageRevenueDataJob.perform_later(@inventory_invoice.id.to_s)
        InvoiceJobs::ManageCollectionDataJob.perform_later(@inventory_invoice.id.to_s, 'Bill')
        MisJobs::Finance::InvoiceServiceJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@inventory_invoice.id.to_s)
      end

      if prescription.present? && @inventory_invoice.present?
        InventoryJobs::PrescriptionDataJob.perform_later(@inventory_invoice.department_name.downcase, prescription.id.to_s)
      end
    end
    @inventory_invoice.update!(state: @inventory_order.state) if @inventory_invoice.present?
    fetch_all_orders
    header_templates
    CommunicationNotificationJob.perform_now('optical_fitting', @inventory_order.id.to_s, @inventory_order.class.to_s) if params[:to] == 'fitting'
    CommunicationNotificationJob.perform_now('optical_ready', @inventory_order.id.to_s, @inventory_order.class.to_s) if params[:to] == 'ready'
    CommunicationNotificationJob.perform_now('optical_delivered', @inventory_order.id.to_s, @inventory_order.class.to_s) if params[:to] == 'delivered'
  end

  def undo_state
    @inventory_order = Invoice::InventoryOrder.find_by(id: params[:id])
    @state_transitions = Invoice::InventoryOrderStateTransition.where(inventory_order_id: @inventory_order.id)
    @inventory_invoice = Invoice::InventoryInvoice.find_by(id: @inventory_order.invoice_id)
    last_state = @state_transitions.last_states[0]
    secondlast_state = @state_transitions.last_states[1]

    if secondlast_state.present?
      last_state.delete
      secondlast_state&.update(transition_end: nil)
      @inventory_order.update(department_id: secondlast_state&.department_id, store_id: secondlast_state&.store_id,
                              state: secondlast_state&.to, delivery_date: secondlast_state&.delivery_date)
    end
    @inventory_invoice.update!(state: @inventory_order.state) if @inventory_invoice.present?
    CommunicationNotificationJob.perform_now('optical_fitting', @inventory_order.id.to_s, @inventory_order.class.to_s) if @inventory_order.state == 'fitting'
    CommunicationNotificationJob.perform_now('optical_ready', @inventory_order.id.to_s, @inventory_order.class.to_s) if @inventory_order.state == 'ready'
    fetch_all_orders
    header_templates
  end

  def edit_delivery_date
    @inventory_order = Invoice::InventoryOrder.find_by(id: params[:id])
  end

  def save_delivery_date
    @inventory_order = Invoice::InventoryOrder.find_by(id: params[:id])
    @state_transitions = Invoice::InventoryInvoiceStateTransition.where(inventory_order_id: @inventory_order.id)
    fetch_all_orders
    header_templates
    date = @inventory_order.estimated_delivery_date&.strftime('%d/%m/%Y')
    new_date = params[:new_delivery_date]
    time = Time.now.try(:strftime, '%R:%S')
    date_time = Time.current
    @inventory_order.update(last_estimated_delivery_date: date_time, last_date_change_user: current_user.fullname,
                              estimated_delivery_date: new_date, delivery_date_change_reason: params[:reason])
  end

  def confirm_disable
    @inventory_order = Invoice::InventoryOrder.find_by(id: params[:id])
    @inventory_store = Inventory::Store.find_by(id: @inventory_order.store_id)
    header_templates
  end

  def disable
    user_name = current_user.fullname
    reason = params[:reason] || 'Order Refund'
     data = {mode_of_payment: params[:mode_of_payment], transaction_id: params[:transaction_id], transaction_note: params[:transaction_note] }
    @inventory_order = Invoice::InventoryOrder.find_by(id: params[:id])
    @inventory_order.update(is_canceled: true, cancel_date: Date.current, canceled_by: user_name,
                            refund_reason: reason, canceled_by_id: current_user.id)
    # Inventory::Transactions::Sale::CreateService.call(@inventory_order.id.to_s, current_user.id.to_s,
    #                                                   user_name, reason)
    @start_date = @end_date = params[:date]
    @store_id = @inventory_order.store_id
    @from = params[:from]
    @inventory_store = Inventory::Store.find_by(id: @inventory_order.store_id)
    fetch_orders
    # @return_transaction = Inventory::Transactions::CreateReturnService.call(@inventory_order.id.to_s, current_user.id.to_s, user_name, 'order')
    @inventory_order.set_cancelled(current_user, reason)
    Inventory::Transactions::History::BlockedLot::CancelService.call(@inventory_order)
    # patient_summary('CANCELLED')
    CommunicationNotificationJob.perform_now('optical_order_cancelled', @inventory_order.id.to_s, @inventory_order.class.to_s)
    if @inventory_order.department_id == '50121007' # optical
      prescription = PatientOpticalPrescription.find_by(id: @inventory_order.prescription_id)
    elsif @inventory_order.department_id == '284748001' # pharmacy
      prescription = PatientPrescription.find_by(id: @inventory_order.prescription_id)
    end
    # InvoiceJobs::ManageCollectionDataJob.perform_later(@return_transaction.id.to_s, 'Return')
    # Analytics::Financial::FinancialJob.perform_later(@inventory_order.id.to_s,
    #                                                  @inventory_order.try(:department_name))
    # InvoiceJobs::ManageRevenueDataJob.perform_later(@inventory_order.id.to_s)
    # InvoiceJobs::CancelReturnInvoiceJob.perform_later(@return_transaction.id.to_s, 'return', 'inventory')
    # MisJobs::Finance::InvoiceServiceJob.set(wait_until: Global.sidekiq.job_config.wait_in_mins.minutes.from_now).perform_later(@inventory_order.id.to_s)
    if prescription.present?
      # InventoryJobs::PrescriptionDataJob.perform_later(
      #   @inventory_order.department_name.downcase, prescription.id.to_s
      # )
    end
    # InventoryJobs::CreateRefundPaymentJob.perform_later(@return_transaction.id.to_s, reason, current_user.id.to_s, 'order')
    if @inventory_order.advance_payment.to_f > 0
      refund_payment_id = Inventory::RefundPayments::CreateService.call(@inventory_order, reason, current_user, 'order', data)
      InvoiceJobs::ManageCollectionDataJob.perform_later(refund_payment_id.to_s, 'Refund')
      InvoiceJobs::CancelReturnInvoiceJob.perform_later(refund_payment_id.to_s, 'return', 'receipt')
      @inventory_order.advance_payment_breakups.pluck(:advance_payment_id).each do |advance_payment_id|
        InvoiceJobs::AdvancePaymentJob.perform_later(advance_payment_id.to_s)
        # advance = AdvancePayment.find_by(id: advance_payment_id)
        # advance_payment_hash = {
        #   is_canceled: true, refund_amount: advance.amount, refund_date: Time.current.strftime('%d/%m/%Y'),
        #   refund_time: Time.current.strftime('%I:%M %p, %d/%m/%Y'), is_refunded: true,
        #   refunded_by: current_user.try(:fullname), refunded_by_id: current_user.try(:id),
        #   refund_reason: reason, canceled_by_id: current_user.id
        # }
        # advance.update!(advance_payment_hash)
      end
    end
    requisition = Inventory::Order::Requisition.find_by(id: @inventory_order.requisition_id)
    if requisition.present?
      requisition_received = Inventory::Order::RequisitionReceived.find_by(requisition_order_id: requisition.id)
      requisition.update(is_disabled: true, is_active: false, status: 'Closed',
                          closed_reason: 'Optical Order Cancelled', closed_by: current_user.fullname,
                          closed_by_id: current_user.id, closed_date_time: Time.current)
      requisition_received.update(is_disabled: true, is_active: false, status: 'Closed',
                                  closed_reason: 'Optical Order Cancelled', closed_by: current_user.fullname,
                                  closed_by_id: current_user.id, closed_date_time: Time.current)
    end
    if @inventory_order.srn_required && @stock_receive_note.present?
      @stock_receive_note = Inventory::Transaction::StockReceiveNote.find_by(order_id: @inventory_order.id)
      InventoryJobs::Transactions::UpdateStockReceiveNoteJob.perform_later(@stock_receive_note.id.to_s, current_user.id.to_s)
    end
    header_templates
  end

  def payment_received_details
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @inventory_order = Invoice::InventoryOrder.find_by(id: params[:id])
    @print_settings = PrintSetting.print_options(current_user.organisation_id.to_s, current_facility.id.to_s, ['485396012'])
  end

  def print_receipt
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @inventory_order = Invoice::InventoryOrder.find_by(id: params[:id])

    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id)

    
    @payment_received = @inventory_order.payment_received_breakups.find_by(id: params[:payment_received_id])
    @refund_payments = RefundPayment.where(invoice_id: @inventory_order.id)
    @receiving_user = User.find_by(id: @payment_received.received_by)

    @organisation_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    if @payment_received.received_from.to_s == @inventory_order.patient_id.to_s
      @received_from = @inventory_order.patient.fullname
    else
      @payer_master = PayerMaster.find_by(id: @payment_received.received_from.to_s)
      @received_from = @payer_master.try(:display_name).to_s.titleize + ' - ' + @payer_master.contact_group.name.to_s.titleize
    end
    @patient = Patient.find_by(id: @inventory_order.patient_id)

    header_templates

    currency_symbol = (@inventory_order.currency_symbol || current_facility.currency_symbol)
    @locals = { mail_job: false, patient: @patient, appointment: @appointment, invoice: @inventory_order, refund_payment: @refund_payment, facility_setting: @facility_setting, flag: 'Invoice', invoice_setting: @invoice_setting, organisation_settings: @organisation_settings, currency_symbol: currency_symbol }
    respond_to do |format|
      format.pdf { render template: 'invoice/inventory_orders/receipt.pdf.erb', pdf: 'xyz', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_setting.try(:left_margin).to_i * 10, right: @print_setting.try(:right_margin).to_i * 10, top: @print_setting.try(:header_height).to_i * 10, bottom: @print_setting.try(:footer_height).to_i * 10 }, locals: @locals }
    end
  end

  def settle_order
    @number_format = CommonHelper.get_number_format(current_facility, current_organisation)
    @inventory_order = Invoice::InventoryOrder.find_by(id: params[:id])
    @payer_masters = PayerMaster.includes(:contact_group).where(facility_id: current_facility.id, is_active: true)
  end

  def settled_invoice
    @inventory_order = Invoice.find_by(id: params[:id])
    @patient = Patient.find_by(id: @inventory_order.patient_id)
    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id).pluck(:name, :id)
    @inventory_order_type = @inventory_order._type
    @type = @inventory_order_type.split('::')[1].to_s&.underscore&.downcase
    @store_id = params[:store_id]

    @inventory_order.payment_pending = params[:settle_invoice][:payment_pending].to_f
    @inventory_order.payment_received = @inventory_order.payment_received + params[:settle_invoice][:payment_received].to_f

    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id.to_s)

    invoice_payment_pending = 0
    invoice_amount_received = 0
    currency_id = (@inventory_order.currency_id || current_facility.currency_id)
    currency_symbol = (@inventory_order.currency_symbol || current_facility.currency_symbol)
    params[:settle_invoice][:payment_received_breakups].to_unsafe_h.each do |_k, payment_received|
      # next unless payment_received[:settle_amount].to_f > 0
      total_amount_received = payment_received[:amount_received].to_f + payment_received[:tax_deducted].to_f + payment_received[:payer_difference].to_f + payment_received[:other_revenue_spilage].to_f
      next unless total_amount_received > 0

      invoice_amount_received += payment_received[:amount_received].to_f

      payment_pending_breakup = @inventory_order.payment_pending_breakups.find_by(id: payment_received[:payment_pending_id])
      next unless payment_pending_breakup.present?

      # Payment Received Document
      payment_received_breakups_new = @inventory_order.payment_received_breakups.new
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
      payment_received_breakups_new[:currency_id] = currency_id
      payment_received_breakups_new[:currency_symbol] = currency_symbol
      # to generate for receipt_id for each txn
      Invoice::CreateBillNumberService.call(@inventory_order)
      payment_received_breakups_new.save!
      # Payment Pending Document
      if total_amount_received != payment_received[:amount].to_f
        amount_remaining = (payment_received[:amount].to_f - total_amount_received).round(2)
        payment_pending_breakup.update(amount: amount_remaining, date: Date.current, time: Time.current.utc)
        invoice_payment_pending += amount_remaining
      elsif total_amount_received == payment_received[:amount].to_f
        payment_pending_breakup.delete
      end
    end
    @inventory_order.amount_received = (@inventory_order.amount_received.to_f + invoice_amount_received).round(2)
    # @inventory_order.payment_pending = invoice_payment_pending.round(2)
    if @inventory_order.save
      CommunicationNotificationJob.perform_now('pharmacy_bill_creation', @inventory_order.id.to_s, @inventory_order.class.to_s)
      @refund_payments = RefundPayment.where(invoice_id: @inventory_order.id)

      # @inventory_orders = if @inventory_order_type.present?
      #               Invoice.where(facility_id: current_facility.id.to_s, payment_completed: false, _type: @inventory_order, is_deleted: false)
      #             else
      #               Invoice.where(facility_id: current_facility.id.to_s, payment_completed: false, is_deleted: false)
      #             end
      # InvoiceJobs::ManageRevenueDataJob.perform_later(@inventory_order.id.to_s)
      # InvoiceJobs::ManageCollectionDataJob.perform_later(@inventory_order.id.to_s, 'Bill')
      # MisJobs::Finance::ItemWiseBillTypeJob.perform_later(@inventory_order.id.to_s)
    end
    header_templates
  end

  def print
    order_id = params[:order_id]
    page_size = params[:page_size]
    facility_id = current_facility.id
    @inventory_order = Invoice::InventoryOrder.find_by(id: order_id)
    @inventory_store = Inventory::Store.find_by(id: @inventory_order.store_id)
    @facility = Facility.find(facility_id)
    @patient_id = @inventory_order.patient_id
    @patient = Patient.find_by(id: @patient_id)
    @mr_no = PatientOtherIdentifier.find_by(patient_id: @patient_id).try(:mr_no)
    @invoice_setting = InvoiceSetting.find_by(organisation_id: current_user.organisation_id.to_s)
    html_template = 'invoice/inventory_orders/print'

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

  private

  def inventory_order_params
    params.require(:invoice_inventory_order)
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
            :patient_mrn, :insurer_group_id, :insurer_id, :amount_received, :home_delivery, :vendor_id,
            :r_glassesprescriptions_distant_sph, :r_glassesprescriptions_distant_cyl,
            :r_glassesprescriptions_distant_axis, :r_glassesprescriptions_distant_vision,
            :r_glassesprescriptions_add_sph, :r_glassesprescriptions_add_cyl, :r_glassesprescriptions_add_axis,
            :r_glassesprescriptions_add_vision, :r_glassesprescriptions_near_sph, :r_glassesprescriptions_near_cyl,
            :r_glassesprescriptions_near_axis, :r_glassesprescriptions_near_vision, :l_glassesprescriptions_near_axis,
            :l_glassesprescriptions_distant_sph, :l_glassesprescriptions_distant_cyl,
            :l_glassesprescriptions_distant_axis, :l_glassesprescriptions_distant_vision,
            :l_glassesprescriptions_add_sph, :l_glassesprescriptions_add_cyl, :l_glassesprescriptions_add_axis,
            :l_glassesprescriptions_add_vision, :l_glassesprescriptions_near_sph, :l_glassesprescriptions_near_cyl,
            :l_glassesprescriptions_near_axis, :l_glassesprescriptions_near_vision,:gstin, :legal_name,
            :offer_on_bill, :total_offer, :offer_manager_id, :offer_name, :offer_code,
            :offer_percentage, :offer_applied_at, :offer_applied_at_name, :offer_applied_by,
            :offer_applied_by_name, :offer_applied_date, :offer_applied_datetime,:is_create_gst_bill,
            :offer_applied_by_name, :offer_applied_date, :offer_applied_datetime, :r_glassesprescriptions_dia,
            :r_glassesprescriptions_size, :r_glassesprescriptions_fittingheight, :r_glassesprescriptions_prismbase,
            :l_glassesprescriptions_dia, :l_glassesprescriptions_size, :l_glassesprescriptions_fittingheight,
            :l_glassesprescriptions_prismbase, :l_glassesprescriptions_ipd, :r_glassesprescriptions_ipd,
            :l_glassesprescriptions_typeoflens, :r_glassesprescriptions_typeoflens, :l_glassesprescriptions_lenstint,
            :r_glassesprescriptions_lenstint, :r_glassesprescriptions_framematerial, :l_glassesprescriptions_framematerial,
            :r_glassesprescriptions_lensmaterial, :l_glassesprescriptions_lensmaterial, :r_glassesprescriptions_distance_pd,
            :r_glassesprescriptions_near_pd, :l_glassesprescriptions_distance_pd, :l_glassesprescriptions_near_pd,
            items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :variant_code, :item_id, :variant_id,
              :lot_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :search, :mark_up,
              :batch_no, :cost_price, :total_cost_price, :stock_package, :stock_subpackage, :stock_unit, :srn_pending,
              :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :list_price, :mrp_pack_denomination,
              :batch_no, :list_price_pack_denomination, :self_batched, :expiry, :expiry_present, :quantity,
              :unit_non_taxable_amount, :unit_taxable_amount, :tax_rate, { tax_group: [:_id, :name, :amount] },
              :tax_group_id, :tax_inclusive, :taxable_amount, :non_taxable_amount, :total_list_price, :total_cost,
              :unit_cost, :description, :store_id, :facility_id, :organisation_id, :_destroy, :model_no, :srn_required,
              :description_comment, :requisition_required, :requisition_pending, { lot_unit_ids: [] }
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
    options = { store_id: @store_id, :available_stock.gt => 0.0, stockable: true }
    if @category == 'out_stock'
      options = options.merge(stock: 0)
    elsif @category == 'all_item'
    else
      options = options.merge(category: @category)
    end

    if params[:search_type] == 'Barcode'
      if query.present?
        lots = Inventory::Item::Lot.where(options).where(barcode_id: query).is_active.skip(current_data_row)
        if lots.length == 0
          lot_units = Inventory::Item::LotUnit.where(options).where(barcode_id: query).is_active.skip(current_data_row)
          @is_lot_unit = true
        end
      else
        lots = Inventory::Item::Lot.where(options).is_active.skip(current_data_row).limit(30)
      end
      # lots = if query.present?
      #          Inventory::Item::Lot.where(options).where(barcode_id: query).is_active.skip(current_data_row)
      #                              .limit(30)
      #        else
      #          Inventory::Item::Lot.where(options).is_active.skip(current_data_row)
      #                              .limit(30)
      #        end
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
              elsif lot_units.present?
                lot_units
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

  def fetch_orders
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, recipient: /#{Regexp.escape(query)}/i }
    options = options.merge(fitter_id: @fitter_id) if @fitter_id.present? && @fitter_id != 'all'
    options = options.merge(home_delivery: @home_delivery) if @home_delivery.present? && @home_delivery != 'all'
    if @state_name.present? && @state_name != 'all' && @state_name != 'cancelled'
      options = options.merge(state: @state_name)
    end
    options = options.merge(is_canceled: true) if @state_name.present? && @state_name == 'cancelled'
    @fitters = Inventory::Fitter.where(:store_ids.in => [@store_id&.to_s], is_deleted: false, is_disable: false).pluck(:name, :id)
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    options[:order_date] = { :$gte => @start_date, :$lte => @end_date } if @start_date.present? && @end_date.present?
    @inventory_orders = Invoice::InventoryOrder.where(options).send(@sort_by || 'newest_first').skip(current_data_row)
                                               .limit(30)
  end

  def fetch_all_orders
    @patientid = @inventory_order.patient_id
    @advance_payments = AdvancePayment.where(patient_id: @patientid, order_id: params[:id])
    @refund_payments = RefundPayment.where(patient_id: @patientid, order_id: params[:id])
    @prescription = PatientPrescription.find_by(id: @inventory_order.prescription_id)
    @appointment = Appointment.find_by(id: @prescription&.appointment_id)
    @inventory_store = Inventory::Store.find_by(id: @inventory_order.store_id)
  end

  def patient_summary(sub_event_name)
    @inventory_store = Inventory::Store.find_by(id: @inventory_order.store_id)
    if @inventory_store.department_id == '284748001'
      type = 'PHARMACY'
    elsif @inventory_store.department_id == '50121007'
      type = 'OPTICAL'
    end
    Patients::Summary::TimelineWorker.call(
      event_name: "#{type}_INVOICE", sub_event_name: sub_event_name, invoice_id: @inventory_invoice_id,
      user_id: current_user.id, user_name: current_user.fullname, encounter_type: type.to_s
    )
  end

  def last_search_by
    @search_by = Invoice::InventoryOrder.last_search_by(current_user.id.to_s, current_facility.id.to_s, params[:store_id])
  end

  def header_templates
    template_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
                                            .custom_template_header_options["#{@inventory_order.department_name&.downcase}_settings"]
    @mr_no = PatientOtherIdentifier.find_by(patient_id: @inventory_order.patient_id).try(:mr_no)
    return unless template_settings

    @template_active_headers = template_settings[:invoices][0].select { |_key, value| value == true }
    @template_fields = @template_active_headers.keys
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

  def update_optical_prescription
    @prescription.update(
      r_acceptance_framematerial: params[:invoice_inventory_order][:r_glassesprescriptions_framematerial],
      r_acceptance_ipd: params[:invoice_inventory_order][:r_glassesprescriptions_ipd],
      r_acceptance_lensmaterial: params[:invoice_inventory_order][:r_glassesprescriptions_lensmaterial],
      r_acceptance_lenstint: params[:invoice_inventory_order][:r_glassesprescriptions_lenstint],
      r_acceptance_typeoflens: params[:invoice_inventory_order][:r_glassesprescriptions_typeoflens],
      r_acceptance_comments: params[:invoice_inventory_order][:r_glassesprescriptions_comments],
      r_acceptance_dia: params[:invoice_inventory_order][:r_glassesprescriptions_dia],
      r_acceptance_size: params[:invoice_inventory_order][:r_glassesprescriptions_size],
      r_acceptance_fittingheight: params[:invoice_inventory_order][:r_glassesprescriptions_fittingheight],
      r_acceptance_prismbase: params[:invoice_inventory_order][:r_glassesprescriptions_prismbase],
      r_acceptance_distance_pd: params[:invoice_inventory_order][:r_glassesprescriptions_distance_pd],
      r_acceptance_near_pd: params[:invoice_inventory_order][:r_glassesprescriptions_near_pd],
      l_acceptance_framematerial: params[:invoice_inventory_order][:l_glassesprescriptions_framematerial],
      l_acceptance_ipd: params[:invoice_inventory_order][:l_glassesprescriptions_ipd],
      l_acceptance_lensmaterial: params[:invoice_inventory_order][:l_glassesprescriptions_lensmaterial],
      l_acceptance_lenstint: params[:invoice_inventory_order][:l_glassesprescriptions_lenstint],
      l_acceptance_typeoflens: params[:invoice_inventory_order][:l_glassesprescriptions_typeoflens],
      l_acceptance_comments: params[:invoice_inventory_order][:l_glassesprescriptions_comments],
      l_acceptance_dia: params[:invoice_inventory_order][:l_glassesprescriptions_dia],
      l_acceptance_size: params[:invoice_inventory_order][:l_glassesprescriptions_size],
      l_acceptance_fittingheight: params[:invoice_inventory_order][:l_glassesprescriptions_fittingheight],
      l_acceptance_prismbase: params[:invoice_inventory_order][:l_glassesprescriptions_prismbase],
      l_acceptance_distance_pd: params[:invoice_inventory_order][:l_glassesprescriptions_distance_pd],
      l_acceptance_near_pd: params[:invoice_inventory_order][:l_glassesprescriptions_near_pd]
    )
  end
end
