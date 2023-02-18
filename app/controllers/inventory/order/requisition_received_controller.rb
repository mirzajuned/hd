class Inventory::Order::RequisitionReceivedController < ApplicationController
  before_action :authorize, :verify_store
  before_action :find_store, only: [:index, :new, :filter_index, :show, :append_index, :close]

  def index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @time_period = params[:time_period]
    @requisition_status = ['Completed','Closed','Pending','All']
    @status = params[:status].present? ? params[:status] : 'Pending'
    fetch_requisition(@store_id)
  end

  def show
    @requisition_received = Inventory::Order::RequisitionReceived.find_by(id: params[:id])
    @transfer_transactions = @requisition_received.transfers
  end

  def filter_index
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_requisition(params[:store_id])
  end

  def append_index
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_transactions
  end

  def print
    order_id = params[:order_id]
    page_size = params[:page_size]
    @requisition_received = Inventory::Order::RequisitionReceived.find_by(id: order_id)
    @inventory_store = Inventory::Store.find_by(id: @requisition_received.store_id)
    @entity = EntityGroup.find_by(id: @inventory_store.entity_group_id.to_s )
    html_template = 'inventory/order/requisition_received/print'

    if page_size == 'A5'
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/pdfgen.html.erb',
             viewport_size: '1280x1024', page_size: 'A4', show_as_html: params[:debug].present?,
             footer: { right: '[page] of [topage]' }, locals: { mail_job: false }
    else
      render template: html_template, pdf: 'xyz', layout: 'invoice/inventory/pdfgen.html.erb',
             viewport_size: '1280x1024', page_size: 'A4', orientation: 'Portrait',
             show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' },
             locals: { mail_job: false }
    end
  end

  def new_transfer
    @requisition_received = Inventory::Order::RequisitionReceived.find_by(id: params[:id])
    @store_id = @requisition_received.store_id
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @category = 'all_item'
    @transfer_transaction = @requisition_received.transfers.new
    @transfer_transaction.items = @requisition_received.items
    @from = params[:from]
    @receive_store = Inventory::Store.find_by(id: @requisition_received.requisition_order_store_id)
    @facility = Facility.find_by(id: @receive_store.facility_id)
    @transfer_transactions = @requisition_received.transfers
  end

  def variant_lots
    @requisition_received = Inventory::Order::RequisitionReceived.find_by(id: params[:id])
    @item = @requisition_received.items.find_by(id: params[:item_id])
    @req_variant = Inventory::Item::Variant.find_by(id: @item.variant_id)
    @inventory_item = Inventory::Item.find_by(id: @req_variant.item_id)
    req_received_store_item = Inventory::Item.find_by(reference_id: @inventory_item.reference_id,
                                                      store_id: @requisition_received.store_id)
    @variant = Inventory::Item::Variant.find_by(reference_id: @req_variant.reference_id,
                                                store_id: @requisition_received.store_id) || Inventory::Item::Variant.new
    @lots = Inventory::Item::Lot
            .where(store_id: params[:store_id], variant_id: @variant&.id, :available_stock.gte => 1).order_by(expiry: 'asc')
            .is_active
    @max_stock = @item.stock
  end

  def add_lots
    @transfer_transaction = Inventory::Transaction::Transfer.new(item_params)
    @variant = Inventory::Item::Variant.find_by(id: params[:variant_id])
    @req_variant_id = params[:req_variant_id].to_s
    @issue_quantity = params[:issue_quantity]
    @remaining_quantity = params[:remaining_quantity]
    @balance_quantity = params[:balance_quantity]
    @items = item_params.to_h['items_attributes']
  end

  def edit_lots
    @items = params[:items]
    @variant = Inventory::Item::Variant.find_by(id: params[:variant_id])
    @issue_quantity = params[:issue_quantity].to_i
    @remaining_quantity = params[:remaining_quantity].to_i
    @balance_quantity = params[:balance_quantity].to_i
    @max_stock = @remaining_quantity + @issue_quantity
  end

  def update_lots
    add_lots
  end

  def close
    requisition_received = Inventory::Order::RequisitionReceived.find_by(id: params[:id])
    @requisition = Inventory::Order::Requisition.find_by(id: requisition_received.requisition_order_id)
    @requisition.update(is_disabled: true, is_active: false, status: 'Closed', closed_reason: params[:closed_reason],
                       closed_by: current_user.fullname, closed_by_id: current_user.id, closed_date_time: Time.current)
    requisition_received.update(is_disabled: true, is_active: false, status: 'Closed', closed_reason: params[:closed_reason],
                                closed_by: current_user.fullname, closed_by_id: current_user.id, closed_date_time: Time.current)
    @start_date = @end_date = params[:date]
    update_requisition_variants
    fetch_requisition(requisition_received.store_id)
  end

  private

  def update_requisition_variants
    @requisition.items.each do |item|
      variant = Inventory::Item::Variant.find_by(id: item.variant_id)
      variant.update!(requested_quantity: 0)
    end
  end

  def find_store
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
  end

  def fetch_requisition(store_id)
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: store_id, remarks: /#{Regexp.escape(query)}/i }
    options = options.merge(status: @status) if @status.present? && @status != "All"
    if @start_date.present? && @end_date.present?
      options[:requisition_order_date] = { :$gte => @start_date, :$lte => @end_date }
    end
    @requisition_received = Inventory::Order::RequisitionReceived.where(options).order_by(created_at: 'desc')
                                                                 .skip(current_data_row).limit(30)
  end

  def item_params
    params.require(:lots).permit(
      items_attributes: [:lot_id, :stock, :item_code, :variant_code, :item_id, :variant_id, :category, :barcode,
                         :barcode_present, :variant_reference_id, :item_reference_id, :lot_reference_id, :facility_id,
                         :store_id, :organisation_id, :search, :variant_identifier, :mark_up, :mrp, :list_price,
                         :unit_non_taxable_amount, :unit_taxable_amount, :tax_rate, :tax_name, :tax_group_id,
                         :tax_inclusive, :vendor_name, :vendor_id, :model_no, { custom_field_data: {} },
                         { custom_field_tags: [] }, :description, :batch_no, :self_batched, :expiry_present,
                         :total_cost, :unit_cost, :available_stock, :expiry, :requisition_item_id]
    )
  end
end
