class Inventory::SubCategoriesController < ApplicationController
  before_action :authorize
  before_action :fetch_sub_category, only: [:edit, :update, :show, :toggle_disable]

  layout 'backbone'
  require 'spreadsheet'

  def index
    fetch_sub_categories
  end

  def new
    fetch_users
    fetch_categories
    @inventory_sub_category = Inventory::SubCategory.new
  end

  def create
    @inventory_sub_category = Inventory::SubCategory.new(sub_category_params)
    name = @inventory_sub_category.name&.titleize
    @inventory_sub_category.name = name
    @inventory_sub_category.save!
    fetch_sub_categories
  end

  def show; end

  def edit
    fetch_users
    fetch_categories
  end

  def update
    @inventory_sub_category.update(sub_category_params)
    @inventory_sub_category.name = @inventory_sub_category.name&.titleize
    @inventory_sub_category.save!
    fetch_sub_categories
  end

  def destroy; end

  def check_name
    existing_name = params[:existing_name]&.titleize
    category_id = params[:category_id]
    name = params[:name]&.titleize

    if existing_name != name
      @inv_sub_category = Inventory::SubCategory.where(name: name, category_id: category_id, organisation_id: current_user.organisation_id)
    end
    respond_to do |format|
      format.json { render json: !@inv_sub_category.try(:to_a).present? }
    end
  end

  def toggle_disable
    @inventory_sub_category.set(is_disable: params[:is_disable])
  end

  private

  def sub_category_params
    params.require(:inventory_sub_category).permit(
      :name, :category_id, :description, :organisation_id, :last_edited_by
    )
  end

  def fetch_categories
    @inventory_categories = Inventory::Category.where(organisation_id: current_organisation['_id'].to_s,
                                                      is_disable: false).order_by(name: :asc)
  end

  def fetch_sub_category
    @inventory_sub_category = Inventory::SubCategory.find_by(id: params[:id])
  end

  def fetch_sub_categories
    @inventory_sub_categories = Inventory::SubCategory.includes(:category).where(organisation_id: current_organisation['_id'].to_s).order_by(name: :asc)
  end

  def fetch_users
    @current_user = current_user
  end
end
