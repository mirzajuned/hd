class Authorization::UserPoliciesController < ApplicationController
  before_action :authorize
  before_action :fetch_user_policy, only: [:edit, :update, :show, :toggle_disable]
  before_action :fetch_user


  def index
    fetch_user_policies
  end

  def new
    fetch_policies
    fetch_hg_policy
    @user_policy = Authorization::UserPolicy.new
  end

  def create
    @user_policy = Authorization::UserPolicy.new(user_policy_params)
    @user_policy.save!
  end

  def add_policy
    fetch_policies
    fetch_hg_policy
    fetch_policy_templates
    @user_policy = Authorization::UserPolicy.find_by(user_id: params[:user_id])
    if @user_policy.blank?
      @user_policy = Authorization::UserPolicy.new(user_id: params[:user_id])
      @user_policy.policy_ids = ""
      organisation_policies = Authorization::Policy.includes(:hg_policy).where(organisation_id: current_organisation['_id'].to_s, is_disable: false)
      organisation_policies.each do |policy|
        @user_policy.policy_ids+=(policy.id.to_s+", ") if policy.hg_policy.default_value == policy.authorized
      end
    end
    fetch_policy_template
    @user_policy.policy_ids = @policy_template.try(:policy_ids) if @policy_template.present?
  end

  def save_policy
    @user_policy = Authorization::UserPolicy.find_by(user_id: params[:authorization_user_policy][:user_id])
    if @user_policy.present?
      @user_policy.update(user_policy_params)
    else
      @user_policy = Authorization::UserPolicy.new(user_policy_params)
      @user_policy.save!
    end

    fetch_user_policies
  end

  def show; end

  def edit
    fetch_users
    fetch_policies
  end

  def update
    @user_policy = Authorization::UserPolicy.find_by(user_id: params[:authorization_user_policy][:user_id])
    @user_policy.update(user_policy_params)
    fetch_user_policies
  end

  def destroy; end

  def toggle_disable
    @user_policy.set(is_disable: params[:is_disable])
    fetch_user_policies
  end


  private

  def user_policy_params
    params.require(:authorization_user_policy).permit(
        :user_id, :organisation_id, :last_edited_by, :policy_ids
    )
  end

  def fetch_user_policy
    @user_policy = Authorization::UserPolicy.find_by(id: params[:id])
  end

  def fetch_hg_policy
    @hg_policy = Authorization::HgPolicy.find_by(id: params[:hg_policy_id])
  end

  def fetch_policy_template
    @policy_template = Authorization::PolicyTemplate.find_by(id: params[:policy_template])
  end

  def fetch_policy_templates
    @policy_templates = Authorization::PolicyTemplate.where(organisation_id: current_organisation['_id'].to_s)
  end

  def fetch_user_policies
    @user_policies = Authorization::UserPolicy.where(organisation_id: current_organisation['_id'].to_s)
  end

  def fetch_policies
    @policies = Authorization::Policy.includes(:hg_policy).where(organisation_id: current_organisation['_id'].to_s, is_disable: false).order_by(module_name: :asc).group_by(&:module_name)
  end

  def fetch_hg_policies
    @policies = Authorization::HgPolicy.includes(:policies).where(organisation_id: current_organisation['_id'].to_s)
  end

  def fetch_user
    @user = User.find_by(id: params[:user_id])
  end
end
