class CommunicationSettingsController < ApplicationController
  after_action :index, only: [:create]
  before_action :fetch_communication_setting, only: [:toggle_disable, :edit, :update, :destroy, :show, :toggle_disable_number, :toggle_disable_template]
  before_action :fetch_communication_templates_numbers, only: [:new, :edit]
  before_action :fetch_communication_template, only: [:toggle_disable_template, :edit_template, :show_template]
  before_action :fetch_communication_number, only: [:toggle_disable_number, :edit_number]

  def index
    fetch_communication_settings
  end

  def new
    @communication_setting = CommunicationSetting.new
    fetch_communication_templates_numbers
  end

  def add_template
    @communication_template = CommunicationTemplate.new
  end

  def add_number
    @communication_number = CommunicationNumber.new
  end

  def create_template
    params[:communication_template][:module_names] = params[:communication_template][:module_names].reject { |c| c.empty? }
    @communication_template = CommunicationTemplate.new(communication_template_params)
    if !@communication_template.save
      flash[:error] = @communication_template.errors.full_messages.to_sentence
    else
      flash[:error] = nil
    end
    fetch_communication_settings
    approved_templates
  end

  def create_number
    @communication_number = CommunicationNumber.new(communication_number_params)
    if !@communication_number.save
      flash[:error] = @communication_number.errors.full_messages.to_sentence
    else
      flash[:error] = nil
    end
    fetch_communication_settings
    approved_numbers
  end

  def edit_template; end

  def edit_number; end

  def update_template
    params[:communication_template][:module_names] = params[:communication_template][:module_names].reject { |c| c.empty? }
    @communication_template = CommunicationTemplate.find(params[:communication_template][:communication_id])
    if !@communication_template.update(communication_template_params)
      flash[:error] = @communication_template.errors.full_messages.to_sentence
    else
      flash[:error] = nil
    end
    approved_templates
  end

  def update_number
    @communication_number = CommunicationNumber.find(params[:communication_number][:communication_id])
    if !@communication_number.update(communication_number_params)
      flash[:error] = @communication_number.errors.full_messages.to_sentence
    else
      flash[:error] = nil
    end
    approved_numbers
  end

  def create
    get_updated_params(params)
    if !@communication_setting.present?
      @communication_setting = CommunicationSetting.new(communication_settings_params)
      @communication_setting.save!
      fetch_communication_settings
      flash[:error] = nil
    else
      flash[:error] = 'Selected Number Already Exists On Link Templates, Please Add Template Using Edit In There Only'
    end
  end

  def get_updated_params(params)
    params[:communication_setting][:communication_template_ids] =
      params[:communication_setting][:communication_template_ids].reject { |c| c.empty? }
    params[:communication_setting][:facility_ids] =
      Facility.where(
        communication_number_id: params[:communication_setting][:communication_number_id]
      ).pluck(:id).join(',').split(',') rescue []
    @communication_setting = CommunicationSetting.find_by(
      communication_number_id: params[:communication_setting][:communication_number_id],
      organisation_id: current_organisation['_id']
    )
  end

  def edit
    fetch_communication_templates_numbers
  end

  def update
    params[:communication_setting][:communication_template_ids] = params[:communication_setting][:communication_template_ids].reject { |c| c.empty? }
    params[:communication_setting][:facility_ids] =
      Facility.where(
        communication_number_id: params[:communication_setting][:communication_number_id]
      ).pluck(:id).join(',').split(',') rescue []
    @communication_setting.update(communication_settings_params)
    fetch_communication_settings
  end

  def show
    fetch_communication_templates_numbers
  end

  def show_template; end

  def toggle_disable
    @communication_setting.set(is_disable: params[:is_disable])
    fetch_communication_settings
  end

  def toggle_disable_template
    @communication_template.set(is_disable: params[:is_disable])
    approved_templates
    checked_template_communication_events_disabled
  end

  def toggle_disable_number
    @communication_number.set(is_disable: params[:is_disable])
    approved_numbers
    checked_number_communication_events_disabled
  end

  def communication_template_preview
    @communication_templates = CommunicationTemplate.in(id: params[:communication_template_ids])
  end

  def approved_templates
    @approved_templates = CommunicationTemplate.where(organisation_id: current_organisation['_id'].to_s)
  end

  def approved_numbers
    @approved_numbers = CommunicationNumber.where.in(organisation_id: [current_organisation['_id'].to_s, nil])
  end

  def event_trigger
    @response = CommunicationNotifications::WhatsappNotificationService.call(CommunicationEvent.first)
  end

  private

  def checked_template_communication_events_disabled
    if @communication_template.try(:is_disable)
      @communication_template.communication_events.map { |p| p.update!(template_disabled_status: true) }
    else
      @communication_template.communication_events.map { |p| p.update!(template_disabled_status: false) }
    end
  end

  def checked_number_communication_events_disabled
    @communication_settings = @communication_number.communication_settings
    @communication_template_ids =
      @communication_number.communication_settings.pluck(:communication_template_ids).flatten.uniq
    @communication_events = CommunicationEvent.where.in(communication_template_id: @communication_template_ids)
    if @communication_number.try(:is_disable)
      @communication_events.map { |p| p.update!(number_disabled_status: true) }
    else
      @communication_events.map { |p| p.update!(number_disabled_status: false) }
    end
  end

  def communication_template_params
    params.require(:communication_template).permit(
      :organisation_id, :communication_type, :template_content, :template_title,
      module_names: []
    )
  end

  def communication_number_params
    params.require(:communication_number).permit(
      :organisation_id, :communication_type, :communication_number, :country_code, :country_flag
    )
  end

  def communication_settings_params
    params.require(:communication_setting).permit(
      :organisation_id, :communication_type, :communication_number_id,
      communication_template_ids: [], facility_ids: []
    )
  end

  def fetch_communication_setting
    @communication_setting = CommunicationSetting.find(params[:id])
  end

  def fetch_communication_template
    @communication_template = CommunicationTemplate.find(params[:id])
  end

  def fetch_communication_number
    @communication_number = CommunicationNumber.find(params[:id])
  end

  def fetch_communication_settings
    @communication_settings = CommunicationSetting.where(organisation_id: current_organisation['_id'].to_s)
  end

  def fetch_communication_templates_numbers
    @communication_numbers = CommunicationNumber.where.in(
      organisation_id: [current_organisation['_id'].to_s, nil], is_disable: false
    )
    @communication_templates = CommunicationTemplate.where(
      organisation_id: current_organisation['_id'].to_s, is_disable: false
    )
  end
end
