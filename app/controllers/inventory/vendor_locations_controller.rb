class Inventory::VendorLocationsController < ApplicationController
  layout 'backbone'
  require 'spreadsheet'

  def new
    @vendor_location = Inventory::VendorLocation.new
    @countries = Country.all
    @vendor_name = Inventory::Vendor.find_by(id: params[:vendor_id])&.name
  end

  def create
    @vendor_location = Inventory::VendorLocation.new(vendor_location_params)
    @vendor_id = params[:inventory_vendor_location][:vendor_id]
    if @vendor_location.save
      fetch_loction_list
    else
      @vendor = Inventory::VendorLocation.new
      render 'new'
    end
  end

  def index
    @vendor_id = params[:vendor_id]
    @vendor_locations = Inventory::VendorLocation.where(vendor_id: @vendor_id)
  end

  def edit
    @vendor_location = Inventory::VendorLocation.find_by(id: params[:id])
    @vendor_id = params[:vendor_id]
    @countries = Country.all
    @vendor_name = Inventory::Vendor.find_by(id: params[:vendor_id])&.name
  end

  def update
    @vendor_location = Inventory::VendorLocation.find_by(id: params[:id])
    @vendor_id = vendor_location_params[:vendor_id]
    if @vendor_location.update(vendor_location_params)
      fetch_loction_list
    else
      render 'edit'
    end
  end

  private

  def fetch_loction_list
    @vendor_locations = Inventory::VendorLocation.where(vendor_id: @vendor_id)
  end

  def vendor_location_params
    params.require(:inventory_vendor_location).permit(
      :name, :mobile_number, :secondary_mobile_number, :email, :dl_number, :company_name, :address, :facility_id,
      :organisation_id, :gst_number, :vendor_group_id, :contact_person, :ifsc_code, :pan_number, :cin_number,
      :msme_number, :credit_days, :account_number, :credit_limit, :city, :state, :pincode, :district, :commune,
      :account_holder_name, :branch_name, :country_id, :vendor_group_name, :po_expiry_days, :vendor_id
    )
  end
end
