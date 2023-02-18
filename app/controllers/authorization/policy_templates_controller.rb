class Authorization::PolicyTemplatesController < ApplicationController
  before_action :authorize
  before_action :fetch_policy_template, only: [:edit, :update, :show, :toggle_disable]


  def index
    fetch_policy_templates
  end

  def new
    fetch_policies
    fetch_hg_policy
    @policy_template = Authorization::PolicyTemplate.new
  end

  def create
    @policy_template = Authorization::PolicyTemplate.new(policy_template_params)
    @policy_template.save!
    fetch_policy_templates
  end

  def show; end

  def edit
    fetch_users
    fetch_policies
  end

  def update
    @policy_template.update(policy_template_params)
    fetch_policy_templates
  end

  def destroy; end

  def toggle_disable
    @policy_template.set(is_disable: params[:is_disable])
    fetch_policy_templates
  end


  private

  def policy_template_params
    params.require(:authorization_policy_template).permit(
        :name, :organisation_id, :last_edited_by, :policy_ids
    )
  end



  def fetch_policy_template
    @policy_template = Authorization::PolicyTemplate.find_by(id: params[:id])
  end

  def fetch_hg_policy
    @hg_policy = Authorization::HgPolicy.find_by(id: params[:hg_policy_id])
  end

  def fetch_policy_templates
    @policy_templates = Authorization::PolicyTemplate.where(organisation_id: current_organisation['_id'].to_s)
  end

  def fetch_policies
    @policies = Authorization::Policy.includes(:hg_policy).where(organisation_id: current_organisation['_id'].to_s)
                    .order_by(module_name: :asc).group_by(&:module_name)
  end

  def fetch_hg_policies
    @policies = Authorization::HgPolicy.includes(:policies).where(organisation_id: current_organisation['_id'].to_s)
  end

  def fetch_users
    @current_user = current_user
  end
end
