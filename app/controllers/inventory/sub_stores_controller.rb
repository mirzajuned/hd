class Inventory::SubStoresController < ApplicationController
  before_action :authorize
  before_action :find_store, only: [:index, :new, :filter_index, :edit]

  def index
    @sub_stores = Inventory::SubStore.where(store_id: params[:store_id])
  end

  def new
    @sub_store = Inventory::SubStore.new
  end

  def show
    @sub_store = Inventory::SubStore.find_by(id: params[:id])
    @store_id = @sub_store.store_id
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    @lots = Inventory::Item::Lot.where(sub_store_id: params[:id])
  end

  def create
    @sub_store = Inventory::SubStore.new(sub_store_params)
    @sub_store.save!
    @store_id = @sub_store.store_id
    fetch_sub_stores
  end

  def edit
    @sub_store = Inventory::SubStore.find_by(id: params[:id])
  end

  def update
    @sub_store = Inventory::SubStore.find_by(id: params[:id])
    @sub_store.update!(sub_store_params)
    @store_id = @sub_store.store_id
    fetch_sub_stores
  end

  def destroy
    @sub_store = Inventory::SubStore.find_by(id: params[:id])
    @sub_store.update(is_deleted: true)
    fetch_sub_stores
  end

  def enable_sub_store
    @sub_store = Inventory::SubStore.find_by(id: params[:id])
    @sub_store.update(is_deleted: false)
    fetch_sub_stores
  end

  def filter_index
    @sub_stores = Inventory::SubStore.where(store_id: params[:store_id])
  end

  private

  def fetch_sub_stores
    @sub_stores = Inventory::SubStore.where(store_id: @sub_store.store_id).order_by(created_at: 'desc')
  end

  def sub_store_params
    params.require(:inventory_sub_store).permit(:name, :store_id, :is_active, :is_deleted, :facility_id,
                                                :organisation_id)
  end

  def find_store
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
  end
end
