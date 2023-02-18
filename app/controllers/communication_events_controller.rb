class CommunicationEventsController < ApplicationController
  before_action :fetch_communication_event, only: [:toggle_disable, :edit, :update, :destroy, :show]

  def index
    @module_type = '0'
    fetch_communication_events
  end

  def new
    @module_type = params[:module_type]
    fetch_users
    @communication_event = CommunicationEvent.new
    fetch_communication_templates
  end

  def create
    @feature_type = CommunicationEvent.feature_type.values.index { |x|
      [params[:communication_event][:feature_type]].include?(x) }
    @communication_event = CommunicationEvent.where(organisation_id: current_organisation['_id'].to_s, feature_type: @feature_type.to_i).first
    if @communication_event.nil?
      @communication_event = CommunicationEvent.new(communication_event_params)
      @communication_event.save!
      flash[:error] = nil
    else
      flash[:error] = "#{params[:communication_event][:feature_type].titleize } Event already exists, Please select another event."
    end
    @module_name = params[:communication_event][:module_name]
    fetch_communication_events
  end

  def edit
    fetch_communication_events
    fetch_communication_templates
  end

  def update
    @communication_event.update(communication_event_params)
    @module_name = CommunicationEvent.module_name.values.index do |x|
      [params[:communication_event][:module_name]].include?(x)
    end
    fetch_communication_events
  end

  def toggle_disable
    @communication_event.set(is_disable: params[:is_disable])
  end

  def destroy
    @communication_event.set(is_deleted: true)
  end

  def set_templates_message
    @communication_tempalte = CommunicationTemplate.find(params[:id])
    render json: { message_text: @communication_tempalte.template_content }
  end

  def show; end

  def communication_event_type
    @communication_event = CommunicationEvent.find_by(id: params[:communication_event_id])
  end

  def communication_reminder_type
    @communication_event = CommunicationEvent.find_by(id: params[:communication_event_id])
  end

  def module_type_based
    @module_type = params[:module_name]
    fetch_communication_events
  end

  private

  def communication_event_params
    params.require(:communication_event).permit(
      :name, :module_name, :organisation_id, :feature_type, :trigger_instantly, :communication_template_id,
      :message_format, :is_disable, :is_deleted, :status, :event_type, :reminder_type, :event_reminder_time,
      :event_reminder_days, :event_reminder_hour, :confirmation_type, :event_confirmation_time,
      :event_confirmation_days
    )
  end

  def fetch_communication_event
    @communication_event = CommunicationEvent.find_by(id: params[:id])
  end

  def fetch_communication_events
    params[:module_name] = 0 if params[:module_name].blank?
    @communication_events = CommunicationEvent.where(
      module_name: params[:module_name], organisation_id: current_organisation['_id'].to_s
    ).order_by(created_at: :desc)
  end

  def fetch_communication_templates
    @communication_templates = CommunicationTemplate.where(
      organisation_id: current_organisation['_id'].to_s, is_disable: false,
      module_names: CommunicationEvent.module_name.values[params[:module_type].to_i]
    ).order_by(name: :asc)
  end

  def fetch_users
    @current_user = current_user
  end
end
