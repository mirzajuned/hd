class Inventory::Item::DescriptionsController < ApplicationController
  before_action :set_inventory_item_description, only: [:show, :edit, :update, :destroy]
  before_action :authorize
  # GET /inventory/item/descriptions
  # GET /inventory/item/descriptions.json
  def index
    @inventory_item_descriptions = Inventory::Item::Description.all
  end

  # GET /inventory/item/descriptions/1
  # GET /inventory/item/descriptions/1.json
  def show
  end

  # GET /inventory/item/descriptions/new
  def new
    @inventory_item_description = Inventory::Item::Description.new
  end

  # GET /inventory/item/descriptions/1/edit
  def edit
  end

  # POST /inventory/item/descriptions
  # POST /inventory/item/descriptions.json
  def create
    @inventory_item_description = Inventory::Item::Description.new(inventory_item_description_params)

    respond_to do |format|
      if @inventory_item_description.save
        format.html { redirect_to @inventory_item_description, notice: 'Description was successfully created.' }
        format.json { render action: 'show', status: :created, location: @inventory_item_description }
      else
        format.html { render action: 'new' }
        format.json { render json: @inventory_item_description.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /inventory/item/descriptions/1
  # PATCH/PUT /inventory/item/descriptions/1.json
  def update
    respond_to do |format|
      if @inventory_item_description.update(inventory_item_description_params)
        format.html { redirect_to @inventory_item_description, notice: 'Description was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @inventory_item_description.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /inventory/item/descriptions/1
  # DELETE /inventory/item/descriptions/1.json
  def destroy
    @inventory_item_description.destroy
    respond_to do |format|
      format.html { redirect_to inventory_item_descriptions_url }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_inventory_item_description
    @inventory_item_description = Inventory::Item::Description.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def inventory_item_description_params
    params.require(:inventory_item_description).permit(:details, :manufacturer, :expiry)
  end
end
