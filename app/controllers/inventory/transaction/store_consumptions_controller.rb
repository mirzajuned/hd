class Inventory::Transaction::StoreConsumptionsController < ApplicationController
  before_action :set_store, only: [:index, :new]
  before_action :authorize, :verify_store
  before_action :fetch_lot_index, only: [:append_lots, :filter_lots]
  before_action :last_search_by, only: [:new, :edit]
  before_action :set_store_consumption_transaction, only: [:edit, :update, :approve, :cancel]

  def index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @time_period = params[:time_period]
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
    fetch_transactions
  end

  def new
    @store_consumption = Inventory::Transaction::StoreConsumption.new
    @lots = Inventory::Item::Lot.where(store_id: params[:store_id], :available_stock.gte => 1, stockable: true)
                                .is_active.limit(30)
  end

  def create
    @store_id = params[:inventory_transaction_store_consumption][:store_id]
    @start_date = @end_date = params[:inventory_transaction_store_consumption][:transaction_date]
    consumption_display_id = InventoryHelper.increment_and_create_store_consumption_transaction_number(current_organisation['_id'].to_s)
    @store_consumption_transaction = Inventory::Transaction::StoreConsumption.new(store_consumption_transaction_params)
    @store_consumption_transaction.consumption_display_id = consumption_display_id
    @negative_items = @store_consumption_transaction.items.negative_stock_items
    if @negative_items.blank?
      if @store_consumption_transaction.save!
        Inventory::Transactions::History::BlockedLot::CreateService.call(@store_consumption_transaction)
      end
      fetch_transactions
    else
      @inventory_store = Inventory::Store.find_by(id: @store_id)
      @lots = Inventory::Item::Lot.where(store_id: @store_id, :available_stock.gte => 1, stockable: true).is_active.limit(30)
      @adjust_transaction = Inventory::Transaction::StoreConsumption.new
      @errors = ['The stock is unavailable', 'Please make sure the item quatity is not more than available stock']
      render :item_stock_validation
    end
  end

  def show
    @store_consumption = Inventory::Transaction::StoreConsumption.find(params[:id])
  end

  def filter_lots; end

  def append_lots; end

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
      items = Inventory::Transaction::StoreConsumption.find_by(id: params[:transaction_id]).items
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
    @users = User.where(facility_ids: current_facility.id, is_active: true).pluck(:fullname, :id)

    @store_consumption = Inventory::Transaction::StoreConsumption.build
  end

  def edit
    @inventory_store = @store_consumption.store
    @store_id = @inventory_store.id
    @category = 'all_item'
    @lots = Inventory::Item::Lot.where(store_id: @store_id, :available_stock.gte => 1, stockable: true)
                                .is_active.limit(30)
    @users = User.where(facility_ids: current_facility.id, is_active: true).pluck(:fullname, :id)
    @items = @store_consumption.items
  end

  def update
    deleted_lots = @store_consumption.items.pluck(:lot_id).map(&:to_s)
    delete_lots(deleted_lots, @store_consumption) if deleted_lots.present?
    @store_consumption.items.delete_all
    if @store_consumption.update(store_consumption_transaction_params)
      Inventory::Transactions::History::BlockedLot::CreateService.call(@store_consumption)
      flash.now[:success] = 'updated'
    end
  end

  def approve
    if @store_consumption.status.open?
      if @store_consumption.set_approved(current_user)
        @store_consumption.update(status: :inprocess)
        InventoryJobs::Transactions::StoreConsumptionJob.perform_later(@store_consumption.id.to_s, current_user.id.to_s)
      end
      flash.now[:success] = 'approved'
    end
  end

  def cancel
    if @store_consumption.status.open?
      if @store_consumption.set_cancelled(current_user)
        Inventory::Transactions::History::BlockedLot::CancelService.call(@store_consumption)
      end
    end
  end

  private

  def fetch_transactions
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, note: /#{Regexp.escape(query)}/i }
    options[:transaction_date] = { :$gte => @start_date, :$lte => @end_date } if
                                   @start_date.present? && @end_date.present?
    @store_consumptions = Inventory::Transaction::StoreConsumption.where(options).order_by(created_at: 'desc')
                                                                  .skip(current_data_row).limit(30)
  end

  def fetch_lot_index
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @store_id)
    @sub_stores = @inventory_store.sub_stores
    @category = params[:item_type]
    @search_type = params[:search_type]
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, :available_stock.gte => 1, stockable: true }
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
    @search_by = Inventory::Transaction::StoreConsumption.last_search_by(current_user.id.to_s, current_facility.id.to_s, params[:store_id])
  end

  def set_store
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
  end

  def store_consumption_transaction_params
    params.require(:inventory_transaction_store_consumption)
          .permit(
            :note, :transaction_date, :entry_type, :entered_by, :user_id, :store_name, :store_id, :total_cost,
            :facility_id, :organisation_id, :department_name, :department_id, :adjusted_amount, :search_type,
            items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :variant_code, :item_id, :batch_no,
              :variant_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :_destroy,
              :search, :mark_up, :lot_id, :cost_price, :total_cost_price, :stock_package, :stock_subpackage, :model_no,
              :stock_unit, :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :list_price, :tax_inclusive,
              :tax_rate, :tax_name, :tax_group_id, :mrp_pack_denomination, :list_price_pack_denomination, :note,
              :self_batched, :lot_reference_id, :variant_reference_id, :item_reference_id, :vendor_name, :vendor_id,
              :expiry, :expiry_present, :total_cost, :unit_cost, :description, :store_id, :facility_id, :employee_id,
              :organisation_id, :unit_non_taxable_amount, :unit_taxable_amount, :sub_store_id, :employee_name,
              :sub_store_name, { lot_unit_ids: [] }
            ]
          )
  end

  def set_store_consumption_transaction
    @store_consumption = Inventory::Transaction::StoreConsumption.find_by(id: params[:id])
  end

  def delete_lots(ids, transaction)
    lot_blocked = Inventory::History::LotBlocked
                  .where(store_id: transaction.store_id, transaction_id: transaction.id,
                         transaction_type: transaction.class.to_s, :lot_id.in => ids)
    lot_blocked.each do |b_lot|
      lot = b_lot.lot
      lot.available_stock = lot.available_stock + b_lot.quantity
      lot.blocked_stock = lot.blocked_stock - b_lot.quantity
      lot.is_blocked = lot.blocked_stock != 0
      lot.update
    end
    lot_blocked.delete_all
  end
end
