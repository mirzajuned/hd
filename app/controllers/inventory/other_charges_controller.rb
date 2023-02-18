class Inventory::OtherChargesController < ApplicationController
  before_action :authorize
  before_action :fetch_other_charges, only: [:index]
  before_action :fetch_other_charge, only: [:edit, :update, :toggle_disable]

  def index; end

  def new
    @inventory_other_charge = Inventory::OtherCharge.new
  end

  def create
    @inventory_other_charge = Inventory::OtherCharge.new(other_charge_params)
    @inventory_other_charge.save!
    fetch_other_charges
  end

  def edit; end

  def update
    @inventory_other_charge.update(other_charge_params)
    fetch_other_charges
  end

  def toggle_disable
    @inventory_other_charge.set(is_disable: params[:is_disable])
  end

  private

  def fetch_other_charges
    @inventory_other_charges = Inventory::OtherCharge.where(organisation_id: current_organisation['_id'].to_s)
  end

  def fetch_other_charge
    @inventory_other_charge = Inventory::OtherCharge.find_by(id: params[:id])
  end

  def other_charge_params
    params.require(:inventory_other_charge).permit(
      :name, :description, :organisation_id, :last_edited_by, :facility_id
    )
  end
end
