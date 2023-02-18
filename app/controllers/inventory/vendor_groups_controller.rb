class Inventory::VendorGroupsController < ApplicationController
  before_action :authorize
  before_action :fetch_vendor_group, only: [:edit, :update, :show, :toggle_disable]

  layout 'backbone'
  require 'spreadsheet'

  def index
    fetch_vendor_groups
  end

  def new
    fetch_users
    @inventory_vendor_group = Inventory::VendorGroup.new
  end

  def create
    @inventory_vendor_group = Inventory::VendorGroup.new(vendor_group_params)
    @inventory_vendor_group.save!
    fetch_vendor_groups
  end

  def show; end

  def edit
    fetch_users
  end

  def update
    @inventory_vendor_group.update(vendor_group_params)
    fetch_vendor_groups
  end

  def destroy; end

  def toggle_disable
    @inventory_vendor_group.set(is_disable: params[:is_disable])
  end

  private

  def vendor_group_params
    params.require(:inventory_vendor_group).permit(
        :name, :description, :organisation_id, :last_edited_by
    )
  end

  def fetch_vendor_group
    @inventory_vendor_group = Inventory::VendorGroup.find_by(id: params[:id])
  end

  def fetch_vendor_groups
    @inventory_vendor_groups = Inventory::VendorGroup.where(organisation_id: current_organisation['_id'].to_s)
                                   .order_by(name: :asc)
  end

  def fetch_users
    @current_user = current_user
  end
end
