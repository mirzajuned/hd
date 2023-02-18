class ApplicationController < ActionController::Base
  auto_session_timeout 1400.minutes

  include CommonHelper
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  rescue_from ActionController::InvalidAuthenticityToken, with: :rescue_root
  rescue_from ActionView::MissingTemplate, with: :rescue_root if Rails.env == 'production'

  before_action :reject_cache, :set_logger, :set_instruction_array, :set_language
  around_action :get_time_zone, if: :current_user
  skip_before_action :check_for_lockup, raise: false
  before_action :miniprofiler unless Rails.env.production?

  def rescue_root
    flash[:notice] = 'Something went wrong.Please try again.'
    redirect_to root_path
  end

  def set_facility
    current_time = Time.current
    user_id = session[:user_id]
    facility_timing = FacilityTiming.find_by(start_time: session[:start_time], facility_id: session[:facility_id],
                                             user_id: user_id)
    facility_timing&.update_attributes(end_time: current_time)

    session_id = request.session_options[:id]
    # $REDIS.xdel('ehr:login', session[:stream_id])
    Redis::Master.new.xdel('ehr:login', session[:stream_id])

    # cache_value = $REDIS.get("cache:#{session_id}")
    cache_value = Redis::Master.new.get("cache:#{session_id}")
    if cache_value.present?
      cache_hash = { "cache:#{session_id}" => JSON.parse(cache_value) }
      # $REDIS.lrem('ehr:session:list', -1, cache_hash.to_json)
      Redis::Master.new.lrem('ehr:session:list', -1, cache_hash.to_json)
    end

    session[:start_time] = current_time
    session[:facility_id] = params[:facility]
    session[:stream_id] = nil # Old Stream id is not stored in ehr:login
    session_json = { session_id.to_s => session.to_hash.to_json }
    stream_id = Redis::Master.new.xadd('ehr:login', session_json, id: '*')
    session[:stream_id] = stream_id

    create_redis_master_session(session_id)

    # cache_value = $REDIS.get("cache:#{session_id}")
    cache_value = Redis::Master.new.get("cache:#{session_id}")
    if cache_value.present?
      cache_hash = { "cache:#{session_id}" => JSON.parse(cache_value) }
      # $REDIS.rpush('ehr:session:list', cache_hash.to_json)
      Redis::Master.new.rpush('ehr:session:list', cache_hash.to_json)
    end

    FacilityTiming.create(start_time: current_time, facility_id: session[:facility_id], user_id: user_id,
                          organisation_id: current_user.organisation.id, ip_address: request.remote_ip)
    redirect_back(fallback_location: root_path)
  end

  auto_session_timeout_actions

  def active
    render_session_status
  end

  def timeout
    render_session_timeout
  end

  def reject_cache
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate' # HTTP 1.1.
    response.headers['Pragma'] = 'no-cache' # HTTP 1.0.
    response.headers['Expires'] = '0' # Proxies.
  end

  def set_logger
    @logger = Logger.new("#{Rails.root}/log/#{Rails.env}_debugger.log")
  end

  def count_sequences(module_type, module_name, has_department = false, department_id = nil, has_entity = false, entity_id = nil)
    if has_department && department_id.present?
      if has_entity && entity_id.present?
        SequenceManager.where(:facility_id.in => [nil, current_facility['id']], :region_id.in => [nil, current_facility['region_master_id']], :entity_group_id.in => [nil, entity_id], organisation_id: current_organisation['_id'], module_type.to_sym => module_name, department_id: department_id, is_deleted: false).count
      else
        SequenceManager.where(:facility_id.in => [nil, current_facility['id']], :region_id.in => [nil, current_facility['region_master_id']], organisation_id: current_organisation['_id'], module_type.to_sym => module_name, department_id: department_id, is_deleted: false).count
      end
    else
      SequenceManager.where(:facility_id.in => [nil, current_facility['id']], :region_id.in => [nil, current_facility['region_master_id']], organisation_id: current_organisation['_id'], module_type.to_sym => module_name, is_deleted: false).count
    end
  end
  # EOF count_sequences
  helper_method :count_sequences

  private

  def miniprofiler
    Rack::MiniProfiler.authorize_request
  end

  def current_user
    @current_user ||= GetUsers.current_user(session[:user_id]) # app/services/get_users.rb
  end
  helper_method :current_user

  def current_facility
    @current_facility ||= GetFacilities.current_facility(session[:facility_id])
  end
  helper_method :current_facility

  def current_user_facilities
    @current_user_facilities ||= GetFacilities.current_user_facilities(current_user.id) # app/services/get_facilities.rb
  end
  helper_method :current_user_facilities

  def current_user_facility_settings
    # app/services/get_facilities.rb
    @current_user_facility_settings ||= GetFacilities.current_user_facility_settings(current_facility.id, current_user.id)
  end
  helper_method :current_user_facility_settings

  # Not in use.
  def current_facility_users
    @current_facility_users ||= GetUsers.current_facility_users(current_facility.id) # app/services/get_facilities.rb
  end
  helper_method :current_facility_users

  def current_organisation
    # app/services/get_organisations.rb
    @current_organisation ||= GetOrganisation.current_organisation(current_user.organisation_id)
  end
  helper_method :current_organisation

  def current_organisation_setting
    @current_organisation_setting ||= OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
  end
  helper_method :current_organisation_setting

  def current_facility_id
    session[:facility_id]
  end
  helper_method :current_facility_id

  def current_facility_setting
    @current_facility_setting ||= FacilitySetting.find_by(facility_id: current_facility&.id)
  end
  helper_method :current_facility_setting

  def current_organisation_setting
    @current_organisation_setting ||= OrganisationsSetting.find_by(organisation_id: current_user&.organisation_id)
  end
  helper_method :current_organisation_setting

  def current_sub_station
    @current_sub_station ||= QueueManagement::SubStation.find_by(
      active_user_id: current_user&.id, facility_id: current_facility&.id
    )
  end
  helper_method :current_sub_station

  def new_user_notifications
    key = "new_user_notification:#{current_user.id}"

    new_user_notifications = Redis::Master.new.get(key)
    new_user_notifications ||= helpers.generate_redis_notifications(key, 'new')

    @new_user_notifications = JSON.parse(new_user_notifications)
  end
  helper_method :new_user_notifications

  def old_user_notifications
    key = "old_user_notification:#{current_user.id}"

    old_user_notifications = Redis::Master.new.get(key)
    old_user_notifications ||= helpers.generate_redis_notifications(key, 'old')

    @old_user_notifications = JSON.parse(old_user_notifications)
  end
  helper_method :old_user_notifications

  def authorize
    if session[:user_id].present? && session[:facility_id].present?
      update_sub_specialty
    else
      session_id = cookies[:_session_id]

      # ping = Redis::Local.new.ping # To check if Local Server is up
      if local_session_present?(session_id)
        get_session(session_id)
      else
        # session_hash = $REDIS.get("cache:#{session_id}")
        session_hash = Redis::Master.new.get("cache:#{session_id}")
        if session_hash.present?
          parse_session = JSON.parse(session_hash)
          return if parse_session.nil?

          # $REDIS_L.set("cache:#{session_id}", parse_session.to_hash.to_json)
          Redis::Local.new.set("cache:#{session_id}", parse_session.to_hash.to_json)
          get_session(session_id)
        else
          reset_user_session
        end
      end
    end
  end

  def verify_store
    @current_store = Inventory::Store.find_by(id: params[:store_id] || params[:id])
    return unless @current_store.present? && @current_store.is_disable == true

    if request.format.symbol == :js
      render js: "window.location='/errors/empty_store'"
    else
      redirect_to '/errors/empty_store', alert: 'Not authorized'
    end
  end

  def local_session_present?(session_id)
    local_session = Redis::Local.new.get("cache:#{session_id}")
    parse_session = JSON.parse(local_session) unless local_session.nil?

    parse_session.present? && parse_session['user_id'].present? && parse_session['facility_id'].present?
  end

  def get_session(session_id)
    # local_session = $REDIS_L.get("cache:#{session_id}")
    local_session = Redis::Local.new.get("cache:#{session_id}")
    parse_session = JSON.parse(local_session) unless local_session.nil?
    return if parse_session.nil?

    session[:user_id] = parse_session['user_id']
    session[:facility_id] = parse_session['facility_id']
    session[:start_time] = Time.current
    session[:stream_id] = parse_session['stream_id']
  end

  def authorize_session
    @current_user = current_user
    return unless @current_user

    if @current_user.department_ids.present?
      redirect_to user_department_url(@current_user)
    else
      redirect_to '/'
    end
  end

  def authorize_webview_session
    return unless params[:mode] == 'tabview'

    @api_key = ApiKey.find_by(access_token: params[:token], expiry_time: { '$gt' => Time.current })
    if @api_key.present?
      session[:user_id] = @api_key.user_id
      session[:facility_id] = params[:facility_id]
    else
      session[:user_id] = nil
      render json: { error: 'Not authorized: Access denied.' }, status: :forbidden
    end
  end

  def authorize_onboard
    redirect_to organisations_onboarding_path unless current_organisation['onboarding_completed'] == true
  end

  def user_state
    # GetUsers.get_user_state(current_user.id,current_facility.id)
    UserState.find_by(user_id: current_user.id, facility_id: current_facility.id)
  end
  helper_method :user_state

  def get_time_zone(&block)
    Time.use_zone(current_facility.time_zone, &block)
  end
  helper_method :get_time_zone

  def print_attributes(format, template, pdf_name, print_setting)
    format.pdf do
      render template: template, pdf: pdf_name, layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4',
             disable_smart_shrinking: true, show_as_html: params[:debug].present?,
             header: { html: { template: 'layouts/pdf-header.html' }, spacing: 0 },
             footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 },
             margin: {
               left: print_setting.try(:left_margin).to_f * 10, right: print_setting.try(:right_margin).to_f * 10,
               top: print_setting.try(:header_height).to_f * 10, bottom: print_setting.try(:footer_height).to_f * 10
             }
    end
  end

  def user_department_url(user)
    department_id = user.department_ids[0]
    url_path = Global.send('user_url_selection')[department_id.to_i] || '/'

    url_path
  end

  def set_instruction_array
    @medication_set_arr = Global.send('medication_instruction_option').send('sets')
  end

  def set_language
    @translated_language = current_facility&.country_id == 'VN_254' ? 'vi' : 'en'
  end

  def reset_user_session
    reset_session
    if request.format.symbol == :js
      render js: "window.location='#{users_login_path}'"
    else
      redirect_to users_login_path, alert: 'Not authorized'
    end
  end

  def create_redis_master_session(session_id)
    key = "cache:#{session_id}"
    expire_at = ((Date.current + 1).to_time + 4.hours).to_i

    Redis::Master.new.set(key, session.to_hash.to_json)
    Redis::Master.new.expireat(key, expire_at)
    Redis::Local.new.expireat(key, expire_at)
  end

  def update_sub_specialty
    user = User.find_by(id: session[:user_id])
    return if user.updated || user.role_ids.exclude?(158965000) || user.specialty_ids.exclude?('309988001')

    @sub_specialties = SubSpecialty.where(specialty_id: '309988001').pluck(:name, :id)

    respond_to do |format|
      format.html { render 'users/new_sub_specialties.html.erb' }
      format.js { render 'users/new_sub_specialties.js.erb' }
    end
  end
end
