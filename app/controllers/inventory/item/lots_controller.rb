class Inventory::Item::LotsController < ApplicationController
  before_action :authorize, :verify_store
  before_action :set_inventory_item_lot, only: [:show, :edit, :update, :destroy]
  before_action :fetch_lot_index, only: [:index, :filter_index, :append_index, :update, :block_lot, :unblock_lot]
  before_action :find_lot, only: [:update, :block_lot, :unblock_lot]

  def index; end

  def filter_index; end

  def append_index; end

  def show
    @lots = Inventory::Audit::History.where(lot_id: params[:id]).order_by(created_at: 'desc')
    check_lot_transfer = Inventory::Transaction::Transfer.where(status: 0, :'items.lot_id' => BSON::ObjectId(params[:id])).count
    check_lot_order = Invoice::InventoryOrder.where(:'items.lot_id' => BSON::ObjectId(params[:id]), delivered: false, :status.ne => 2).count
    @disable_block_lot = (check_lot_transfer + check_lot_order) > 0
  end

  def new
    @inventory_item = Inventory::Item.find_by(id: params[:item_id])
  end

  def edit
    @inventory_lot = Inventory::Item::Lot.find_by(id: params[:id])
    @lot_histories = Inventory::Audit::History.where(lot_id: params[:id], flow: "Out")
    old_lot_ids = @inventory_lot.old_lot_ids
    @total_old_transactions = 0
    old_lot_ids.each do |lot_id|
      lots = Inventory::Audit::History.where(lot_id: lot_id, transaction_type: 'Invoice')
      @total_old_transactions += lots&.size
    end
  end

  def create
    @current_inventory = '334046963'
    @facilityid = current_facility.id
    @inventory_item = Inventory::Item.find_by(id: params[:inventory_item][:item_id])
    self_batched = false # flag to check later

    if params[:inventory_item][:lots][:batch_no]
      if params[:inventory_item][:lots][:batch_no].empty?
        batch_no = Inventory::ItemsHelper.increment_and_create_batch_no(@inventory_item.id, @facilityid)
        # puts "Batch number is #{batch_no}"
        self_batched = true
      else
        batch_no = params[:inventory_item][:lots][:batch_no]
      end
    end

    @inventory_item_lot = @inventory_item.lots.new(inventory_item_lot_params(@inventory_item.category))
    @inventory_item_lot.batch_no = batch_no
    @inventory_item_lot.self_batched = self_batched
    @inventory_item_lot.generic_display_name = @inventory_item.generic_display_name
    @inventory_item_lot.generic_display_ids = @inventory_item.generic_display_ids     

    @inventory_department_request_logs = Inventory::Department::RequestLog.where(facility_id: @facilityid, status: -1)
    @items = Inventory::Item.where(facility_id: @facilityid, is_deleted: false).limit(20)
    @allCount = @items.count # After saving the item counts going to be increased
    @title = 'Central Inventory'
    @out_stock_count = @items.where(stock: 0).count

    respond_to do |format|
      if @inventory_item_lot.save
        if @inventory_item.inventory_capacity
          capacity = 0
          @inventory_item.lots.where(is_deleted: false).each { |lot| capacity += lot.stock }
          @inventory_item.inventory_capacity = capacity
        end
        @inventory_item.stock = @inventory_item.calculate_stock
        @inventory_item.update

        format.js { render action: 'create' }
      else
        format.js { render action: 'new' }
      end
    end
  end

  def update
    lot_units = Inventory::Item::LotUnit.where(lot_id: @lot.id)
    barcode_id = params[:inventory_lot][:barcode_id]
    if @lot.list_price.to_f != params[:inventory_lot][:list_price]&.to_f
      new_lot = Inventory::Item::Lot.new(@lot.attributes.except(:_id, :updated_at, :created_at, :list_price,
                                                                :reference_id, :unit_non_taxable_amount,
                                                                :unit_taxable_amount))
      new_lot.comment = 'price adjust'
      new_lot.old_lot_id = @lot.id
      new_lot.old_lot_ids << @lot.id.to_s
      new_lot.list_price = params[:inventory_lot][:list_price]
      new_lot.reference_id = new_lot.id
      check_taxable_amount
      new_lot.unit_taxable_amount = @unit_taxable_amount
      new_lot.unit_non_taxable_amount = @unit_non_taxable_amount
      if (@lot.barcode_id != barcode_id) && barcode_id.present?
        barcode_id = Inventory::Lots::GenerateBarCodeService.call(barcode_id)
        new_lot.barcode_id = barcode_id.data
        new_lot.system_generated_barcode = false
        @lot.update(barcode_id: barcode_id.data, system_generated_barcode: false)
      end
      if new_lot.save!
        Inventory::Audit::History::CreateService.call(
          0, new_lot, @lot.transaction_type, @lot.transaction_id.to_s, current_user.id.to_s
        )
        InventoryJobs::Transactions::Lot::CreateLotUnitJob.perform_later(new_lot.id.to_s) if @lot.unit_level
      end
      @lot.update(stock: 0, total_cost: 0.0, empty: true, available_stock: 0)
      lot_units.update_all(available_stock: 0, stock: 0)
    end
    return unless barcode_id.present?

    if (barcode_id != @lot.barcode_id) && (params[:inventory_lot][:list_price]&.to_f == @lot.list_price.to_f)
      barcode_id = Inventory::Lots::GenerateBarCodeService.call(barcode_id)
      @lot.update(barcode_id: barcode_id.data, system_generated_barcode: false)
    end
  end

  def destroy
    @current_inventory = '334046963'
    current_inventory = '334046963'
    @inventory_item = Inventory::Item.find_by(id: @inventory_item_lot.item_id)
    if @inventory_item_lot.update(is_deleted: true)
      @inventory_item.update(in_cart: false) if @inventory_item.in_cart
      if @inventory_item.inventory_capacity
        capacity = 0
        @inventory_item.lots.where(is_deleted: false).each { |lot| capacity += lot.stock }
        @inventory_item.inventory_capacity = capacity
      end
      @inventory_item.stock = @inventory_item.calculate_stock
      @inventory_item.stock = 0 if @inventory_item.stock.blank?
      @inventory_item.update
    end
    @facilityid = current_facility.id
    @inventory_department_request_logs = Inventory::Department::RequestLog.where(facility_id: @facilityid, status: -1)
    @items = Inventory::Item.where(facility_id: @facilityid, is_deleted: false).limit(20)
    @allCount = @items.count # After saving the item counts going to be increased
    @title = 'Central Inventory'
    @out_stock_count = @items.where(stock: 0).count

    respond_to do |format|
      format.js { render action: 'destroy' }
    end
  end

  def download_data
    store_id = params[:store_id]
    expiry_time = params[:expiry_time]
    @data_array, @total_purchase_value, @total_selling_value = Inventory::Lots::DownloadLotsService.call(store_id, expiry_time)
    @filename = "#{params[:department_name]&.downcase}_stock_valuation_report.xlsx"
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}\"" }
    end
  end

  def lot_valuation_report
    # options = { :facility_ids.in => [current_facility.id], is_active: true }
    # @all_user = User.where(options.merge(:inventory_store_ids.in => [params[:store_id]])).pluck(:fullname, :id)
    @date = params[:date]
    @inventory_store = Inventory::Store.find(params[:store_id])
  end

  def print_barcode
    @lot = Inventory::Item::Lot.find_by(id: params[:lot_id])
    html_template = 'inventory/item/lots/print_barcode'
    render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/pdfgen.html.erb',
             viewport_size: '1280x1024', page_size: 'A4', orientation: 'Portrait',
             show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' },
             locals: { mail_job: false }
  end

  def block_lot
    block_unblock_lots = []
    block_lots = { action: 'block', blocked_by_user_name: current_user.try(:fullname), blocked_by_user: current_user.id.to_s,
                     blocked_datetime: Time.current, blocked_stock_by_user_comment: params[:blocked_stock_by_user_comment] }
    block_unblock_lots << block_lots
    if @lot.to_a.present?
      block_comment = params[:blocked_stock_by_user_comment]
      item = Inventory::Item.find_by(id: @lot.try(:item_id))
      blocked_stock_by_user = (@lot.stock - @lot.blocked_stock)&.round(2)
      blocked_stock = (@lot.blocked_stock + blocked_stock_by_user)&.round(2)
      lot_units = @lot.lot_units.where(is_blocked: false)
      if lot_units.count > 0
        lot_units.update_all(is_blocked: true, blocked_stock: 1, available_stock: 0, is_blocked_by_user: true)
      end
      @lot.update(is_blocked: true, is_blocked_by_user: true, blocked_by_user: current_user.id.to_s,
                  blocked_by_user_name: current_user.try(:fullname), blocked_datetime: Time.current,
                  blocked_stock_by_user: blocked_stock_by_user, blocked_stock: blocked_stock, available_stock: 0,
                  blocked_stock_by_user_comment: block_comment)
      @lot.add_to_set(block_unblock_lots: block_unblock_lots)         
    end
  end
  
  def unblock_lot
    block_unblock_lots = []
    unblock_lots = { action: 'unblock', unblocked_by_user_name: current_user.try(:fullname), unblocked_by_user: current_user.id.to_s, unblocked_datetime: Time.current, unblocked_stock_by_user_comment: params[:blocked_stock_by_user_comment] }
    block_unblock_lots << unblock_lots
    if @lot.to_a.present?
      blocked_stock_by_user = @lot.blocked_stock_by_user&.round(2)
      blocked_stock = (@lot.blocked_stock - blocked_stock_by_user)&.round(2)
      lot_units = @lot.lot_units.where(is_blocked: true, is_blocked_by_user: true)
      if lot_units.count > 0
        lot_units.update_all(is_blocked: false, blocked_stock: 0, available_stock: 1, is_blocked_by_user: false)
      end
      is_blocked = blocked_stock > 0 ? true : false      
      @lot.update(is_blocked: is_blocked, is_blocked_by_user: false, blocked_by_user: nil,
                  blocked_by_user_name: current_user.try(:fullname), blocked_datetime: nil, blocked_stock_by_user: nil,
                  blocked_stock: blocked_stock, available_stock: blocked_stock_by_user, blocked_stock_by_user_comment: nil)
      @lot.add_to_set(block_unblock_lots: block_unblock_lots)      
    end
  end

  private

  def set_inventory_item_lot
    @inventory_item_lot = Inventory::Item::Lot.find_by(id: params[:id])
  end

  def fetch_lot_index
    @sub_store_name = params[:sub_store_name]
    current_data_row = params[:total_count_row].to_i
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @store_id)
    @sub_stores = @inventory_store.sub_stores
    @default_days = Inventory::Store.find_by(id: params[:store_id]).days_before_expired
    query = params[:q].to_s
    @expiry_time = params[:expiry_time]
    options = { store_id: params[:store_id], search: /#{Regexp.escape(query)}/i }
    options = options.merge!(sub_store_id: params[:sub_store_id]) if params[:sub_store_id].present?
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
    @lots = Inventory::Item::Lot.where(options).is_active.order_by(created_at: 'desc').skip(current_data_row).limit(30)
  end

  def check_taxable_amount
    tax_rate = @lot.tax_rate || 0
    selling_price = params[:inventory_lot][:list_price]
    if @lot.tax_inclusive
      @unit_taxable_amount = (selling_price.to_f * tax_rate) / (100 + tax_rate)
      @unit_non_taxable_amount = selling_price.to_f - @unit_taxable_amount
    else
      @unit_taxable_amount = (selling_price.to_f * tax_rate) / 100
      @unit_non_taxable_amount = selling_price.to_f
    end
  end

  def inventory_item_lot_params(category)
    case category
    when 'medication'
      params.require(:inventory_item).require(:lots).permit(:price, :mark_up, :mrp, :list_price, :vendor, :expiry,
                                                            :stock)
    when 'implant'
      params.require(:inventory_item).require(:lots).permit(:price, :mark_up, :mrp, :list_price, :vendor, :expiry,
                                                            :warranty_expiry, :stock)
    when 'consumable'
      params.require(:inventory_item).require(:lots).permit(:price, :mark_up, :mrp, :list_price, :vendor, :expiry,
                                                            :stock)
    when 'miscellaneous'
      params.require(:inventory_item).require(:lots).permit(:price, :mark_up, :mrp, :list_price, :vendor, :expiry,
                                                            :stock)
    when 'stockable'
      params.require(:inventory_item).require(:lots).permit(:price, :mark_up, :mrp, :list_price, :vendor, :expiry,
                                                            :warranty_expiry, :condition, :stock)
    when 'optical'
      params.require(:inventory_item).require(:lots).permit(:price, :mark_up, :mrp, :list_price, :vendor, :expiry,
                                                            :stock)

    end
  end

  def find_lot
    @lot = Inventory::Item::Lot.find_by(id: params[:id])
  end
  # EOF find_lot
end
