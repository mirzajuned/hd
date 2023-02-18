class Inventory::Transaction::PurchaseBillsController < ApplicationController
  before_action :authorize, :verify_store
  before_action :set_purchase_bill, only: [:show, :cancel, :approve, :edit, :update]

  def index
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @time_period = params[:time_period]
    @vendor_name = params[:vendor_name]
    @vendor_id = params[:vendor_id]
    @vendors = Inventory::Vendor.where(:category_ids.in => @inventory_store.category_ids).pluck(:name, :id)
    # @vendor_locations = Inventory::VendorLocation.where(:vendor_id.in => ids, is_deleted: false).pluck(:name, :id)
    fetch_purchase_bills
  end

  def filter_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @vendor_name = params[:vendor_name]
    @vendor_id = params[:vendor_id]
    fetch_purchase_bills
  end

  def new
    @time_period = params[:time_period].present? ? params[:time_period] : 'This Month'
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @category = 'all_item'
    @time_period = 'This Month'
    @vendor_location = Inventory::VendorLocation.find_by(id: params[:vendor_location_id])
    @vendor = @vendor_location&.vendor
    category_ids = Inventory::Store.find_by(id: params[:store_id])&.category_ids
    ids = Inventory::Vendor.where(:category_ids.in => category_ids, is_deleted: false).pluck(:id)
    @vendor_locations = Inventory::VendorLocation.where(:vendor_id.in => ids, is_deleted: false)
    @purchase_bill = Inventory::Transaction::PurchaseBill.new
    @stores = Inventory::Store.where(organisation_id: current_user.organisation_id, is_active: true, is_disable: false)
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_purchase_transaction_index
  end

  def create
    @store_id = params[:inventory_transaction_purchase_bill][:store_id]
    @start_date = Date.current.beginning_of_month.strftime('%Y-%m-%d')
    @end_date = Date.current.end_of_month.strftime('%Y-%m-%d')
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @vendors = Inventory::Vendor.where(:category_ids.in => @inventory_store.category_ids).pluck(:name, :id)
    @purchase_bill = Inventory::Transaction::PurchaseBill.new(purchase_bill_params)
    pb_display_id = InventoryHelper.increment_and_create_purchase_bill_number(current_organisation['_id'].to_s)
    @purchase_bill.purchase_bill_display_id = pb_display_id
    purchase_transaction_ids = params['inventory_transaction_purchase_bill']['purchase_transaction_ids'].split(',')
    @purchase_bill.purchase_transaction_ids = purchase_transaction_ids
    purchase_transactions = Inventory::Transaction::Purchase.where(:id.in => purchase_transaction_ids)
                                                            .pluck(:is_purchase_bill_created)
    if purchase_transactions.include?(true)
      flash[:error] = 'Invalid purchase bill'
    else
      @purchase_bill.save!
      InventoryJobs::Transactions::PurchaseBillJob.perform_now(@purchase_bill.id.to_s, current_user.id.to_s, 'create')
    end
    fetch_purchase_bills
  end

  def edit
    @time_period = params[:time_period].present? ? params[:time_period] : 'This Month'
    @start_date = Date.today.at_beginning_of_month
    @end_date = Date.today.end_of_month
    @store_id = @purchase_bill.store_id
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @store_id)
    @sub_stores = @inventory_store.sub_stores.where(is_deleted: false).pluck(:name, :id)
    @category = 'all_item'
    category_ids = Inventory::Store.find_by(id: @store_id)&.category_ids
    ids = Inventory::Vendor.where(:category_ids.in => category_ids, is_deleted: false).pluck(:id)
    @vendor_locations = Inventory::VendorLocation.where(:vendor_id.in => ids, is_deleted: false)
    @vendor_location = Inventory::VendorLocation.find_by(id: params[:vendor_location_id])
    @vendor = @vendor_location&.vendor
    if params[:action] == 'edit' && (@purchase_bill.vendor_location_id.to_s == params[:vendor_location_id])
      purchase_transaction_ids = @purchase_bill.purchase_transaction_ids
      @purchase_transactions_data = Inventory::Transaction::Purchase.where(:id.in => purchase_transaction_ids)
    end
    fetch_purchase_transaction_index
  end

  def update
    old_purchase_transaction_ids = @purchase_bill.purchase_transaction_ids || []
    new_purchase_transaction_ids = params[:inventory_transaction_purchase_bill][:purchase_transaction_ids].split(',') || []
    deleted_purchase_transaction_ids = old_purchase_transaction_ids - new_purchase_transaction_ids
    @store_id = @purchase_bill.store_id
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    update_purchase_transactions(deleted_purchase_transaction_ids) if deleted_purchase_transaction_ids.present?
    @purchase_bill.purchase_transaction_ids = new_purchase_transaction_ids
    @purchase_bill.update(purchase_bill_params)
    InventoryJobs::Transactions::PurchaseBillJob.perform_now(@purchase_bill.id.to_s, current_user.id.to_s, 'create')
    fetch_purchase_bills
  end

  def approve
    return unless @purchase_bill.open?

    if @purchase_bill.set_approved(current_user, '')
      InventoryJobs::Transactions::PurchaseBillJob.perform_now(@purchase_bill.id.to_s, current_user.id.to_s, 'approve')
    end
  end

  def cancel
    return unless @purchase_bill.open?

    if @purchase_bill.set_cancelled(current_user, params[:cancelled_reason])
      @purchase_bill.update(cancelled_reason: params[:cancelled_reason])
      InventoryJobs::Transactions::PurchaseBillJob.perform_now(@purchase_bill.id.to_s, current_user.id.to_s, 'cancel')
    end
  end

  def purchase_transaction_item
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @vendor = Inventory::Vendor.find_by(id: params[:vendor_id])
    @purchase_transaction = Inventory::Transaction::Purchase.find_by(id: params[:transaction_id])
    @purchase_bill = Inventory::Transaction::PurchaseBill.new
  end

  def filter_transactions
    @store_id = params[:store_id]
    @category = params[:category]
    @vendor = Inventory::Vendor.find_by(id: params[:vendor_id])
    @create_against = params[:create_against].present? && params[:create_against] == 'bill' ? 0 : 1
    @start_date = params[:start_date]
    @end_date = params[:end_date]

    fetch_purchase_transaction_index
  end

  def show
    @purchase_transactions = Inventory::Transaction::Purchase.where(:id.in => @purchase_bill.purchase_transaction_ids)
    @vendor = Inventory::Vendor.find_by(id: @purchase_bill.vendor_id)
  end

  def set_vendor
    vendor_location = Inventory::VendorLocation.find_by(id: params[:vendor_location_id])
    render json: { vendor_location: vendor_location }
  end

  def print
    order_id = params[:order_id]
    page_size = params[:page_size]
    @purchase_bill = Inventory::Transaction::PurchaseBill.find_by(id: order_id)
    transaction_ids = @purchase_bill.try(:purchase_transaction_ids)
    @purchase_transactions = Inventory::Transaction::Purchase.where(:id.in => transaction_ids)
    @inventory_store = Inventory::Store.find_by(id: @purchase_bill.store_id)
    @entity_name = EntityGroup.find_by(id: @inventory_store.entity_group_id.to_s).try(:name)
    html_template = 'inventory/transaction/purchase_bills/print_bill'

    if page_size == 'A5'
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/pdfgen.html.erb',
             viewport_size: '1280x1024', page_size: 'A4', show_as_html: params[:debug].present?,
             orientation: 'landscape', footer: { right: '[page] of [topage]' }, locals: { mail_job: false }
    else
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/pdfgen.html.erb',
             viewport_size: '1280x1024', page_size: 'A4', orientation: 'landscape',
             show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' },
             locals: { mail_job: false }
    end
  end

  private

  def purchase_bill_params
    params.require('inventory_transaction_purchase_bill')
          .permit(
            :vendor_name, :transaction_date, :transaction_time, :note, :is_deleted, :vendor_id, :department_id,
            :department_name, :total_cost, :discount, :net_amount, :create_against, :tax_amount, :user_id, :store_id,
            :facility_id, :organisation_id, :created_by, :created_by_id, :cancelled_by_id, :cancelled_by_name,
            :cancelled_on, :approved_by_id, :approved_by_name, :approved_on, :purchase_transaction_id,
            :vendor_gst_number, :total_other_charges_amount, :purchase_taxable_amount, :amt_before_tax,
            :purchase_bill_display_id, :invoice_number, :invoice_date, :gst_type, :invoice_date_time,
            :vendor_address, :vendor_location_id, :vendor_location_name, :vendor_location_address, 
            :vendor_gst_number, :store_gst_number, :vendor_location_mobile, :vendor_location_email, 
            :tax_type, { purchase_transaction_ids: [] },
            { tax_breakup: [:id, :name, :amount, :rate, :taxable_amount, :tax_group] }
          )
  end

  def fetch_purchase_bills
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, is_deleted: false }
    options = options.merge(invoice_number: /#{Regexp.escape(query)}/i) if query.present?
    if @vendor_id.present? && @vendor_id != 'all'
      options = options.merge(vendor_id: @vendor_id)
    end
    if @start_date.present? && @end_date.present?
      options[:transaction_date] = { :$gte => @start_date, :$lte => @end_date }
      @start_date = Date.parse(@start_date).strftime('%Y-%m-%d')
      @end_date = Date.parse(@end_date).strftime('%Y-%m-%d')
    end
    @purchase_bills = Inventory::Transaction::PurchaseBill.where(options).order_by(created_at: 'desc').skip(current_data_row)
                                                          .limit(30)
  end

  def fetch_purchase_transaction_index
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @create_against = params[:create_against].present? && params[:create_against] == 'bill' ? 0 : 1
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    search_data = { "grn": 'purchase_display_id', "po": 'po_display_id', "bill": 'bill_number', "challan": 'challan_number' }
    if @vendor_location.present?
      options = { store_id: @store_id, status: 1, is_purchase_bill_created: false, bill_type: @create_against,
                  vendor_location_id: @vendor_location&.id, is_deleted: false }
      if @start_date.present? && @end_date.present?
        options[:transaction_date] = { :$gte => @start_date, :$lte => @end_date }
       end
      if query.present? && params[:search_term].present?
        key = search_data[params[:search_term].to_sym]
        options = options.merge!(key.to_sym => /#{Regexp.escape(query)}/i)
      end
    else
      options = { store_id: @store_id, vendor_location_id: @vendor_location&.id, is_deleted: false, is_purchase_bill_created: false }
    end
    @purchase_transactions = Inventory::Transaction::Purchase.where(options).order_by(approved_on: 'desc').skip(current_data_row)
                                                             .limit(30)
    if @purchase_transactions_data.present? && (@purchase_bill.create_against == params[:create_against])
      @purchase_transactions = @purchase_transactions_data + @purchase_transactions
    end
  end

  def set_purchase_bill
    @purchase_bill = Inventory::Transaction::PurchaseBill.find_by(id: params[:id])
  end

  def update_purchase_transactions(deleted_purchase_transaction_ids)
    deleted_purchase_transaction_ids.each do |purchase_id|
      purchase = Inventory::Transaction::Purchase.find_by(id: purchase_id)
      purchase.update!(is_purchase_bill_created: false, purchase_bill_created_by: nil,
                       purchase_bill_created_on: nil, purchase_bill_created_by_name: nil)
    end
  end
end
