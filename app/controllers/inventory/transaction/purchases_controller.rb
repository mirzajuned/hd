class Inventory::Transaction::PurchasesController < ApplicationController
  include Inventory::ItemsHelper
  before_action :authorize, :verify_store
  before_action :download_report, only: [:item_wise_report, :bill_wise_report]
  before_action :set_purchase, only: [:edit, :update, :cancel, :approve, :print_grn, :show]
  before_action :fetch_other_charges, only: [:new, :edit]

  def index
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @time_period = params[:time_period]
    @vendor_name = params[:vendor_name]
    @vendor_id = params[:vendor_id]
    @vendors = Inventory::Vendor.where(:category_ids.in => @inventory_store.category_ids).pluck(:name, :id)
    # @vendor_locations = Inventory::VendorLocation.where(:vendor_id.in => @vendor_ids).pluck(:name, :id)
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
    @vendor_name = params[:vendor_name]
    @vendor_id = params[:vendor_id]
    fetch_transactions
  end

  def new
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @store_id)
    @sub_stores = @inventory_store.sub_stores.where(is_deleted: false).pluck(:name, :id)
    @category = 'all_item'
    @vendor_location = Inventory::VendorLocation.find_by(:id => params[:vendor_location_id])
    @vendor = @vendor_location.vendor
    @vendor_location_address = Inventory::PurchaseOrderHelper.po_vendor_location_address(@vendor_location)
    fetch_variant_index
    @purchase_transaction = Inventory::Transaction::Purchase.new
  end

  def new_lot
    @variant_id = params[:variant_id]
    @vendor_id = params[:vendor_id]
    @variant_name = params[:variant_name]
    @variant = Inventory::Item::Variant.find_by(id: params[:variant_id])
    @item = Inventory::Item.find_by(id: @variant.item_id)
    @vendor_rate = Inventory::VendorRate.find_by(vendor_id: @vendor_id,variant_reference_id: @variant.reference_id,
                                                 organisation_id: current_organisation['_id'].to_s)
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @variant.store_id)
    @sub_stores = @inventory_store.sub_stores.where(is_deleted: false).pluck(:name, :id)
    category_expiry_days = Inventory::Category.find_by(id: @item.category_id).expiry_days.to_i
    @expiry_days = Date.current + category_expiry_days
    @currency_symbol = current_facility.currency_symbol
  end

  def add_lot
    @variant = Inventory::Item::Variant.find_by(id: params[:variant_id])
    @item = Inventory::Item.find_by(id: @variant.item_id)
    @purchase_transaction = Inventory::Transaction::Purchase.build(purchase_item_params)
    @tax_group = TaxGroup.find(@item.tax_group_id)
    @tax_rate_details = @tax_group.tax_rate_details.collect{|tax_rate| tax_rate.merge(type: TaxRate.find(tax_rate[:_id]).type)}
    @currency_symbol = current_facility.currency_symbol
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @variant.store_id)
    @sub_stores = @inventory_store.sub_stores.where(is_deleted: false).pluck(:name, :id)
    # @purchase_transaction.items
  end

  def create
    @store_id = params[:inventory_transaction_purchase][:store_id]
    @start_date = @end_date = params[:inventory_transaction_purchase][:transaction_date]
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    bkp_purchase_display_id = InventoryHelper.increment_and_create_purchase_transaction_number(current_organisation['_id'].to_s)
    @purchase_transaction = Inventory::Transaction::Purchase.new(purchase_transaction_params)
    @purchase_transaction.bkp_purchase_display_id = bkp_purchase_display_id
    @purchase_transaction.save!
    purchase_display_id = SequenceManagers::GenerateSequenceService.call(
                            'purchase_transaction', @purchase_transaction,
                            { organisation_id: current_organisation['_id'].to_s, 
                                facility_id: current_facility['_id'].to_s, 
                                region_id: current_facility['region_master_id'].to_s, 
                                department_id: @purchase_transaction.try(:department_id),
                                entity_group_id: @inventory_store.try(:entity_group_id).to_s
                            })
    @purchase_transaction.update(purchase_display_id: purchase_display_id)
    @vendors = Inventory::Vendor.where(:category_ids.in => @inventory_store.category_ids, is_deleted: false).pluck(:name, :id)
    @purchase_order_ids = @purchase_transaction.try(:purchase_order_ids)
    
    po_item_hash = Hash.new(0)
    po_item_paid_hash = Hash.new(0)
    po_item_free_hash = Hash.new(0)
    po_item_stock = params[:inventory_transaction_purchase][:items_attributes].values.pluck(:po_item_id, :stock)
    po_paid_stock = params[:inventory_transaction_purchase][:items_attributes].values.pluck(:po_item_id, :paid_stock)
    po_free_stock = params[:inventory_transaction_purchase][:items_attributes].values.pluck(:po_item_id, :stock_free_unit)
    po_item_stock.each_with_index do |item,index| 
      po_item_hash[item[0]] += item[1].to_f
    end
    po_paid_stock.each_with_index do |item,index| 
      po_item_paid_hash[item[0]] += item[1].to_f
    end
    po_free_stock.each_with_index do |item,index| 
      po_item_free_hash[item[0]] += item[1].to_f
    end
    total_other_charges_amount = @purchase_transaction.total_other_charges_amount || 0
    if @purchase_order_ids.present? && po_item_hash.present?
      InventoryJobs::Transactions::UpdatePurchaseOrderJob.perform_later(
        @purchase_order_ids[0].to_s, po_item_hash, po_item_paid_hash, po_item_free_hash, 'create',
        total_other_charges_amount
      )
      @time_period = 'Custom Date'
    end
    fetch_transactions
  end

  def edit 
    @items = @purchase_transaction.items
    @store_id = @purchase_transaction.store_id
    @category = 'all_item'
    @vendor = @purchase_transaction.vendor
    order_id = @purchase_transaction.purchase_order_ids[0]
    @purchase_order = Inventory::Order::Purchase.find_by(id: order_id) if order_id.present?
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @store_id)
    @sub_stores = @inventory_store.sub_stores.where(is_deleted: false).pluck(:name, :id)
    @purchase_transactions = Inventory::Transaction::Purchase.where(purchase_order_ids: order_id)
    @vendor_location = Inventory::VendorLocation.find_by(id: @purchase_transaction.vendor_location_id)
    fetch_variant_index
  end

  def update
    purchase_order_id = params[:inventory_transaction_purchase][:purchase_order_id]
    if purchase_order_id.present?
      purchase_order = Inventory::Order::Purchase.find_by(id: purchase_order_id)
      old_other_charge_amount = @purchase_transaction.total_other_charges_amount || 0
      new_other_charge_amount = params[:inventory_transaction_purchase][:total_other_charges_amount].to_f
      amount_diff = old_other_charge_amount - new_other_charge_amount
      remaining_amount = purchase_order.remaining_total_other_charges_amount.to_f
      purchase_order.update(remaining_total_other_charges_amount: remaining_amount + amount_diff)
      @purchase_transaction.items.each do |item|
        po_item = purchase_order.items.find_by(id: item.po_item_id)
        new_item_hash = Hash.new(0)
        new_item_paid_hash = Hash.new(0)
        new_item_free_hash = Hash.new(0)
        new_item_stock = params[:inventory_transaction_purchase][:items_attributes].values.pluck(:po_item_id, :stock)
        new_paid_item_stock = params[:inventory_transaction_purchase][:items_attributes].values.pluck(:po_item_id, :paid_stock)
        new_free_item_stock = params[:inventory_transaction_purchase][:items_attributes].values.pluck(:po_item_id, :stock_free_unit)
        new_item_stock.each_with_index do |item,index| 
          new_item_hash[item[0]] += item[1].to_f
        end
        new_paid_item_stock.each_with_index do |item,index| 
          new_item_paid_hash[item[0]] += item[1].to_f
        end
        new_free_item_stock.each_with_index do |item,index| 
          new_item_free_hash[item[0]] += item[1].to_f
        end
        stock_blocked = new_item_hash[item&.po_item_id&.to_s]&.to_f || 0
        stock_paid_blocked = new_item_paid_hash[item&.po_item_id&.to_s]&.to_f || 0
        stock_free_blocked = new_item_free_hash[item&.po_item_id&.to_s]&.to_f || 0
        po_item.update!(stock_blocked: stock_blocked, stock_paid_blocked: stock_paid_blocked, stock_free_blocked: stock_free_blocked)
      end
    end
    @purchase_transaction.items.delete_all
    @purchase_transaction.other_charges.delete_all
    @purchase_transaction.update(purchase_transaction_params)
    flash.now[:success] = 'updated'
  end

  def update_purchase_order_item(purchase_order_id)
    purchase_order = Inventory::Order::Purchase.find_by(id: purchase_order_id)
    @purchase_transaction.items.each do |item|
      po_item = purchase_order.items.find_by(id: item.po_item_id)

    end
  end

  def cancel
    @purchase_transaction.set_cancelled(current_user, params[:cancelled_reason]) if @purchase_transaction.open?
    po_item_hash = Hash.new(0)
    po_item_paid_hash = Hash.new(0)
    po_item_free_hash = Hash.new(0)
    # po_item_hash = @purchase_transaction.items.pluck(:po_item_id, :stock).map{|a,b| [a.to_s, b]}.to_h
    # po_item_paid_hash = @purchase_transaction.items.pluck(:po_item_id, :paid_stock).map{|a,b| [a.to_s, b]}.to_h
    # po_item_free_hash = @purchase_transaction.items.pluck(:po_item_id, :stock_free_unit).map{|a,b| [a.to_s, b]}.to_h

    po_item_stock = @purchase_transaction.items.pluck(:po_item_id, :stock)
    po_paid_stock = @purchase_transaction.items.pluck(:po_item_id, :paid_stock)
    po_free_stock = @purchase_transaction.items.pluck(:po_item_id, :stock_free_unit)
    po_item_stock.each_with_index do |item,index| 
      po_item_hash[item[0].to_s] += item[1].to_f
    end
    po_paid_stock.each_with_index do |item,index| 
      po_item_paid_hash[item[0].to_s] += item[1].to_f
    end
    po_free_stock.each_with_index do |item,index| 
      po_item_free_hash[item[0].to_s] += item[1].to_f
    end
 
    purchase_order_id = @purchase_transaction.purchase_order_ids[0]
    total_other_charges_amount = @purchase_transaction.total_other_charges_amount || 0
    if purchase_order_id.present? && po_item_hash.present?
      InventoryJobs::Transactions::UpdatePurchaseOrderJob.perform_later(
        purchase_order_id.to_s, po_item_hash, po_item_paid_hash, po_item_free_hash, 'cancel',
        total_other_charges_amount
      )
    end
  end

  def approve
    if @purchase_transaction.open?
      if @purchase_transaction.set_approved(current_user, '')
        InventoryJobs::Transactions::PurchaseJob.perform_later(@purchase_transaction.id.to_s, current_user.id.to_s)
      end
    end
  end

  def print_grn
    @inventory_store = @purchase_transaction.store
    @entity_name = EntityGroup.find_by(id: @inventory_store.entity_group_id.to_s ).try(:name)
    @purchase_order_transaction = Inventory::Order::Purchase.find_by(id: @purchase_transaction.try(:purchase_order_ids)[0])
    html_template = 'inventory/transaction/purchases/print_grn.html.erb'
    if params[:page_size] == 'A5'
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

  def show
    @returns_transactions = Inventory::Transaction::VendorReturn.where(transaction_ids: params[:id])
  end

  def add_custom_field
    @item = Inventory::Item.build
  end

  def append_variants
    @store_id = params[:store_id]
    @category = params[:item_type]
    fetch_variant_index
  end

  def filter_variants
    @store_id = params[:store_id]
    @category = params[:item_type]
    fetch_variant_index
  end

  def filter_purchase
    @store_id = params[:store_id]
    @department_id = params[:department_id]
  end

  def vendor_list
    category_ids = Inventory::Store.find_by(id: params[:store_id])&.category_ids
    vendor_ids = Inventory::Vendor.where(:category_ids.in => category_ids, is_deleted: false).pluck(:id)
    @vendor_locations = Inventory::VendorLocation.where(:vendor_id.in => vendor_ids)
  end

  def report
    options = { :facility_ids.in => [current_facility.id], is_active: true }
    @all_user = User.where(options.merge(:inventory_store_ids.in => [params[:store_id]])).pluck(:fullname, :id)
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @report_type = params[:report_type]
    @inventory_store = Inventory::Store.find(params[:store_id])
  end

  def bill_wise_report
    @store_name = "#{@store.name} Purchase Bill Wise Report"
    @time_period = "Detailed Purchase Bill Wise Report For a Period of #{params[:start_date]} #{params[:start_time]} to #{params[:end_date]} #{params[:end_time]}"
    @data_array, @total_array, @headings = Inventory::Transactions::DownloadPurchaseBillService.call(@options, params[:department_id], params[:user_id], current_facility, params[:gst_include])
    @filename = "#{@store.name.squish&.titleize&.tr(' ', '_')}_#{Time.now.strftime('%d %B %Y')}_#{Time.now.try(:strftime, '%R:%S')}_#{@user.squish&.titleize&.tr(' ', '_')}_bill_wise_purchase_report"
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}.xlsx\"" }
    end
  end

  def item_wise_report
    @store_name = "#{@store.name} Purchase Item Wise Report"
    @time_period = "Detailed Purchase Item Wise Report For a Period of #{params[:start_date]} #{params[:start_time]} to #{params[:end_date]} #{params[:end_time]}"
    @data_array, @grand_total = Inventory::Transactions::DownloadPurchaseItemService.call(@options, params[:user_id])
    @filename = "#{@store.name.squish&.titleize&.tr(' ', '_')}_#{Time.now.strftime('%d %B %Y')}_#{Time.now.try(:strftime, '%R:%S')}_#{@user.squish&.titleize&.tr(' ', '_')}_item_wise_purchase_report"
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}.xlsx\"" }
    end
  end

  def review_order
    @purchase = Inventory::Transaction::Purchase.find_by(id: params[:id])
  end

  def barcode
    @lots = Inventory::Item::Lot.where(transaction_id: params[:id], store_id: params[:store_id])
    @purchase = Inventory::Transaction::Purchase.find_by(id: params[:id])
  end

  def assign_barcodes
    @purchase_transaction = Inventory::Transaction::Purchase.find(params["inventory_transaction_purchase"]["purchase_id"])
    @vendor = Inventory::Vendor.find_by(id: @purchase_transaction.vendor_id)
    if  params["inventory_transaction_purchase"]["confirm"] == "true"
      params["inventory_transaction_purchase"]["items_attributes"].each do |key,value|
          lot = Inventory::Item::Lot.find(value["id"])
        if value["system_generated_barcode"] == "true"
           barcode_id = Inventory::Lots::GenerateBarCodeService.default(lot.lot_code, lot.organisation_id)
           lot.update(barcode_id: barcode_id,system_generated_barcode: true)
        else
          lot.update(barcode_id: value["barcode_id"])
        end
      end
    end
  end

  def complete_payment
    @purchase_transaction = Inventory::Transaction::Purchase.find_by(id: params[:id])
    @vendor = Inventory::Vendor.find_by(id: @purchase_transaction.vendor_id)
    @returns_transactions = Inventory::Transaction::VendorReturn.where(purchase_transaction_id: params[:id])
    amount_remaining = @purchase_transaction.amount_remaining
    total_extra_amount_paid = @purchase_transaction.extra_amount_paid + amount_remaining
    @purchase_transaction.update(amount_paid: @purchase_transaction.net_amount, payment_completed: true, amount_remaining: 0,
                     extra_amount_paid: total_extra_amount_paid, status: :completed )
    payment_breakup = @purchase_transaction.payment_received_breakups.new(payment_breakup_param)
    payment_breakup.save
  end

  def print
    order_id = params[:order_id]
    page_size = params[:page_size]
    @purchase = Inventory::Transaction::Purchase.find_by(id: order_id)
    @purchase_order_transaction = Inventory::Order::Purchase.find_by(id: @purchase.try(:purchase_order_ids)[0])
    @inventory_store = Inventory::Store.find_by(id: @purchase.store_id)
    @entity_name = EntityGroup.find_by(id: @inventory_store.entity_group_id.to_s).try(:name)
    html_template = 'inventory/transaction/purchases/print'

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

  def check_bill_number
    bill_number = params[:inventory_transaction_purchase][:bill_number].to_s
    unless params[:existing_bill_number] == bill_number
      @bill_number = Inventory::Transaction::Purchase.find_by(bill_number: bill_number, vendor_location_id: params[:vendor_location_id])
    end
    respond_to do |format|
      format.json { render json: !@bill_number.try(:to_a).present? }
    end
  end

  def check_challan_number
    challan_number = params[:inventory_transaction_purchase][:challan_number].to_s
    unless params[:existing_challan_number] == challan_number
      @challan_number = Inventory::Transaction::Purchase.find_by(challan_number: challan_number, vendor_location_id: params[:vendor_location_id])
    end
    respond_to do |format|
      format.json { render json: !@challan_number.try(:to_a).present? }
    end
  end

  private

  def purchase_transaction_params
    # params.require(:inventory_transaction_purchase).permit!
    params.require(:inventory_transaction_purchase)
          .permit(
            :note, :vendor_id, :transaction_date, :vendor_name, :entry_type, :entered_by, :user_id, :store_id,
            :total_cost, :facility_id, :organisation_id, :mode_of_payment, :comments, :discount, :net_amount,
            :amount_paid, :amount_remaining, :credit_adjustment, :debit_amount, :extra_amount_paid, :department_id,
            :department_name, { purchase_order_ids: [] }, :vendor_gst_number, :store_gst_number, :vendor_dl_number,
            :purchase_taxable_amount, :transaction_time, :bill_type, :challan_date, :challan_number, :bill_number, :bill_date,
            :total_other_charges_amount, :tax_amount, :version, :optical_order_id, :requisition_order_id, :vendor_location_id,
            :total_paid_stock, :po_display_id, :vendor_location_name, :vendor_location_address, :vendor_address, 
            { tax_breakup: [:_id, :name, :amount, :tax_rate, :tax_type, :taxable_amount] },
            items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :default_variant_code, :item_id,
              :default_variant_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :_destroy,
              :search, :mark_up, :batch_no, :cost_price, :total_cost_price, :stock_package, :stock_subpackage, :paid_stock,
              :stock_unit, :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :list_price, :tax_inclusive,
              :tax_rate, :tax_name, :tax_group_id, :mrp_pack_denomination, :list_price_pack_denomination, :self_batched,
              :expiry, :expiry_present, :total_cost, :unit_cost, :description, :store_id, :facility_id, :system_generated_barcode,
              :item_reference_id, :organisation_id, :unit_non_taxable_amount, :unit_taxable_amount, :barcode_id, :model_no,
              :unit_cost_without_tax, :purchase_tax_amount, :unit_purchase_tax_amount, :item_cost_without_tax,
              :sub_store_id, :sub_store_name, :department_id, :department_name, :po_ordered_quantity, :po_item_id,
              :po_original_ordered_quantity, :item_discount, :item_discount_type, :amount_after_tax, :remarks,
              :discount_per_unit, :net_unit_cost_without_tax, :margin, :variant_reference_id, :item_type, :dispensing_unit,
              { tax_group: [:_id, :name, :amount] }
            ],
            payment_received_breakups_attributes: [
              :amount, :currency_symbol, :currency_id, :date, :time, :received_by, :received_from, :mode_of_payment,
              :cash, :card, :card_number, :cheque_date, :cheque_note, :transfer_date, :transfer_note, :other_note,
              :paytm_transaction_id, :paytm_transaction_note, :gpay_transaction_id, :gpay_transaction_note,
              :phonepe_transaction_id, :phonepe_transaction_note, :is_settled
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
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    if @category.present?
      if (@category.include? 'all_item') || @category_id.blank? #for store item index
        vendor_location_id = Inventory::VendorLocation.find_by(id: params[:vendor_location_id])&.vendor_id
        vendor_id = vendor_location_id || @vendor&.id
        vendor_category_ids = Inventory::Vendor.find_by(id: vendor_id)&.category_ids || []
        store_category_ids = @inventory_store.category_ids || []
        category_ids = vendor_category_ids & store_category_ids
        options = { :category_id.in => category_ids, level: 'store' }
      else
        options = { :category_id.in => [@category_id], level: 'store'}
      end
    else
      options = { :category_id.in => @inventory_store.category_ids, level: 'store' }
    end

    if @stock == 'out_stock'
      options = options.merge(empty: true)
    elsif @stock == 'running_low'
      options = options.merge(running_low: true)
    end
    options = options.merge!(store_id: @store_id, stockable: true, search: /#{Regexp.escape(query)}/i)
    @variants = Inventory::Item::Variant.where(options).is_active.order_by(created_at: 'desc').skip(current_data_row)
                                        .limit(30).includes(:item)
    @variants = @variants.select { |variant| variant.item&.tax_group_id.present? }
  end

  def fetch_transactions
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, vendor_name: /#{Regexp.escape(query)}/i, is_deleted: false }
    options = options.merge(vendor_id: @vendor_id) if @vendor_id.present? && @vendor_id != 'all'
    if @start_date.present? && @end_date.present?
      options[:transaction_date] = { :$gte => @start_date, :$lte => @end_date }
      @start_date = Date.parse(@start_date).strftime('%Y-%m-%d')
      @end_date = Date.parse(@end_date).strftime('%Y-%m-%d')
    end
    @purchases = Inventory::Transaction::Purchase.where(options).order_by(created_at: 'desc').skip(current_data_row)
                                                 .limit(30)
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

  def set_purchase
    @purchase_transaction = Inventory::Transaction::Purchase.find_by(id: params[:id])
  end

  def payment_breakup_param
    { amount: @purchase_transaction.amount_remaining, date:  DateTime.current.utc, time: Time.current.utc,
      received_by: @purchase_transaction.vendor_id, received_from: current_user.id, mode_of_payment: 'Cash',
      currency_id: current_facility.currency_id, currency_symbol: current_facility.currency_symbol }
  end

  def fetch_other_charges
    @other_charges = Inventory::OtherCharge.where(organisation_id: current_user.organisation_id, is_disable: false)
                                           .pluck(:name, :id)
  end
end
