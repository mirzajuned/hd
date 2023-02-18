class Inventory::VendorRatesController < ApplicationController
  before_action :authorize
  before_action :fetch_vendor_rates, only: [:edit, :update, :show]

  layout 'backbone'
  require 'spreadsheet'
  require 'roo'

  def index
    fetch_vendor_rates
  end

  def new
    fetch_users
    @inventory_vendor_rate = Inventory::VendorRate.new
  end

  def edit_multiple
    fetch_users
    fetch_item_non_and_stockable
    fetch_vendor_groups
    fetch_vendor_list
    @selected_vendor = params[:vendor_id]
    @vendor = Inventory::Vendor.find_by(id: @selected_vendor)
    fetch_vendor_rates
    @inventory_vendor_rate_attributes = @inventory_vendor_rates.map(&:attributes)
  end

  def update_multiple
    fetch_users
    inventory_vendor_rate = params[:inventory_vendor_rate].to_unsafe_h

    CreateMultipleVendorRateJob.perform_later(inventory_vendor_rate, @current_user.id.to_s)
  end

  def show; end

  def download_data
    vendor_id = params[:vendor_id]
    @vendor = Inventory::Vendor.find_by(id: vendor_id)
    fetch_item_variants_master
    respond_to do |format|
      format.xlsx {
        response.headers[
            'Content-Disposition'
        ] = "attachment; filename=vendor_rates_#{@vendor.try(:name)}_#{Date.current.strftime('%Y%m%d')}_#{Time.current.strftime('%H%M%S')}.xlsx"
      }
      format.xls
    end
    # fetch_item_variant_vendor_rates
  end

  def upload_data

    @selected_vendor = params[:vendor_rates_bulk_data][:vendor_id]
    uploaded_excel = params[:vendor_rates_bulk_data][:document]

    fetch_users
    fetch_item_variants_master
    fetch_vendor_groups
    fetch_vendor_list
    @vendor = Inventory::Vendor.find_by(id: @selected_vendor)

    excel_file = Roo::Spreadsheet.open(uploaded_excel.tempfile)

    @uploaded_vendor_rates = excel_file.sheet('Sheet1').parse(headers: true)

    respond_to do |format|
      format.js { render 'edit_multiple.js.erb' }
    end
  end

  def bulk_upload_data
    fetch_users
    fetch_item_variants_master
    fetch_vendor_groups
    fetch_vendor_list
    @selected_vendor = params[:vendor_id]
    @vendor = Inventory::Vendor.find_by(id: @selected_vendor)

    fetch_vendor_rates

    @inventory_vendor_rate_attributes = @inventory_vendor_rates.map(&:attributes)
  end

  def edit
    fetch_users
    @inventory_vendor_rate = Inventory::VendorRate.find(params[:id])
  end

  def update
    @inventory_vendor_rate = Inventory::VendorRate.find(params[:id])
    @inventory_vendor_rate.update(vendor_rate_params)
    fetch_vendor_rates
  end

  def destroy; end

  def toggle_disable
    @inventory_vendor_group.set(is_disable: params[:is_disable])
  end

  private

  def vendor_rate_params
    params.require(:inventory_vendor_rate).permit(:item_name, :vendor_name, :vendor_id, :vendor_group_name,
                   :vendor_group_id, :rate, :selling_price)
  end

  def fetch_vendor_rates
    @inventory_vendor_rates = Inventory::VendorRate.where(organisation_id: current_organisation['_id'].to_s)
                                 .order_by(created_at: 'desc')
  end

  def fetch_item_variant_vendor_rates
    @variant_vendor_rates = []
    @variants.each do |variant|
      existing_vendor_rate = Inventory::Item::Variant.find_by(vendor_id: params[:vendor_id])
      @variant_vendor_rates << existing_vendor_rate
    end
    @variant_vendor_rates
  end

  def fetch_item_variants_master
    query = params[:q].to_s
    # options = { organisation_id: current_organisation['_id'].to_s, level: 'organisation', stockable: true }
    options = { organisation_id: current_organisation['_id'].to_s, level: 'organisation' }
    options = options.merge!(search: /#{Regexp.escape(query)}/i) if query.present?
    @variants = Inventory::Item::Variant.where(options).is_active.order_by(created_at: 'desc')
  end

  def fetch_vendor_group
    @inventory_vendor_group = Inventory::VendorGroup.find_by(id: params[:id])
  end

  def fetch_vendor_groups
    @inventory_vendor_groups = Inventory::VendorGroup.where(organisation_id: current_organisation['_id'].to_s, is_deleted: false)
                                   .order_by(name: :asc)
  end

  def fetch_vendor_list
    @vendors = Inventory::Vendor.where(organisation_id: current_organisation['_id'].to_s, is_deleted: false).order_by(name: 'asc').pluck(:name, :id)
  end

  def fetch_users
    @current_user = current_user
  end
  def fetch_item_non_and_stockable
    @variants = Inventory::Item::Variant.any_of({ organisation_id: current_organisation['_id'].to_s, level: 'organisation',stockable: true } ,{ vendor_id: params[:vendor_id], level: 'organisation'} ).is_active.order_by(created_at: 'desc')
  end  
  
  
end
