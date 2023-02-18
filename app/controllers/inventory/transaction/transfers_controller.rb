class Inventory::Transaction::TransfersController < ApplicationController
  include Inventory::ItemsHelper
  before_action :authorize, :verify_store
  before_action :facility_store_data, only: [:facility_list, :store_list]
  before_action :last_search_by, only: [:new, :edit]
  before_action :set_transfer_transaction, only: [:edit, :update, :approve, :cancel, :re_stock]

  def index
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @time_period = params[:time_period]
    fetch_transactions
  end

  def append_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_transactions
  end

  def filter_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    fetch_transactions
  end

  def show
    @transfer = Inventory::Transaction::Transfer.find_by(id: params[:id])
    @receive = Inventory::Transaction::Receive.find_by(id: @transfer.receive_id)
  end

  def new
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @category = 'all_item'
    @lots = Inventory::Item::Lot.where(store_id: params[:store_id], :available_stock.gt => 0.0, stockable: true)
                                .is_active.limit(30)
    find_receive_stores
    @transfer_transaction = Inventory::Transaction::Transfer.new
    @receive_store = Inventory::Store.find_by(id: params[:receive_store_id])
    facility_id = params[:facility_id] || current_facility.id
    @facility = Facility.find_by(id: facility_id)
    @from = params[:from]
    @transfer_transaction.items
  end

  def create
    @store_id = params[:inventory_transaction_transfer][:store_id]
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    request_from = params[:inventory_transaction_transfer][:request_from]
    @start_date = @end_date = params[:inventory_transaction_transfer][:transaction_date]
    @transfer_transaction = Inventory::Transaction::Transfer.new(transfer_transaction_params)
    if request_from == 'requisition_received'
      issue_display_id = InventoryHelper.increment_and_create_issue_display_number(current_organisation['_id'].to_s)
      @transfer_transaction.issue_display_id = issue_display_id
    else
      transfer_display_id = InventoryHelper.increment_and_create_transfer_display_number(current_organisation['_id'].to_s)
      @transfer_transaction.transfer_display_id = transfer_display_id
    end
    @negative_items = @transfer_transaction.items.negative_stock_items
    if @negative_items.blank?
      if @transfer_transaction.save!
        Inventory::Transactions::History::BlockedLot::CreateService.call(@transfer_transaction)
        if @transfer_transaction.requisition_received_id.present?
          #update requisition_received remaining stock
          InventoryJobs::Orders::RequisitionReceivedStockJob.perform_later(@transfer_transaction.id.to_s, 'create')
        end
        # InventoryJobs::Transactions::TransferJob.perform_later(@transfer_transaction.id.to_s, current_user.id.to_s)
      end
      if request_from == 'requisition_received'
        id = params[:inventory_transaction_transfer][:requisition_received_id]
        @requisition_received = Inventory::Order::RequisitionReceived.find_by(id: id)
        @transfer_transactions = @requisition_received.transfers
        render '/inventory/order/requisition_received/show.js.erb' 
      else
        fetch_transactions
        render '/inventory/transaction/transfers/create.js.erb'
      end
    else
      @category = 'all_item'
      @lots = Inventory::Item::Lot.where(store_id: @store_id, :stock.gte => 1, stockable: true).is_active.limit(30)
      @errors = ['The stock is unavailable', 'Please make sure the item quatity is not more than available stock']
      render "/inventory/transaction/adjustments/item_stock_validation.js.erb"
    end
  end

  def edit
    @inventory_store = @transfer_transaction.store
    @store_id = @inventory_store.id
    @category = 'all_item'
    @receive_store_id = @transfer_transaction.receive_store_id
    @lots = Inventory::Item::Lot.where(store_id: @store_id, :available_stock.gt => 0.0, stockable: true)
                                .is_active.limit(30)
    find_receive_stores
    @items = @transfer_transaction.items
  end

  def update
    if @transfer_transaction.update(transfer_transaction_params)
      lot_ids = transfer_transaction_params[:items_attributes].values.pluck(:lot_id)
      deleted_lots = @transfer_transaction.items.pluck(:lot_id).map(&:to_s) - lot_ids
      @transfer_transaction.items.where(:lot_id.in => deleted_lots).delete_all
      Inventory::Transactions::History::BlockedLot::UpdateService.call(@transfer_transaction, deleted_lots)
      flash.now[:success] = 'updated'
    end
  end

  def approve
    if @transfer_transaction.status.open?
      if @transfer_transaction.set_approved(current_user)
        # @transfer_transaction.update(status: :inprocess)
        InventoryJobs::Transactions::TransferJob.perform_later(@transfer_transaction.id.to_s, current_user.id.to_s)
      end
      flash.now[:success] = 'approved'
    end
  end

  def cancel
    if @transfer_transaction.status.open?
      if @transfer_transaction.set_cancelled(current_user)
        Inventory::Transactions::History::BlockedLot::CancelService.call(@transfer_transaction)
        #update requisition_received remaining stock
        InventoryJobs::Orders::RequisitionReceivedStockJob.perform_later(@transfer_transaction.id.to_s, 'cancel')
      end
    end
  end

  def re_stock
    InventoryJobs::Transactions::ReStockJob.perform_later(@transfer_transaction.id.to_s, current_user.id.to_s)
    @transfer = @transfer_transaction
    @transfer.update(is_missing_stock_available: false)
    @receive = Inventory::Transaction::Receive.find_by(id: @transfer.receive_id)
    @transfer_transaction.set_closed(current_user)
    flash.now[:success] = 're-stocked'
  end

  def new_lot
    @lot = Inventory::Item::Lot.includes(:lot_units).find_by(id: params[:lot_id])
    @lot_units = @lot.lot_units
    @variant = Inventory::Item::Variant.find_by(id: @lot.variant_id)
    @item = Inventory::Item.find_by(id: @lot.item_id)
  end

  def add_lot
    if params[:is_lot_unit].present?
      lot_unit = Inventory::Item::LotUnit.find_by(id: params[:lot_id])
      lot_id = lot_unit.lot_id
    else
      lot_id = params[:lot_id]
    end
    if params[:embedded_item_id].present?
      items = Inventory::Transaction::Transfer.find_by(id: params[:transaction_id]).items
      items.find_by(id: params[:embedded_item_id]).delete
    end
    @lot = Inventory::Item::Lot.find_by(id: lot_id)
    @variant = Inventory::Item::Variant.find_by(id: @lot.variant_id)
    @item = Inventory::Item.find_by(id: @lot.item_id)
    if params[:item].present?
      lot_unit = params[:item].values.pluck(:lot_unit_id, :lot_unit_checked)
      @lot_units = check_lot_unit(lot_unit)
    elsif params[:is_lot_unit].present?
      @lot_units = [lot_unit.id.to_s]
    end

    @transfer_transaction = Inventory::Transaction::Transfer.build
  end

  def append_lots
    @store_id = params[:store_id]
    @category = params[:item_type]
    @search_type = params[:search_type]
    fetch_lot_index
  end

  def filter_lots
    @store_id = params[:store_id]
    @category = params[:item_type]
    @search_type = params[:search_type]
    fetch_lot_index
  end

  def filter_transfer
    @store_id = params[:store_id]
    @department_id = params[:department_id]
  end

  def report
    options = { :facility_ids.in => [current_facility.id], is_active: true }
    @all_user = User.where(options.merge(:inventory_store_ids.in => [params[:store_id]])).pluck(:fullname, :id)
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @inventory_store = Inventory::Store.find(params[:store_id])
  end

  def download_data
    store = Inventory::Store.find(params[:store_id])
    options = { store_id: params[:store_id], start_date: Time.parse(params['start_date'] + ' ' + params['start_time']),
                end_date: Time.parse(params['end_date'] + ' ' + params['end_time']), user: params[:user_id] }
    user = params[:user_id] == 'all_user' ? 'all_user' : User.find(params[:user_id]).fullname
    @store_name = "#{store.name} Transfer Report"
    @address = store.address
    @time_period = "Detailed Transfer Report For a Period of #{params[:start_date]} #{params[:start_time]} to #{params[:end_date]} #{params[:end_time]}"
    @generate_on = "Generated On: #{Time.now.try(:strftime, '%R:%S')} | #{Time.now.strftime('%d %B %Y')} | #{Date.today.strftime('%A')}"
    @generate_by = "Generated By: #{user&.titleize}"
    @filename = "#{store.name.squish&.titleize&.tr(' ', '_')}_#{Time.now.strftime('%d %B %Y')}_#{Time.now.try(:strftime, '%R:%S')}_#{user.squish&.titleize&.tr(' ', '_')}_transfer_report"
    @data_array, @grand_total = Inventory::Transactions::DownloadTransferService.call(options, params[:department_id], params[:user_id])
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}.xlsx\"" }
    end
  end

  def facility_list; end

  def store_list
    @facility = []
    facility = Facility.find_by(id: params[:facility_id])
    @facility << facility.name << facility.id
    @inventory_store = []
    @inventory_store << @store.name << @store.id
    @inventory_stores = Inventory::Store.where(facility_id: params[:facility_id], is_active: true,
                                               enable_receiving: true, is_disable: false)
                          .pluck(:name, :id) - [[@store.name, @store.id]]
    render 'facility_list'
  end

  private

  def fetch_lot_index
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @store_id)
    receive_store = Inventory::Store.find_by(id: params[:receive_store_id])
    store_category_ids = @inventory_store.category_ids || []
    receive_store_category_ids = receive_store&.category_ids || []
    category_ids = store_category_ids & receive_store_category_ids
    @sub_stores = @inventory_store.sub_stores
    @search_type = params[:search_type]
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, :available_stock.gt => 0.0, stockable: true, :category_id.in => category_ids }
    if @category == 'out_stock'
      options = options.merge(available_stock: 0)
    elsif @category == 'all_item'
    else
      options = options.merge(category: @category)
    end

    if params[:search_type] == 'Barcode'
      if query.present?
        lots = Inventory::Item::Lot.where(options).where(barcode_id: query).is_active.skip(current_data_row).limit(30)
        if lots.length == 0
          lot_units = Inventory::Item::LotUnit.where(options).where(barcode_id: query).is_active.skip(current_data_row).limit(30)
          @is_lot_unit = true
        end
      else
        lots = Inventory::Item::Lot.where(options).is_active.skip(current_data_row).limit(30)
      end
      # lots = if query.present?
      #          Inventory::Item::Lot.where(options).where(barcode_id: query).is_active.skip(current_data_row)
      #                              .limit(30)
      #        else
      #          Inventory::Item::Lot.where(options).is_active.skip(current_data_row)
      #                              .limit(30)
      #        end
      variant = Inventory::Item::Variant.find_by(barcode_id: query)
      variant_lots = Inventory::Item::Lot.where(options).where(variant_id: variant.id).is_active if variant.present?
      item = Inventory::Item.find_by(barcode_id: query)
      master_lots = Inventory::Item::Lot.where(options).where(item_id: item.id).is_active if item.present?
      @lots = if lots.present?
                lots
              elsif variant.present? && !variant_lots.empty?
                variant_lots
              elsif item.present? && !master_lots.empty?
                master_lots
              elsif lot_units.present?
                lot_units
              else
                lots
              end
    elsif params[:search_type] == 'GenericName'
      @lots = Inventory::Item::Lot.where(options).where(generic_display_name: /#{Regexp.escape(query)}/i).is_active
                                  .skip(current_data_row).limit(30)
    else
      @lots = Inventory::Item::Lot.where(options).where(search: /#{Regexp.escape(query)}/i).is_active
                                  .skip(current_data_row).limit(30)
    end
  end

  def transfer_transaction_params
    # params.require(:inventory_transaction_transfer).permit!
    params.require(:inventory_transaction_transfer)
          .permit(
            :note, :requisition_received_id, :receive_store_id, :transaction_date, :receive_store_name, :entry_type,
            :entered_by, :user_id, :search_type, :store_name, :store_id, :total_cost, :facility_id, :organisation_id,
            :transaction_time, :department_name, :department_id, :receive_facility_id, :receive_facility_name,
            :transfer_type, :transfer_from, :requisition_id, :optical_order_id, items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :variant_code, :item_id, :lot_id,
              :variant_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :_destroy,
              :search, :mark_up, :batch_no, :cost_price, :total_cost_price, :stock_package, :stock_subpackage,
              :stock_unit, :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :list_price, :tax_inclusive,
              :tax_rate, :tax_name, :tax_group_id, :mrp_pack_denomination, :list_price_pack_denomination,
              :self_batched, :lot_reference_id, :variant_reference_id, :item_reference_id, :vendor_name, :vendor_id,
              :expiry, :expiry_present, :total_cost, :unit_cost, :description, :store_id, :facility_id,
              :organisation_id, :unit_non_taxable_amount, :unit_taxable_amount, :model_no, :id, :__destroy,
              :sub_store_id, :sub_store_name, :hsn_no, :dispensing_unit, :unit_cost_without_tax, :purchase_tax_amount,
              :item_cost_without_tax, :unit_purchase_tax_amount, :requisition_item_id, { lot_unit_ids: [] }
            ]
          )
  end

  def fetch_transactions
    current_data_row = params[:total_count_row].to_i
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @sub_stores = @inventory_store.sub_stores.pluck(:name, :id)
    query = params[:q].to_s
    options = { store_id: @store_id, note: /#{Regexp.escape(query)}/i, is_deleted: false }
    if @start_date.present? && @end_date.present?
      options[:transaction_date] = { :$gte => @start_date, :$lte => @end_date }
    end
    @transfers = Inventory::Transaction::Transfer.where(options).order_by(created_at: 'desc').skip(current_data_row)
                                                 .limit(30)
  end

  def facility_store_data
    @store = Inventory::Store.find_by(id: params[:store_id])
    @facility_array = []
    @inventory_stores = []
    @facility_ids = @store.facility_ids
    @facility_ids.each do |facility_id|
      @facility_array << [Facility.find(facility_id).name, facility_id]
    end
    @receive_central_hub_stores = Inventory::Store.where(receive_items_from_other_central_hub: true, is_active: true,
                                                         organisation_id: current_user.organisation_id,
                                                         department_id: '550368792', is_disable: false)
                                                  .pluck(:name, :id) - [[@store.name, @store.id]]
  end

  def last_search_by
    @search_by = Inventory::Transaction::Transfer.last_search_by(current_user.id.to_s, current_facility.id.to_s, params[:store_id])
  end

  def set_transfer_transaction
    @transfer_transaction = Inventory::Transaction::Transfer.find_by(id: params[:id])
  end

  def find_receive_stores
    stores = Inventory::Store.where(is_active: true)
    receive_stores = stores.where( facility_id: current_facility.id,
                                enable_receiving: true, is_disable: false )
                           .pluck(:name, :id) - [[@inventory_store.name, @inventory_store.id]]
    hubs = stores.where(receive_items_from_linked_stores: true, department_id: '550368792',
        organisation_id: current_user.organisation_id, :store_ids.in => [@inventory_store.id], is_disable: false)
      .pluck(:name, :id) - [[@inventory_store.name, @inventory_store.id]]
    @receive_stores = receive_stores + hubs
  end

  def check_lot_unit(lot_unit)
    lot_unit_array = []
    lot_unit.each do |unit|
      if unit[1] == 'true'
        lot_unit_array << unit[0]
      end
    end
    lot_unit_array
  end
end
