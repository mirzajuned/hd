class Inventory::Order::IndentsController < ApplicationController
  before_action :authorize, :verify_store
  before_action :find_store, only: [:index, :new, :show, :filter_index, :filter_variants, :append_variants, :add_lot,
                                    :requisition_data]

  def index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @time_period = params[:time_period]
    @indent = Inventory::Order::Indent.new
    @variants = Inventory::Item::Variant.where(store_id: params[:store_id])
    @receive_stores = []
    stores = Inventory::Store.where(organisation_id: current_user.organisation_id, :user_ids.in => [current_user.id], is_active: true, is_disable: false, enable_purchase_order: true)
    stores.each do |store_id|
      store = Inventory::Store.find_by(id: store_id)
      @receive_stores << [store&.name.to_s, store.id.to_s]
    end
    @store_name = params[:store_name]
    fetch_indent(@store_id)
  end

  def new
    @store_id = params[:store_id]
    @receive_stores = []
    stores = Inventory::Store.where(organisation_id: current_user.organisation_id, :user_ids.in => [current_user.id],
                                    is_active: true, is_disable: false, enable_purchase_order: true)
    stores.each do |store_id|
      store = Inventory::Store.find_by(id: store_id)
      @receive_stores << [store.name.to_s, store.id.to_s]
    end
    @indent = Inventory::Order::Indent.new
    category_ids = Inventory::Store.find_by(id: params[:store_id])&.category_ids
    @vendors = Inventory::Vendor.where(:category_ids.in => category_ids, is_deleted: false)
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @sub_stores = @inventory_store.sub_stores.where(is_deleted: false).pluck(:name, :id)
    @indent_types = ['Normal', 'Urgent']
    if @receive_stores.size == 1
      @store_id = @receive_stores[0][1]
      @selected_store = @receive_stores[0]
      @requisition_received = Inventory::Order::RequisitionReceived.where(store_id:  @store_id, status: 'Pending')
                                                                   .order_by('created_at DESC')
    else
      @store_id = ""
      @selected_store = ""
    end
    fetch_variant_index
  end

  def create
    @store_id = params[:inventory_order_indent][:store_id]
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @start_date = @end_date = params[:inventory_order_indent][:indent_date]
    bkp_indent_display_id = InventoryHelper.increment_and_create_indent_display_id(current_organisation['_id'].to_s)
    @indent = Inventory::Order::Indent.new(indent_order_params)
    @indent.bkp_indent_display_id = bkp_indent_display_id
    @indent.save!
    indent_display_id = SequenceManagers::GenerateSequenceService.call(
                          'indent_order', @indent.id.to_s, 
                          { organisation_id: current_organisation['_id'].to_s, 
                            facility_id: current_facility['_id'].to_s, 
                            region_id: current_facility['region_master_id'].to_s, 
                            department_id: @indent.department_id,
                            entity_group_id: @inventory_store.try(:entity_group_id).to_s
                          })
    @indent.update(indent_display_id: indent_display_id)
    fetch_indent(@store_id)
    InventoryJobs::Orders::UpdateRequisitionReceivedJob.perform_later(@indent.id.to_s, current_user.id.to_s)
  end

  def show
    @indent = Inventory::Order::Indent.find_by(id: params[:id])
    @purchase_orders = Inventory::Order::Purchase.where(indent_id: params[:id])
  end

  def filter_variants
    @store_id = params[:store_id]
    fetch_variant_index
  end

  def append_variants
    @store_id = params[:store_id]
    fetch_variant_index
  end

  def filter_index
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_indent(params[:store_id])
  end

  def add_lot
    @variant = Inventory::Item::Variant.find_by(id: params[:variant_id])
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @variant.store_id)
    @sub_stores = @inventory_store.sub_stores.where(is_deleted: false).pluck(:name, :id)
    @item = Inventory::Item.find_by(id: @variant.item_id)
    @item_units = @item.item_units.to_i
    @row_count = params[:row_count]
    @rol_rule = Inventory::RolRule.find_by(store_id: @variant.store_id, variant_reference_id: @variant.reference_id,
                                           organisation_id: current_organisation['_id'].to_s)
    pending_tranfered_quantity = @variant.pending_tranfered_quantity || 0
    requested_quantity = @variant.requested_quantity || 0
    pending_po_quantity = @variant.pending_po_quantity || 0
    indent_requested_quantity = @variant.indent_requested_quantity || 0
    effective_qty = @variant.stock + pending_tranfered_quantity + requested_quantity + indent_requested_quantity + pending_po_quantity
    arr = ['Pending', 'Approved', 'Partially-Completed']
    @orders = Inventory::Order::Purchase.where(:'items.default_variant_id' => @variant.id, store_id: @inventory_store.id,
                                               :order_status.in => arr, :'items.stock_received_status' => false)
    @text = "One or more existing open purchase orders with #{@variant.description} already present."
    @total_count = 1
    @orders.each do |order|
      order_item = order.items.find_by(store_id: @inventory_store.id, variant_reference_id: @variant.reference_id,
                                       variant_identifier: @variant.variant_identifier, stock_received_status: false)
      if order_item.present?
        qty = order_item.stock.to_i - order_item.stock_received.to_i
        @text += "#{@total_count}. PO No. #{order.purchase_display_id}, P. Qty: #{qty}, PO Date: #{order.order_date&.strftime('%d-%m-%Y')}, User: #{order.entered_by}.  "
        @total_count += 1
      end
    end

    if @rol_rule.present?
      max_value = @rol_rule.try(:max_value) - effective_qty if @rol_rule.try(:max_value).present?
      @item_max_value = (max_value / @item_units) * @item_units
    end
  end

  def requisition_data
    @requisition_received = Inventory::Order::RequisitionReceived.find_by(id: params[:requisition_id])
    @category_ids = @inventory_store.category_ids || []
    @var_ref_ids = params[:var_ref_ids] || []
    @row_count = params[:row_count]
    @sub_stores = @inventory_store.sub_stores.where(is_deleted: false).pluck(:name, :id)
  end

  def print
    order_id = params[:order_id]
    page_size = params[:page_size]
    @indent = Inventory::Order::Indent.find_by(id: order_id)
    @inventory_store = Inventory::Store.find_by(id: @indent.store_id)
    @entity = EntityGroup.find_by(id: @inventory_store.entity_group_id.to_s )
    html_template = 'inventory/order/indents/print'

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

  def new_transaction
    @indent = Inventory::Order::Indent.find_by(id: params[:id])

    @store_id = @indent.try(:store_id)
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @store_id)
    @purchase_orders = Inventory::Order::Purchase.where(indent_id: params[:id])
    category_ids = Inventory::Store.find_by(id: @store_id)&.category_ids
    vendor_ids = Inventory::Vendor.where(:category_ids.in => category_ids, is_deleted: false).pluck(:id)
    @vendor_locations = Inventory::VendorLocation.where(:vendor_id.in => vendor_ids)
    @sub_stores = @inventory_store.sub_stores.where(is_deleted: false).pluck(:name, :id)
    terms_and_conditions = Inventory::TermsAndCondition.where(organisation_id: current_user.organisation_id, is_disable: false)
    @payment_terms = terms_and_conditions.where(type: 'payment_terms').pluck(:description, :id)
    @delivery_terms = terms_and_conditions.where(type: 'delivery_terms').pluck(:description, :id)
    options = { organisation_id: current_user.organisation_id, is_active: true, is_disable: false }
    options = options.merge!(department_id: '550368792') if @inventory_store.department_id == '550368792'
    @stores = Inventory::Store.where(options)
    @other_charges = Inventory::OtherCharge.where(organisation_id: current_user.organisation_id, is_disable: false).pluck(:name, :id)
    vendor_id = params[:vendor_id].present? ? params[:vendor_id] : @indent&.vendor_id
    @vendor = Inventory::Vendor.find_by(id: vendor_id)
    indent_items = @indent.items
    @purchase_order = Inventory::Order::Purchase.build_with_indent(indent_items)
  end
  
  private

  def fetch_variant_index
    @search_type = params[:search_type]
    current_data_row = params[:total_count_row].to_i
    @indent_store_id = params[:indent_store_id]
    @indent_store = Inventory::Store.find_by(id: @indent_store_id)
    @requisition_received = Inventory::Order::RequisitionReceived.where(store_id: @store_id, status: 'Pending').order_by('created_at DESC')
    query = params[:q].to_s
    store_category_ids = @inventory_store&.category_ids || []
    options = { store_id: @store_id, stockable: true, search: /#{Regexp.escape(query)}/i,
                :category_id.in => store_category_ids }
    @variants = Inventory::Item::Variant.where(options).is_active.order_by(created_at: 'desc').skip(current_data_row)
                                        .limit(30)
  end

  def fetch_indent(store_id)
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    if params[:type].present? && params[:store_name] !="All Stores"
      options = {store_id: store_id,remarks: /#{Regexp.escape(query)}/i }
    elsif  params[:type].present? && params[:store_name] == "All Stores"   
      store_ids = Inventory::Store.where(organisation_id: current_user.organisation_id, :user_ids.in => [current_user.id], is_active: true, is_disable: false, enable_purchase_order: true).pluck(:id)
      options = {remarks: /#{Regexp.escape(query)}/i, :store_id.in => store_ids }
    else
      store_ids = Inventory::Store.where(organisation_id: current_user.organisation_id, :user_ids.in => [current_user.id], is_active: true, is_disable: false, enable_purchase_order: true).pluck(:id)
      options = {remarks: /#{Regexp.escape(query)}/i, :store_id.in => store_ids }
    end  
    options[:indent_date] = {:$gte => @start_date, :$lte => @end_date } if @start_date.present? && @end_date.present?
    @indents = Inventory::Order::Indent.where(options).order_by(created_at: 'desc').skip(current_data_row)
                                       .limit(30)
  end

  def find_store
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
  end

  def indent_order_params
    params.require(:inventory_order_indent)
          .permit(
            :remarks, :indent_date, :indent_date_time, :user_id, :store_id, :vendor_id, :vendor_name, :indent_type,
            :facility_id, :organisation_id, :department_id, :department_name, :created_by, :created_by_id, :store_name,
            :is_disabled, :is_active, :status, :is_edited, :indent_remarks, :dispensing_unit, :sub_package_units,
            :create_from, :create_store_name, :store_name,
            items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :variant_code, :item_id, :list_price,
              :default_variant_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :_destroy,
              :search, :mark_up, :batch_no, :cost_price, :total_cost_price, :stock_package, :stock_subpackage,
              :stock_unit, :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :requisition_received_id,
              :requisition_received_item_id, :tax_name, :tax_group_id, :mrp_pack_denomination, :variant_id,
              :list_price_pack_denomination, :self_batched, :expiry, :expiry_present, :description, :store_id,
              :facility_id, :organisation_id, :model_no, :tax_rate, :tax_inclusive, :sub_store_id, :sub_store_name,
              :paid_stock, :remarks, :variant_reference_id, :item_reference_id, :dispensing_unit, :category_id, 
              :indent_remarks, :item_units
            ]
          )
  end
end
