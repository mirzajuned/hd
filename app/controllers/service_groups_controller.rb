class ServiceGroupsController < ApplicationController
  before_action :authorize
  before_action :get_service_groups, only: [:index, :create]
  before_action :get_service_group, only: [:destroy]

  def index
    @service_group = ServiceGroup.new
  end

  def create
    @service_group = ServiceGroup.new(service_group_params)

    if @service_group.save
      respond_to do |format|
        format.js { render 'create.js.erb' }
      end
    else
      respond_to do |format|
        format.js { render 'error.js.erb' }
      end
    end
  end

  def destroy
    @service_group.update(is_active: false) if @service_group.present?
    head :ok
  end

  private

  def service_group_params
    params.require(:service_group).permit(:name, :organisation_id, :user_id)
  end

  def get_service_group
    @service_group = ServiceGroup.find_by(id: params[:id])
  end

  def get_service_groups
    @service_groups = ServiceGroup.where(organisation_id: current_user.organisation_id, is_active: true)
  end
end
