class Inventory::RolRulesController < ApplicationController
  before_action :authorize
  before_action :fetch_rol_rules, only: [:edit, :update, :show]

  layout 'backbone'
  require 'spreadsheet'

  def index
    fetch_rol_rules
  end

  def new
    fetch_users
    @inventory_rol_rule = Inventory::RolRule.new
  end

  def edit_multiple
    fetch_users
    fetch_item_variants_master
    fetch_stores_list
    @selected_store = params[:store_id]
    @store = Inventory::Store.find_by(id: @selected_store)
    fetch_rol_rules
    @inventory_rol_rule_attributes = @inventory_rol_rules.map(&:attributes)
  end

  def update_multiple
    fetch_users
    inventory_rol_rule = params[:inventory_rol_rule].to_unsafe_h

    CreateMultipleRolRuleJob.perform_later(inventory_rol_rule, @current_user.id.to_s)
  end

  def show; end

  def edit
    fetch_users
  end

  def update; end

  def destroy; end

  def toggle_disable; end

  private

  def fetch_rol_rules
    @inventory_rol_rules = Inventory::RolRule.where(organisation_id: current_organisation['_id'].to_s)
                                             .order_by(created_at: 'desc')
  end

  def fetch_item_variants_master
    query = params[:q].to_s
    options = { organisation_id: current_organisation['_id'].to_s, level: 'organisation', stockable: true }
    options = options.merge!(search: /#{Regexp.escape(query)}/i) if query.present?
    @variants = Inventory::Item::Variant.where(options).is_active.order_by(created_at: 'desc')
  end

  def fetch_stores_list
    @stores = Inventory::Store.where(organisation_id: current_organisation['_id'].to_s, is_disable: false)
                              .order_by(name: 'asc').pluck(:name, :id)
  end

  def fetch_users
    @current_user = current_user
  end
end
