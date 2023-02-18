class Inventory::Transaction::StockReceiveNotesController < ApplicationController
	before_action :authorize, :verify_store
	before_action :set_store, only: [:index, :new, :edit, :filter_sale_order]
  before_action :set_stock_receive_note, only: [ :show, :print ]

	def index
		@time_period = params[:time_period]
    append_index
	end

	def new
		@store_id = params[:store_id]
    @category = 'all_item'
    @inventory_orders = Invoice::InventoryOrder.where(store_id: @store_id, srn_pending: true, is_canceled: false)
    @other_charges = Inventory::OtherCharge.where(organisation_id: current_user.organisation_id, is_disable: false).pluck(:name, :id)
    category_ids = Inventory::Store.find_by(id: params[:store_id])&.category_ids
    vendor_ids = Inventory::Vendor.where(:category_ids.in => category_ids, is_deleted: false).pluck( :id)
    @vendor_locations = Inventory::VendorLocation.where(:vendor_id.in => vendor_ids)
    @stock_receive_note = Inventory::Transaction::StockReceiveNote.new
	end

  def create
    @store_id = params[:inventory_transaction_stock_receive_note][:store_id]
    order_id = params[:inventory_transaction_stock_receive_note][:order_id]
    vendor_location_id = params[:inventory_transaction_stock_receive_note][:vendor_location_id]
    vendor = Inventory::VendorLocation.find_by(id: vendor_location_id).vendor
    bkp_srn_display_id = InventoryHelper.increment_and_create_srn_number(current_organisation['_id'].to_s)
    @stock_receive_note = Inventory::Transaction::StockReceiveNote.new(stock_receive_note_params)
    @stock_receive_note.bkp_srn_display_id = bkp_srn_display_id
    @stock_receive_note.vendor_id = vendor.id
    @stock_receive_note.vendor_name = vendor.name

    @stock_receive_note.order_id = order_id
    if @stock_receive_note.save!
      srn_display_id = SequenceManagers::GenerateSequenceService.call(
                          'srn', @stock_receive_note,
                          { organisation_id: current_organisation['_id'].to_s, 
                            facility_id: current_facility['_id'].to_s, 
                            region_id: current_facility['region_master_id'].to_s, 
                            department_id: @stock_receive_note.department_id,
                            entity_group_id: @stock_receive_note.store.try(:entity_group_id).to_s
                          }
                        )
      @stock_receive_note.update(srn_display_id: srn_display_id)
      # Inventory::Transactions::History::BlockedLot::CreateService.call(@stock_receive_note)
      InventoryJobs::Transactions::StockReceiveNoteJob.perform_later(@stock_receive_note.id.to_s, current_user.id.to_s)
    end
  end

  def filter_index
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_transactions
  end

  def append_index
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_transactions
  end

  def show;end

  def print
    @inventory_store = @stock_receive_note.store
    html_template = 'inventory/transaction/stock_receive_notes/print.html.erb'
    orientation = params[:page_size] == 'A5' ? 'Landscape' : 'Portrait'
    render template: html_template, pdf: 'son', layout: 'invoice/inventory/pdfgen.html.erb',
           viewport_size: '1280x1024', page_size: 'A4', orientation: orientation,
           show_as_html: params[:debug].present?, footer: { right: '[page] of [topage]' },
           locals: { mail_job: false }
  end

  def stock_receive_note_params
    params.require(:inventory_transaction_stock_receive_note)
          .permit(
            :note, :transaction_date, :entry_type, :entered_by, :user_id, :store_id, :total_cost, :facility_id,
            :organisation_id, :mode_of_payment, :comments, :discount, :net_amount, :amount_remaining,
            :credit_adjustment, :debit_amount, :extra_amount_paid, :department_id, :department_name, :transaction_time,
            :vendor_name, :vendor_id, :document_number, :taxable_amount, :total_other_charges_amount, :bill_type,
            :challan_date, :challan_number, :bill_number, :bill_date, :vendor_location_id,
            { tax_breakup: [:_id, :name, :amount, :tax_rate, :tax_type, :taxable_amount] },
            items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :variant_code, :item_id, :variant_id,
              :default_variant_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :_destroy,
              :search, :mark_up, :batch_no, :cost_price, :total_cost_price, :stock_package, :stock_subpackage,
              :stock_unit, :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :list_price, :tax_inclusive,
              :tax_rate, :tax_name, :tax_group_id, :mrp_pack_denomination, :list_price_pack_denomination, :self_batched,
              :expiry, :expiry_present, :total_cost, :unit_cost, :description, :store_id, :facility_id, :system_generated_barcode,
              :item_reference_id, :organisation_id, :unit_non_taxable_amount, :unit_taxable_amount, :barcode_id, :model_no,
              :unit_cost_without_tax, :purchase_tax_amount, :unit_purchase_tax_amount, :item_cost_without_tax,
              :order_id, :variant_reference_id, :sub_store_id, :sub_store_name, { tax_group: [:_id, :name, :amount] }
            ],
            other_charges_attributes: [
              :other_charge_id, :name, :amount, :percent, :net_amount
            ]
          )
  end

	def append_index
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_transactions
  end

  def new_sale_order
  	@sale_order = Invoice::InventoryOrder.find_by(id: params[:order_id])
    @inventory_store = Inventory::Store.find_by(id: @sale_order.store_id)
    @sub_stores = @inventory_store.sub_stores[0]
  end

  def filter_sale_order
  	@inventory_orders = Invoice::InventoryOrder.where(store_id: @inventory_store.id, srn_pending: true,
  	                                                  recipient: /#{Regexp.escape(params[:q])}/i)
  end

	private

  def set_stock_receive_note
    @stock_receive_note = Inventory::Transaction::StockReceiveNote.find_by(id: params[:id])
  end

	def set_store
		@inventory_store = Inventory::Store.find_by(id: params[:store_id])
	end

	def fetch_transactions
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: params[:store_id], is_deleted: false, note: /#{Regexp.escape(query)}/i }
    if @start_date.present? && @end_date.present?
      options[:transaction_date] = { :$gte => @start_date, :$lte => @end_date }
      @start_date = Date.parse(@start_date).strftime('%Y-%m-%d')
      @end_date = Date.parse(@end_date).strftime('%Y-%m-%d')
    end
    @stock_receive_notes = Inventory::Transaction::StockReceiveNote.where(options)
                        .order_by(created_at: 'desc').skip(current_data_row)
                        .limit(30)
  end
end