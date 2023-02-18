class Invoice::Inventories::DepartmentInvoicesController < ApplicationController
  before_action :set_invoice_inventory_department, only: [:show, :edit, :update, :destroy]

  # GET /invoice/inventory/departments
  # GET /invoice/inventory/departments.json
  def index
    facility_id = current_facility.id
    current_department = params[:current_department_id]
    @invoice_inventory_departments = Invoice::Inventories::DepartmentInvoice.where(facility_id: facility_id, current_department_id: current_department).order_by('created_at desc')
    # render json: @invoice_inventory_departments.as_json
  end

  # GET /invoice/inventory/departments/1
  # GET /invoice/inventory/departments/1.json
  def show; end

  # GET /invoice/inventory/departments/new
  def new
    @invoice_inventory_department = Invoice::Inventories::DepartmentInvoice.new
  end

  # GET /invoice/inventory/departments/1/edit
  def edit; end

  # POST /invoice/inventory/departments
  # POST /invoice/inventory/departments.json
  def create
    facility_id = current_facility.id
    items = params[:items]
    department_id = params[:current_department_id]
    @department_log = Invoice::Inventories::DepartmentInvoice.new(recipient: params[:recipient], note: params[:note], facility_id: facility_id, current_department_id: params[:current_department_id])
    total_price = 0
    if @department_log.save(validate: false)
      items.each do |key, value|
        department_item = Inventory::Department::Item.find_by(facility_id: facility_id, id: key, department_id: department_id)
        next if value.to_i > department_item.stock

        lots = department_item.lots.where(empty: false, is_deleted: false).order('expiry asc')
        quantity = value.to_i
        lots.each  do |lot|
          log_item = @department_log.items.new(create_department_log_item_params(department_item, lot))
          log_item.mrp = lot.mrp
          log_item.list_price = lot.list_price
          log_item.expiry = lot.expiry
          log_item.batch_no = lot.batch_no
          if log_item.save
            if quantity >= lot.stock
              log_item.update_attributes(quantity: lot.stock)
              quantity -= lot.stock
              lot.update_attributes(stock: 0, empty: true)
            elsif lot.stock > quantity
              log_item.update_attributes(quantity: quantity)
              lot.update_attributes(stock: lot.stock - quantity)
              quantity = lot.stock - quantity
              break
            end
          end
        end

        department_item.update_attributes(stock: department_item.calculate_stock, checkout_count: (department_item.checkout_count || 0) + 1)
      end

      q = @department_log.items.all.pluck(:quantity)
      m = @department_log.items.all.pluck(:mrp)
      total_price = q.zip(m).map { |i, j| i * j }.sum
      @department_log.update_attributes(total: total_price)
      print "Updated total price of log to #{@department_log.total}" if @department_log.save(validate: false)
    end
    respond_to do |format|
      format.json { render json: @department_log.as_json }
    end
  end

  # PATCH/PUT /invoice/inventory/departments/1
  # PATCH/PUT /invoice/inventory/departments/1.json
  def update
    respond_to do |format|
      if @invoice_inventory_department.update(invoice_inventory_department_params)
        format.html { redirect_to @invoice_inventory_department, notice: 'Department was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @invoice_inventory_department.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /invoice/inventory/departments/1
  # DELETE /invoice/inventory/departments/1.json
  def destroy
    @invoice_inventory_department.destroy
    respond_to do |format|
      format.html { redirect_to invoice_inventory_departments_url }
      format.json { head :no_content }
    end
  end

  def print_invoice
    log_id = params[:log_id]

    @organisation = current_user.organisation
    @department_log = Invoice::Inventories::DepartmentInvoice.find(log_id)
    render template: 'invoice/inventories/department_invoices/print_invoice', pdf: 'xyz', layout: 'invoice/inventory/departments/pdfgen.html.erb', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' }, viewport_size: '1280x1024'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_invoice_inventory_department
    @invoice_inventory_department = Invoice::Inventories::DepartmentInvoice.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def invoice_inventory_department_params
    params[:invoice_inventory_department]
  end

  def create_department_log_item_params(item, lot)
    objs = ActionController::Parameters.new(item.as_json.merge(lot.as_json))
    objs.permit(:barcode, :batch_no, :price, :mark_up, :mrp, :list_price, :vendor, :manufacturer, :expiry, :description)
  end
end
