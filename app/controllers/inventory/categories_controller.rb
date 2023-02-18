class Inventory::CategoriesController < ApplicationController
  before_action :authorize
  before_action :fetch_category, only: [:edit, :update, :show, :toggle_disable]

  layout 'backbone'
  require 'spreadsheet'

  def index
    fetch_categories
  end

  def new
    fetch_users
    @inventory_category = Inventory::Category.new
  end

  def create
    @inventory_category = Inventory::Category.new(category_params)
    @inventory_category.save!
    fetch_categories
  end

  def show; end

  def edit
    fetch_users
  end

  def update
    @inventory_category.update(category_params)
    fetch_categories
  end

  def destroy; end

  def check_name
    existing_name = params[:existing_name].downcase
    name = params[:inventory_category][:name].to_s.strip.downcase

    if existing_name != name
      @inv_category = Inventory::Category.find_by(organisation_id: current_user.organisation_id, name: /#{Regexp.escape(name)}$/i)
    end
    respond_to do |format|
      format.json { render json: !@inv_category.try(:to_a).present? }
    end
  end

  def check_prefix
    existing_prefix = params[:existing_prefix].downcase
    prefix = params[:inventory_category][:prefix].to_s.strip.downcase

    if existing_prefix != prefix
      @inv_category = Inventory::Category.find_by(organisation_id: current_user.organisation_id, prefix: /#{Regexp.escape(prefix)}$/i)
    end
    respond_to do |format|
      format.json { render json: !@inv_category.try(:to_a).present? }
    end
  end

  def toggle_disable
    @inventory_category.set(is_disable: params[:is_disable])
  end

  def link_unlink_multiple_dispensing_unit
    @type = params[:type]
    @category_id = params[:category_id]
    @category = Inventory::Category.find_by(id: params[:category_id])
    dispensing_unit_ids = Inventory::Category.find_by(id: params[:category_id])&.dispensing_unit_ids
    dispensing_units = Inventory::DispensingUnit.where(organisation_id: current_organisation['_id'].to_s, is_disable: false)
    @dispensing_units = []
    @other_dispensing_units = []
    dispensing_units.each do |dispensing_unit|
      if @type == 'unlink_dispensing_unit'
        if dispensing_unit_ids.include? dispensing_unit.id
          @dispensing_units << dispensing_unit
        else
          @other_dispensing_units << dispensing_unit
        end
      elsif dispensing_unit_ids.include? dispensing_unit.id
        @other_dispensing_units << dispensing_unit
      else
        @dispensing_units << dispensing_unit
      end
    end
  end

  def save_link_unlink_multiple_dispensing_unit
    @category_id = params[:category_id]
    @dispensing_units = Inventory::DispensingUnit.where(:id.in => params[:dispensing_unit_ids])
    @category = Inventory::Category.find_by(id: @category_id)
    if params[:type] == 'unlink_dispensing_unit'
      @dispensing_units.each do |dispensing_unit|
        dispensing_unit.pull(category_ids: @category.id)
        @category.pull(dispensing_unit_ids: dispensing_unit.id)
      end
    else
      @dispensing_units.each do |dispensing_unit|
        dispensing_unit.add_to_set(category_ids: @category.id)
        @category.add_to_set(dispensing_unit_ids: dispensing_unit.id)
      end
    end
    fetch_categories
  end

  private

  def category_params
    params.require(:inventory_category).permit(
      :name, :description, :organisation_id, :last_edited_by, :multiple_variants, :type, :stockable, :prefix, :expiry_days
    )
  end

  def fetch_category
    @inventory_category = Inventory::Category.find_by(id: params[:id])
  end

  def fetch_categories
    @inventory_categories = Inventory::Category.where(organisation_id: current_organisation['_id'].to_s)
                                               .order_by(name: :asc)
  end

  def fetch_users
    @current_user = current_user
  end
end
