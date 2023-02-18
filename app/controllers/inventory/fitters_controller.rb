class Inventory::FittersController < ApplicationController
  before_action :authorize
  layout 'backbone'
  require 'spreadsheet'
  # before_action :set_inventory_item, [only: :create, :update]
  before_action :fetch_fitter, only: [:edit, :update, :toggle_disable]

  def index
    @store_id = params[:store_id]
    #@fitters = Inventory::Fitter.where(:store_ids.in => [ @store_id])
    fetch_fitter_list(@store_id)
  end

  def new
    @fitter = Inventory::Fitter.new
    @store_id = params[:store_id]
  end

  def create
    @fitter = Inventory::Fitter.new(fitter_params)
    @store_ids = params[:inventory_fitter][:store_ids]
    @store_id = @store_ids[0]
    if @fitter.save
       fetch_fitter_list(@store_id)
    else
      @fitter = Inventory::Fitter.new
      render 'new'
    end
  end

  def edit
    @fitter = Inventory::Fitter.find_by(id: params[:id])
    @store_id = params[:store_id]
  end

  def update
    @fitter = Inventory::Fitter.find_by(id: params[:id])
    @store_id = params[:inventory_fitter][:store_id]
    if @fitter.update(fitter_params)
      fetch_fitter_list(@store_id)
    else
      render 'edit'
    end
  end

  def destroy
    @fitter = Inventory::Fitter.find_by(id: params[:id])
    @store_id = params[:store_id]
    if @fitter.update(is_deleted: true, is_disable: true)
      fetch_fitter_list(@store_id)
    else
      head :no_content
    end
  end
  def toggle_disable
    @fitter.set(is_disable: params[:is_disable], is_deleted: params[:is_disable])
  end

  private

  def fetch_fitter_list(store_ids)
    @fitters = Inventory::Fitter.where(:store_ids.in => [@store_id], is_deleted: false, is_disable: false)
  end

  def fetch_fitter
    @fitter = Inventory::Fitter.find_by(id: params[:id])
  end

  def fitter_params
    params.require(:inventory_fitter).permit(:name, :mobile_number, :secondary_mobile_number, :email,
                                             :company_name, :address, :facility_id, :organisation_id, :store_id, :store_ids => [])
  end
end
