class Inventory::Order::PurchasesController < ApplicationController
  include Inventory::ItemsHelper
  before_action :authorize, :verify_store

  def index
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @time_period = params[:time_period]
    @store_name = params[:store_name]
    @purchase_status = ['Pending', 'Approved', 'Cancelled', 'Completed', 'Partially-Completed', 'Closed','All']
    @status = params[:status].present? ? params[:status] : 'All'
    fetch_orders
  end

  def append_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_orders
  end

  def filter_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_orders
  end

  def new
    @receive_stores = []
    stores = Inventory::Store.where(organisation_id: current_user.organisation_id, :user_ids.in => [current_user.id],
                                    is_active: true, is_disable: false, enable_purchase_order: true)
    stores.each do |store_id|
      store = Inventory::Store.find_by(id: store_id)
      @receive_stores << [store.name.to_s, store.id.to_s]
    end
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @store_id)
    @sub_stores = @inventory_store.sub_stores.where(is_deleted: false).pluck(:name, :id)
    @category = 'all_item'
    category_ids = Inventory::Store.find_by(id: params[:store_id])&.category_ids
    vendor_ids = Inventory::Vendor.where(:category_ids.in => category_ids, is_deleted: false).pluck(:id)
    @vendor_locations = Inventory::VendorLocation.where(:vendor_id.in => vendor_ids)
    @purchase_order = Inventory::Order::Purchase.new
    @other_charges = Inventory::OtherCharge.where(organisation_id: current_user.organisation_id, is_disable: false).pluck(:name, :id)
    terms_and_conditions = Inventory::TermsAndCondition.where(organisation_id: current_user.organisation_id, is_disable: false)
    @payment_terms = terms_and_conditions.where(type: 'payment_terms').pluck(:description, :id)
    @delivery_terms = terms_and_conditions.where(type: 'delivery_terms').pluck(:description, :id)
    vendor_id = Inventory::VendorLocation.find_by(id: params[:vendor_id])&.vendor_id
    options = { organisation_id: current_user.organisation_id, is_active: true, is_disable: false }
    options = options.merge!(department_id: '550368792') if @inventory_store.department_id == '550368792'
    @stores = Inventory::Store.where(options)
    @vendor = Inventory::Vendor.find_by(id: vendor_id)
    @purchase_types = ['Normal', 'Urgent']
    @selected_store = @receive_stores.size > 1 ? '' : @receive_stores[0]
    fetch_variant_index
  end

  def new_lot
    @variant_id = params[:variant_id]
    @vendor_id = params[:vendor_id]
    @variant_name = params[:variant_name]
    @variant = Inventory::Item::Variant.find_by(id: params[:variant_id])
    @item = Inventory::Item.find_by(id: @variant.item_id)
    @vendor_rate = Inventory::VendorRate.find_by(vendor_id: @vendor_id, variant_reference_id: @variant.reference_id,
                                                 organisation_id: current_organisation['_id'].to_s)
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @item.store_id)
    @sub_stores = @inventory_store.sub_stores.where(is_deleted: false).pluck(:name, :id)
    category_expiry_days = Inventory::Category.find_by(id: @item.category_id).expiry_days.to_i
    @expiry_days = Date.current + category_expiry_days
    @currency_symbol = current_facility.currency_symbol
  end

  def add_lot
    @variant = Inventory::Item::Variant.find_by(id: params[:variant_id])
    @item = Inventory::Item.find_by(id: @variant.item_id)
    @tax_group = TaxGroup.find(@item.tax_group_id)
    @tax_rate_details = @tax_group.tax_rate_details.collect { |tax_rate| tax_rate.merge(type: TaxRate.find(tax_rate[:_id]).type) }
    @purchase_order = Inventory::Order::Purchase.build(purchase_item_params)
    @purchase_order.items
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @item.store_id)
    @sub_stores = @inventory_store.sub_stores.where(is_deleted: false).pluck(:name, :id)
    @currency_symbol = current_facility.currency_symbol
  end

  def create
    @purchase_status = ['Pending', 'Approved', 'Cancelled', 'Completed', 'Partially-Completed', 'Closed','All']
    @store_id = params[:inventory_order_purchase][:store_id]
    @start_date = @end_date = params[:inventory_order_purchase][:order_date]
    purchase_display_id = Invoice::InventoryInvoicesHelper.increment_and_create_order_number(
      current_organisation['_id'].to_s
    )
    @vendor_location_id = params[:inventory_order_purchase][:vendor_location_id]
    @purchase_order = Inventory::Order::Purchase.new(purchase_order_params)
    @purchase_order.purchase_display_id = purchase_display_id
    @indent_id = params[:inventory_order_purchase][:indent_id]
    if @indent_id.present?
      @time_period = 'Custom Date'
      InventoryJobs::Orders::IndentJob.perform_later(@indent_id.to_s, @purchase_order.id.to_s, 'create')
    end
    @purchase_order.save!
    update_vendor_details
    update_address(@purchase_order.try(:store_id))
    fetch_orders
  end

  def edit
    @purchase_order = Inventory::Order::Purchase.find_by(id: params[:id])
    @items = @purchase_order.items
    @indent = Inventory::Order::Indent.find_by(id: @purchase_order.indent_id)
    @inventory_store = Inventory::Store.find_by(id: @purchase_order.store_id)
    @store_id = @inventory_store.id
    category_ids = @inventory_store&.category_ids
    vendor_ids = Inventory::Vendor.where(:category_ids.in => category_ids, is_deleted: false).pluck(:id)
    @vendor_locations = Inventory::VendorLocation.where(:vendor_id.in => vendor_ids)
    @other_charges = Inventory::OtherCharge.where(organisation_id: current_user.organisation_id, is_disable: false).pluck(:name, :id)
    terms_and_conditions = Inventory::TermsAndCondition.where(organisation_id: current_user.organisation_id, is_disable: false)
    @payment_terms = terms_and_conditions.where(type: 'payment_terms').pluck(:description, :id)
    @delivery_terms = terms_and_conditions.where(type: 'delivery_terms').pluck(:description, :id)
    @stores = Inventory::Store.where(organisation_id: current_user.organisation_id, is_active: true, is_disable: false)
    @vendor = Inventory::Vendor.find_by(id: @purchase_order.vendor_id)
    @sub_stores = @inventory_store.sub_stores.where(is_deleted: false).pluck(:name, :id)
    @purchase_orders = Inventory::Order::Purchase.where(indent_id: @purchase_order.indent_id)
    @purchase_types = ['Normal', 'Urgent']
    @receive_stores = []
    stores = Inventory::Store.where(organisation_id: current_user.organisation_id, :user_ids.in => [current_user.id],
                                    is_active: true, is_disable: false)
    @selected_store = [@inventory_store.name.to_s, @inventory_store.id.to_s]
    stores.each do |store_id|
      store = Inventory::Store.find_by(id: store_id)
      @receive_stores << [store.name.to_s, store.id.to_s]
    end
    fetch_variant_index
  end

  def update
    @indent_id = params[:inventory_order_purchase][:indent_id]
    @indent = Inventory::Order::Indent.find_by(id: @indent_id)
    @purchase_order = Inventory::Order::Purchase.find_by(id: params[:id])
    update_indent if @indent_id.present?
    @store_id = params[:inventory_order_purchase][:store_id]
    @start_date = @end_date = params[:inventory_order_purchase][:order_date]
    @purchase_order.items.delete_all
    @purchase_order.other_charges.delete_all
    @purchase_order.update(purchase_order_params)
    @vendor = Inventory::Vendor.find_by(id: @purchase_order.vendor_id)
    @vendor_location_id = @purchase_order.vendor_location_id
    update_vendor_details if @vendor_location_id.present?
    flash.now[:success] = 'updated'
    update_address(@purchase_order&.store_id)
    fetch_orders
  end

  def update_indent
    indent_items = @indent.items
    @purchase_order.items.each do |item|
      indent_item = indent_items.find_by(id: item.indent_item_id)
      new_item_hash = params[:inventory_order_purchase][:items_attributes].values.pluck(:indent_item_id, :paid_stock).to_h
      new_item_stock = new_item_hash[item&.indent_item_id&.to_s]&.to_f || 0
      old_item_stock = item.try(:paid_stock).to_f
      stock_diff = old_item_stock&.round(2) - new_item_stock&.round(2)
      total_stock_received = indent_item.stock_received.to_f - stock_diff
      indent_item.stock_received = total_stock_received
      indent_item.stock_received_status = true if total_stock_received.to_f == indent_item.try(:stock).to_f
      indent_item.save!
    end
    
    total_indent_stock = @indent.items.pluck(:stock).inject(&:+)
    total_stock_received = @indent.items.pluck(:stock_received).inject(&:+)

    if total_stock_received == 0
      status = 'Open'
      indent_completed = false
      indent_closed = false
      transaction_present = false
    elsif total_indent_stock == total_stock_received
      status = 'Completed'
      indent_completed = true
      indent_closed = true
      transaction_present = true
    else
      status = 'Partially-Completed'
      indent_completed = false
      indent_closed = false
      transaction_present = true
    end
    @indent.status = status
    @indent.is_completed = indent_completed
    @indent.is_closed = indent_closed
    @indent.transaction_present = true
    @indent.save!
  end

  def show
    @purchase_order = Inventory::Order::Purchase.find_by(id: params[:id])
    @purchase_transactions = Inventory::Transaction::Purchase.where(purchase_order_ids: params[:id])
    @current_store =  Inventory::Store.find_by(id: params[:current_store_id])
  end

  def add_custom_field
    @item = Inventory::Item.build
  end

  def append_variants
    @store_id = params[:receive_store_id]
    @category = params[:item_type]
    fetch_variant_index
  end

  def filter_variants
    @store_id = params[:receive_store_id]
    @category = params[:item_type]
    fetch_variant_index
  end

  def filter_purchase
    @store_id = params[:store_id]
    @department_id = params[:department_id]
  end

  def download_data
    department_id = params[:department_id]
    options = { store_id: params[:store_id] }
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
    @data_array = Inventory::Orders::DownloadPurchaseService.call(options, department_id)
    @filename = "#{params[:department_name]&.downcase}_purchase_list.xls"
    respond_to do |format|
      format.xls { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}\"" }
    end
  end

  def new_transaction
    @purchase_order = Inventory::Order::Purchase.find_by(id: params[:id])
    @store_id = @purchase_order.try(:store_id)
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @store_id)
    @purchase_transactions = Inventory::Transaction::Purchase.where(purchase_order_ids: params[:id])
    @vendors = Inventory::Vendor.where(:category_ids.in => @inventory_store.category_ids, is_deleted: false).pluck(:name, :id)
    @sub_stores = @inventory_store.sub_stores.where(is_deleted: false).pluck(:name, :id)
    @vendor_location = Inventory::VendorLocation.find_by(id: @purchase_order&.vendor_location_id)
    @vendor = @vendor_location.vendor
    @vendor_location_address = @purchase_order.vendor_location_address

    order_items = @purchase_order.items
    @other_charges = Inventory::OtherCharge.where(organisation_id: current_user.organisation_id, is_disable: false).pluck(:name, :id)
    @purchase_transaction = Inventory::Transaction::Purchase.build_with_order(order_items)
  end

  def update_status
    @purchase_order = Inventory::Order::Purchase.find_by(id: params[:id])
    status = params[:status]
    if status == 'close'
      options = { is_closed: true, closed_by: current_user.id, closed_by_name: current_user.fullname,
                  closed_date_time: Time.current, closed_reason: 'Closed', order_status: 'Closed' }
    elsif status == 'cancel'
      options = { order_status: 'Cancelled', is_closed: true, is_cancelled: true }
    else
      return
    end
    @purchase_order.update(options)
    @store_id = @purchase_order.try(:store_id)
    @start_date = @end_date = @purchase_order.try(:order_date)
    fetch_orders
  end

  def print
    order_id = params[:order_id]
    page_size = params[:page_size]
    @purchase_order = Inventory::Order::Purchase.find_by(id: order_id)
    @inventory_store = Inventory::Store.find_by(id: @purchase_order.store_id)
    @entity_name = EntityGroup.find_by(id: @inventory_store.entity_group_id.to_s).try(:name)
    # @vendor_location = Inventory::VendorLocation.find_by(id: @purchase_order.vendor_location_id)
    # @vendor = @vendor_location.vendor
    @indent = Inventory::Order::Indent.find_by(id: @purchase_order.indent_id)
    @bill_to_store = Inventory::Store.find_by(id: @purchase_order.bill_to_store)
    @ship_to_store = Inventory::Store.find_by(id: @purchase_order.ship_to_store)
    @requisition = Inventory::Order::Requisition.find_by(id: @purchase_order.requisition_order_id)
    @optical_order = Invoice::InventoryOrder.find_by(id: @purchase_order.optical_order_id)
    html_template = 'inventory/order/purchases/print'

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

  def approve
    @purchase_order = Inventory::Order::Purchase.find_by(id: params[:id])
    @purchase_order.set_approved(current_user, '')
    @store_id = @purchase_order.try(:store_id)
    @start_date = @end_date = @purchase_order.try(:order_date)
    @current_store =  Inventory::Store.find_by(id: params[:current_store_id])
    @vendor_location_id = @purchase_order.vendor_location_id
    update_vendor_details
    update_address(@store_id)
    fetch_orders
  end

  def cancel
    @purchase_order = Inventory::Order::Purchase.find_by(id: params[:id])
    @purchase_order.set_cancelled(current_user, params[:cancelled_reason]) if @purchase_order.pending?
    @store_id = @purchase_order.try(:store_id)
    @start_date = @end_date = @purchase_order.try(:order_date)
    if @purchase_order.indent_id.present?
      InventoryJobs::Orders::IndentJob.perform_later(@purchase_order.indent_id.to_s, @purchase_order.id.to_s, 'cancel')
    end
    fetch_orders
  end

  def check_batch
    data = Inventory::Item::Lot.where(variant_id: params[:variant_id], batch_no: params[:batch_no], 
      facility_id: params[:facility_id], organisation_id: params[:organisation_id]).last
    if data.present?
      res = data.expiry.strftime("%d/%m/%Y")
    end
    render json: { status: true, res: res, data: data }
  end

  def vendor_details
    vendor_location = Inventory::VendorLocation.find_by(id: params[:vendor_location_id])
    # vendor = Inventory::Vendor.find_by(id: vendor_location.vendor_id)
    if vendor_location.present?
      if vendor_location.po_expiry_days
        po_expiry_date = (Date.current + vendor_location.po_expiry_days).strftime("%d/%m/%Y")
      else
        po_expiry_date = ''
      end
      render json: { status: true, po_expiry_date: po_expiry_date, credit_days: vendor_location.credit_days } 
    end
  end

  def close
    @purchase_order = Inventory::Order::Purchase.find_by(id: params[:id])
    @purchase_order.set_closed(current_user, params[:closed_reason])
    @purchase_order.update(is_closed: true)
    if @purchase_order.indent_id.present?
      InventoryJobs::Orders::IndentJob.perform_later(@purchase_order.indent_id.to_s, @purchase_order.id.to_s, 'close')
    end
  end

  private

  def purchase_order_params
    params.require(:inventory_order_purchase)
          .permit(
            :note, :vendor_id, :order_date, :vendor_name, :entry_type, :entered_by, :user_id, :store_id,
            :total_cost, :facility_id, :organisation_id, :mode_of_payment, :comments, :discount, :net_amount,
            :amount_paid, :amount_remaining, :credit_adjustment, :department_id, :department_name, :indent_id,
            :total_other_charges_amount, :purchase_type, :tax_amount, :purchase_taxable_amount, :ship_to_store,
            :bill_to_store, :vendor_credit_days, :po_expiry_date, :order_date_time, :version, :po_type,
            :remaining_total_other_charges_amount, :create_from, :create_store_name, :hdn_global_discount,
            :global_discount, :global_discount_type, :po_total_paid_stock, :remaining_po_total_paid_stock, 
            :store_gst, :vendor_location_id, :store_name,
            { tax_breakup: [:_id, :name, :amount, :tax_rate, :tax_type, :taxable_amount] },
            { payment_terms: [:_id, :description, :comment] }, { delivery_terms: [:_id, :description, :comment] },
            items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :default_variant_code, :item_id,
              :default_variant_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :_destroy,
              :search, :mark_up, :batch_no, :cost_price, :total_cost_price, :stock_package, :stock_subpackage,
              :stock_unit, :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :list_price, :tax_inclusive,
              :tax_rate, :tax_name, :tax_group_id, :mrp_pack_denomination, :list_price_pack_denomination, :self_batched,
              :expiry, :expiry_present, :total_cost, :unit_cost, :description, :store_id, :facility_id, :indent_item_id,
              :organisation_id, :unit_non_taxable_amount, :unit_taxable_amount, :model_no, :unit_cost_without_tax,
              :purchase_tax_amount, :unit_purchase_tax_amount, :item_cost_without_tax, :variant_reference_id,
              :sub_store_id, :sub_store_name, :remarks, :department_id, :department_name, :item_discount, :item_discount_type,
              :paid_stock, :currency_id, :currency_symbol, :discount_per_unit, :item_reference_id, :amount_after_tax,
              :indent_ordered_quantity, :indent_original_ordered_quantity, :item_discount_percent, :variant_id,
              { tax_group: [:_id, :name, :amount] }
            ],
            other_charges_attributes: [
              :other_charge_id, :name, :amount, :percent, :net_amount
            ]
          )
  end

  def purchase_item_params
    params.require(:item).permit! # We are not saving these params on this steps, hence permitted all params.
  end

  def fetch_variant_index
    store_id = params[:action] == 'edit' ? @purchase_order.store_id : params[:receive_store_id]
    @receive_store  = Inventory::Store.find_by(id: store_id)
    @inventory_store = @receive_store unless @inventory_store.present?
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    store_category_ids = @receive_store&.category_ids || []
    if @category.present?
      if (@category.include? 'all_item') || @category_id.blank? # for store item index
        options = { :category_id.in => store_category_ids, level: 'store' }
      else
        options = { :category_id.in => [@category_id], level: 'store' }
      end
    else
      options = { :category_id.in => store_category_ids, level: 'store' }
    end
    if @stock == 'out_stock'
      options = options.merge(empty: true)
    elsif @stock == 'running_low'
      options = options.merge(running_low: true)
    end
    options = options.merge!(store_id: store_id, stockable: true, search: /#{Regexp.escape(query)}/i)
    @variants = Inventory::Item::Variant.where(options).is_active.order_by(created_at: 'desc')
    # @variants = Inventory::Item::Variant.where(options).is_active.order_by(created_at: 'desc').skip(current_data_row)
    #                                     .limit(30)
  end

  # def fetch_variant_index
  #   store_id = params[:action] == 'edit' ? @purchase_order.store_id : params[:receive_store_id]
  #   @receive_store  = Inventory::Store.find_by(id: store_id)
  #   @inventory_store = @receive_store unless @inventory_store.present?
  #   current_data_row = params[:total_count_row].to_i
  #   query = params[:q].to_s
  #   store_category_ids = @receive_store&.category_ids || []
  #   if @category.present?
  #     if (@category.include? 'all_item') || @category_id.blank? # for store item index
  #       vendor_id = Inventory::VendorLocation.find_by(id: params[:vendor_id])&.vendor_id
  #       vendor_category_ids = Inventory::Vendor.find_by(id: vendor_id)&.category_ids || []
  #       # store_category_ids = @inventory_store.category_ids || []
  #       category_ids = vendor_category_ids & store_category_ids
  #       options = { :category_id.in => category_ids, level: 'store' }
  #     else
  #       options = { :category_id.in => [@category_id], level: 'store' }
  #     end
  #   else
  #     options = { :category_id.in => store_category_ids, level: 'store' }
  #   end
  #   if @stock == 'out_stock'
  #     options = options.merge(empty: true)
  #   elsif @stock == 'running_low'
  #     options = options.merge(running_low: true)
  #   end
  #   options = options.merge!(store_id: store_id, stockable: true, search: /#{Regexp.escape(query)}/i)
  #   @variants = Inventory::Item::Variant.where(options).is_active.order_by(created_at: 'desc')
  #   # @variants = Inventory::Item::Variant.where(options).is_active.order_by(created_at: 'desc').skip(current_data_row)
  #   #                                     .limit(30)
  # end

  def fetch_orders
    @receive_stores = []
    stores = Inventory::Store.where(organisation_id: current_user.organisation_id, :user_ids.in => [current_user.id], is_active: true, is_disable: false, enable_purchase_order: true)
    stores.each do |store_id|
      store = Inventory::Store.find_by(id: store_id)
      @receive_stores << [store&.name.to_s, store.id.to_s]
    end
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    if params[:type].present? && params[:store_name] !="All Stores"
      store_ids = Inventory::Store.where(organisation_id: current_user.organisation_id, :user_ids.in => [current_user.id], is_active: true, is_disable: false, enable_purchase_order: true).pluck(:id)
      options = { store_id: @store_id, note: /#{Regexp.escape(query)}/i, is_deleted: false, :store_id.in => store_ids }
    elsif  params[:type].present? && params[:store_name] == "All Stores" 
      store_ids = Inventory::Store.where(organisation_id: current_user.organisation_id, :user_ids.in => [current_user.id], is_active: true, is_disable: false, enable_purchase_order: true).pluck(:id)
      options = { note: /#{Regexp.escape(query)}/i, is_deleted: false, :store_id.in => store_ids }
    else
      store_ids = Inventory::Store.where(organisation_id: current_user.organisation_id, :user_ids.in => [current_user.id], is_active: true, is_disable: false, enable_purchase_order: true).pluck(:id)
      options = { note: /#{Regexp.escape(query)}/i, is_deleted: false, :store_id.in => store_ids }
      options = options.merge(order_status: @status) if @status.present? && @status != "All"
    end  
    options[:order_date] = { :$gte => @start_date, :$lte => @end_date } if @start_date.present? && @end_date.present?
    @purchases = Inventory::Order::Purchase.where(options).order_by(created_at: 'desc').skip(current_data_row)
                                           .limit(30)
  end

  def update_vendor_details
    vendor_location = Inventory::VendorLocation.find_by(id: @vendor_location_id)
    location_address = Inventory::PurchaseOrderHelper.po_vendor_location_address(vendor_location)
    @purchase_order.vendor_location_name = vendor_location.name
    @purchase_order.vendor_location_address = location_address
    vendor = vendor_location.vendor
    vendor_address = Inventory::PurchaseOrderHelper.po_vendor_location_address(vendor)
    @purchase_order.vendor_name = vendor.name
    @purchase_order.vendor_address = vendor_address
    @purchase_order.vendor_gst_number = vendor_location.gst_number
    @purchase_order.save!
  end

  def update_address(store_id)
    store = Inventory::Store.find_by(id: store_id)
    shipping_address = Inventory::PurchaseOrderHelper.shipping_address(store)
    ship_to_address = {store: store.try(:name), address:  shipping_address }
    billing_address = Inventory::PurchaseOrderHelper.billing_address(store)
    bill_to_address = {store: store.try(:name), address: billing_address }
    @purchase_order.update(bill_to_address: bill_to_address, ship_to_address: ship_to_address)
  end
end