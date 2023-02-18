class Inventory::StoresController < ApplicationController
  before_action :authorize
  before_action :verify_store, only: [:information, :opening_current_stock, :stock_information]
  before_action :find_stores, only: [:index, :update, :filter_index, :link_unlink_multiple_stores,
                                     :save_link_unlink_multiple_stores, :save_link_unlink_multiple_category,
                                     :save_link_unlink_multiple_vendor, :save_vendor_location]
  before_action :form_params, only: [:new, :edit]
  before_action :trusted_domains, only: [:new, :edit]
  respond_to :js, :json, :html
  layout 'loggedin'

  def new
    @store = Inventory::Store.new
    @store_type = params[:store_type]
    # @organisation_id = params[:organisation_id]
    fetch_user_facility
    @countries = Country.all
  end

  def create
    @store_type = params[:inventory_store][:store_type]
    @store = Inventory::Store.new(store_params)
    if @store.save
      find_stores
      if @store.department_id == '284748001' # pharmacy
        MisFilterJobs::ManageFiltersJob.perform_later('pharmacy_store', @store.organisation_id.to_s, @store.facility_id.to_s)
      elsif @store.department_id == '50121007' # optical
        @fitters = Inventory::Fitter.where(facility_id: current_facility_id, organisation_id: @store.organisation_id.to_s,:vendor_id.ne => nil)
        if @fitters.present?
          @fitters.each do |fitter|
            fitter.add_to_set(store_ids: @store.id.to_s)
          end  
        end  
        MisFilterJobs::ManageFiltersJob.perform_later('optical_store', @store.organisation_id.to_s, @store.facility_id.to_s)
      end
      InventoryJobs::CreateDefaultSubStoreJob.perform_later(@store.id.to_s)
    else
      @store = Inventory::Store.new
      # @organisation_id = params[:organisation_id]
      fetch_user_facility
      @countries = Country.all
      render 'new'
    end
  end

  def edit
    @store = Inventory::Store.find_by(id: params[:id])
    @store_type = params[:store_type]
    fetch_user_facility
    @countries = Country.all
  end

  def update
    @store = Inventory::Store.find_by(id: params[:id])
    @store_type = params[:inventory_store][:store_type]
    if @store.update(store_params)
      if @store.department_id == '284748001' # pharmacy
        MisFilterJobs::ManageFiltersJob.perform_later('pharmacy_store', @store.organisation_id.to_s, @store.facility_id.to_s)
      elsif @store.department_id == '50121007' # optical
        MisFilterJobs::ManageFiltersJob.perform_later('optical_store', @store.organisation_id.to_s, @store.facility_id.to_s)
      end
    else
      render 'edit'
    end
  end

  def index
    @store_type = params[:store_type]
  end

  # Inventory related methods

  def show
    @inventory_stores = Inventory::Store.where(facility_id: current_facility_id, :user_ids.in => [current_user.id], is_active: true, is_disable: false)

    @inventory_store = Inventory::Store.find_by(id: params[:id], is_disable: false)
    @organisation = Organisation.find_by(id: current_user.organisation_id)
    # if @inventory_store.blank?
    #   @inventory_store = @inventory_stores.where(department_id: params[:id]).first
    # end # incase of pharmacist/optician logged in
    @vendors = Inventory::Vendor.where(:store_ids.in => [BSON::ObjectId(params[:id].to_s)], is_deleted: false) if @inventory_store.present?
    if @inventory_store.blank? # incase of pharmacist/optician logged in and not linked to any store
      @inventory_store = Inventory::Store.where(
        facility_id: current_facility_id, department_id: params[:id], is_disable: false
      ).first
    end

    redirect_to('/errors/empty_store') && return if @inventory_store.blank? # incase of store is not created

    @title = @inventory_store.try(:name).try(:titlecase)
    set_facility_setting
    if @inventory_store.try(:department_id).to_s == '284748001'
      pharmacy_prescription_data
    elsif @inventory_store.try(:department_id).to_s == '50121007'
      optical_prescription_data
    elsif @inventory_store.try(:department_id).to_s == '384748001'
      ipd_ot_store_data
    else
      @store_id = @inventory_store.id
      @store_url = '/inventory/stores/show.html'
      @category = ['all_item']
      fetch_items_index
      @store_panel_url = 'items_list'
    end
    @categories = Inventory::Category.where(:id.in => @inventory_store.category_ids).pluck(:name, :id)
    render @store_url
  end

  def information
    @store = Inventory::Store.find_by(id: params[:store_id])

    @trusted_domains = TrustedDomain.where(
      organisation_id: current_user.organisation_id, deleted: false, disabled: false
    )
  end

  def stock_information
    @store = Inventory::Store.find_by(id: params[:store_id])
    @item_out_stock = Inventory::Item.where(store_id: @store.id, empty: true, stockable: true).is_active.count
    @item_running_low = Inventory::Item.where(store_id: @store.id, running_low: true, stockable: true).is_active.count
    @variant_out_stock = Inventory::Item::Variant.where(store_id: @store.id, empty: true, stockable: true).is_active.count
    @variant_running_low = Inventory::Item::Variant.where(store_id: @store.id, running_low: true, stockable: true).is_active.count
    @expiring_soon_item = Inventory::Item::Lot.where(store_id: @store.id, 'expiry' => { '$lte' => Date.current + @store.days_before_expired.to_i }).count
  end

  def opening_current_stock
    store_id = params[:store_id]
    today_balance = Inventory::Audit::Balance.find_by(store_id: store_id, date: Date.today)
    yesterday_balance = Inventory::Audit::Balance.find_by(store_id: store_id, date: Date.yesterday)
    if today_balance.present?
      @today_stock_value = today_balance
    elsif yesterday_balance.present?
      @yesterday_stock_value = yesterday_balance
    else
      lots = Inventory::Item::Lot.where(store_id: store_id)
      @stock = lots.pluck(:stock).sum
      @amount = lots.pluck(:total_cost).sum
    end
  end

  def link_unlink_multiple_stores
    filter_store
  end

  def save_link_unlink_multiple_stores
    @store_id = params[:store_id]
    @store_type = params[:store_type]
    @stores = Inventory::Store.where(:id.in => params[:store_ids])
    @store = Inventory::Store.find_by(id: @store_id)
    if params[:type] == 'unlink_store'
      @stores.each do |store|
        @store.pull(store_ids: store.id)
      end
    else
      @stores.each do |store|
        @store.add_to_set(store_ids: store.id)
      end
    end
  end

  def load_store_filters
    store_params = params['ajax']
    facility_id = store_params['facility_id']
    store_type = store_params['store_type']

    store_filter = Reports::Filter.find_by(
      is_active: true, facility_id: facility_id,
      filter_name: "#{store_type}_store"
    )
    if store_filter.present? && store_filter.values.present?
      filter_values = { 'All': '' }
      filter_values.merge!(store_filter.values)
    else
      filter_values = { 'Store Not Found': '' }
    end
    respond_to do |format|
      format.json { render json: filter_values }
    end
  end

  def toggle_disable
    @store = Inventory::Store.find_by(id: params[:id])
    @store.set(is_disable: params[:is_disable])
  end

  def filter_index
    filter_store
  end

  def link_unlink_multiple_category
    @type = params[:type]
    @store_type = params[:store_type]
    @store_id = params[:store_id]
    @store = Inventory::Store.find_by(id: params[:store_id])
    category_ids = Inventory::Store.find_by(id: params[:store_id])&.category_ids
    categories = Inventory::Category.where(organisation_id: current_organisation['_id'].to_s, is_disable: false)
    @categories = []
    @other_categories = []
    categories.each do |category|
      if @type == 'unlink_category'
        if category_ids.include? category.id
          @categories << category
        else
          @other_categories << category
        end
      elsif category_ids.include? category.id
        @other_categories << category
      else
        @categories << category
      end
    end
  end

  def save_link_unlink_multiple_category
    @store_id = params[:store_id]
    @store_type = params[:store_type]
    @categories = Inventory::Category.where(:id.in => params[:category_ids])
    @store = Inventory::Store.find_by(id: @store_id)
    if params[:type] == 'unlink_category'
      @categories.each do |category|
        @store.pull(category_ids: category.id)
        category.pull(store_ids: @store.id)
      end
    else
      @categories.each do |category|
        @store.add_to_set(category_ids: category.id)
        category.add_to_set(store_ids: @store.id)
        InventoryJobs::CloneCategoryItemJob.perform_later(category.id.to_s, @store_id.to_s, current_organisation['_id'].to_s)
      end
    end
  end

  def link_unlink_multiple_vendor
    @type = params[:type]
    @store_type = params[:store_type]
    @store_id = params[:store_id]
    vendor_ids = Inventory::Store.find_by(id: params[:store_id])&.vendor_ids
    vendors = Inventory::Vendor.where(organisation_id: current_organisation['_id'].to_s, is_deleted: false)
    @vendors = []
    @other_vendors = []
    vendors.each do |vendor|
      linked_cat = Inventory::Category.where(:id.in => vendor.category_ids).pluck(:is_disable).uniq
      if linked_cat.include? false
        if @type == 'unlink_vendor'
          if vendor_ids.include? vendor.id
            @vendors << vendor
          else
            @other_vendors << vendor
          end
        elsif vendor_ids.include? vendor.id
          @other_vendors << vendor
        else
          @vendors << vendor
        end
      end
    end
  end

  def save_link_unlink_multiple_vendor
    @store_id = params[:store_id]
    @store_type = params[:store_type]
    @vendors = Inventory::Vendor.where(:id.in => params[:vendor_ids])
    @store = Inventory::Store.find_by(id: @store_id)
    if params[:type] == 'unlink_vendor'
      @vendors.each do |vendor|
        vendor.pull(store_ids: @store.id)
        @store.pull(vendor_ids: vendor.id)
      end
    else
      @vendors.each do |vendor|
        vendor.add_to_set(store_ids: @store.id)
        @store.add_to_set(vendor_ids: vendor.id)
      end
    end
  end

  def show_vendor_purchase_rate
    @vendor_purchare_rates = Inventory::VendorPurchaseRateHistory.where(
      facility_id: current_facility.id, variant_id: params[:variant_id]).order_by(created_at: 'desc'
    )
  end

  def lot_stock_data
    variant = Inventory::Item::Variant.find_by(id: params[:variant_id])
    variants = Inventory::Item::Variant.where(reference_id: variant.reference_id, organisation_id: current_user.organisation_id)
    @lot_data_array = []
    variants.each do |variant|
      lots = Inventory::Item::Lot.where(variant_id: variant.id, :stock.gt => 0.0)
      lots.each do |lot|
        @lot_data_array << lot
      end
    end
  end

  def link_vendor_location_stores
   @store_id = params[:store_id]
   @store = Inventory::Store.find_by(id: @store_id)
   category_ids = @store&.category_ids
   @vendors =  Inventory::Vendor.where(:category_ids.in => category_ids, is_deleted: false)
  end

  def save_vendor_location
    @store_id = params[:store_id]
    ids = params[:vendor_location_ids].reject(&:empty?).uniq
    @vendor_locations = Inventory::VendorLocation.where(:id.in => ids)
    @store = Inventory::Store.find_by(id: @store_id)
    @store.update(vendor_location_ids: [])
    @vendor_locations.each do |location|
      @store.add_to_set(vendor_location_ids: location.id)
    end
  end

  private

  def find_stores
    @inventory_stores = Inventory::Store.where(organisation_id: current_organisation['_id'].to_s,
                                               :department_id.ne => '550368792')
                                        .order_by(name: :asc).group_by(&:facility_id)
    @facilities_data = Facility.where(:id.in => @inventory_stores.keys).pluck(:name, :id)
    @inventory_central_hubs = Inventory::Store.where(organisation_id: current_organisation['_id'].to_s,
                                                     department_id: '550368792').order_by(name: :asc)
  end

  def filter_store
    @facilities = Facility.where(organisation_id: current_user.organisation_id).pluck(:name, :id)
    @departments = Inventory::Store.where(organisation_id: current_organisation['_id'].to_s, is_active: true)
                                   .pluck(:department_name, :department_id).uniq
    @store_id = params[:store_id]
    @linked_store_ids = Inventory::Store.find_by(id: params[:store_id])&.store_ids
    @store = Inventory::Store.find_by(id: params[:store_id])
    @type = params[:type]
    @store_type = params[:store_type]
    options = { organisation_id: current_user.organisation_id, is_active: true, :id.ne => params[:store_id], is_disable: false }
    if params[:facility_id].present? && params[:facility_id] != 'all'
      options = options.merge(facility_id: params[:facility_id]) if params[:department_id] != '550368792'
    end
    if params[:department_id].present? && params[:department_id] != 'all'
      options = options.merge(department_id: params[:department_id])
    end
    @facility_id = params[:facility_id]
    if params[:department_id].nil? && params[:store_type] == 'store' && !@inventory_central_hubs.empty?
      options = options.merge(department_id: @inventory_central_hubs[0].department_id)
      @department_id = @inventory_central_hubs[0].department_id
    else
      @department_id = params[:department_id]
    end
    find_linked_unlinked_stores(options)
  end

  def find_linked_unlinked_stores(options)
    @stores = []
    @other_stores = []
    Inventory::Store.where(options).each do |store|
      if @type == 'unlink_store'
        if @linked_store_ids.include? store.id
          @stores << store
        else
          @other_stores << store
        end
      elsif @linked_store_ids.include? store.id
        @other_stores << store
      else
        @stores << store
      end
    end
  end

  def fetch_items_index
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s

    if @inventory_store.present?
      if @category.present?
        if (@category.include? 'all_item') || @category_id.blank? #for store item index
          options = { store_id: @inventory_store.id, :category_id.in => @inventory_store.category_ids, level: 'store' }
        else
          options = { store_id: @inventory_store.id, :category_id.in => [@category_id], level: 'store'}
        end
      else
        options = { store_id: @inventory_store.id, :category_id.in => @inventory_store.category_ids, level: 'store' }
      end

    else #for org items index
      options = { organisation_id: current_user.organisation_id, level: 'organisation' }
    end

    # options = { organisation_id: current_user.organisation_id }

    options = options.merge({ search: /#{Regexp.escape(query)}/i })
    if @stock == 'out_stock'
      options = options.merge(empty: true)
    elsif @stock == 'running_low'
      options = options.merge(running_low: true)
    end
    @items = Inventory::Item.where(options).is_active.order_by(created_at: 'desc').skip(current_data_row).limit(30)
  end

  def store_params
    params.require(:inventory_store).permit(
      :name, :abbreviation_name, :department_name, :department_id, :billable_transaction, :enable_stock_entry,
      :enable_transfer, :enable_receiving, :enable_purchase_order, :enable_transfer_order, :enable_receiving_order,
      :authorised_role_ids, :checkoutable, :central, :is_active, :logistics, :address, :city, :state, :pincode,
      :commune, :district, :telephone, :mobilenumber, :fax, :email, :last_edited_by, :organisation_id, :country_id,
      :facility_id, :enable_stock_management, :dl_number, :tin, :gst, :username, :asset_path, :vendor_location_ids,
      :days_before_expired, :facility_name, :auto_requisition, :transfer_to_stores_of_linked_facilities,
      :transfer_other_central_hub, :receive_items_from_stores_of_linked_facilities, :master_configuration,
      :receive_items_from_other_central_hub, :entity_group_id, :transfer_to_linked_stores, :requisition,
      :receive_items_from_linked_stores, :master_configuration, :requisition_fulfillment, :reorder_level, :shop_name,
      :enable_sub_store, :store_consumption, :requisition_requested_store_id, :requisition_requested_store_name,
      :gst_state_code, :alpha_code, :is_union_territory, :is_utgst_applicable, :enable_tax_invoice, :billing_country_id, 
      :billing_address, :billing_city, :billing_state, :billing_pincode, :billing_commune, :billing_district
    )
  end

  def pharmacy_prescription_data
    @current_date = params[:current_date].present? ? Date.parse(params[:current_date]) : Date.current
    end_of_day = @current_date.strftime('%d/%m/%Y') + ' 23:59:59'
    @all_prescriptions = PatientPrescription.where(encounterdate: @current_date..Time.zone.parse(end_of_day),
                                                   facility_id: current_facility_id, is_deleted: false,
                                                   store_id: @inventory_store.id).order('created_at DESC')
    options = { my_queue: true }
    if @organisation.workflow_waiting_disable || @facility_setting.queue_management == false
      options = options.merge!(user_id: current_user.id)
    else
      options = options.merge!(:user_ids.in => [current_user.id.to_s])
    end
    @my_queue_prescriptions = @all_prescriptions.where(options)
    @converted_prescriptions = @all_prescriptions.where(converted: 'true')
    @not_converted_prescriptions = @all_prescriptions.where(converted: 'false')
    get_patient_params(@all_prescriptions.pluck(:patient_id))
    @store_panel_url = 'prescriptions/pharmacy/pharmacy_management.html.erb'
    @store_url = if @inventory_store.try(:enable_stock_management) == false
                   '/prescriptions/pharmacy_management.html.erb'
                 else
                   '/inventory/stores/show.html'
                 end
  end

  def optical_prescription_data
    @current_date = params[:current_date].present? ? Date.parse(params[:current_date]) : Date.current
    end_of_day = @current_date.strftime('%d/%m/%Y') + ' 23:59:59'

    @all_prescriptions = PatientOpticalPrescription.where(
      encounterdate: @current_date..Time.zone.parse(end_of_day), store_id: @inventory_store.id,
      facility_id: current_facility.id, :advise_glasses.in => [nil, 'advise']
    ).order('created_at DESC')

    options = { my_queue: true }
    if @organisation.workflow_waiting_disable || @facility_setting.queue_management
      options = options.merge!(user_id: current_user.id)
    else
      options = options.merge!(:user_ids.in => [current_user.id.to_s])
    end
    @my_queue_prescriptions = @all_prescriptions.where(options)
    @converted_prescriptions = @all_prescriptions.where(converted: 'true')
    @not_converted_prescriptions = @all_prescriptions.where(converted: 'false')
    get_patient_params(@all_prescriptions.pluck(:patient_id))

    @store_panel_url = 'prescriptions/optical/optical_management.html.erb'
    @store_url = if @inventory_store.try(:enable_stock_management) == false
                   '/prescriptions/optical_management.html.erb'
                 else
                   '/inventory/stores/show.html'
                 end
  end

  def ipd_ot_store_data
    @current_date = params[:current_date].present? ? Date.parse(params[:current_date]) : Date.current
    end_of_day = @current_date.strftime('%d/%m/%Y') + ' 23:59:59'
    @admissions = AdmissionListView.where(admission_date: @current_date..Time.zone.parse(end_of_day), facility_id: current_facility_id)
                                   .order('created_at DESC')
    @processed_admissions = @admissions.where(is_tray_created: true)
    @un_processed_admissions = @admissions.where(is_tray_created: false)
    get_patient_params(@admissions.pluck(:patient_id))
    @store_panel_url = 'ipd_management/ipd_management.html.erb'
    @store_url = if @inventory_store.try(:enable_stock_management) == false
                   '/ipd_management/ipd_management.html.erb'
                 else
                   '/inventory/stores/show.html'
                 end
  end

  def get_patient_params(patient_ids)
    patients = Patient.where(:id.in => patient_ids)
    @patient_fields = patients.map do |patient|
      age_year, age_month = patient.calculate_age(true)
      title_content = ''
      title_content += 'One Eyed' if patient.one_eyed == 'Yes'
      age_in_months = (age_year.to_i * 12) + age_month.to_i
      if age_year.present? && (49...960).exclude?(age_in_months)
        title_content += ' | ' if patient.one_eyed == 'Yes'
        title_content += age_year < 4 ? 'Baby' : 'Old Age'
      end
      bang = !title_content.empty?
      { id: patient.id, bang: bang, title: title_content }
    end
  end

  def fetch_user_facility
    @current_user = current_user
    @facilities = @current_user.facilities.pluck(:name, :id)
    @requisition_requested_store = Inventory::Store.where(organisation_id: current_user.organisation_id,
                                                          is_active: true, is_disable: false,
                                                          department_id: '550368792').pluck(:name, :id)
  end

  def form_params
    @enable_entity_group = current_organisation['enable_entity_group']
    @col_length = (@enable_entity_group.present?) ? 'col-sm-4' : 'col-sm-8'
    @entity_groups = EntityGroup.where(organisation_id: current_organisation['_id']).uniq
  end

  def set_facility_setting
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id)
  end

  def trusted_domains
    @trusted_domains = TrustedDomain.where(
      organisation_id: current_user.organisation_id, deleted: false, disabled: false
    )
  end
end
