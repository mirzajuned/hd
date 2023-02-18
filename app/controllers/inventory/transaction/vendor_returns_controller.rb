class Inventory::Transaction::VendorReturnsController < ApplicationController
  include Inventory::ItemsHelper
  before_action :authorize, :verify_store
  before_action :stock_report, only: [:bill_stock_report, :item_stock_report]
  before_action :download_report, only: [:download_item_stock_report, :download_bill_stock_report]

  def index
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @time_period = params[:time_period]
    @vendor_name = params[:vendor_name]
    @vendor_id = params[:vendor_id]
    @vendors = Inventory::Vendor.where(:category_ids.in => @inventory_store.category_ids, is_deleted: false).pluck(:name, :id)
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
    @time_period = params[:time_period]
    @vendor_name = params[:vendor_name]
    @vendor_id = params[:vendor_id]
    fetch_transactions
  end

  def filter_transactions
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    fetch_purchase_transactions
  end

  def return_purchase
    @lots = Inventory::Item::Lot.where(transaction_id: params[:id], store_id: params[:store_id])
    @purchase = Inventory::Transaction::Purchase.find_by(id: params[:id])
    category_ids = Inventory::Store.find_by(id: params[:store_id])&.category_ids
    vendor_ids = Inventory::Vendor.where(:category_ids.in => category_ids, is_deleted: false).pluck(:id)
    @vendor_locations = Inventory::VendorLocation.where(:vendor_id.in => vendor_ids, is_deleted: false)
    @vendor_location = Inventory::VendorLocation.find_by(id: @purchase.vendor_location_id)
    @vendor = @vendor_location.vendor
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @return_purchase = Inventory::Transaction::VendorReturn.new
  end

  def new
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @vendor_location = Inventory::VendorLocation.find_by(:id => params[:vendor_location_id])
    @vendor = @vendor_location.vendor
    address = []
    address << @vendor_location&.address << @vendor_location&.city << @vendor_location&.district << @vendor_location&.state << @vendor_location&.pincode
    address = address.reject(&:blank?)&.join(', ')
    vendor_name = @vendor_location&.name
    @vendor_location_address = vendor_name ? "#{vendor_name} #{"- #{address}"}" : '-'
    @purchases = Inventory::Transaction::Purchase.where(vendor_location_id: @vendor_location&.id, amount_remaining: 0,
                                                        store_id: params[:store_id]).order_by(created_at: 'desc')
    @return_transaction = Inventory::Transaction::VendorReturn.new
  end

  def create
    @store_id = params[:inventory_transaction_vendor_return][:store_id]
    store = Inventory::Store.find_by(id: @store_id)
    @start_date = @end_date = params[:inventory_transaction_vendor_return][:transaction_date]
    bkp_purchase_return_id = InventoryHelper.increment_and_create_return_purchase_number(
      current_organisation['_id'].to_s
    )
    @return_transaction = Inventory::Transaction::VendorReturn.new(return_transaction_params)
    @return_transaction.bkp_purchase_return_id = bkp_purchase_return_id
    @vendor_location_id = params[:inventory_transaction_vendor_return][:vendor_location_id]
    update_vendor_details
    @return_transaction.transaction_ids = params[:inventory_transaction_vendor_return][:items_attributes]
    &.values&.pluck(:transaction_id)&.uniq
    Inventory::Vendor::DebitNoteService.call(@return_transaction, 'In') if
    params[:inventory_transaction_vendor_return][:debit_amount].present?
    InventoryJobs::Transactions::VendorReturnJob.perform_later(@return_transaction.id.to_s, current_user.id.to_s) if
    @return_transaction.save!
    purchase_return_id =  SequenceManagers::GenerateSequenceService.call(
                            'purchase_return_transaction', @return_transaction,
                            { organisation_id: current_organisation['_id'].to_s, 
                                facility_id: current_facility['_id'].to_s, 
                                region_id: current_facility['region_master_id'].to_s, 
                                department_id: @return_transaction.try(:department_id),
                                entity_group_id: store.try(:entity_group_id).to_s

                              })
    @return_transaction.update(purchase_return_id: purchase_return_id)
    fetch_transactions
    if params[:inventory_transaction_vendor_return][:return_type] == 'return_against_purchase'
      @purchase_transaction = Inventory::Transaction::Purchase.find_by(id: @return_transaction.purchase_transaction_id)
      @returns_transactions = Inventory::Transaction::VendorReturn.where(
        purchase_transaction_id: @return_transaction.purchase_transaction_id
      )
      render 'print_preview'
    else
      render 'create'
    end
  end

  def add_lot
    @lot = Inventory::Item::Lot.find_by(id: params[:lot_id])
    @variant = Inventory::Item::Variant.find_by(id: @lot.variant_id)
    @item = Inventory::Item.find_by(id: @lot.item_id)

    @return_transaction = Inventory::Transaction::VendorReturn.build
  end

  def show
    @return_transaction = Inventory::Transaction::VendorReturn.find_by(id: params[:id])
    @vendor = Inventory::Vendor.find_by(id: @return_transaction.vendor_id)
  end

  def vendor_list
    category_ids = Inventory::Store.find_by(id: params[:store_id])&.category_ids
    vendor_ids = Inventory::Vendor.where(:category_ids.in => category_ids, is_deleted: false).pluck(:id)
    @vendor_locations = Inventory::VendorLocation.where(:vendor_id.in => vendor_ids)
  end

  def print
    page_size = params[:page_size]
    facility_id = current_facility.id
    @return_transaction = Inventory::Transaction::VendorReturn.find_by(id: params[:id])
    @inventory_store = Inventory::Store.find_by(id: @return_transaction.store_id)
    @entity = EntityGroup.find_by(id: @inventory_store.entity_group_id.to_s )
    @facility = Facility.find_by(id: facility_id)
    @vendor = Inventory::Vendor.find_by(id: @return_transaction.vendor_id)

    html_template = 'inventory/transaction/vendor_returns/print'

    if page_size == 'A5'
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/pdfgen.html.erb',
             viewport_size: '1280x1080', page_size: 'A4', orientation: 'Landscape', show_as_html: params[:debug].present?,
             footer: { right: '[page] of [topage]' }, locals: { mail_job: false }
    else
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/pdfgen.html.erb',
             viewport_size: '1280x1024', page_size: 'A4', orientation: 'Landscape',
             show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' },
             locals: { mail_job: false }
    end
  end

  def bill_stock_report; end

  def item_stock_report; end

  def download_item_stock_report
    @store_name = "#{@store.name} Purchase Return Item Wise Report"
    @time_period = "Purchase Return Item Wise Report For a Period of #{params[:start_date]} #{params[:start_time]} to #{params[:end_date]} #{params[:end_time]}"
    @data_array, @grand_total = Inventory::Transactions::DownloadVendorReturnItemService.call(@options, params[:department_id], params[:user_id])
    @filename = "#{@store.name.squish&.titleize&.tr(' ', '_')}_#{Time.now.strftime('%d %B %Y')}_#{Time.now.try(:strftime, '%R:%S')}_#{@user.squish&.titleize&.tr(' ', '_')}_item_wise_purchase_return_report"
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}.xlsx\"" }
    end
  end

  def download_bill_stock_report
    @store_name = "#{@store.name} Purchase Return Bill Wise Report"
    @time_period = "Detailed Purchase Return Bill Wise Report For a Period of #{params[:start_date]} #{params[:start_time]} to #{params[:end_date]} #{params[:end_time]}"
    @data_array, @total_array = Inventory::Transactions::DownloadVendorReturnBillService.call(@options, params[:department_id], params[:user_id])
    @filename = "#{@store.name.squish&.titleize&.tr(' ', '_')}_#{Time.now.strftime('%d %B %Y')}_#{Time.now.try(:strftime, '%R:%S')}_#{@user.squish&.titleize&.tr(' ', '_')}_bill_wise_purchase_return_report"
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}.xlsx\"" }
    end
  end

  private

  def return_transaction_params
    params.require(:inventory_transaction_vendor_return)
          .permit(
            :note, :transaction_date, :entry_type, :entered_by, :user_id, :store_name, :store_id, :total_cost,
            :return_discount, :return_amount, :paid_amount, :debit_amount, :facility_id, :organisation_id,
            :purchase_transaction_id, :vendor_name, :vendor_id, :vendor_mobile, :return_type, :transaction_time,
            :department_name, :department_id, :full_settlement, :comments, :vendor_location_id, :vendor_location_name,
            :vendor_location_address, :vendor_address,
            items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :variant_code, :item_id, :lot_id,
              :variant_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :_destroy,
              :search, :mark_up, :batch_no, :cost_price, :total_cost_price, :stock_package, :stock_subpackage,
              :stock_unit, :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :list_price, :tax_inclusive,
              :tax_rate, :tax_name, :tax_group_id, :mrp_pack_denomination, :list_price_pack_denomination,
              :self_batched, :lot_reference_id, :variant_reference_id, :item_reference_id, :vendor_name, :vendor_id,
              :expiry, :expiry_present, :total_cost, :unit_cost, :description, :store_id, :facility_id,
              :organisation_id, :unit_non_taxable_amount, :unit_taxable_amount, :transaction_id, :model_no,
              :sub_store_id, :sub_store_name, :unit_level, :net_unit_cost_without_tax, :margin, :purchase_tax_amount,
              :pr_net_unit_cost_without_tax, :remarks
            ],
            payment_received_breakups_attributes: [
              :amount, :currency_symbol, :currency_id, :date, :time, :received_by, :received_from, :mode_of_payment,
              :cash, :card, :card_number, :cheque_date, :cheque_note, :transfer_date, :transfer_note, :other_note,
              :paytm_transaction_id, :paytm_transaction_note, :gpay_transaction_id, :gpay_transaction_note,
              :phonepe_transaction_id, :phonepe_transaction_note, :is_settled
            ]
          )
  end

  def fetch_transactions
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, note: /#{Regexp.escape(query)}/i }
    options = options.merge(vendor_id: @vendor_id) if @vendor_id.present? && @vendor_id != 'all'
    if @start_date.present? && @end_date.present?
      options[:transaction_date] = { :$gte => @start_date, :$lte => @end_date }
    end
    @returns = Inventory::Transaction::VendorReturn.where(options).order_by(created_at: 'desc').skip(current_data_row)
                                                   .limit(30)
  end

  def fetch_purchase_transactions
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { vendor_location_id: params[:vendor_location_id], store_id: @store_id,
                purchase_display_id: /#{Regexp.escape(query)}/i, amount_remaining: 0 }
    if @start_date.present? && @end_date.present?
      options[:transaction_date] = { :$gte => @start_date, :$lte => @end_date }
    end
    @purchases = Inventory::Transaction::Purchase.where(options).order_by(created_at: 'desc').skip(current_data_row)
                                                 .limit(30)
  end

  def stock_report
    options = { :facility_ids.in => [current_facility.id], is_active: true }
    @all_user = User.where(options.merge(:inventory_store_ids.in => [params[:store_id]])).pluck(:fullname, :id)
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
  end

  def download_report
    @store = Inventory::Store.find_by(id: params[:store_id])
    @options = { store_id: params[:store_id], start_date: Time.parse(params['start_date'] + ' ' + params['start_time']),
                 end_date: Time.parse(params['end_date'] + ' ' + params['end_time']), user: params[:user_id] }
    @user = params[:user_id] == 'all_user' ? 'all_user' : User.find_by(id: params[:user_id]).fullname
    @address = @store.address
    @generate_on = "Generated On: #{Time.now.try(:strftime, '%R:%S')} | #{Time.now.strftime('%d %B %Y')} | #{Date.today.strftime('%A')}"
    @generate_by = "Generated By: #{@user&.titleize}"
  end

  def update_vendor_details
    vendor_location = Inventory::VendorLocation.find_by(id: @vendor_location_id)
    location_address = Inventory::PurchaseOrderHelper.po_vendor_location_address(vendor_location)
    @return_transaction.vendor_location_name = vendor_location.name
    @return_transaction.vendor_location_address = location_address
    @vendor = vendor_location.vendor
    vendor_address = Inventory::PurchaseOrderHelper.po_vendor_location_address(@vendor)
    @return_transaction.vendor_name = @vendor.name
    @return_transaction.vendor_address = vendor_address
    @return_transaction.vendor_gst_number = vendor_location.gst_number
    @return_transaction.vendor_dl_number = vendor_location.dl_number
  end
end
