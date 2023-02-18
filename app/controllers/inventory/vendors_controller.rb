class Inventory::VendorsController < ApplicationController
  before_action :authorize, :verify_store
  layout 'backbone'
  require 'spreadsheet'
  # before_action :set_inventory_item, [only: :create, :update]

  def new
    fetch_vendor_groups
    @vendor = Inventory::Vendor.new
    @store_id = params[:store_id]
    @countries = Country.all
  end

  def create
    @vendor = Inventory::Vendor.new(vendor_params)
    @store_id = params[:inventory_vendor][:store_id]
    if @vendor.save
      if @vendor.is_fitter == true
        InventoryJobs::CreateFitterJob.perform_later(@vendor.id.to_s, current_facility_id.to_s)
      end  
      if @store_id.present?
        @store = Inventory::Store.find_by(id: @store_id)
        @vendor.add_to_set(store_ids: @store.id)
        @store.add_to_set(vendor_ids: @vendor.id)
        fetch_store_vendor_list(@store_id)
      else
        fetch_org_vendor_list
      end
    else
      @vendor = Inventory::Vendor.new
      render 'new'
    end
  end

  def show
    @vendor = Inventory::Vendor.find_by(id: params[:id])
    @store_id = params[:store_id]
  end

  def edit
    fetch_vendor_groups
    @vendor = Inventory::Vendor.find_by(id: params[:id])
    @store_id = params[:store_id]
    @countries = Country.all
  end

  def update
    @vendor = Inventory::Vendor.find_by(id: params[:id])
    @store_id = params[:inventory_vendor][:store_id]
    if @vendor.update(vendor_params)
      fitter = Inventory::Fitter.find_by(vendor_id: @vendor.id)
      if fitter.present? || params[:inventory_vendor][:is_fitter] == 'true'
        InventoryJobs::CreateFitterJob.perform_later(@vendor.id.to_s, current_facility_id.to_s)
      end 
      if @store_id.present?
        fetch_store_vendor_list(@store_id)
      else
        fetch_org_vendor_list
      end
    else
      render 'edit'
    end
  end

  def index
    @store_id = params[:store_id]
    if @store_id.present?
      fetch_store_vendor_list(@store_id)
      @inventory_store = Inventory::Store.find_by(id: @store_id)
    else
      fetch_org_vendor_list
    end
  end

  def destroy
    @vendor = Inventory::Vendor.find_by(id: params[:id])
    @store_id = params[:store_id]
    if @vendor.update(is_deleted: true)
      fitter = Inventory::Fitter.find_by(vendor_id: params[:id])
      if fitter.present?
         fitter.update(is_disable: true, is_deleted: true)
      end  
      if @store_id.present?
        fetch_store_vendor_list(@store_id)
      else
        fetch_org_vendor_list
      end
    else
      head :no_content
    end
  end

  def enable_vendor
    @vendor = Inventory::Vendor.find_by(id: params[:id])
    @store_id = params[:store_id]
    if @vendor.update(is_deleted: false)
      fitter = Inventory::Fitter.find_by(vendor_id: params[:id])
      if fitter.present?
         fitter.update(is_disable: false, is_deleted: false)
      end 
      if @store_id.present?
        fetch_store_vendor_list(@store_id)
      else
        fetch_org_vendor_list
      end
    else
      head :no_content
    end
  end

  def filter_index
    @store_id = params[:store_id]
    fetch_store_vendor_list(@store_id)
  end

  def link_unlink_multiple_category
    @type = params[:type]
    @store_type = params[:store_type]
    @vendor_id = params[:vendor_id]
    @vendor = Inventory::Vendor.find_by(id: params[:vendor_id])
    category_ids = Inventory::Vendor.find_by(id: params[:vendor_id])&.category_ids
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
    @vendor_id = params[:vendor_id]
    @store_type = params[:store_type]
    @categories = Inventory::Category.where(:id.in => params[:category_ids])
    @vendor = Inventory::Vendor.find_by(id: @vendor_id)
    if params[:type] == 'unlink_category'
      @categories.each do |category|
        category.pull(vendor_ids: @vendor.id)
        @vendor.pull(category_ids: category.id)
        # InventoryJobs::LinkVendorStoreJob.perform_later(category.id.to_s, @vendor.id.to_s, 'un_link')
      end
    else
      @categories.each do |category|
        category.add_to_set(vendor_ids: @vendor.id)
        @vendor.add_to_set(category_ids: category.id)
        # InventoryJobs::LinkVendorStoreJob.perform_later(category.id.to_s, @vendor.id.to_s, 'link')
      end
    end
    fetch_org_vendor_list
  end

  private

  def fetch_store_vendor_list(store_id)
    @inventory_store = Inventory::Store.find_by(id: store_id)
    query = params[:q].to_s
    store_category_ids = @inventory_store&.category_ids || []
    @vendors = Inventory::Vendor.where(:category_ids.in => store_category_ids, name: /#{Regexp.escape(query)}/i)
                                .order_by(created_at: 'desc')
  end

  def fetch_org_vendor_list
    query = params[:q].to_s
    @vendors = Inventory::Vendor.includes(:vendor_group).where(organisation_id: current_organisation['_id'].to_s, name: /#{Regexp.escape(query)}/i)
                   .order_by(created_at: 'desc')
  end

  def fetch_vendor_groups
    @vendor_groups = Inventory::VendorGroup.where(organisation_id: current_organisation['_id'].to_s,
                                                      is_disable: false).order_by(name: :asc)
  end

  def vendor_params
    params.require(:inventory_vendor).permit(:name, :mobile_number, :secondary_mobile_number, :email, :dl_number,
                                             :company_name, :address, :facility_id, :organisation_id, :store_id,
                                             :gst_number, :vendor_group_id, :contact_person, :ifsc_code,
                                             :pan_number, :cin_number, :msme_number, :credit_days, :account_number,
                                             :credit_limit, :city, :state, :pincode, :district, :commune,
                                             :account_holder_name, :branch_name, :country_id, :vendor_group_name,
                                             :po_expiry_days, :fitting_charges, :is_fitter, :store_ids => [])
  end
end