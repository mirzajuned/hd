class CampsController < ApplicationController
  before_action :authorize
  before_action :set_facilities, except: [:edit]
  before_action :find_camp, only: [:edit, :update]
  before_action :failed_hits

  def index
    @facility_id = params[:facility_id] || current_facility.id
    @camps = Camp.where(facility_id: @facility_id.to_s).order_by(created_at: 'desc')
    @camp_status = {}
    @type = params[:type]
    @camps.each do |camp|
      status = if camp.camp_date > Date.current
                 'Upcoming'
               elsif camp.camp_date < Date.current
                 'Closed'
               else
                 'Today'
               end
      @camp_status[camp.id] = status
    end
  end

  def new
    @type = params[:type]
    @camp = Camp.new
    @sponsors = PayerMaster.where(contact_group_name: 'Sponsor', facility_id: current_facility.id, is_active: true)
                           .pluck(:display_name, :id)
  end

  def create
    @camp = Camp.new(camp_params)
    append_fields
    save_in_outreach
    raise StandardError, (JSON.parse(@request)['msg']).to_s unless JSON.parse(@request)['status'] == 200

    @camp.save!
    OutreachJobs::CampReferenceJob.perform_later(@camp.id.to_s, current_user.id.to_s)
  rescue StandardError => e
    @err = e.message.to_s
    logger.info ">>>>>>>>>#{@err}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    if @err == '401 Unauthorized' && @no_of_failed_hits <= 3
      Token::GenerateToken.call
      @no_of_failed_hits += 1
      create
    else
      respond_to do |format|
        format.js { render partial: 'error.js.erb', locals: { err: 'opps failed to save' } }
      end
    end
  end

  def save_in_outreach
    session_id = OutreachSession.last.try(:session_id)
    url = Global.outreach_url[Rails.env]['create_camp']
    payload = @camp.as_json.except!('_id')

    @request = RestClient::Request.execute(method: :post, url: url, payload: payload,
                                           headers: { 'Authorization' => 'Bearer ' + session_id,
                                                      'Content-Type' => 'application/json' })
  end

  def update_in_outreach
    session_id = OutreachSession.last.try(:session_id)
    url = Global.outreach_url[Rails.env]['update_camp']
    update_hash = camp_params.as_json.except!('_id')
    update_hash[:username] = @camp.username
    payload = update_hash

    @request = RestClient::Request.execute(method: :patch, url: url, payload: payload,
                                           headers: { 'Authorization' => 'Bearer ' + session_id,
                                                      'Content-Type' => 'application/json' })
  end

  def update
    update_in_outreach
    raise StandardError, (JSON.parse(@request)['msg']).to_s unless JSON.parse(@request)['status'] == 200

    @camp.update_attributes!(camp_params)
    OutreachJobs::CampReferenceUpdateJob.perform_later(@camp.id.to_s, params.as_json)
  rescue StandardError => e
    @err = e.message.to_s
    logger.info ">>>>>>>>>#{@err}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    if @err == '401 Unauthorized' && @no_of_failed_hits <= 3
      Token::GenerateToken.call
      @no_of_failed_hits += 1
      update
    else
      respond_to do |format|
        format.js { render partial: 'error.js.erb', locals: { err: 'opps failed to save' } }
      end
    end
  end

  def edit
    @facilities = Facility.where(id: @camp.facility_id)
    @facility_arr = @facilities.pluck(:name, :id)
    @sponsors = PayerMaster.where(contact_group_name: 'Sponsor', facility_id: @camp.facility_id, is_active: true)
                           .pluck(:display_name, :id)
  end

  def deactivate
    @camp = Camp.find_by(id: params[:id])
    @camp.update(is_active: params[:value])
    deactivate_in_outreach
  rescue StandardError => e
    @err = e.message.to_s
    logger.info ">>>>>>>>>#{@err}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    if @err == '401 Unauthorized' && @no_of_failed_hits <= 3
      Token::GenerateToken.call
      @no_of_failed_hits += 1
      deactivate_in_outreach
    end
  end

  def facility_sponsors
    @sponsors = PayerMaster.where(contact_group_name: 'Sponsor', facility_id: params[:facility_id], is_active: true)
    camp_arr = []
    @sponsors.each do |sponsor|
      s_hash = {}
      s_hash[:id] = sponsor.id
      s_hash[:text] = sponsor.display_name
      camp_arr << s_hash
    end
    render json: camp_arr
  end

  def deactivate_in_outreach
    session_id = OutreachSession.last.try(:session_id)
    url = Global.outreach_url[Rails.env]['active_state_camp']
    payload = { username: @camp.username, value: params[:value] }

    @request = RestClient::Request.execute(method: :get, url: url, payload: payload,
                                           headers: { 'Authorization' => 'Bearer ' + session_id,
                                                      'Content-Type' => 'application/json' })
  end

  private

  def failed_hits
    @no_of_failed_hits = 0
  end

  def set_facilities
    @facilities = Facility.where(organisation_id: current_organisation['_id'])
    @facility_arr = @facilities.pluck(:name, :id)
  end

  def append_fields
    @camp.organisation_id = BSON::ObjectId(current_organisation['_id'])
    @camp.created_by = current_user.fullname
    @camp.password = generate_password
    @camp.username = generate_username
  end

  def generate_password
    code1 = Array.new(1) { Array('A'..'Z').sample }.join
    code2 = Array.new(5) { Array('a'..'z').sample }.join
    code3 = Array.new(1) { ['@'].sample }.join
    code4 = Array.new(1) { Array(0..9).sample }.join
    code1 + code2 + code3 + code4
  end

  def generate_username
    o = [('a'..'z'), ('A'..'Z'), (0..9)].map(&:to_a).flatten
    random_string = (0...5).map { o[rand(o.length)] }.join
    'CAMP' + current_facility.name.slice(0, 2) + random_string
  end

  def find_camp
    @camp = Camp.find_by(id: params[:id])
  end

  def camp_params
    params.require(:camp).permit(:facility_id, :organisation_id, :camp_name, :username, :email, :scheduled_on,
                                 :created_by, :password, :camp_location, :patient_served, :status, :camp_type, :pincode,
                                 :contact_person, :contact_no, :country, :country_id, :state, :city, :commune, :district,
                                 :area, :venue, :days, :expected_outpatients, :expected_surgeries, :camp_date,
                                 :review_camp_applicable, :review_date, :review_camp_venue, co_sponsors: [])
  end
end
