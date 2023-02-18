class Inventory::Vendors::DocumentsController < ApplicationController
  before_action :authorize
  before_action :find_vendor, only: [:new, :create, :index, :destroy]
  layout "loggedin"

  def index
    @vendor_assets = @vendor.assets
  end

  def new
    @vendor_asset = @vendor.assets.new
  end

  def create
    @vendor_asset = @vendor.assets.new(documents_params)
    if @vendor_asset.save
      render json: { 'success': true }
    else
      retry_image_upload
    end
  end

  def show
  end

  def destroy
    @asset = Inventory::Vendor::AssetUpload.find(params[:id])
    @asset.update!(is_deleted: true)
    @vendor_assets = @vendor.assets
  end

  private

  def documents_params
    params.require(:inventory_vendor_asset_upload).permit(:name, :asset_path)
  end

  def find_vendor
    @vendor = Inventory::Vendor.find_by(id: params[:vendor_id])
  end

  def retry_image_upload(counter = 1)
    @vendor_asset.update(asset_path: documents_params[:asset_path], upload_retry_counter: counter)
    if @vendor_asset.asset_path.file.exists?
      render json: { 'success': true }
    else
      counter = counter + 1
      if counter <= 5
        retry_image_upload(counter)
      else
        @vendor_asset.destroy
        render json: { 'success': false }
      end
    end
  end
end
