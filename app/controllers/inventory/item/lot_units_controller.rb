class Inventory::Item::LotUnitsController < ApplicationController
  before_action :authorize, :verify_store
  before_action :set_inventory_lot_unit, only: [:show, :edit, :update, :destroy]
  before_action :fetch_lot_unit_index, only: [:index, :filter_index, :append_index, :update]

  def index; end

  def filter_index; end

  def append_index; end

  def show
    @lot_units = Inventory::Audit::History.where(lot_id: params[:id]).order_by(created_at: 'desc')
  end

  def edit; end

  def update
    @lot_unit = Inventory::Item::LotUnit.find_by(id: params[:id])
    barcode_id = params[:inventory_lot_unit][:barcode_id]
    if (@lot_unit.barcode_id != barcode_id) && barcode_id.present?
      barcode_id = Inventory::Lots::GenerateBarCodeService.call(barcode_id)
      @lot_unit.update!(barcode_id: barcode_id.data, system_generated_barcode: false)
    end
  end

  private

  def set_inventory_lot_unit
    @inventory_lot_unit = Inventory::Item::LotUnit.find_by(id: params[:id])
  end

  def fetch_lot_unit_index
    @lot_type = params[:lot_type]
    current_data_row = params[:total_count_row].to_i
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @default_days = Inventory::Store.find_by(id: params[:store_id]).days_before_expired.to_i
    query = params[:q].to_s
    @expiry_time = params[:expiry_time]
    options = { store_id: params[:store_id], search: /#{Regexp.escape(query)}/i }
    options = options.merge!(sub_store_id: params[:lot_type_id]) if params[:lot_type_id].present?
    if @expiry_time.present?
      days_before_expired = if @expiry_time == 'one_month'
                              30
                            elsif @expiry_time == 'two_months'
                              60
                            elsif @expiry_time == 'three_months'
                              90
                            else
                              @default_days
                            end
      options = options.merge('expiry' => { '$lte' => Date.current + days_before_expired })
    end
    @lot_units = Inventory::Item::LotUnit.where(options).is_active.order_by(created_at: 'desc').skip(current_data_row)
                                         .limit(30)
    fetch_sub_stores
  end

  def fetch_sub_stores
    @sub_stores = @inventory_store.sub_stores.pluck(:name, :id)
  end
end
