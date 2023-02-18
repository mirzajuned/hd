class Inventory::Item::StocksController < ApplicationController
  before_action :set_inventory_item_stock, only: [:show, :edit, :update, :destroy]
  before_action :authorize
  # GET /inventory/item/stocks
  # GET /inventory/item/stocks.json
  def index
    @inventory_item_stocks = Inventory::Item::Stock.all
  end

  # GET /inventory/item/stocks/1
  # GET /inventory/item/stocks/1.json
  def show
  end

  # GET /inventory/item/stocks/new
  def new
    @inventory_item_stock = Inventory::Item::Stock.new
  end

  # GET /inventory/item/stocks/1/edit
  def edit
  end

  # POST /inventory/item/stocks
  # POST /inventory/item/stocks.json
  def create
    @inventory_item_stock = Inventory::Item::Stock.new(inventory_item_stock_params)

    respond_to do |format|
      if @inventory_item_stock.save
        format.html { redirect_to @inventory_item_stock, notice: 'Stock was successfully created.' }
        format.json { render action: 'show', status: :created, location: @inventory_item_stock }
      else
        format.html { render action: 'new' }
        format.json { render json: @inventory_item_stock.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /inventory/item/stocks/1
  # PATCH/PUT /inventory/item/stocks/1.json
  def update
    respond_to do |format|
      if @inventory_item_stock.update(inventory_item_stock_params)
        format.html { redirect_to @inventory_item_stock, notice: 'Stock was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @inventory_item_stock.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /inventory/item/stocks/1
  # DELETE /inventory/item/stocks/1.json
  def destroy
    @inventory_item_stock.destroy
    respond_to do |format|
      format.html { redirect_to inventory_item_stocks_url }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_inventory_item_stock
    @inventory_item_stock = Inventory::Item::Stock.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def inventory_item_stock_params
    params.require(:inventory_item_stock).permit(:unit_price, :quantity)
  end
end
