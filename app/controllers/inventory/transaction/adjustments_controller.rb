class Inventory::Transaction::AdjustmentsController < ApplicationController
  include Inventory::ItemsHelper
  before_action :authorize, :verify_store
  before_action :fetch_lot_index, only: [:append_lots, :filter_lots]
  before_action :last_search_by, only: [:new]

  def index
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @time_period = params[:time_period]
    fetch_transactions
  end

  def new
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @lots = Inventory::Item::Lot.where(store_id: params[:store_id], :available_stock.gt => 0.0, stockable: true)
                                .is_active.limit(30)
    @adjust_transaction = Inventory::Transaction::Adjustment.new
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
      lot_id = lot_unit.lot_id
    else
      lot_id = params[:lot_id]
    end
    if params[:embedded_item_id].present?
      items = Inventory::Transaction::Adjustment.find_by(id: params[:transaction_id]).items
      items.find_by(id: params[:embedded_item_id]).delete
    end
    @lot = Inventory::Item::Lot.find_by(id: lot_id)
    @variant = Inventory::Item::Variant.find_by(id: @lot.variant_id)
    @item = Inventory::Item.find_by(id: @lot.item_id)
    if params[:item].present?
      lot_unit = params[:item].values.pluck(:lot_unit_id, :lot_unit_checked)
      @lot_units = check_lot_unit(lot_unit)
    elsif params[:is_lot_unit].present?
      @lot_units = [lot_unit.id.to_s]
    end

    @adjust_transaction = Inventory::Transaction::Adjustment.build
  end

  def create
    @store_id = params[:inventory_transaction_adjustment][:store_id]
    @start_date = @end_date = params[:inventory_transaction_adjustment][:transaction_date]
    bkp_adjustment_display_id = InventoryHelper.increment_and_create_adjustment_transaction_number(current_organisation['_id'])
    @adjustment_transaction = Inventory::Transaction::Adjustment.new(adjustment_transaction_params)
    @adjustment_transaction.bkp_adjustment_display_id = bkp_adjustment_display_id
    @negative_items = @adjustment_transaction.items.negative_stock_items
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    if @negative_items.blank?
      if @adjustment_transaction.save!
        # adjustment_display_id = SequenceManagers::GenerateSequenceService.call(
        #                     'stock_adjustment', @adjustment_transaction,
        #                     { organisation_id: current_organisation['_id'].to_s, 
        #                         facility_id: current_facility['_id'].to_s, 
        #                         region_id: current_facility['region_master_id'].to_s, 
        #                         department_id: @adjustment_transaction.try(:department_id),
        #                         entity_group_id: @inventory_store.try(:entity_group_id).to_s
        #                     })
        @adjustment_transaction.update(adjustment_display_id: "ABGVF123")
        Inventory::Transactions::Adjustment::UpdateStockService.call(@adjustment_transaction, current_user.id)
      end
      fetch_transactions
    else
      @lots = Inventory::Item::Lot.where(store_id: @store_id, :available_stock.gt => 0.0, stockable: true).is_active.limit(30)
      @adjust_transaction = Inventory::Transaction::Adjustment.new
      @errors = ['The stock is unavailable', 'Please make sure the item quatity is not more than available stock']
      render :item_stock_validation
    end  
  end

  def append_lots; end

  def filter_lots; end

  def filter_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_transactions
  end

  def append_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_transactions
  end

  def show
    @adjustment = Inventory::Transaction::Adjustment.find(params[:id])

  end

  def report
    options = { :facility_ids.in => [current_facility.id], is_active: true }
    @all_user = User.where(options.merge(:inventory_store_ids.in => [params[:store_id]])).pluck(:fullname, :id)
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @inventory_store = Inventory::Store.find(params[:store_id])
  end

  def download_data
    store = Inventory::Store.find(params[:store_id])
    options = { store_id: params[:store_id], start_date: Time.parse(params['start_date'] + ' ' + params['start_time']),
                end_date: Time.parse(params['end_date'] + ' ' + params['end_time']), user: params[:user_id] }
    user = params[:user_id] == 'all_user' ? 'all_user' : User.find(params[:user_id]).fullname
    @store_name = "#{store.name} Adjustment Report"
    @address = store.address
    @time_period = "Detailed Adjustment Report For a Period of #{params[:start_date]} #{params[:start_time]} to #{params[:end_date]} #{params[:end_time]}"
    @generate_on = "Generated On: #{Time.now.try(:strftime, '%R:%S')} | #{Time.now.strftime('%d %B %Y')} | #{Date.today.strftime('%A')}"
    @generate_by = "Generated By: #{user&.titleize}"
    @filename = "#{store.name.squish&.titleize&.tr(' ', '_')}_#{Time.now.strftime('%d %B %Y')}_#{Time.now.try(:strftime, '%R:%S')}_#{user.squish&.titleize&.tr(' ', '_')}_receive_report"
    @data_array = Inventory::Transactions::DownloadAdjustmentService.call(options, params[:department_id], params[:user_id])
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}.xlsx\"" }
    end
  end

  private

  def adjustment_transaction_params
    params.require(:inventory_transaction_adjustment)
          .permit(
            :note, :transaction_date, :entry_type, :entered_by, :user_id, :store_name, :store_id, :total_cost,
            :facility_id, :organisation_id, :department_name, :department_id, :adjusted_amount, :search_type,
            items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :variant_code, :item_id, :lot_id,
              :variant_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :_destroy,
              :search, :mark_up, :batch_no, :cost_price, :total_cost_price, :stock_package, :stock_subpackage,
              :stock_unit, :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :list_price, :tax_inclusive,
              :tax_rate, :tax_name, :tax_group_id, :mrp_pack_denomination, :list_price_pack_denomination,
              :self_batched, :lot_reference_id, :variant_reference_id, :item_reference_id, :vendor_name, :vendor_id,
              :expiry, :expiry_present, :total_cost, :unit_cost, :description, :store_id, :facility_id,
              :organisation_id, :unit_non_taxable_amount, :unit_taxable_amount, :model_no, :sub_store_id, :item_entry_type,
              :sub_store_name, { lot_unit_ids: [] }
            ]
          )
  end

  def fetch_transactions
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, note: /#{Regexp.escape(query)}/i }
    options[:transaction_date] = { :$gte => @start_date, :$lte => @end_date } if
                                   @start_date.present? && @end_date.present?
    @adjustments = Inventory::Transaction::Adjustment.where(options).order_by(created_at: 'desc').skip(current_data_row)
                                                     .limit(30)
  end

  def fetch_lot_index
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @store_id)
    @sub_stores = @inventory_store.sub_stores
    @category = params[:item_type]
    @search_type = params[:search_type]
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
      lots = Inventory::Item::Lot.where(options).where(barcode_id: query).is_active.skip(current_data_row)
                                 .limit(30)
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

  def last_search_by
    @search_by = Inventory::Transaction::Adjustment.last_search_by(current_user.id.to_s, current_facility.id.to_s, params[:store_id])
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
end
