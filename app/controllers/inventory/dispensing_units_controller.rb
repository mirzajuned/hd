class Inventory::DispensingUnitsController < ApplicationController
  before_action :authorize
  before_action :fetch_dispensing_unit, only: [:edit, :update, :show, :toggle_disable]

  layout 'backbone'
  require 'spreadsheet'

  def index
    fetch_dispensing_units
  end

  def new
    fetch_users
    @inventory_dispensing_unit = Inventory::DispensingUnit.new
  end

  def create
    @inventory_dispensing_unit = Inventory::DispensingUnit.new(dispensing_unit_params)
    @inventory_dispensing_unit.save!
    fetch_dispensing_units
  end

  def show; end

  def edit
    fetch_users
  end

  def update
    @inventory_dispensing_unit.update(dispensing_unit_params)
    fetch_dispensing_units
  end

  def destroy; end

  def toggle_disable
    @inventory_dispensing_unit.set(is_disable: params[:is_disable])
  end

  private

  def dispensing_unit_params
    params.require(:inventory_dispensing_unit).permit(
        :name, :organisation_id, :last_edited_by
    )
  end

  def fetch_dispensing_unit
    @inventory_dispensing_unit = Inventory::DispensingUnit.find_by(id: params[:id])
  end

  def fetch_dispensing_units
    @inventory_dispensing_units = Inventory::DispensingUnit.where(organisation_id: current_organisation['_id'].to_s)
                                .order_by(name: :asc)
  end

  def fetch_users
    @current_user = current_user
  end
end
