class Inventory::Transaction::DocumentsController < ApplicationController
  before_action :authorize
  before_action :find_purchase_bill, only: [:new, :create, :index, :destroy]
  layout "loggedin"

  def index
    @purchase_bill_assets = @purchase_bill.purchase_bill_assets
  end

  def new
    @purchase_bill_asset = @purchase_bill.purchase_bill_assets.new
  end

  def create
    @purchase_bill_asset = @purchase_bill.purchase_bill_assets.new(documents_params)
    if @purchase_bill_asset.save
      render json: { 'success': true }
    else
      retry_image_upload
    end
  end

  def show
  end

  def destroy
    @asset = Inventory::Transaction::PurchaseBillAssetUpload.find(params[:id])
    @asset.update!(is_deleted: true)
    @purchase_bill_assets = @purchase_bill.purchase_bill_assets
  end

  private

  def documents_params
    params.require(:inventory_transaction_purchase_bill_asset_upload).permit(:name, :asset_path)
  end

  def find_purchase_bill
    @purchase_bill = Inventory::Transaction::PurchaseBill.find_by(id: params[:purchase_bill_id])
  end

  def retry_image_upload(counter = 1)
    @purchase_bill_asset.update(asset_path: documents_params[:asset_path], upload_retry_counter: counter)
    if @purchase_bill_asset.asset_path.file.exists?
      render json: { 'success': true }
    else
      counter = counter + 1
      if counter <= 5
        retry_image_upload(counter)
      else
        @purchase_bill_asset.destroy
        render json: { 'success': false }
      end
    end
  end
end
