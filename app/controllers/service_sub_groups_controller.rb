class ServiceSubGroupsController < ApplicationController
  before_action :authorize
  before_action :get_service_sub_groups, only: [:index, :create]
  before_action :get_service_sub_group, only: [:destroy]

  def index
    @service_sub_group = ServiceSubGroup.new
  end

  def create
    @service_sub_group = ServiceSubGroup.new(service_sub_group_params)

    if @service_sub_group.save
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
    @service_sub_group.update(is_active: false) if @service_sub_group.present?
    head :ok
  end

  private

  def service_sub_group_params
    params.require(:service_sub_group).permit(:name, :organisation_id, :user_id)
  end

  def get_service_sub_group
    @service_sub_group = ServiceSubGroup.find_by(id: params[:id])
  end

  def get_service_sub_groups
    @service_sub_groups = ServiceSubGroup.where(organisation_id: current_user.organisation_id, is_active: true)
  end
end
