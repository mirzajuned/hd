class Inventory::Transaction::StockOpeningsController < ApplicationController
  before_action :authorize, :verify_store
  before_action :set_store, only: [:index, :new, :new_lot]
  before_action :set_variant, only: [:add_lot, :new_lot]
  before_action :set_stock_opening, only: [ :show, :edit, :update, :approve, :cancel, :print ]

  def index
    @time_period = params[:time_period]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @store_id = params[:store_id]
    fetch_transactions
  end

  def new
    @store_id = params[:store_id]
    @category = 'all_item'
    fetch_variant_index
    @stock_opening = Inventory::Transaction::StockOpening.new
  end

  def create
    @store_id = params[:inventory_transaction_stock_opening][:store_id]
    bkp_stock_opening_display_id = InventoryHelper.increment_and_create_stock_opening_display_id(current_organisation['_id'].to_s)
    @stock_opening = Inventory::Transaction::StockOpening.new(stock_opening_params)
    @stock_opening.bkp_stock_opening_display_id = bkp_stock_opening_display_id
    @start_date = @end_date = params[:inventory_transaction_stock_opening][:transaction_date]
    @stock_opening.save!
    stock_opening_display_id = SequenceManagers::GenerateSequenceService.call(
                                  'son_transaction', @stock_opening.id.to_s,
                                  { organisation_id: current_organisation['_id'].to_s, 
                                    facility_id: current_facility['_id'].to_s, 
                                    region_id: current_facility['region_master_id'].to_s, 
                                    department_id: @stock_opening.department_id,
                                    entity_group_id: @stock_opening.store.try(:entity_group_id).to_s
                                  }
                                )
    @stock_opening.update(stock_opening_display_id: stock_opening_display_id)
    fetch_transactions
  end

  def edit
    @category = 'all_item'
    @stock_opening_items = @stock_opening.items
    @inventory_store = @stock_opening.store
    @store_id = @inventory_store.id
    fetch_variant_index
  end

  def update
    @stock_opening.update(stock_opening_params)
  end

  def show
    @inventory_store = Inventory::Store.find_by(id: @stock_opening.store_id)
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
    @stock_opening = Inventory::Transaction::StockOpening.build(item_params)
    @stock_opening_item = @stock_opening.items[0]
    @tax_group = TaxGroup.find(@item.tax_group_id)
    @tax_rate_details = @tax_group.tax_rate_details
                                  .collect { |tax_rate| tax_rate.merge(type: TaxRate.find(tax_rate[:_id]).type) }
  end

  def filter_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @time_period = params[:time_period]
    fetch_transactions
  end

  def append_index
    @store_id = params[:store_id]
    fetch_transactions
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

  def approve
    if @stock_opening.status_open?
      if @stock_opening.set_approved(current_user)
        InventoryJobs::Transactions::StockUpdateJob
          .perform_later(@stock_opening.id.to_s, current_user.id.to_s, 'Stock Opening')
      end
    end
  end

  def cancel
    @stock_opening.update!(status: 'cancelled', cancelled_reason: params[:cancelled_reason], 
      cancelled_by_name: current_user.fullname, cancelled_on: Time.current) if @stock_opening.status_open?
  end

  def print
    @inventory_store = @stock_opening.store
    html_template = 'inventory/transaction/stock_openings/print.html.erb'
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

  def set_variant
    @variant = Inventory::Item::Variant.find_by(id: params[:variant_id])
  end

  def fetch_transactions
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, is_deleted: false, document_number: /#{Regexp.escape(query)}/i }
    if @start_date.present? && @end_date.present?
      options[:transaction_date] = { :$gte => @start_date, :$lte => @end_date }
      @start_date = Date.parse(@start_date).strftime('%Y-%m-%d')
      @end_date = Date.parse(@end_date).strftime('%Y-%m-%d')
    end
    @stock_openings = Inventory::Transaction::StockOpening.where(options)
                        .order_by(created_at: 'desc').skip(current_data_row)
                        .limit(30)
  end

  def fetch_variant_index
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    if (@category.include? 'all_item') || @category_id.blank? #for store item index
      category_ids = @inventory_store.category_ids
      options = { :category_id.in => category_ids }
    end
    options = options.merge!(store_id: @store_id, stockable: true, search: /#{Regexp.escape(query)}/i)
    @variants = Inventory::Item::Variant.where(options).is_active
                  .order_by(created_at: 'desc').skip(current_data_row).limit(30).includes(:item)
    @variants = @variants.select { |variant| variant.item&.tax_group_id.present? }
  end

  def stock_opening_params
    params.require(:inventory_transaction_stock_opening)
          .permit(
            :note, :transaction_date, :entry_type, :entered_by, :user_id, :store_id,
            :total_cost, :facility_id, :organisation_id, :mode_of_payment, :comments, :discount, :net_amount,
            :amount_remaining, :credit_adjustment, :debit_amount, :extra_amount_paid, :department_id,
            :department_name, { purchase_order_ids: [] }, :transaction_time,
            :document_number, :taxable_amount,
            { tax_breakup: [:_id, :name, :amount, :tax_rate, :tax_type, :taxable_amount] },
            items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :default_variant_code, :item_id,
              :default_variant_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :_destroy,
              :search, :mark_up, :batch_no, :cost_price, :total_cost_price, :stock_package, :stock_subpackage,
              :stock_unit, :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :list_price, :tax_inclusive,
              :tax_rate, :tax_name, :tax_group_id, :mrp_pack_denomination, :list_price_pack_denomination, :self_batched,
              :expiry, :expiry_present, :total_cost, :unit_cost, :description, :store_id, :facility_id, :system_generated_barcode,
              :item_reference_id, :organisation_id, :unit_non_taxable_amount, :unit_taxable_amount, :barcode_id, :model_no,
              :unit_cost_without_tax, :purchase_tax_amount, :unit_purchase_tax_amount, :item_cost_without_tax, :id,
              :sub_store_id, :sub_store_name, :department_id, :department_name, { tax_group: [:_id, :name, :amount] }
            ]
          )
  end

  def item_params
    params.require(:item).permit!
  end

  def set_stock_opening
    @stock_opening = Inventory::Transaction::StockOpening.find_by(id: params[:id])
  end
end
