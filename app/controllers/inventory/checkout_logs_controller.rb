class Inventory::CheckoutLogsController < ApplicationController
  before_action :set_inventory_checkout_log, only: [:show, :edit, :update, :destroy]
  before_action :authorize
  # GET /inventory/checkout_logs
  # GET /inventory/checkout_logs.json
  def index
    facility_id = current_facility.id
    @inventory_checkout_logs = Inventory::CheckoutLog.where(facility_id: facility_id).newest_log_first.limit(10)
  end

  def show_more_checkout_log
    @count = params[:count]
    facility_id = current_facility.id
    @inventory_checkout_logs = Inventory::CheckoutLog.where(facility_id: facility_id).newest_log_first.skip(params[:count].to_i).limit(10)
    respond_to do |format|
      format.js {}
    end
  end

  # GET /inventory/checkout_logs/1
  # GET /inventory/checkout_logs/1.json
  def show
  end

  # GET /inventory/checkout_logs/new
  def new
    @inventory_checkout_log = Inventory::CheckoutLog.new
  end

  # GET /inventory/checkout_logs/1/edit
  def edit
  end

  # POST /inventory/checkout_logs
  # POST /inventory/checkout_logs.json
  def create
    @inventory_checkout_log = Inventory::CheckoutLog.new(inventory_checkout_log_params)

    respond_to do |format|
      if @inventory_checkout_log.save
        format.html { redirect_to @inventory_checkout_log, notice: 'Checkout log was successfully created.' }
        format.json { render action: 'show', status: :created, location: @inventory_checkout_log }
      else
        format.html { render action: 'new' }
        format.json { render json: @inventory_checkout_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /inventory/checkout_logs/1
  # PATCH/PUT /inventory/checkout_logs/1.json
  def update
    respond_to do |format|
      if @inventory_checkout_log.update(inventory_checkout_log_params)
        format.html { redirect_to @inventory_checkout_log, notice: 'Checkout log was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @inventory_checkout_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /inventory/checkout_logs/1
  # DELETE /inventory/checkout_logs/1.json
  def destroy
    @inventory_checkout_log.destroy
    respond_to do |format|
      format.html { redirect_to inventory_checkout_logs_url }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_inventory_checkout_log
    @inventory_checkout_log = Inventory::CheckoutLog.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def inventory_checkout_log_params
    params[:inventory_checkout_log]
  end
end
