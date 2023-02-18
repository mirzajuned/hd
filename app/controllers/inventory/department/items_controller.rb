class Inventory::Department::ItemsController < ApplicationController
  before_action :set_inventory_department_item, only: [:edit, :update, :destroy]
  before_action :authorize
  # GET /inventory/department/items
  # GET /inventory/department/items.json
  def index
    facility_id = current_facility.id
    organisation_id = current_user.organisation_id
    department = params[:department]
    @inventory_department_items = ::Inventory::Department::Item.where(facility_id: facility_id, department_id: department)
  end

  # GET /inventory/department/items/1
  # GET /inventory/department/items/1.json
  def show
    @inventory_item = Inventory::Department::Item.find(params[:id])
    @current_inventory = @inventory_item.department_id
  end

  # GET /inventory/department/items/new
  def new
    @inventory_department_item = Inventory::Department::Item.new
  end

  # GET /inventory/department/items/1/edit
  def edit
    puts params
    @item = Inventory::Item.find(params[:id])
  end

  # POST /inventory/department/items
  # POST /inventory/department/items.json
  def create
    @inventory_department_item = Inventory::Department::Item.new(inventory_department_item_params)

    respond_to do |format|
      if @inventory_department_item.save
        format.html { redirect_to @inventory_department_item, notice: 'Item was successfully created.' }
        format.json { render action: 'show', status: :created, location: @inventory_department_item }
      else
        format.html { render action: 'new' }
        format.json { render json: @inventory_department_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /inventory/department/items/1
  # PATCH/PUT /inventory/department/items/1.json
  def update
    respond_to do |format|
      if @inventory_department_item.update(inventory_department_item_params)
        format.html { redirect_to @inventory_department_item, notice: 'Item was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @inventory_department_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /inventory/department/items/1
  # DELETE /inventory/department/items/1.json
  def destroy
    @inventory_department_item.destroy
    respond_to do |format|
      format.html { redirect_to inventory_department_items_url }
      format.json { head :no_content }
    end
  end

  def update_cart
    facility_id = current_facility.id
    @inventory_item = Inventory::Department::Item.find(params[:item_id])
    @inventory_item.update(in_cart: params[:in_cart]) # true or false (boolean)
    @inventory_item_cart_count = Inventory::Department::Item.where(in_cart: true, is_deleted: false, facility_id: facility_id, department_id: params[:department_id], 'stock' => { '$gte' => 1 }).count
    respond_to do |format|
      format.json {}
    end
  end

  def log_request
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
  end

  def pharmacy_requests
    facility_id = current_facility.id
    @prescriptions = PatientPrescription.where(facility_id: facility_id, dispatched_from_pharmacy: false).order('encounterdate DESC')
    # render json: @prescriptions.as_json
    # render json: {"Hi": "Hello"}
    respond_to do |format|
      format.json
    end
  end

  def optical_requests
    facility_id = current_facility.id

    @prescriptions = PatientOpticalPrescription.where(:facility_id => facility_id, :dispatched_from_optical => false, :advise_glasses.in => [nil, "advise"]).order('encounterdate DESC')

    respond_to do |format|
      format.json
    end
  end

  def update_pharmacy_request
    @prescription = PatientPrescription.find(params[:id])
    @prescription.update_attributes(dispatched_from_pharmacy: params[:dispatched_from_pharmacy])
    InventoryJobs::PrescriptionDataJob.perform_later('pharmacy', @prescription.id.to_s)
    render json: @prescription.as_json
  end

  def update_optical_request
    @prescription = PatientOpticalPrescription.find(params[:id])
    @prescription.update_attributes(dispatched_from_optical: params[:dispatched_from_optical])
    InventoryJobs::PrescriptionDataJob.perform_later('optical', @prescription.id.to_s)
    render json: @prescription.as_json
  end

  def filter_type_items
    @department_id = params[:department_id]
    @category = params[:item_type]
    if params[:item_type] == 'out_stock'
      @items = Inventory::Department::Item.where(facility_id: current_facility.id, department_id: params[:department_id], stock: 0, is_deleted: false)
    elsif params[:item_type] == 'all_item'
      @items = Inventory::Department::Item.where(facility_id: current_facility.id, department_id: params[:department_id], is_deleted: false)
      if params[:department_id] == '50121007'
        @items = Inventory::Department::Item.where(facility_id: current_facility.id, department_id: params[:department_id], is_deleted: false)
        # @item1 = Inventory::Department::Item::Optical::Frame.where(facility_id: current_facility.id,is_deleted: false)
        # @item2 = Inventory::Department::Item::Optical::Contact.where(facility_id: current_facility.id,is_deleted: false)
        # @item3 = Inventory::Department::Item::Optical::Other.where(facility_id: current_facility.id,is_deleted: false)
        # @items = @item1+@item2+@item3
      end
    elsif params[:item_type] == 'frame'
      @items = Inventory::Department::Item::Optical::Frame.where(facility_id: current_facility.id, is_deleted: false)
    elsif params[:item_type] == 'contact'
      @items = Inventory::Department::Item::Optical::Contact.where(facility_id: current_facility.id, is_deleted: false)
    elsif params[:item_type] == 'other'
      @items = Inventory::Department::Item::Optical::Other.where(facility_id: current_facility.id, is_deleted: false)
    else
      @items = Inventory::Department::Item.where(facility_id: current_facility.id, department_id: params[:department_id], _type: 'Inventory::Department::Item::' + params[:item_type].capitalize, is_deleted: false)
    end
    # respond_to do |format|
    #   format.js {render '/inventory/filter_type_items.js.erb' }
    # end
  end

  def item_details
    if params[:department_id] == 'central'
      @item = Inventory::Item.find(params[:id])
      @category = @item.category
      @department_id = 'central'
    else
      @item = Inventory::Department::Item.find(params[:id])
      @category = @item._type.split('::')[3].downcase
      @department_id = @item.category
    end
    respond_to do |format|
      format.js {}
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_inventory_department_item
    @inventory_department_item = Inventory::Department::Item.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def inventory_department_item_params
    params[:inventory_department_item]
  end
end
