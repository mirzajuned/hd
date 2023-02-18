class Inventory::Department::RequestLogsController < ApplicationController
  before_action :set_inventory_department_request_log, only: [:show, :edit, :update, :destroy]
  before_action :authorize
  # GET /inventory/department/request_logs
  # GET /inventory/department/request_logs.json
  def index
    # status = params[:show]
    # if status == 'pending'
    facility_id = current_facility.id
    @inventory_department_request_logs = Inventory::Department::RequestLog.where(facility_id: facility_id, status: -1)
    # end
    # p @inventory_department_request_logs
    # @inventory_department_request_logs
  end

  # GET /inventory/department/request_logs/1
  # GET /inventory/department/request_logs/1.json
  def show
    facility_id = current_facility.id
    @inventoryitems = Inventory::Item.where(facility_id: facility_id, is_deleted: false)
    @department_name = Inventory::Department.find_by(department_id: @inventory_department_request_log.department).name
  end

  # GET /inventory/department/request_logs/new
  def new
    @inventory_department_request_log = Inventory::Department::RequestLog.new
    @current_inventory = params[:current_inventory]
  end

  # GET /inventory/department/request_logs/1/edit
  def edit
  end

  # POST /inventory/department/request_logs
  # POST /inventory/department/request_logs.json
  def create
    facility_id = current_facility.id
    note = params[:note]
    department = params[:department]
    items = params[:items]
    i = 0
    j = 0
    for key, value in items
      i = i + 1
      pair = key.split("<->")
      item_name = pair[0]
      if item_name.present?
        j = j + 1
      end
    end

    unless j == 0

      @request_log = Inventory::Department::RequestLog.new(department: department, note: note, facility_id: facility_id)

      if @request_log.save!
        for key, value in items
          pair = key.split("<->")
          item_name = pair[0]
          item_id = pair[1]
          # puts "#{value} -- #{key} -- #{item_id} -- #{item_name}"
          # puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
          if item_name.present?
            central_item_id = Inventory::Item.find_by(description: item_name.split(" (")[0], facility_id: facility_id)
            if central_item_id
              item = @request_log.items.new(name: item_name, inventory_item_id: central_item_id.id.to_s, quantity: value.to_i)
            else
              item = @request_log.items.new(name: item_name, quantity: value.to_i)
            end
            if item.save!
              # puts "#{item}"
            end
          end
        end
        p @request_log
      end

    end

    if item.present?
      respond_to do |format|
        format.json { render json: @request_log }
      end
    else
      respond_to do |format|
        format.js { render js: "notice = new PNotify({ title: 'Error', text: 'Error Checking Out Items', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end
    end

    #
    # @inventory_department_request_log = Inventory::Department::RequestLog.new(inventory_department_request_log_params)
    #
    # respond_to do |format|
    #   if @inventory_department_request_log.save
    #     format.html { redirect_to @inventory_department_request_log, notice: 'Request log was successfully created.' }
    #     format.json { render action: 'show', status: :created, location: @inventory_department_request_log }
    #   else
    #     format.html { render action: 'new' }
    #     format.json { render json: @inventory_department_request_log.errors, status: :unprocessable_entity }
    #   end
    # end
  end

  # PATCH/PUT /inventory/department/request_logs/1
  # PATCH/PUT /inventory/department/request_logs/1.json
  def update
    respond_to do |format|
      if @inventory_department_request_log.update(inventory_department_request_log_params)
        format.html { redirect_to @inventory_department_request_log, notice: 'Request log was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @inventory_department_request_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /inventory/department/request_logs/1
  # DELETE /inventory/department/request_logs/1.json
  def destroy
    facility_id = current_facility.id
    if @inventory_department_request_log.update(status: 2) # soft deleted
      @inventory_department_request_logs = Inventory::Department::RequestLog.where(facility_id: facility_id, status: -1)
      @items = Inventory::Item.where(facility_id: facility_id, is_deleted: false)
      @allCount = @items.count
      @title = 'Central Inventory'
      @out_stock_count = @items.where(stock: 0).count

      @inventory_item_cart_count = @items.where(in_cart: true).count
    end

    respond_to do |format|
      format.js { render action: 'destroy' }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_inventory_department_request_log
    @inventory_department_request_log = Inventory::Department::RequestLog.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def inventory_department_request_log_params
    # params[:inventory_department_request_log]
    params.permit(:status)
  end
end
