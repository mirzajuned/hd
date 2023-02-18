class Inventory::Transaction::DirectStocksController < ApplicationController
  before_action :authorize, :verify_store
  before_action :set_store, only: [:index, :new, :new_lot]
  before_action :set_variant, only: [:add_lot, :new_lot]
  before_action :find_direct_stock, only: [:edit, :update, :show, :approve, :cancel, :print]

  def index
    @time_period = params[:time_period]
    append_index
  end

  def new
    @store_id = params[:store_id]
    @category = 'all_item'
    fetch_variant_index
    @vendor_location = Inventory::VendorLocation.find_by(id: params[:vendor_location_id])
    @vendor = @vendor_location.vendor
    address = []
    address << @vendor_location&.address << @vendor_location&.city << @vendor_location&.district << @vendor_location&.state << @vendor_location&.pincode
    address = address.reject(&:blank?)&.join(', ')
    vendor_name = @vendor_location&.name
    @vendor_location_address = vendor_name ? "#{vendor_name} #{"- #{address}"}" : '-'
    @direct_stock = Inventory::Transaction::DirectStock.new()
  end

  def create
    @store_id = params[:inventory_transaction_direct_stock][:store_id]
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    direct_stock_display_id = InventoryHelper.increment_and_create_direct_stock_display_id(current_organisation['_id'].to_s)
    @direct_stock = Inventory::Transaction::DirectStock.new(direct_stock_params)
    @direct_stock.direct_stock_display_id = direct_stock_display_id
    @start_date = @end_date = params[:inventory_transaction_direct_stock][:transaction_date]
    fetch_transactions
    @direct_stock.save!
  end

  def edit
    @inventory_store = @direct_stock.store
    @store_id = @inventory_store.id
    @category = 'all_item'
    @direct_stock_items = @direct_stock.items
    @vendor_location = Inventory::VendorLocation.find_by(id: @direct_stock.vendor_location_id)
    @vendor = @vendor_location.vendor
    address = []
    address << @vendor_location&.address << @vendor_location&.city << @vendor_location&.district << @vendor_location&.state << @vendor_location&.pincode
    address = address.reject(&:blank?)&.join(', ')
    vendor_name = @vendor_location&.name
    @vendor_location_address = vendor_name ? "#{vendor_name} #{"- #{address}"}" : '-'
    fetch_variant_index
  end

  def update
    @direct_stock.update(direct_stock_params)
  end

  def show; end

  def filter_index
    @time_period = params[:time_period]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @store_id = params[:store_id]
    fetch_transactions
  end

  def append_index
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @store_id = params[:store_id]
    fetch_transactions
  end

  def new_lot
    @variant_id = params[:variant_id]
    @variant_name = params[:variant_name]
    @item = Inventory::Item.find_by(id: @variant.item_id)
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @sub_stores = Inventory::SubStore.where(store_id: @inventory_store.id, is_deleted: false).pluck(:name, :id)
  end

  def add_lot
    @item = Inventory::Item.find_by(id: @variant.item_id)
    @direct_stock = Inventory::Transaction::DirectStock.build(item_params)
    @direct_stock_item = @direct_stock.items[0]
    @tax_group = TaxGroup.find(@item.tax_group_id)
    @tax_rate_details = @tax_group.tax_rate_details
                                  .collect { |tax_rate| tax_rate.merge(type: TaxRate.find(tax_rate[:_id]).type) }
  end

  def append_variants
    @store_id = params[:store_id]
    @category = params[:item_type]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    fetch_variant_index
  end

  def filter_variants
    @store_id = params[:store_id]
    @category = params[:item_type]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    fetch_variant_index
  end

  def vendor_list
    category_ids = Inventory::Store.find_by(id: params[:store_id])&.category_ids
    vendor_ids = Inventory::Vendor.where(:category_ids.in => category_ids, is_deleted: false).pluck( :id)
    @vendor_locations = Inventory::VendorLocation.where(:vendor_id.in => vendor_ids)
  end

  def approve
    if @direct_stock.status_open?
      if @direct_stock.set_approved(current_user)
        InventoryJobs::Transactions::StockUpdateJob
          .perform_later(@direct_stock.id.to_s, current_user.id.to_s, 'Direct Stock')
      end
    end
  end

  def cancel
    @direct_stock.set_cancelled(current_user) if @direct_stock.status_open?
  end

  def print
    @inventory_store = @direct_stock.store
    html_template = 'inventory/transaction/direct_stocks/print.html.erb'
    orientation = params[:page_size] == 'A5' ? 'Landscape' : 'Portrait'
    render template: html_template, pdf: 'son', layout: 'invoice/inventory/pdfgen.html.erb',
           viewport_size: '1280x1024', page_size: 'A4', orientation: orientation,
           show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' },
           locals: { mail_job: false }
  end

  private

  def set_store
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
  end

  def fetch_variant_index
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { search: /#{Regexp.escape(query)}/i, stockable: true, store_id: @store_id }
    if (@category.include? 'all_item') || @category.blank?
      vendor_location_id = Inventory::VendorLocation.find_by(id: params[:vendor_location_id])&.vendor_id
      vendor_id = vendor_location_id || @vendor&.id
      vendor_category_ids = Inventory::Vendor.find_by(id: vendor_id)&.category_ids || []
      store_category_ids = @inventory_store.category_ids || []
      category_ids = vendor_category_ids & store_category_ids
      options = options.merge(organisation_id: current_user.organisation_id, :category_id.in => category_ids)
    end
    @variants = Inventory::Item::Variant.where(options).is_active
                                        .order_by(created_at: 'desc').skip(current_data_row)
                                        .limit(30).includes(:item)
    @variants = @variants.select { |variant| variant.item.tax_group_id.present? }
  end

  def fetch_transactions
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, is_deleted: false, vendor_name: /#{Regexp.escape(query)}/i }
    if @start_date.present? && @end_date.present?
      options[:transaction_date] = { :$gte => @start_date, :$lte => @end_date }
      @start_date = Date.parse(@start_date).strftime('%Y-%m-%d')
      @end_date = Date.parse(@end_date).strftime('%Y-%m-%d')
    end
    @direct_stocks = Inventory::Transaction::DirectStock.where(options)
                                                        .order_by(created_at: 'desc').skip(current_data_row)
                                                        .limit(30)
  end

  def item_params
    params.require(:item).permit!
  end

  def direct_stock_params
    params.require(:inventory_transaction_direct_stock)
          .permit(
            :note, :transaction_date, :entry_type, :entered_by, :user_id, :store_id,
            :total_cost, :facility_id, :organisation_id, :mode_of_payment, :comments, :discount, :net_amount,
            :amount_remaining, :credit_adjustment, :debit_amount, :extra_amount_paid, :department_id,
            :department_name, { purchase_order_ids: [] }, :transaction_time, :taxable_amount, :vendor_id,
            :vendor_name, :bill_type, :challan_date, :challan_number, :bill_number, :bill_date, :vendor_location_id,
            :vendor_address, :vendor_location_address, :vendor_location_name,
            { tax_breakup: [:_id, :name, :amount, :tax_rate, :tax_type, :taxable_amount] },
            items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :default_variant_code, :item_id,
              :default_variant_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :_destroy,
              :search, :mark_up, :batch_no, :cost_price, :total_cost_price, :stock_package, :stock_subpackage,
              :stock_unit, :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :list_price, :tax_inclusive,
              :tax_rate, :tax_name, :tax_group_id, :mrp_pack_denomination, :list_price_pack_denomination, :self_batched,
              :expiry, :expiry_present, :total_cost, :unit_cost, :description, :store_id, :facility_id,
              :system_generated_barcode, :item_reference_id, :organisation_id, :unit_non_taxable_amount,
              :unit_taxable_amount, :barcode_id, :model_no, :unit_cost_without_tax, :purchase_tax_amount,
              :unit_purchase_tax_amount, :item_cost_without_tax, :id, :sub_store_id, :sub_store_name, :department_id,
              :department_name, { tax_group: [:_id, :name, :amount] }
            ]
          )
  end

  def set_variant
    @variant = Inventory::Item::Variant.find_by(id: params[:variant_id])
  end

  def find_direct_stock
    @direct_stock = Inventory::Transaction::DirectStock.find_by(id: params[:id])
  end
end
