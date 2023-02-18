class Inventory::Order::RequisitionsController < ApplicationController
  before_action :authorize, :verify_store
  before_action :find_store, only: [:index, :new, :filter_lots, :append_variants, :filter_variants, :fetch_variants,
                                    :filter_index, :edit, :show, :disable, :approve, :append_index]

  def index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @time_period = params[:time_period]
    fetch_requisition(@store_id)
  end

  def new
    @store_id = params[:store_id]
    @requisition = Inventory::Order::Requisition.new
    @receive_stores = []
    @inventory_store.store_ids.each do |store_id|
      store = Inventory::Store.find_by(id: store_id)
      @receive_stores << [store.name.to_s, store.id.to_s]
    end
    @selected_store = @receive_stores.size > 1 ? '' : @receive_stores[0]
    @from = params[:from]
    @order_id = params[:order_id]
    @inventory_order = Invoice::InventoryOrder.find_by(id: @order_id)
    @requisition_types = ['Normal', 'Urgent']
  end

  def add_lot
    @variant = Inventory::Item::Variant.find_by(id: params[:variant_id])
    @item = Inventory::Item.find_by(id: @variant.item_id)
    @rol_rule = Inventory::RolRule.find_by(store_id: @variant.store_id, variant_reference_id: @variant.reference_id,
                                           organisation_id: current_organisation['_id'].to_s)
    if @rol_rule.nil? && (@variant.requested_quantity > 0 || @variant.pending_tranfered_quantity > 0 || @variant.peding_requisition_validation)
      requisition = Inventory::Order::Requisition.where(:'items.variant_id' => @variant.id.to_s).last
      respond_to do |format|
        if @variant.pending_tranfered_quantity > 0
          format.js { render js: "notice = new PNotify({ title: 'Warning', text: 'The Stock Already issued for the Item. USER: #{requisition.entered_by.titleize}, REQ. NO: #{requisition.requisition_display_id}, Order Date: #{requisition.requisition_date_time&.strftime('%d-%m-%Y')}', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
        else
          format.js { render js: "notice = new PNotify({ title: 'Warning', text: 'Requisition Already Generated for This Item. USER: #{requisition.entered_by.titleize}, REQ. NO: #{requisition.requisition_display_id}, Order Date: #{requisition.requisition_date_time&.strftime('%d-%m-%Y')}', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
        end
      end
    else
      @item = Inventory::Item.find_by(id: @variant.item_id)
      @item_units = @item.item_units.to_i
      pending_tranfered_quantity = @variant.pending_tranfered_quantity || 0
      requested_quantity = @variant.requested_quantity || 0
      pending_po_quantity = @variant.pending_po_quantity || 0
      indent_requested_quantity = @variant.indent_requested_quantity || 0
      effective_qty = @variant.stock + pending_tranfered_quantity + requested_quantity + indent_requested_quantity + pending_po_quantity
      @inventory_store = Inventory::Store.find_by(id: params[:store_id])
      # @requisition_store = Inventory::Store.find_by(id: params[:requisition_store_id])
      if @rol_rule.present?
        max_value = @rol_rule.try(:max_value) - effective_qty if @rol_rule.try(:max_value).present?
        remaning_value = max_value % @item_units
        @item_max_value = (max_value - remaning_value )
        # @item_max_value = item_max_value.to_i > 0 ? item_max_value : 0
      end
      @requisition = Inventory::Order::Requisition.build
    end
  end

  def filter_variants
    fetch_variant_index
  end

  def append_variants
    fetch_variant_index
  end

  def filter_index
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_requisition(params[:store_id])
  end

  def append_index
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_transactions
  end

  def create
    @store_id = params[:inventory_order_requisition][:store_id]
    @request_from = params[:inventory_order_requisition][:request_from]
    @receive_store_id = params[:inventory_order_requisition][:receive_store_id]
    receive_store = Inventory::Store.find_by(id: @receive_store_id)
    @category_ids = receive_store.category_ids
    @vendor_id = params[:inventory_order_requisition][:vendor_id]
    check_requisition_validation if @request_from == 'inventory_order'
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @start_date = @end_date = params[:inventory_order_requisition][:requisition_date]
    requisition_display_id = InventoryHelper.increment_and_create_requisition_display_id(current_organisation['_id'].to_s)
    if @request_from == 'inventory_order'
      fetch_requisition(@store_id)
      if @is_vendor_rate_validated && @is_category_validated
        @requisition = Inventory::Order::Requisition.new(requisition_order_params)
        @requisition.requisition_display_id = requisition_display_id
        @requisition.save!
        update_optical_order(@requisition.optical_order_id)
        @requisition.update!(approved_date_time: Time.current, status: 'approved')
        requisition_received_id = Inventory::Orders::CreateRequisitionReceivedService.call(@requisition.id)
        if requisition_received_id.present?
          InventoryJobs::Orders::CreateIndentJob.perform_later(requisition_received_id.to_s, @requisition.optical_order_id.to_s, current_user.id.to_s)
        end
        respond_to do |format|
          format.js { render 'invoice/inventory_orders/index.js.erb' }
        end
      else
        respond_to do |format|
          if @is_vendor_rate_validated == false && @is_category_validated == false
            text = 'Category and/Or Vendor Rate'
          elsif @is_category_validated == false
            text = 'Category'
          else
            text = 'Vendor Rate'
          end
          format.js { render js: "notice = new PNotify({ title: 'Warning', text: '#{text} is not defined. Variant: #{@variant.description.titleize}', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
          format.js { render 'invoice/inventory_orders/index.js.erb' }
        end
      end
    else
      @requisition = Inventory::Order::Requisition.new(requisition_order_params)
      @requisition.requisition_display_id = requisition_display_id
      @requisition.save!
      fetch_requisition(@store_id)
    end
    InventoryJobs::Orders::UpdateRequisitionVariantsJob.perform_later(@requisition.id.to_s, 'create')
  end

  def edit
    @store_id = params[:store_id]
    @requisition = Inventory::Order::Requisition.find_by(id: params[:id])
    fetch_variant_index
    @receive_stores = []
    @inventory_store.store_ids.each do |store_id|
      store = Inventory::Store.find_by(id: store_id)
      @receive_stores << [store.name.to_s, store.id.to_s]
    end
    selected_store = Inventory::Store.find_by(id: @requisition.receive_store_id)
    @selected_store = [selected_store.name.to_s, selected_store.id.to_s]
    @requisition_types = ['Normal', 'Urgent']
  end

  def update
    @store_id = params[:inventory_order_requisition][:store_id]
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @start_date = @end_date = params[:inventory_order_requisition][:requisition_date]
    @requisition = Inventory::Order::Requisition.find_by(id: params[:id])
    old_variant_ids = @requisition.items.pluck(:variant_id) || []
    new_variant_ids = params[:inventory_order_requisition][:items_attributes].values.pluck(:variant_id) || []
    variant_ids = old_variant_ids - new_variant_ids
    update_delete_variant_status(variant_ids) if variant_ids.present?
    @requisition.items.delete_all
    @requisition.update!(requisition_order_params)
    fetch_requisition(@store_id)
    InventoryJobs::Orders::UpdateRequisitionVariantsJob.perform_later(@requisition.id.to_s, 'update')
  end

  def show
    @requisition = Inventory::Order::Requisition.find_by(id: params[:id])
    @from = params[:from]
    render 'inventory/order/requisitions/show_requisitions.js.erb' if @from.present?
  end

  def print
    order_id = params[:order_id]
    page_size = params[:page_size]
    @requisition = Inventory::Order::Requisition.find_by(id: order_id)
    @inventory_store = Inventory::Store.find_by(id: @requisition.store_id)
    @entity = EntityGroup.find_by(id: @inventory_store.entity_group_id.to_s )
    html_template = 'inventory/order/requisitions/print'

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

  def fetch_variants
    @request_from = params[:request_from]
    @inventory_order = Invoice::InventoryOrder.find_by(id: params[:order_id])
    fetch_variant_index
  end

  def disable
    requisition = Inventory::Order::Requisition.find_by(id: params[:id])
    requisition.update(is_disabled: true, is_active: false, status: 'Cancelled',
                      cancelled_reason: params[:cancelled_reason], cancelled_by: current_user.fullname,
                      cancelled_date_time: Time.current)
    @start_date = @end_date = params[:date]
    fetch_requisition(params[:store_id])
    InventoryJobs::Orders::UpdateRequisitionVariantsJob.perform_later(requisition.id.to_s, 'disable')
  end

  def approve
    requisition = Inventory::Order::Requisition.find_by(id: params[:id])
    requisition.update!(approved_by: current_user.fullname, approved_by_id: current_user.id,
                        approved_date_time: Time.current, status: 'approved')
    @start_date = @end_date = params[:date]
    fetch_requisition(params[:store_id])
    InventoryJobs::Orders::RequisitionJob.perform_later(requisition.id.to_s)
  end

  private

  def fetch_requisition(store_id)
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: store_id }
    if @request_from == 'inventory_order'
      @fitters = Inventory::Fitter.where(store_id: store_id).pluck(:name, :id)
      options[:order_date] = { :$gte => @start_date, :$lte => @end_date } if @start_date.present? && @end_date.present?
      @inventory_orders = Invoice::InventoryOrder.where(options).send(@sort_by || 'newest_first')
                                                 .skip(current_data_row).limit(30)
    else
      options[:requisition_date] = { :$gte => @start_date, :$lte => @end_date } if @start_date.present? && @end_date.present?
      options = options.merge(remarks: /#{Regexp.escape(query)}/i)
      @requisitions = Inventory::Order::Requisition.where(options).order_by(created_at: 'desc').skip(current_data_row)
                                                 .limit(30)
    end
  end

  def find_store
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
  end

  def fetch_variant_index
    @store_id = params[:store_id]
    @requisition_store_id = params[:requisition_store_id]
    query = params[:q].to_s
    options = { store_id: @store_id, search: /#{Regexp.escape(query)}/i }
    if params[:order_id].present?
      inventory_order_items = Invoice::InventoryOrder.find_by(id: params[:order_id]).items
      variant_ids = inventory_order_items.where(requisition_required: true).pluck(:variant_id)
      options = options.merge!(:id.in => variant_ids )
    else
      store_category_ids = @inventory_store.category_ids || []
      @requisition_store = Inventory::Store.find_by(id: @requisition_store_id)
      requested_category_ids = @requisition_store&.category_ids || []
      category_ids = store_category_ids & requested_category_ids
      options = options.merge!(:category_id.in => category_ids, stockable: true)
    end
    @search_type = params[:search_type]
    current_data_row = params[:total_count_row].to_i
    @variants = Inventory::Item::Variant.where(options).is_active.order_by(created_at: 'desc').skip(current_data_row)
                                        .limit(30)
  end

  def update_optical_order(optical_order_id)
    optical_order = Invoice::InventoryOrder.find_by(id: optical_order_id)
    optical_order.update!(requisition_pending: false, requisition_id: @requisition.id, requisition_created_at: Time.current,
                          requisition_order_created_by_id: current_user.id)
  end

  def check_requisition_validation
    @is_vendor_rate_validated = false
    @is_category_validated = false
    @variant_ids = params[:inventory_order_requisition][:items_attributes].values.pluck(:variant_reference_id)
    @variant_ids.each do |variant_id|
      @variant = Inventory::Item::Variant.find_by(reference_id: variant_id)
      if @category_ids.include? @variant.category_id
        @is_category_validated = true
      else
        @is_category_validated = false
        break
      end
      # Need to add vendor ID in the following query
      vendor_rate = Inventory::VendorRate.find_by(variant_reference_id: variant_id, vendor_id: @vendor_id)
      if vendor_rate.present?
        rate = vendor_rate.rate
        selling_price = vendor_rate.selling_price
        if rate.present? && selling_price.present?
          @is_vendor_rate_validated = true
        else
          @is_vendor_rate_validated = false
          break
        end
      else
        @is_vendor_rate_validated = false
        break
      end
    end
  end

  def update_delete_variant_status(variant_ids)
    variant_ids.each do |variant_id|
      variant = Inventory::Item::Variant.find_by(id: variant_id)
      variant.update(peding_requisition_validation: false)
    end
  end

  def requisition_order_params
    params.require(:inventory_order_requisition)
          .permit(
            :remarks, :requisition_date, :requisition_date_time, :requisition_creation_time, :user_id, :store_id,
            :requisition_type, :facility_id, :organisation_id, :mode_of_payment, :department_id, :department_name,
            :receive_store_id, :receive_store_name, :entered_by, :store_name, :is_disabled, :is_active, :status,
            :is_edited, :entered_by_id, :receive_status, :created_from, :optical_order_id, :request_from, :vendor_id,
            :fulfilment_status,
            items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :variant_code, :item_id,
              :default_variant_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :_destroy,
              :search, :mark_up, :batch_no, :cost_price, :total_cost_price, :stock_package, :stock_subpackage,
              :stock_unit, :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :list_price,
              :tax_name, :tax_group_id, :mrp_pack_denomination, :list_price_pack_denomination, :self_batched,
              :expiry, :expiry_present, :description, :store_id, :facility_id, :organisation_id, :model_no,
              :variant_id, :requested_quantity, :category_id, :variant_reference_id, :item_reference_id, :tax_rate, 
              :tax_group_id, :remark, :tax_inclusive, :dispensing_unit
            ]
          )
  end
end
