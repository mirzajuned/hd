class Authorization::PoliciesController < ApplicationController
  before_action :authorize
  before_action :fetch_policy, only: [:edit, :update, :show, :toggle_disable]
  

  def index
    fetch_policies
  end

  def new
    fetch_users
    fetch_hg_policy
    @policy = Authorization::Policy.new
  end

  def create
    @policy = Authorization::Policy.new(policy_params)
    @policy.save!
    fetch_policies
  end

  def show; end

  def edit
    fetch_users
    fetch_policy
    fetch_hg_policy
  end

  def update
    @policy.update(policy_params)
    fetch_policies
  end

  def destroy; end

  def toggle_disable
    @policy.set(is_disable: params[:is_disable])
  end


  private

  def policy_params
    params.require(:authorization_policy).permit(
        :authorized, :entity_data, :organisation_id, :last_edited_by, :rules, :module_name, :module_id,
        :feature_name, :feature_id, :component_name, :component_id, :description, :hg_policy_id, :maker_checker
    )
  end

  def fetch_policy
    @policy = Authorization::Policy.find_by(id: params[:id])
  end

  def fetch_hg_policy
    @hg_policy = Authorization::HgPolicy.find_by(id: params[:hg_policy_id])
  end

  def fetch_policies
    @policies = Authorization::Policy.includes(:hg_policy).where(organisation_id: current_organisation['_id'].to_s, is_disable: false).order_by(module_name: :asc).group_by(&:module_name)
  end

  def fetch_hg_policies
    @policies = Authorization::HgPolicy.includes(:policies).where(organisation_id: current_organisation['_id'].to_s)
  end

  def fetch_users
    @current_user = current_user
  end
end
