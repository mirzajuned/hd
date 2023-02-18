class Inpatient::BillOfMaterialsController < ApplicationController
  before_action :authorize
  before_action :last_search_by, only: [:new, :edit]
  
  def new
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = AdmissionListView.find_by(admission_id: params[:admission_id])
    @user = User.find_by(id: @admission.user_id)
    @inventory_store = Inventory::Store.where(facility_id: current_facility_id, is_active: true, department_id: '384748001', is_disable: false).first
    @lots = Inventory::Item::Lot.where(store_id: @inventory_store.id, :stock.gte => 1, stockable: true)
    @trays = Inventory::Transaction::Tray.where(admission_id: params[:admission_id], patient_id: params[:patient_id],
                                                is_canceled: false, is_closed: false, :status.ne => 'consumed')
                                         .order_by(created_at: 'desc')
    @bom_transaction = Inpatient::BillOfMaterial.new
  end

  def filter_lots
    @store_id = params[:store_id]
    @category = params[:item_type]
    @search_type = params[:search_type]
    fetch_lot_index
  end

  def append_lots
    @store_id = params[:store_id]
    @category = params[:item_type]
    @search_type = params[:search_type]
    fetch_lot_index
  end

  def add_lot
    @lot = Inventory::Item::Lot.find_by(id: params[:lot_id])
    @variant = Inventory::Item::Variant.find_by(id: @lot.variant_id)
    @item = Inventory::Item.find_by(id: @lot.item_id)

    @bom_transaction = Inpatient::BillOfMaterial.build
  end

  def set_bill_of_material
    @bill_of_material = Inpatient::BillOfMaterial.find_by(id: params[:id])

    respond_to do |format|
      format.html { render 'set_bill_of_material.html.erb', layout: false }
    end
  end

  def create
    @store_id = params[:inpatient_bill_of_material][:store_id]
    @start_date = @end_date = params[:inpatient_bill_of_material][:transaction_date]
    @bill_of_material = Inpatient::BillOfMaterial.new(bill_of_material_params)
    @admission_id = params[:inpatient_bill_of_material][:admission_id]
    ipdrecord = Inpatient::IpdRecord.find_by(admission_id: @admission_id)
    @admission = Admission.find_by(id: @admission_id)
    @admission_list_view = AdmissionListView.find_by(admission_id: @admission_id)
    @patient = Patient.find_by(id: @admission_list_view&.patient_id)
    @current_date = params[:current_date] || Date.current
    @bill_of_material.tray_ids = params[:inpatient_bill_of_material][:items_attributes]
    &.values&.pluck(:tray_id)&.uniq&.compact
    @inventory_store = Inventory::Store.find_by(id: params[:inpatient_bill_of_material][:store_id])
    InventoryJobs::Transactions::BomJob.perform_later(@bill_of_material.id.to_s, current_user.id.to_s) if
    @bill_of_material.save!
    @admission.update(admission_in_progress: true)
    Patients::Summary::TimelineWorker.call(event_name: 'IPD_RECORD', sub_event_name: 'CREATED',
                                           ipd_record_id: ipdrecord.id, user_id: current_user.id,
                                           user_name: current_user.fullname, ipdtemplatetype: 'Bom Note',
                                           bom_id: @bill_of_material.id)
    # @all_trays = Inventory::Transaction::Tray.where(patient_id: @patient.id, admission_id: @admission.admission_id,
    # is_canceled: false).order_by(created_at: 'desc')
  end

  def edit
    @bom_transaction = Inpatient::BillOfMaterial.find_by(id: params[:id])
    @patient = Patient.find_by(id: params[:patient_id])
    @admission = AdmissionListView.find_by(admission_id: params[:admission_id])
    @user = User.find_by(id: @admission.user_id)
    @inventory_store = Inventory::Store.where(facility_id: current_facility_id, is_active: true, department_id: '384748001', is_disable: false).first
    @lots = Inventory::Item::Lot.where(store_id: @inventory_store.id, :stock.gte => 1, stockable: true)
    ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
    @lot_ids = @bom_transaction.items.pluck(:lot_id).map(&:to_s)
  end

  def update
    @store_id = params[:inpatient_bill_of_material][:store_id]
    @start_date = @end_date = params[:inpatient_bill_of_material][:transaction_date]
    @admission_id = params[:inpatient_bill_of_material][:admission_id]
    @admission = Admission.find_by(id: @admission_id)
    ipdrecord = Inpatient::IpdRecord.find_by(admission_id: @admission_id)
    @admission_list_view = AdmissionListView.find_by(admission_id: @admission_id)
    @patient = Patient.find_by(id: @admission_list_view&.patient_id)
    @current_date = params[:current_date] || Date.current
    @inventory_store = Inventory::Store.find_by(id: params[:inpatient_bill_of_material][:store_id])
    @bill_of_material = Inpatient::BillOfMaterial.find_by(id: params[:id])
    bom_old_item_data = @bill_of_material.items.pluck(:lot_id, :bom_quantity)
    @bill_of_material.items.delete_all
    @bill_of_material.update(bill_of_material_params)
    Patients::Summary::TimelineWorker.call(event_name: 'IPD_RECORD', sub_event_name: 'UPDATED',
                                           ipd_record_id: ipdrecord.id, user_id: current_user.id,
                                           user_name: current_user.fullname, ipdtemplatetype: 'Bom Note',
                                           bom_id: @bill_of_material.id)
    InventoryJobs::Transactions::UpdateBomJob.perform_later(@bill_of_material.id.to_s, current_user.id.to_s, bom_old_item_data)
  end

  def show
    ipd_record = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
    @bill_of_materials = Inpatient::BillOfMaterial.where(admission_id: params[:admission_id],
                                                         patient_id: ipd_record.patient_id,
                                                         used_in_operative_note: false, is_canceled: false,
                                                         :id.ne => params[:id])
    @bom = Inpatient::BillOfMaterial.find_by(id: params[:id])
    @admission = AdmissionListView.find_by(admission_id: @bom.admission_id)
    @bom_ids = ipd_record.operative_notes.pluck(:bill_of_material_id)
    @final_bom = @bill_of_materials.pluck(:id, :transaction_date, :transaction_time) << [@bom.id, @bom.transaction_date, @bom.transaction_time]
    render 'inpatient/ipd_record/operative_note/ophthalmology_notes/show.js.erb' if params[:from] == 'operative_note'
  end

  def delete_bom
    ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
    @bill_of_material = Inpatient::BillOfMaterial.find_by(id: params[:id])
    bom_old_item_data = @bill_of_material.items.pluck(:lot_id, :bom_quantity)
    @admission = Admission.find_by(id: params[:admission_id])
    @bill_of_material.update(is_canceled: true, cancel_date: Date.current, canceled_by: current_user.fullname,
                             canceled_by_id: current_user.id)
    all_bom = Inpatient::BillOfMaterial.where(admission_id: params[:admission_id], patient_id: params[:patient_id],
                                              is_canceled: false)
    @admission.update(admission_in_progress: false) if all_bom.empty?
    IpdRecords::DeleteBillOfMaterialService.call(@bill_of_material.id, current_user.id.to_s)
  end

  def set_bill_of_material
    @bill_of_material = Inpatient::BillOfMaterial.find_by(id: params[:id])
  end

  private

  def fetch_lot_index
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
    if params[:search_type] == 'Barcode'
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

  def bill_of_material_params
    params.require(:inpatient_bill_of_material)
          .permit(
            :note, :transaction_date, :transaction_time, :entry_type, :entered_by, :user_id, :store_name, :store_id,
            :patient_name, :patient_mobile, :patient_id, :admission_id, :display_id, :checkout_date, :checkout_time,
            :facility_id, :organisation_id, :department_name, :department_id, :search_type, :user_name,
            :admitting_doctor, :admission_date, :total_cost, :is_edited, :discount, :total_billing_price,
            :patient_display_id,
            items_attributes: [
              { custom_field_data: {} }, { custom_field_tags: [] }, :item_code, :variant_code, :item_id, :variant_id,
              :lot_id, :category, :barcode, :barcode_present, :reference_id, :variant_identifier, :search, :mark_up,
              :batch_no, :cost_price, :total_cost_price, :stock_package, :stock_subpackage, :stock_unit,
              :stock_free_unit, :stock, :mrp_pack, :mrp, :list_price_pack, :list_price, :mrp_pack_denomination,
              :batch_no, :list_price_pack_denomination, :self_batched, :expiry, :expiry_present, :quantity,
              :unit_non_taxable_amount, :unit_taxable_amount, :tax_rate, { tax_group: [:_id, :name, :amount] },
              :tax_group_id, :tax_inclusive, :taxable_amount, :non_taxable_amount, :total_list_price, :total_cost,
              :unit_cost, :description, :store_id, :facility_id, :organisation_id, :billable, :_destroy,
              :variant_reference_id, :item_reference_id, :tray_id, :tray_item_id, :bom_list_price, :bom_quantity,
              :sub_store_id, :sub_store_name
            ]
          )
  end

  def last_search_by
    @search_by = Inpatient::BillOfMaterial.last_search_by(current_user.id.to_s, current_facility.id.to_s, params[:store_id])
  end
end
