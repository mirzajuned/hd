class Inventory::SupplyChainsController < ApplicationController
  def index; end

  def update_expiry_format
    organisation = Organisation.find(params[:id])
    organisation.update!(inventory_expiry_format: params[:inventory_expiry_format], inventory_hsn_code_required: params[:inventory_hsn_code_required])
  end
end
