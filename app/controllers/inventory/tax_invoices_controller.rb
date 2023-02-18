class Inventory::TaxInvoicesController < ApplicationController
  before_action :authorize
  before_action :find_store, only: [:index, :new, :filter_index, :edit]
  before_action :find_tax_invoice, only: [:edit, :approve, :cancel, :update, :print_tax_invoice]

  def index
    @time_period = params[:time_period]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @store_id = params[:store_id]
    fetch_tax_invoices
  end

  def new
    @tax_invoice = Inventory::TaxInvoice.new
    @stores = Inventory::Store.where(organisation_id: current_user.organisation_id, is_active: true, is_disable: false)
    @transportations = Inventory::Transportation.where(organisation_id: current_user.organisation_id, is_disable: false).pluck(:name, :id)
    @store_id = params[:store_id]
    @time_period = params[:time_period]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @type = params[:type]
    fetch_transfer_transactions
  end

  def create
    @tax_invoice = Inventory::TaxInvoice.new(tax_invoice_params)
    transfer_ids = params[:inventory_tax_invoice][:transfer_ids].split(',')
    if @tax_invoice.type == 'tax_invoice'
      transaction_display_id = InventoryHelper.increment_and_create_tax_invoice_display_number(current_organisation['_id'].to_s)
      transfers = Inventory::Transaction::Transfer.where(:id.in => transfer_ids, is_tax_invoice_created: true)
    else
      transaction_display_id = InventoryHelper.increment_and_create_challan_display_number(current_organisation['_id'].to_s)
      transfers = Inventory::Transaction::Transfer.where(:id.in => transfer_ids, is_delivery_challan_created: true)
    end
    @tax_invoice.transaction_display_id = transaction_display_id
    @tax_invoice.transfer_ids = transfer_ids
    @store_id = @tax_invoice.store_id
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    # @start_date = @end_date = @tax_invoice.transaction_date
    @start_date = Date.current.beginning_of_month.strftime('%Y-%m-%d')
    @end_date = Date.current.end_of_month.strftime('%Y-%m-%d')
    if transfers.present?
      flash.now[:success] = 'Invalid Transfer Transactions'
    else
      @tax_invoice.save!
      InventoryJobs::Transactions::TaxInvoiceJob.perform_now(@tax_invoice.id.to_s, @tax_invoice.type, current_user.id.to_s, 'create')
    end
    fetch_tax_invoices
  end

  def show
    @tax_invoice = Inventory::TaxInvoice.find_by(id: params[:id])
    @receive_store = Inventory::Store.find_by(id: @tax_invoice.created_against_store_id)
  end

  def add_transfer_data
    @transfer = Inventory::Transaction::Transfer.find_by(id: params[:transfer_id])
    @inventory_store = Inventory::Store.find_by(id: @transfer.store_id)
    @receive_store = Inventory::Store.find_by(id: params[:receive_store_id])
    items = @transfer.items
    transfer_display_id = @transfer.transfer_from == 'store' ? @transfer.transfer_display_id : @transfer.issue_display_id
    info = ["#{@transfer.entry_type}", "#{transfer_display_id}", "#{@transfer.transaction_time&.strftime('%d-%m-%Y')}", "#{@transfer.approved_by_name}"]
    @items = [info] + items
  end

  def filter_transfer
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @time_period = params[:time_period]
    @type = params[:type]
    fetch_transfer_transactions
  end

  def edit
    @tax_invoice = Inventory::TaxInvoice.find_by(id: params[:id])
    @stores = Inventory::Store.where(organisation_id: current_user.organisation_id, is_active: true, is_disable: false)
    @transportations = Inventory::Transportation.where(organisation_id: current_user.organisation_id, is_disable: false).pluck(:name, :id)
    @store_id = @tax_invoice.store_id
    @type = @tax_invoice.type
    @time_period = 'This Month'
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    if @tax_invoice.created_against_store_id.to_s == params["receive_store_id"]
      transfer_ids = @tax_invoice.transfer_ids
      @transfers_data = Inventory::Transaction::Transfer.where(:id.in => transfer_ids) 
    end
    fetch_transfer_transactions
  end

  def update
    old_transfer_ids = @tax_invoice.transfer_ids || []
    new_transfer_ids = params[:inventory_tax_invoice][:transfer_ids].split(',') || []
    deleted_transfer_ids = old_transfer_ids - new_transfer_ids
    @store_id = @tax_invoice.store_id
    # @start_date = @end_date = @tax_invoice.transaction_date
    @start_date = Date.current.beginning_of_month.strftime('%Y-%m-%d')
    @end_date = Date.current.end_of_month.strftime('%Y-%m-%d')
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    update_transfer_transactions(deleted_transfer_ids, @tax_invoice.type) if deleted_transfer_ids.present?
    @tax_invoice.transfer_ids = new_transfer_ids
    @tax_invoice.update(tax_invoice_params)
    InventoryJobs::Transactions::TaxInvoiceJob.perform_now(@tax_invoice.id.to_s, @tax_invoice.type, current_user.id.to_s, 'create')
    fetch_tax_invoices
  end

  def approve
    if @tax_invoice.open?
      if @tax_invoice.set_approved(current_user, "")
        InventoryJobs::Transactions::TaxInvoiceJob.perform_now(@tax_invoice.id.to_s, @tax_invoice.type, current_user.id.to_s, 'approve')
      end
      @tax_invoice.transfer_ids.each do |transfer_id|
        Inventory::Transactions::Receive::CreateService.call(transfer_id)
      end
    end
    flash.now[:success] = 'approved'
  end

  def cancel
    if @tax_invoice.open?
      if @tax_invoice.set_cancelled(current_user,params[:cancelled_reason])
        InventoryJobs::Transactions::TaxInvoiceJob.perform_now(@tax_invoice.id.to_s, @tax_invoice.type, current_user.id.to_s, 'cancel')
      end
    end
    flash.now[:success] = 'cancelled'
  end

  def filter_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_tax_invoices
  end

  def print_tax_invoice
    @store_id = @tax_invoice.store_id
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @entity_name = EntityGroup.find_by(id: @inventory_store.entity_group_id.to_s ).try(:name)
    @transfer_ids = @tax_invoice.transfer_ids
    all_item_details
    @receive_store = Inventory::Store.find_by(id: @tax_invoice.created_against_store_id)
    @receive_entity_name = EntityGroup.find_by(id: @receive_store.entity_group_id.to_s ).try(:name)
    # @vendor = @purchase_transaction.vendor
    # @purchase_order_transaction = Inventory::Order::Purchase.find_by(id: @purchase_transaction.try(:purchase_order_ids)[0])
    html_template = 'inventory/tax_invoices/print_tax_invoice.html.erb'
    render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/pdfgen.html.erb',
             viewport_size: '1280x1024', page_size: 'A4', show_as_html: params[:debug].present?,
             footer: { right: '[page] of [topage]' }, locals: { mail_job: false }
  end

  private

  def all_item_details
    @items = []
    @transfer_ids.each do |transfer_id|
      transfer_items = Inventory::Transaction::Transfer.find_by(id: transfer_id).items
      @items += transfer_items
    end
  end

  def find_tax_invoice
    @tax_invoice = Inventory::TaxInvoice.find_by(id: params[:id])
  end

  def tax_invoice_params
    params.require(:inventory_tax_invoice).permit(:type, :creation_on, :transaction_date, :created_by,
                    :transaction_date_time, :created_against_store_id, :store_id, :transportation_mode, :delivery_date,
                    :dispatch_remarks, :taxable_amount, :tax_amount, :total_amount, :facility_id, :organisation_id,
                    :user_id, :transportation_mode_name, :created_on, :created_by_id, :transportation_transaction_id,
                    :gst_type, :tax_type, { tax_breakup: [:id, :name, :amount, :tax_rate, :taxable_amount] })
  end

  def find_store
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
  end

  def fetch_transfer_transactions
    current_data_row = params[:total_count_row].to_i
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    query = params[:q].to_s
    @receive_store_id = params[:receive_store_id]
    @receive_store = Inventory::Store.find_by(id: @receive_store_id)
    options = { store_id: @store_id, receive_store_id: @receive_store_id, is_deleted: false, status: 1 }
    options.merge!(is_delivery_challan_created: false) #if @type == 'delivery_challan'
    options.merge!(is_tax_invoice_created: false) #if @type == 'tax_invoice'
    if @start_date.present? && @end_date.present?
      options[:transaction_date] = { :$gte => @start_date, :$lte => @end_date }
    end
    @transfers = Inventory::Transaction::Transfer.where(options).order_by(created_at: 'desc').skip(current_data_row)
                                                 .limit(30)
    if @transfers_data.present?
      @transfers = @transfers + @transfers_data
    end
  end

  def fetch_tax_invoices
    current_data_row = params[:total_count_row].to_i
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    query = params[:q].to_s
    options = { store_id: @store_id, is_active: true }
     # type = params[:type].present? && params[:type] == "tax_invoice" ? "is_tax_invoice_created" : "is_delivery_challan_created" 
     # options.merge!({type: true})
    if @start_date.present? && @end_date.present?
      options[:transaction_date] = { :$gte => @start_date, :$lte => @end_date }
    end
    @type = params[:type]
    options = options.merge(type: @type) if @type.present? && @type != 'all'
    options = options.merge({ transaction_display_id: /#{Regexp.escape(query)}/i }) if query.present?
    @tax_invoices = Inventory::TaxInvoice.where(options).order_by(created_at: 'desc').skip(current_data_row)
                                                        .limit(30)
  end

  def update_transfer_transactions(deleted_transfer_ids, type)
    deleted_transfer_ids.each do |transfer_id|
      transfer = Inventory::Transaction::Transfer.find_by(id: transfer_id)
      if type == 'delivery_challan'
        transfer.update!(is_delivery_challan_created: false, delivery_challan_created_by: nil,
                         delivery_challan_created_on: nil)
      else
        transfer.update!(is_tax_invoice_created: false, tax_invoice_created_by: nil,
                         tax_invoice_created_on: nil)
      end
    end
  end
end
