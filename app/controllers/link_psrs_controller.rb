class LinkPsrsController < ApplicationController
  before_action :authorize
  before_action :doorkeeper_authorize!, only: [:save_psr_data]
  before_action :find_facility_with_token, only: [:unregister_device, :edit]

  def index
    @active_devices = LinkFacilityDevice.where(organisation_id: current_user.organisation_id, is_registered: true)
    @unregistered_devices = LinkFacilityDevice.where(organisation_id: current_user.organisation_id,
                                                     is_registered: false, is_reregistered: false)
    map_active_devices
    map_unregistered_devices
  end

  def new
    get_organisation_facilities
    @device_name = nil
    @link_facility_id = nil
  end

  def edit
    get_organisation_facilities
    @device_name = @link_facility.device_name
    @link_facility_id = @link_facility.id
  end

  def generate_qr_code; end

  def received_psr_data
    qr_auth_token = JSON.parse(params[:qr_code_token])['qr_code_token']
    @available_device = LinkFacilityDevice.find_by(qr_auth_token: qr_auth_token)
    if params[:link_fac_id].present? && @available_device.present?
      @link_facility = LinkFacilityDevice.find(BSON::ObjectId(params[:link_fac_id]))
      @link_facility.update(is_reregistered: true)
    end
  end

  def unregister_device
    session_id = TokenSession.last.try(:session_id)
    begin
      url = if Rails.env.development?
              'http://127.0.0.1:8080/api/v1/ehr/unregister_device/update'
            elsif Rails.env.preproduction?
              'https://pppsr.healthgraph.in/api/v1/ehr/unregister_device/update'
            else
              'https://psr.healthgraph.in/api/v1/ehr/unregister_device/update'
            end

      payload = { is_registered: false, qr_auth_token: @qr_auth_token, unregistered_by: current_user.username }.as_json
      request = RestClient::Request.execute(method: :post, url: url,
                                            payload: payload,
                                            headers: { 'Authorization' => 'Bearer ' + session_id,
                                                       'Content-Type' => 'application/json' })
      # puts request
      @psr_result = update_device_boolean
      @response = JSON.parse(request)
    rescue StandardError
      redirect_to api_v1_sessions_create_session_path(params: params.permit!, url: 'unregister_device_path')
    end
    respond_to do |format|
      format.js {}
    end
  end

  def update_device_boolean
    @link_facility.update(is_registered: false, unregistered_on: DateTime.current,
                          unregistered_by: current_user.username)
  end

  def get_country
    country_name = Country.find(Facility.find(params[:fac_id]).country_id).name
    render json: { status: 200, country: country_name }
  end

  private

  def map_active_devices
    @map_active_devices = {}
    @active_devices.each do |device|
      @map_active_devices[device.id] = device
    end
  end

  def get_organisation_facilities
    @current_user = current_user
    @facilities = @current_user.facilities.pluck(:name, :id)
    # @facilities = Facility.where(organisation_id: current_user.organisation_id, is_active: true)
    @facility_count = @facilities.count
  end

  def map_unregistered_devices
    @map_unregistered_devices = {}
    @unregistered_devices.each do |device|
      @map_unregistered_devices[device.id] = device
    end
  end

  def find_facility_with_token
    @link_facility = LinkFacilityDevice.find(BSON::ObjectId(params[:id]))
    @qr_auth_token = @link_facility.qr_auth_token
  end
end
