class Inventory::Transaction::TraysController < ApplicationController
  include Inventory::ItemsHelper
  before_action :authorize
  before_action :tray_action, only: [:delete_tray, :close_tray]
  before_action :last_search_by, only: [:new, :edit]

  def index
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @time_period = params[:time_period]
    @state_name = params[:state_name]
    @state_id = params[:state_id]
    fetch_transactions
  end

  def new
    @admission = AdmissionListView.find_by(admission_id: params[:admission_id])
    @user = User.find_by(id: @admission.user_id)
    @patient = Patient.find_by(id: params[:patient_id])
    @lots = Inventory::Item::Lot.where(store_id: params[:store_id], :stock.gte => 1, stockable: true)
                                .is_active.limit(30)
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @tray_transaction = Inventory::Transaction::Tray.new
  end

  def show
    @tray = Inventory::Transaction::Tray.find_by(id: params[:id])
    @admission = AdmissionListView.find_by(admission_id: @tray.admission_id)
    @all_trays = Inventory::Transaction::Tray.where(patient_id: @tray.patient_id)
    @from = params[:from]
    render 'inventory/transaction/trays/show_tray.js.erb' if @from == 'patient_queue'
  end

  def filter_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end_date]
    @state_name = params[:state_name]
    @state_id = params[:state_id]
    fetch_transactions
  end

  def append_index
    @store_id = params[:store_id]
    @start_date = params[:start_date]
    @end_date = params[:end]
    fetch_transactions
  end

  def append_lots
    @store_id = params[:store_id]
    @category = params[:item_type]
    fetch_lot_index
  end

  def add_lot
    @lot = Inventory::Item::Lot.find_by(id: params[:lot_id])
    @variant = Inventory::Item::Variant.find_by(id: @lot.variant_id)
    @item = Inventory::Item.find_by(id: @lot.item_id)

    @tray_transaction = Inventory::Transaction::Tray.build
  end

  def filter_lots
    @store_id = params[:store_id]
    @category = params[:item_type]
    @search_type = params[:search_type]
    fetch_lot_index
  end

  def create
    @store_id = params[:inventory_transaction_tray][:store_id]
    @start_date = @end_date = params[:inventory_transaction_tray][:transaction_date]
    @tray_transaction = Inventory::Transaction::Tray.new(tray_transaction_params)
    @admission_id = params[:inventory_transaction_tray][:admission_id]
    @admission = AdmissionListView.find_by(admission_id: @admission_id)
    @patient = Patient.find_by(id: @admission&.patient_id)
    @current_date = params[:current_date] || Date.current
    tray_display_id = InventoryHelper.increment_and_create_tray_display_number(current_organisation['_id'].to_s)
    @tray_transaction.tray_display_id = tray_display_id
    @tray_transaction.status = 'open'
    @inventory_store = Inventory::Store.find_by(id: params[:inventory_transaction_tray][:store_id])
    InventoryJobs::Transactions::TrayJob.perform_later(@tray_transaction.id.to_s, current_user.id.to_s) if
    @tray_transaction.save!
    @admission.update(is_tray_created: true)
    @all_trays = Inventory::Transaction::Tray.where(patient_id: @patient.id, admission_id: @admission.admission_id,
                                                    is_canceled: false).order_by(created_at: 'desc')
  end

  def edit
    @admission = AdmissionListView.find_by(admission_id: params[:admission_id])
    @user = User.find_by(id: @admission.user_id)
    @patient = Patient.find_by(id: params[:patient_id])
    @lots = Inventory::Item::Lot.where(store_id: params[:store_id], :stock.gte => 1, stockable: true)
                                .is_active.limit(30)
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @tray_transaction = Inventory::Transaction::Tray.find_by(id: params[:id], store_id: params[:store_id])
    @lot_ids = @tray_transaction.items.pluck(:lot_id).map(&:to_s)
    @tray_ids = Inpatient::BillOfMaterial.where(facility_id: current_facility_id, patient_id: @patient.id,
                                                is_canceled: false).all.pluck(:tray_ids).uniq.flatten
  end

  def update
    @store_id = params[:inventory_transaction_tray][:store_id]
    @start_date = @end_date = params[:inventory_transaction_tray][:transaction_date]
    @admission = AdmissionListView.find_by(admission_id: params[:inventory_transaction_tray][:admission_id])
    @patient = Patient.find_by(id: @admission&.patient_id)
    @current_date = params[:current_date] || Date.current
    @inventory_store = Inventory::Store.find_by(id: params[:inventory_transaction_tray][:store_id])
    @tray_transaction = Inventory::Transaction::Tray.find_by(id: params[:id])
    lot_ids = @tray_transaction.items.map { |item| [item.lot_id.to_s, item.stock] }
    @tray_transaction.items.delete_all
    @tray_transaction.update(tray_transaction_params)
    InventoryJobs::Transactions::UpdateTrayJob.perform_later(@tray_transaction.id.to_s, current_user.id.to_s, lot_ids)
    @all_trays = Inventory::Transaction::Tray.where(patient_id: @patient.id, admission_id: @admission.admission_id,
                                                    is_canceled: false).order_by(created_at: 'desc')
  end

  def delete_tray; end

  def close_tray; end

  private

  def tray_action
    @admission = AdmissionListView.find_by(admission_id: params[:admission_id])
    @user = User.find_by(id: @admission.user_id)
    @patient = Patient.find_by(id: params[:patient_id])
    @lots = Inventory::Item::Lot.where(store_id: params[:store_id], :stock.gte => 1, stockable: true)
                                .is_active.limit(30)
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @tray_ids = Inpatient::BillOfMaterial.where(facility_id: current_facility_id, patient_id: @patient.id,
                                                is_canceled: false).all.pluck(:tray_ids).uniq.flatten
    @all_trays = Inventory::Transaction::Tray.where(patient_id: @patient.id, admission_id: @admission.admission_id,
                                                    is_canceled: false).order_by(created_at: 'desc')
    transaction_type = params[:action] == 'close_tray' ? 'Close Tray' : 'Cancel Tray'
    Inventory::Transactions::Tray::CreateService.call(params[:tray_id], current_user.id.to_s,
                                                      current_user.fullname, transaction_type)
    @tray = Inventory::Transaction::Tray.find_by(id: params[:tray_id])
    @admission.update(is_tray_created: false) if @all_trays.empty? && (params[:action] == 'delete_tray')
    render 'inventory/transaction/trays/show.js.erb' if params[:from] == 'transaction'
  end

  def tray_transaction_params
    params.require(:inventory_transaction_tray)
          .permit(
            :note, :transaction_date, :transaction_time, :entry_type, :entered_by, :user_id, :store_name, :store_id,
            :patient_name, :patient_mobile, :patient_id, :admission_id, :display_id, :checkout_date, :checkout_time,
            :facility_id, :organisation_id, :department_name, :department_id, :search_type, :user_name,
            :admitting_doctor, :admission_date, :total_cost, :is_edited, :patient_mobile, :patient_display_id,
            items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :variant_code, :item_id, :lot_id,
              :variant_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :_destroy,
              :search, :mark_up, :batch_no, :cost_price, :total_cost_price, :stock_package, :stock_subpackage,
              :stock_unit, :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :list_price, :tax_inclusive,
              :tax_rate, :tax_name, :tax_group_id, :mrp_pack_denomination, :list_price_pack_denomination,
              :self_batched, :lot_reference_id, :variant_reference_id, :item_reference_id, :vendor_name, :vendor_id,
              :expiry, :expiry_present, :total_cost, :unit_cost, :description, :store_id, :facility_id,
              :organisation_id, :unit_non_taxable_amount, :unit_taxable_amount, :total_list_price, :initial_stock,
              :sub_store_id, :sub_store_name
            ]
          )
  end

  def fetch_lot_index
    @search_type = params[:search_type]
    @inventory_store = Inventory::Store.includes(:sub_stores).find_by(id: @store_id)
    @sub_stores = @inventory_store.sub_stores
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, :stock.gte => 1, stockable: true }
    if @category == 'out_stock'
      options = options.merge(stock: 0)
    elsif @category == 'all_item'
    else
      options = options.merge(category: @category)
    end
    if @search_type == 'Barcode'
      lots = Inventory::Item::Lot.where(options).where(barcode_id: query).is_active.skip(current_data_row)
                                 .limit(30)
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
              else
                lots
              end
    elsif @search_type == 'GenericName'
      @lots = Inventory::Item::Lot.where(options).where(generic_display_name: /#{Regexp.escape(query)}/i).is_active
                                  .skip(current_data_row).limit(30)
    else
      @lots = Inventory::Item::Lot.where(options).where(description: /#{Regexp.escape(query)}/i).is_active
                                  .skip(current_data_row).limit(30)
    end
  end

  def fetch_transactions
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    options = { store_id: @store_id, is_deleted: false, patient_name: /#{Regexp.escape(query)}/i }
    options = options.merge(status: @state_id) if @state_id.present? && @state_id != 'all'
    if @start_date.present? && @end_date.present?
      options[:transaction_date] = { :$gte => @start_date, :$lte => @end_date }
      @start_date = Date.parse(@start_date).strftime('%Y-%m-%d')
      @end_date = Date.parse(@end_date).strftime('%Y-%m-%d')
    end
    @tray_transaction = Inventory::Transaction::Tray.where(options).order_by(created_at: 'desc').skip(current_data_row)
                                                    .limit(30)
  end

  def last_search_by
    @search_by = Inventory::Transaction::Tray.last_search_by(current_user.id.to_s, current_facility.id.to_s, params[:store_id])
  end
end
