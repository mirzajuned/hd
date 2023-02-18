class Inventory::Department::Item::LotsController < ApplicationController
  before_action :set_inventory_department_item_lot, only: [:show, :edit, :update, :destroy]
  before_action :authorize
  # GET /inventory/department/item/lots
  # GET /inventory/department/item/lots.json
  def index
    # fail
    @inventory_department_item = Inventory::Department::Item.find(params[:item_id])
    @inventory_department_item_lots = @inventory_department_item.lots.where(empty: false, is_deleted: false)
  end

  # GET /inventory/department/item/lots/1
  # GET /inventory/department/item/lots/1.json
  def show
  end

  # GET /inventory/department/item/lots/new
  def new
    @inventory_department_item_lot = Inventory::Department::Item::Lot.new
  end

  # GET /inventory/department/item/lots/1/edit
  def edit
  end

  # POST /inventory/department/item/lots
  # POST /inventory/department/item/lots.json
  def create
    @inventory_department_item_lot = Inventory::Department::Item::Lot.new(inventory_department_item_lot_params)

    respond_to do |format|
      if @inventory_department_item_lot.save
        format.html { redirect_to @inventory_department_item_lot, notice: 'Lot was successfully created.' }
        format.json { render action: 'show', status: :created, location: @inventory_department_item_lot }
      else
        format.html { render action: 'new' }
        format.json { render json: @inventory_department_item_lot.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /inventory/department/item/lots/1
  # PATCH/PUT /inventory/department/item/lots/1.json
  def update
    respond_to do |format|
      if @inventory_department_item_lot.update(inventory_department_item_lot_params)
        format.html { redirect_to @inventory_department_item_lot, notice: 'Lot was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @inventory_department_item_lot.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /inventory/department/item/lots/1
  # DELETE /inventory/department/item/lots/1.json
  def destroy
    @inventory_department_item_lot.destroy
    respond_to do |format|
      format.html { redirect_to inventory_department_item_lots_url }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_inventory_department_item_lot
    @inventory_department_item_lot = Inventory::Department::Item::Lot.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def inventory_department_item_lot_params
    params[:inventory_department_item_lot]
  end
end
