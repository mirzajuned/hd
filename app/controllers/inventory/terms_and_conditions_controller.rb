class Inventory::TermsAndConditionsController < ApplicationController
  before_action :authorize
  before_action :fetch_terms_and_condition, only: [:edit, :update, :toggle_disable]

  def index
    fetch_terms_and_conditions
  end

  def new
    @terms_and_condition = Inventory::TermsAndCondition.new
  end

  def create
    @terms_and_condition = Inventory::TermsAndCondition.new(other_charge_params)
    @terms_and_condition.save!
    fetch_terms_and_conditions
  end

  def edit; end

  def update
    @terms_and_condition.update(other_charge_params)
    fetch_terms_and_conditions
  end

  def toggle_disable
    @terms_and_condition.set(is_disable: params[:is_disable])
  end

  private

  def fetch_terms_and_conditions
    @terms_and_conditions = Inventory::TermsAndCondition.where(organisation_id: current_organisation['_id'].to_s)
  end

  def fetch_terms_and_condition
    @terms_and_condition = Inventory::TermsAndCondition.find_by(id: params[:id])
  end

  def other_charge_params
    params.require(:inventory_terms_and_condition).permit(
      :type, :description, :organisation_id, :user_id, :facility_id, :created_by, :created_on
    )
  end
end
