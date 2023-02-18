class CommunicationEventSetupsController < ApplicationController
  before_action :fetch_communication_event_setup, only: [:toggle_disable, :edit, :update, :destroy]

  def index
    fetch_communication_event_setups
    @facilities = @current_user.facilities.pluck(:name, :id)
  end

  def new
    fetch_users
    @facilities = @current_user.facilities
    @communication_event_setup = CommunicationEventSetup.new
  end

  def create
    @communication_event_setup = CommunicationEventSetup.new(communication_event_setup_params)
    @communication_event_setup.save!
    @facilities = @current_user.facilities.pluck(:name, :id)
    fetch_communication_event_setups
  end

  def edit
    fetch_communication_event_setups
    @facilities = @current_user.facilities
  end

  def update
    @communication_event_setup.update(communication_event_setup_params)
    fetch_communication_event_setups
    @facilities = @current_user.facilities
  end

  def toggle_disable
    @communication_event_setup.set(is_disable: params[:is_disable])
  end

  private

  def communication_event_setup_params
    params.require(:communication_event_setup).permit(
      :module_name, :organisation_id, :feature_type, :is_disable, :facility_id
    )
  end

  def fetch_communication_event_setup
    @communication_event_setup = CommunicationEventSetup.find_by(id: params[:id])
  end

  def fetch_communication_event_setups
    if params[:facility_id].blank?
      @communication_event_setups = CommunicationEventSetup.where(
        organisation_id: current_organisation['_id'].to_s
      ).order_by(created_at: :desc)
    else
      @communication_event_setups = CommunicationEventSetup.where(
        organisation_id: current_organisation['_id'].to_s, facility_id: params[:facility_id]
      ).order_by(created_at: :desc)
    end
  end

  def fetch_communication_templates
    @communication_templates = CommunicationTemplate.where(
      organisation_id: current_organisation['_id'].to_s
    ).order_by(name: :asc)
  end

  def fetch_users
    @current_user = current_user
  end
end
