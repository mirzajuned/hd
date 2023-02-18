# ApplicationController can be commented out in future when all pre-session method are pulled here.
class SessionsController < ApplicationController
  layout 'loggedout'

  before_action :authorize_session, only: [:new, :signup]
  before_action :signup_params, only: [:signup]
  before_action :additional_params, only: [:signup_save]
  # before_action :redis_up?, only: [:create]

  after_action :update_session, only: [:new]

  def new
    @recaptcha_site_key = ENVIRONMENT_CREDENTIALS['recaptcha']['recaptcha_site_key']
  end

  def create
    authorized_user = User.authenticate(params[:session][:username], params[:session][:password])
    if verify_recaptcha(model: authorized_user) && authorized_user
      if Security::IpWhitelisting.check_ip(authorized_user.organisation_id.to_s, authorized_user.id.to_s, request.remote_ip)
        user_expiry_date = authorized_user.try(:account_expiry_date)
        if user_expiry_date.present? && (user_expiry_date > Date.current)
          session_id = request.session_options[:id]
          session[:user_id] = authorized_user.id
          session[:facility_id] = authorized_user.facility_ids[0]
          session[:start_time] = Time.current

          session_json = { "#{session_id}" => session.to_hash.to_json }
          stream_id = Redis::Master.new.xadd('ehr:login', session_json, id: '*')

          # stream_id = Redis::Master.new.xadd('ehr:login', session.to_hash, id: '*')

          session[:stream_id] = stream_id

          create_redis_master_session(session_id)

          # cache_value = $REDIS.get("cache:#{session_id}")
          cache_value = Redis::Master.new.get("cache:#{session_id}")
          if cache_value.present?
            cache_hash = { "cache:#{session_id}" => JSON.parse(cache_value) }
            # $REDIS.rpush('ehr:session:list', cache_hash.to_json)
            Redis::Master.new.rpush('ehr:session:list', cache_hash.to_json)
          end

          User::StatusManagement.on_login(authorized_user.id, authorized_user.facility_ids[0], authorized_user.organisation.id)

          FacilityTiming.create(
            start_time: session[:start_time], facility_id: session[:facility_id], user_id: session[:user_id],
            organisation_id: authorized_user.organisation.id, ip_address: request.remote_ip
          )

          MisJobs::Administrative::UserSessionAuditJob.perform_later(user_session_audit_params('Login', authorized_user.facility_ids[0]).to_json)
          # sleep [2, 3, 4].sample

          redirect_path = authorized_user.department_ids.present? ? user_department_url(authorized_user) : '/'
          redirect_to redirect_path
        else
          flash[:notice] = 'Your account is expired. Please contact admin.'
          redirect_to users_login_path
        end
      else
        flash[:notice] = 'Access Denied. Please contact Admin'
        redirect_to users_login_path
      end
    # elsif session[:failed_attempt] > @allowed_attempts.to_i && !verify_recaptcha(model: authorized_user) && authorized_user
    elsif !verify_recaptcha(model: authorized_user) && authorized_user
      flash[:notice] = 'Please fill the Captcha'
      redirect_to users_login_path
    else
      # session[:failed_attempt] = session[:failed_attempt].to_i + 1
      flash[:notice] = 'Invalid Username/Password'
      redirect_to users_login_path
    end
  end

  def destroy
    @opd_total_patient_count, @ipd_total_patient_count, @facility_to_myqueue_hash = User::StatusManagement.get_patients_counts_in_myqueue(current_user)
    clear_my_queue_before_offline = ActiveModel::Type::Boolean.new.cast("#{current_organisation['clear_my_queue_before_offline']}")
    if @opd_total_patient_count > 0 && clear_my_queue_before_offline == true
      @facilities = current_user.facilities.where(show_user_state: true).order(name: :asc)
      @user_state = UserState.where(user_id: current_user.id)
      respond_to do |format|
        format.js { render 'logout_patients_in_myqueue' }
      end
    else
      User::StatusManagement.on_logout(current_user.id, current_facility.id, current_organisation['_id'])
      update_facility_timing

      lrem_current_helpers

      session_id = request.session_options[:id]
      session_json = { "#{session_id}" => session.to_hash.to_json }
      Redis::Master.new.xadd('ehr:logout', session_json, id: '*')
      # $REDIS.xdel('ehr:login', session[:stream_id])
      Redis::Master.new.xdel('ehr:login', session[:stream_id])

      # cache_value = $REDIS.get("cache:#{session_id}")
      cache_value = Redis::Master.new.get("cache:#{session_id}")
      if cache_value.present?
        cache_hash = { "cache:#{session_id}" => JSON.parse(cache_value) }
        # $REDIS.lrem('ehr:session:list', -1, cache_hash.to_json)
        Redis::Master.new.lrem('ehr:session:list', -1, cache_hash.to_json)
      end

      # $REDIS.del("cache:#{session_id}")
      Redis::Master.new.del("cache:#{session_id}")

      session_id = request.session_options[:id]
      session_json = { "#{session_id}" => session.to_hash.to_json }
      facility_id = nil
      Redis::Master.new.xadd('ehr:logout', session_json, id: '*')
      # $REDIS.xdel('ehr:login', session[:stream_id])
      Redis::Master.new.xdel('ehr:login', session[:stream_id])

      # cache_value = $REDIS.get("cache:#{session_id}")
      cache_value = Redis::Master.new.get("cache:#{session_id}")
      if cache_value.present?
        cache_hash = { "cache:#{session_id}" => JSON.parse(cache_value) }
        # $REDIS.lrem('ehr:session:list', -1, cache_hash.to_json)
        Redis::Master.new.lrem('ehr:session:list', -1, cache_hash.to_json)
        facility_id = JSON.parse(cache_value)['facility_id']
      end
      # $REDIS.del("cache:#{session_id}")
      MisJobs::Administrative::UserSessionAuditJob.perform_now(user_session_audit_params('Logout', facility_id).to_json)
      Redis::Master.new.del("cache:#{session_id}")

      reset_session
      cookies[:lockup] = {}
      # sleep [2, 3, 4].sample

      respond_to do |format|
        format.js {render :js => "window.location.href='/users/login'"}
        format.html { redirect_to users_login_path }
      end
    end
  end

  def signup
    @recaptcha_site_key = ENVIRONMENT_CREDENTIALS['recaptcha']['recaptcha_site_key']
  end

  def signup_save
    # return 401 unless request.format.html?
    if request.format.html?
      @redirect_path = "#{request.protocol}#{request.host_with_port}" # Get Path Dynamically

      if verify_recaptcha(model: @user) && @user.save! && @organisation.save!(logo: params[:organisation][:logo]) && @facility.save!
        respond_to do |format|
          format.html {}
        end
        SignupJob.perform_later(@organisation.id.to_s, @facility.id.to_s, @user.id.to_s)
      elsif !verify_recaptcha(model: @user)
        flash[:notice] = 'Please fill the Captcha'
        redirect_to users_signup_path
      else
        redirect_to users_signup_path
      end
    else
      render :status => '401'
    end
  end

  private

  def organisation_params
    params.require(:organisation).permit(
      :name, :type, :type_id, :setup_type, :account_counter, :account_expiry_date, :onboarding_completed, :tagline,
      :logo, :address1, :address2, :city, :state, :pincode, :country_id, :telephone, :fax, :website, :terms, :district, :commune,
      :acceptancy_name, :acceptance_date, :referral_code, :query_contact, :email, :identifier_prefix, :account_no,
      :my_referral_code, :integration_identifier,
      currency_ids: [], specialty_ids: [],
      letter_head_customisations: [:header_height, :footer_height, :left_margin, :right_margin, :logo_location, :header_location, :right, :header]
    )
  end

  def facility_params
    params.require(:facility).permit(
      :name, :country_id, :time_zone, :currency_id, :currency_symbol, :clinical_workflow, :address, :city, :state, :district, :commune,
      :pincode, :telephone, :fax, :email, :abbreviation, :display_name, :integration_identifier, :organisation_id, :consultant_role_ids,
      currency_ids: [], department_ids: [], user_ids: [], specialty_ids: []
    )
  end

  def user_params
    params.require(:user).permit(
      :_id, :fullname, :email, :username, :gender, :dob, :age, :mobilenumber, :alternate_telephone, :address, :city,
      :state, :pincode, :country_id, :alternate_email, :user_selected_url, :account_expiry_date, :organisation_id,
      :district, :commune, :status, :quota, :integration_identifier,
      role_ids: [], facility_ids: [], department_ids: [], specialty_ids: [], sub_specialty_ids: []
    )
  end

  def additional_params
    organisation = params[:organisation]
    facility = params[:facility]
    user = params[:user]
    if facility[:country_id] ==  "KH_039"
      facility[:consultant_role_ids] = [28229004]
    else
      facility[:consultant_role_ids] = [158965000]
    end

    # Addition Fields for Organisation
    organisation[:query_contact] = organisation[:telephone]
    organisation[:email] = user[:email]
    organisation[:identifier_prefix] = user[:email].gsub(/[^a-zA-Z ]/i, '').upcase[0, 3]
    organisation[:account_no] = "#{organisation[:identifier_prefix]}-ACC-#{organisation[:account_counter]}"
    organisation[:my_referral_code] = my_referral_code
    organisation[:country_id] = facility[:country_id]
    organisation[:currency_ids] = [facility[:currency_id]]
    organisation[:specialty_ids] = facility[:specialty_ids]

    @organisation = Organisation.new(organisation_params)

    # Addition Fields for Facility
    facility[:name] = organisation[:name]
    facility[:address] = organisation[:address1]
    facility[:city] = organisation[:city]
    facility[:state] = organisation[:state]
    facility[:district] = organisation[:district]
    facility[:commune] = organisation[:commune]
    facility[:pincode] = organisation[:pincode]
    facility[:telephone] = organisation[:telephone]
    facility[:fax] = organisation[:fax]
    facility[:email] = user[:email]
    facility[:abbreviation] = user[:email].gsub(/[^a-zA-Z ]/i, '').upcase[0, 3]
    facility[:display_name] = organisation[:name]
    facility[:currency_ids] = [facility[:currency_id]]
    facility[:department_ids] = ['485396012', '486546481', '225738002'] # making opd, ipd, ot ids fix for now
    facility[:user_ids] = [user[:_id]]
    facility[:organisation_id] = @organisation.id.to_s

    @facility = Facility.new(facility_params)

    # Addition Fields for User
    user[:mobilenumber] = organisation[:telephone]
    user[:alternate_telephone] = organisation[:telephone]
    user[:address] = organisation[:address1]
    user[:city] = organisation[:city]
    user[:state] = organisation[:state]
    user[:pincode] = organisation[:pincode]
    user[:alternate_email] = user[:email]
    user[:district] = organisation[:district]
    user[:commune] = organisation[:commune]
    user[:role_ids] = user[:role_ids].split(',').map(&:to_i)

    if [6868009, 160943002].include?(user[:role_ids][0]) # in case of admin, owner
      user[:department_ids] = ['224608005']
      user[:specialty_ids] = []
    else
      user[:department_ids] = ['485396012', '486546481', '225738002', '224608005']
      user[:specialty_ids] = facility[:specialty_ids]
      if user[:specialty_ids].include?('309988001')
        user[:sub_specialty_ids] = ['422234006']
        user[:sub_specialty_names] = ['General Ophthalmology']
      elsif user[:specialty_ids].include?('309989009')
        user[:sub_specialty_ids] = ['78001009']
        user[:sub_specialty_names] = ['General Orthopedics']
      end
    end

    user[:account_expiry_date] = organisation[:account_expiry_date]
    user[:facility_ids] = [@facility.id.to_s]
    user[:organisation_id] = @organisation.id.to_s
    user[:country_id] = facility[:country_id]
    user[:status] = 'inactive'
    user[:quota] = 'paid'
    @user = User.new(user_params)
  end

  def signup_params
    # Country
    @countries = Country.all
    @default_country = @countries.find_by(abbreviation1: 'IN') # Set Default India

    # TimeZone & Time
    @zones_array = @default_country.get_time_zones
    @time = TZInfo::Timezone.get(@zones_array[0][1]).now.in_time_zone.strftime('%I:%M %p, %d %b %Y')

    # Currency
    @currencies = Currency.all
    currency_id = "#{@default_country.currencies.split(',')[0]}001"
    @default_currency = Currency.find_by(id: currency_id)

    # Department
    @departments = Department.where(is_launched: true) # .where(id: '309988001')

    # Specialties
    @specialties = Specialty.where(is_launched: true)
  end

  def user_session_audit_params(event_type, facility_id)
    unless facility_id
      facility_id = current_user.facility_ids[0]
    end
    {
      user_id: current_user.id,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      session_id: request.session_options[:id],
      event: event_type,
      event_by: 'User',
      event_datetime: Time.current,
      facility_id: facility_id
    }
  end

  def my_referral_code(counter = 1)
    specialty = Specialty.find_by(id: params[:facility][:specialty_ids][0].to_s)

    code_prefix = Time.current.strftime('%Y').tr('0', '')
    code_middle = specialty.name.first(3).upcase
    code_suffix = "#{counter}#{Time.current.strftime('%d%m')}"

    @my_referral_code = "#{code_prefix}#{code_middle}#{code_suffix}"

    referral_code = ReferralCode.find_by(code: @my_referral_code)
    if referral_code.present?
      counter += 1
      my_referral_code(counter)
    end

    @my_referral_code
  end

  def user_department_url(user)
    department_id = user.department_ids[0]
    url_path = Global.send('user_url_selection')[department_id.to_i] || '/'

    url_path
  end

  # def redis_up?
  #   redirect_to users_login_path unless Redis::Local.new.ping
  # end

  def update_facility_timing
    facility_timing = FacilityTiming.find_by(start_time: session[:start_time], facility_id: session[:facility_id],
                                             user_id: session[:user_id], end_time: nil)
    facility_timing&.update_attributes(end_time: Time.current)
  end

  def update_session
    session_id = request.session_options[:id]
    # stream_id = $REDIS.xadd('ehr:login', '*', session_id, session.to_hash.to_json)
    # Redis::Master.new.xadd('ehr:login', '*', session_id, session.to_hash.to_json)
    session_json = { "#{session_id}" => session.to_hash.to_json }
    Redis::Master.new.xadd('ehr:login', session_json, id: '*')
  end

  def lrem_current_helpers
    user_id = session[:user_id]
    facility_id = session[:facility_id]
    organisation_id = current_user&.organisation_id

    user = Redis::Local.new.get("user:#{user_id}")
    lrem_redis_master({ "user:#{user_id}" => JSON.parse(user) }) if user.present?

    facility = Redis::Local.new.get("facility:#{facility_id}")
    lrem_redis_master({ "facility:#{facility_id}" => JSON.parse(facility) }) if facility.present?

    organisation = Redis::Local.new.get("organisation:#{organisation_id}")
    lrem_redis_master({ "organisation:#{organisation_id}" => JSON.parse(organisation) }) if organisation.present?

    facility_users = Redis::Local.new.get("facility_users:#{facility_id}")
    lrem_redis_master({ "facility_users:#{facility_id}" => JSON.parse(facility_users) }) if facility_users.present?

    user_facilities = Redis::Local.new.get("user_facilities:#{user_id}")
    lrem_redis_master({ "user_facilities:#{user_id}" => JSON.parse(user_facilities) }) if user_facilities.present?

    ufs = Redis::Local.new.get("user_facility_settings:#{user_id}")
    lrem_redis_master({ "user_facility_settings:#{user_id}" => JSON.parse(ufs) }) if ufs.present?
  end

  def lrem_redis_master(current_hash)
    Redis::Master.new.lrem('ehr:current:list', -1, current_hash.to_json)

    Redis::Local.new.del(current_hash.keys[0])
  end
end
