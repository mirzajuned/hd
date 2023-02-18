class UsersController < ApplicationController
  before_action :authorize, except: [:validate_user, :activate, :activate_save, :set_details, :save_details,
                                     :new_sub_specialties, :update_sub_specialties]
  before_action :find_user, only: [:edit, :update, :destroy, :activate_button, :edit_email, :update_email,
                                   :user_preferred_url, :update_sub_specialties, :reset_password]
  before_action :form_params, only: [:new, :edit]
  before_action :find_all_users, only: [:all_users_data]
  before_action :trusted_domains, only: [:new, :edit, :edit_email]

  def index
    @facility_id = params[:facility_id]
    @facility_name = params[:facility_name]
    @role_id = params[:role_id]
  end

  def all_users
    @facilities = Facility.where(organisation_id: current_organisation['_id'])
    @roles = Role.all
  end

  def all_users_data
    @all_users = @all_users.where(:facility_ids.in => [params[:facility_id]]) if params[:facility_id].present?
    @all_users = @all_users.where(:role_ids.in => [params[:role_id].to_i]) if params[:role_id].present?
    @all_users = @all_users.where(is_active: params[:is_active]) if params[:is_active].present?
    @users_count = search_user_params(@all_users).count
    @users = search_user_params(@all_users).limit(params[:iDisplayLength]).offset(params[:iDisplayStart])
    @total_users_count = @all_users.count
    respond_to do |format|
      format.json {}
    end
  end

  def new
    @user = User.new
  end

  def create
    set_user_params

    @user = User.new(user_params)
    ip_address = @user.ip_address.pluck(:remote_ip)
    Redis::Master.new.rpush("user:#{@user.id.to_s}:whitelisted-ips", ip_address)
    Redis::Master.new.set("user:#{@user.id.to_s}:is-open-access-enabled", @user.is_open_access_enabled)
    # @user.skip_username_validation = true  #Skip Username Validation
    if @user.save(validate: false)
      # show_params
      link_facilities_params
      render 'link_user_to_facility'

      UserJobs::CreateJob.perform_later(@user.id.to_s)
      UserJobs::CreateIpAddressTrailJob.perform_later(@user.id.to_s, current_user.id.to_s, 'create', [], [])
      if @user.role_ids.include?(158966000)
        UserJobs::UserAddAdverseMailSettingJob.perform_later(@user.id.to_s, params[:action])
      end
      user_status_job
    else
      form_params
      render 'new'
    end
  end

  def edit; end

  def update
    set_user_params
    # @user.skip_username_validation = true #Skip Username Validation
    old_ips = @user.ip_address.where(:level.ne => 'facility').pluck(:remote_ip)
    @user.ip_address.where(:level.ne => 'facility').delete_all
    @user.attributes = user_params
    if @user.save(validate: false)
      ip_address = @user.ip_address.pluck(:remote_ip)
      Redis::Master.new.set("user:#{params[:id]}:is-open-access-enabled", @user.is_open_access_enabled)
      update_user_ip_address(params[:id], old_ips)
      show_params
      render 'show'
      UserJobs::UpdateJob.perform_later(@user.id.to_s)
      if @user.role_ids.include?(158966000)
        UserJobs::UserAddAdverseMailSettingJob.perform_later(@user.id.to_s, params[:action])
      end
      user_status_job
    else
      form_params
      render 'edit'
    end
  end

  def destroy
    if @user.username.present?
      @user.update_attributes(is_active: false, last_edited_by: current_user.fullname, status: 'inactive')
      Redis::Master.new.del("user:#{@user.id}:whitelisted-ips")
      @user.ip_address.delete_all

      UserJobs::ActivateJob.perform_later(@user.id.to_s)
      user_status_job
      if @user.role_ids.include?(158966000)
        UserJobs::UserAddAdverseMailSettingJob.perform_later(@user.id.to_s, params[:action])
      end
    else
      @user.delete

      # TODO: Test this case
      UserStatus.where(user_id: @user.id).delete_all
    end
  end

  def download_data
    organisation_id = params[:organisation_id]
    @data_array = DownloadUserService.call(organisation_id)
    @filename = 'facility_wise_user_report.xlsx'
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}\"" }
    end
  end

  def user_wise_download_data
    organisation_id = params[:organisation_id]
    @data_array = DownloadUserService.user_download_data(organisation_id)
    @filename = 'user_wise_report.xlsx'
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}\"" }
    end
  end

  # Activate Existing User
  def activate_button
    @user.update_attributes(is_active: true, last_edited_by: current_user.fullname, status: 'active')

    UserJobs::ActivateJob.perform_later(@user.id.to_s)
    UserJobs::UpdateIpAddressJob.perform_later(@user.facility_ids.map(&:to_s), @user.id.to_s, 'link', 'facilities')

    user_status_job
  end

  def department_facilities
    @facilities = Facility.where(
      organisation_id: params[:organisation_id], department_ids: params[:department_id], is_active: true
    ).pluck(:name, :id)

    render json: { "facilities": @facilities }
  end

  def data
    @current_user = current_user
    @all_users = User.where(facility_ids: params[:facility_id], role_ids: params[:role_id].to_i)
    @users_count = @all_users.where(fullname: /#{Regexp.escape(params[:sSearch])}/i).count
    @users = @all_users.includes(:roles).where(fullname: /#{params[:sSearch]}/i)
                       .limit(params[:iDisplayLength]).offset(params[:iDisplayStart])
                       .order('fullname ' + params[:sSortDir_0])
    @total_users_count = @all_users.count

    respond_to do |format|
      format.json {}
    end
  end

  # Validate Unique Fields Via Jquery Validator
  def validate_user
    user = params[:user]
    options = { :id.ne => params[:user_id], organisation_id: current_user.try(:organisation_id) }

    if user.present? && !current_user.try(:allow_duplicate_email?) && (user[:email].present? || user[:username].present? || user[:employee_id].present?)
      options = options.merge(email: user[:email]) if user[:email].present? && !current_user.try(:allow_duplicate_email?)
      options = options.merge(username: user[:username]) if user[:username].present?
      options = options.merge(employee_id: user[:employee_id]) if user[:employee_id].present?

      @user = User.find_by(options)
    end

    if params[:email_local].present? && params[:email_domain].present? && !current_user.try(:allow_duplicate_email?)
      email = "#{params[:email_local]}@#{params[:email_domain]}"
      options = options.merge(email: email)

      @user = User.find_by(options)
    end

    respond_to do |format|
      format.json { render json: @user.nil? }
    end
  end

  def new_sub_specialties; end

  def update_sub_specialties
    sub_specialty_ids = params[:sub_specialty_ids].split(',')
    sub_specialties = SubSpecialty.where(:id.in => sub_specialty_ids)
    @user&.update(sub_specialty_ids: sub_specialty_ids, sub_specialty_names: sub_specialties.pluck(:name),
                  updated: true)

    redirect_to '/'
  end

  # This method is used after new user is created
  def link_facilities_save
    # facilities = Facility.where(:id.in => params[:user][:facility_ids])
    # @user = User.find_by(id: params[:user][:id]).add_to_set(facility_ids: facilities.pluck(:id))

    # facilities.each do |fac|
    #   fac.add_to_set(user_ids: @user.id)
    # end

    UserJobs::LinkFacilityCreateJob.perform_later(params[:user][:id].to_s, params[:user][:facility_ids])
    UserJobs::UpdateIpAddressJob.perform_later(params[:user][:facility_ids], params[:user][:id].to_s, 'link', 'facilities')
  end

  def link_unlink_multiple_users
    @flag = params[:flag]
    @facility_id = params[:facility_id]
    users = User.where(organisation_id: current_user.organisation_id)
    facility_ids = [BSON::ObjectId(@facility_id.to_s)]

    if @flag == 'link'
      @users = users.where(:facility_ids.nin => facility_ids)
      @other_users = users.where(:facility_ids.in => facility_ids)
    else
      @users = users.where(:facility_ids.in => facility_ids, is_active: true)
      @users = @users.delete_if { |user| user.facility_ids.count <= 1 }
      @other_users = users.where(:facility_ids.nin => facility_ids)
    end
  end

  def link_unlink_multiple_users_save
    flag = params[:flag]
    if params[:user_ids].count > 0
      users = User.where(:id.in => params[:user_ids])
      facility = Facility.find_by(id: params[:facility_id])
      # $REDIS.del("facility:#{facility.id}")
      Redis::Local.new.del("facility:#{facility.id}")

      users.each do |user|
        if flag == 'link'
          facility.add_to_set(user_ids: user.id)
          user.add_to_set(facility_ids: facility.id)
        elsif user.facility_ids.count > 1
          facility.pull(user_ids: user.id)
          user.pull(facility_ids: facility.id)
        end

        if user.is_active
          UserJobs::UpdateJob.perform_later(user.id.to_s)
        end

        # $REDIS.del("user:#{user.id}")
        Redis::Local.new.del("user:#{user.id}")
        # $REDIS.del("user_facilities:#{user.id}")
        Redis::Local.new.del("user_facilities:#{user.id}")

        # UserState Background
        user_state = UserState.find_by(facility_id: facility.id, user_id: user.id)
        UserState.create(facility_id: facility.id, user_id: user.id) if user_state.nil?
      end
      UserJobs::UpdateIpAddressJob.perform_later(params[:user_ids], facility.id.to_s, flag, 'users')
      # UserJobs::ActivateJob.perform_later(users.pluck(:id).map { |e| e.to_s }) if flag == 'link'
    end
  end

  def link_unlink_multiple_facilities
    @flag = params[:flag]
    @user_id = params[:user_id]
    @current_user = current_user
    @current_facility = current_facility
    facilities = if params[:level] == 'facility'
                   Facility.where(:id.in => @current_user.facilities.pluck(:id))
                 else
                   Facility.where(organisation_id: @current_user.organisation_id)
                 end
    if @flag == 'link'
      @facilities = facilities.where(:user_ids.nin => [BSON::ObjectId(@user_id.to_s)])
      @other_facilities = facilities.where(:user_ids.in => [BSON::ObjectId(@user_id.to_s)])
    else
      @facilities = facilities.where(user_ids: @user_id)
      @other_facilities = facilities.where(:user_ids.nin => [BSON::ObjectId(@user_id.to_s)])
    end
  end

  def link_unlink_multiple_facilities_save
    flag = params[:flag]
    if params[:facility_ids].count > 0
      user = User.find_by(id: params[:user_id])
      facilities = Facility.where(:id.in => params[:facility_ids])

      # $REDIS.del("user:#{user.id}")
      Redis::Local.new.del("user:#{user.id}")
      # $REDIS.del("user_facilities:#{user.id}")
      Redis::Local.new.del("user_facilities:#{user.id}")

      facilities.each do |facility|
        if flag == 'link'
          user.add_to_set(facility_ids: facility.id)
          facility.add_to_set(user_ids: user.id)
        elsif user.facility_ids.count > 1
          user.pull(facility_ids: facility.id)
          facility.pull(user_ids: user.id)
        end

        # $REDIS.del("facility:#{facility.id}")
        Redis::Local.new.del("facility:#{facility.id}")
        # UserState Background
        user_state = UserState.find_by(facility_id: facility.id, user_id: user.id)
        UserState.create(facility_id: facility.id, user_id: user.id) if user_state.nil?
      end
      UserJobs::UpdateIpAddressJob.perform_later(params[:facility_ids], user.id.to_s, flag, 'facilities')
      if user.is_active
        UserJobs::UpdateJob.perform_later(user.id.to_s)
      end
    end
  end

  # def unlink_user
  #   User.find_by(id: params[:user_id]).pull(facility_ids: BSON::ObjectId("#{params[:facility_id]}"))
  #   Facility.find_by(id: params[:facility_id]).pull(user_ids: BSON::ObjectId("#{params[:user_id]}"))

  #   respond_to do |format|
  #     format.js { render js: "$('#manage_users').dataTable().fnDraw();" }
  #   end
  # end

  def link_unlink_user_store
    @facility_id = params[:facility_id]
    @store_id = params[:store_id]
    @type = params[:type]
    @store = Inventory::Store.find_by(id: params[:store_id])
    # options = { :facility_ids.in => [@facility_id], is_active: true }
    options = { organisation_id: current_user.organisation_id, is_active: true }
    if @type == 'unlink_user'
      @users = User.where(options.merge(:inventory_store_ids.in => [@store_id]))
      @other_users = User.where(options.merge(:inventory_store_ids.nin => [@store_id]))
    else
      @users = User.where(options.merge(:inventory_store_ids.nin => [@store_id]))
      @other_users = User.where(options.merge(:inventory_store_ids.in => [@store_id]))
    end
  end

  def save_link_unlink_user_store
    @facility_id = params[:facility_id]
    @store_id = params[:store_id]

    @users = User.where(:id.in => params[:user_ids])
    @store = Inventory::Store.find_by(id: @store_id)

    # @facility = Facility.find_by(id: params[:facility_id])
    if params[:type] == 'unlink_user'
      @users.each do |user|
        user.pull(inventory_store_ids: @store.id)
        @store.pull(user_ids: user.id)
      end
    else
      @users.each do |user|
        user.add_to_set(inventory_store_ids: @store.id)
        @store.add_to_set(user_ids: user.id)
      end
    end

    # UserState Background
    # @user_state = UserState.find_by(facility_id: @facility.id, user_id: @user.id)
    # if @user_state.nil?
    #   UserState.create(facility_id: @facility.id, user_id: @user.id)
    # end
  end

  # Set Username, Password --> New User
  def set_details
    @user = User.find_by(id: params[:code])
    if @user.present? && @user.username.nil?
      respond_to do |format|
        format.html { render layout: 'loggedout' }
      end
    else
      redirect_to users_login_path
    end
  end

  # Set Username, Password --> New User
  def save_details
    @user = User.find_by(id: params[:user][:id])
    @user.username = params[:user][:username]
    @user.password = params[:user][:password]
    @user.status = 'active'
    @user.upsert
    if @user.update(is_active: true)
      UserJobs::UpdateJob.perform_later(@user.id.to_s)
      redirect_to users_login_path

      user_status_job
    else
      render :set_details, layout: 'loggedout'
    end
  end

  # Set User New Signup
  def activate
    @user = User.find_by(id: params[:code])
    if @user.is_active
      if @user.organisation.onboarding_completed == true
        redirect_to users_login_path
      else
        redirect_to organisations_onboarding_path
      end
    else
      respond_to do |format|
        format.html { render layout: 'loggedout' }
      end
    end
  end

  # Set User New Signup
  def activate_save
    @user = User.find_by(id: params[:user][:id])
    @user.password = params[:user][:password]
    @user.is_active = true
    @user.status = 'active'
    @user.upsert
    redirect_to users_login_path

    user_status_job
  end

  def reset_password; end

  # Edit Email Option for Inactive Users
  def edit_email; end

  # Update Email & Resend Activation Link
  def update_email
    @user.attributes = user_params
    UserJobs::ResendConfirmationMailJob.perform_later(@user.id.to_s) if @user.save(validate: false)
  end

  # Move these Methods to OnboardingController in Future
  # Onboarding --> Needs Work when onboarding Starts
  def org_new
    @user = User.new
    @user.organisation_id = params[:organisation_id]
    respond_to do |format|
      format.js { render 'new' }
    end
  end

  # Onboarding --> Needs Work when onboarding Starts
  def org_fetch
    @users = User.where(organisation_id: params[:parent_id])

    respond_to do |format|
      format.json {}
    end
  end

  # Onboarding --> Needs Work when onboarding Starts
  def fetch_week
    @facilities = current_user.facilities
    respond_to do |format|
      format.html { render '/facilities/get_list', layout: false }
    end
  end

  # Used by Private Settings
  def save_appointment_types
    @current_user = current_user
    params[:appointment_types][params[:default]][:is_default] = true if params[:default]
    @appointment_types = params[:appointment_types]
    @appointment_types.each do |_index, appointment_type_values|
      if appointment_type_values[:label] != '' && appointment_type_values[:duration] != ''
        at_values = { label: appointment_type_values[:label], background: appointment_type_values[:background],
                      user_id: appointment_type_values[:user_id], duration: appointment_type_values[:duration],
                      is_default: appointment_type_values[:is_default] }
        at_values[:id] = appointment_type_values[:id] unless appointment_type_values[:id].nil?

        duplicate_appointment = AppointmentType.find_by(
          label: appointment_type_values[:label], background: appointment_type_values[:background],
          duration: appointment_type_values[:duration], user_id: @current_user.id
        )
        duplicate_appointment.try(:destroy)

        appointment_type = AppointmentType.new(at_values)
        appointment_type.upsert
      end

      if params[:appointment_types_for_delete] != ''
        AppointmentType.where(:id.in => params[:appointment_types_for_delete].split(',')).update_all(is_active: false)
      end
    end

    @appointment_types = AppointmentType.where(user_id: @current_user.id, is_active: true)

    if @current_user.organisation.onboarding_completed == false

      respond_to do |format|
        format.js { render 'save_appointment_onboarding_type' }
      end

    else

      respond_to do |format|
        format.js { render js: "notice = new PNotify({ title: 'Success', text: 'Appointment types saved successfully', type: 'success' }); notice.get().click(function(){ notice.remove() });" }
      end
    end
  end

  # Used by Private Settings --> Needs Work
  def user_preferred_url
    default_department_id = params[:department_id]
    if default_department_id.present?
      new_department_ids = @user.department_ids.unshift(default_department_id).uniq
      @user.update(department_ids: new_department_ids)
    end

    render json: { 'success': true }
  end

  private

  def user_params
    params.require(:user).permit(
      :integration_identifier, :organisation_id, :last_edited_by, :user_selected_url, 
      :is_internal_user, :salutation, :fullname, :email, :username, :gender, :dob, :age, 
      :employee_id, :designation, :registration_number, :district,
      :commune, :mobilenumber, :telephone, :country_id, :address, :city, :state, :pincode, 
      :alternate_email, :status, :quota, :account_expiry_date, :is_set_state_done_manually, 
      :is_open_access_enabled, :qualification, :fellowship,
      role_ids: [], specialty_ids: [], specialty_names: [], department_ids: [], sub_specialty_ids: [],
      sub_specialty_names: [], ip_address_attributes: [:remote_ip, :remote_ip_name]
    )
  end

  def find_all_users
    @all_users = User.where(organisation_id: current_organisation['_id'])
  end

  def search_user_params(all_users)
    all_users.where(fullname: /#{Regexp.escape(params[:sSearch])}/i)
                    .or(@all_users.includes(:roles).where(username: /#{params[:sSearch]}/i))
                    .or(@all_users.where(:role_ids.in => [Role.find_by(label: /#{params[:sSearch]}/i).try(:id)]))
  end

  def find_user
    @user = User.find_by(id: params[:id])
  end

  def form_params
    @current_user = current_user
    @organisation = @current_user.organisation
    @countries = Country.all

    # if @organisation.type == "individual"
    #   @department = @current_user.department
    # else
    @departments = Department.all
    # end

    all_roles = Global.send('user_roles')
    all_roles = JSON.parse(all_roles.to_json)
    @roles_arr = []
    all_roles.each { |role| @roles_arr << [role[1]['label'], role[0]] }

    @specialties_arr = Specialty.where(:id.in => current_organisation['specialty_ids'])

    @sub_specialties = if (@user&.role_ids&.include?(158965000) || @user&.role_ids&.include?(158966000)) && params[:action] == 'edit'
                         SubSpecialty.where(:specialty_id.in => @user.specialty_ids)
                       else
                         []
                       end
  end

  def set_user_params
    params[:user][:alternate_email] = params[:user][:email]
    params[:user][:role_ids] = params[:user][:role_ids].split(',').map(&:to_i)
    params[:user][:account_expiry_date] = current_organisation['account_expiry_date']
    params[:user][:specialty_ids] = params[:user][:specialty_ids].values.delete_if { |ele| ele['flag'] == 'false' }.pluck('id')
    params[:user][:department_ids] = params[:user][:department_ids].values.delete_if { |ele| ele['flag'] == 'false' }.pluck('id')
    params[:user][:department_ids].insert(0, params[:user][:department_ids].delete_at(params[:user][:department_ids].index(params[:user][:selected_department]))) # making default dep

    if params[:user][:sub_specialty_ids].present?
      params_sub_specialties = params[:user][:sub_specialty_ids].values.delete_if { |ele| ele['flag'] == 'false' }
      params[:user][:sub_specialty_ids] = params_sub_specialties.pluck('id')
      params[:user][:sub_specialty_names] = params_sub_specialties.pluck('name')
    else
      params[:user][:sub_specialty_ids] = []
      params[:user][:sub_specialty_names] = []
    end

    params[:user][:specialty_names] = Specialty.where(:id.in => params[:user][:specialty_ids]).pluck(:name)
  end

  def show_params
    @user_departments = Department.where(:id.in => @user.department_ids)
    @user_specialties = Specialty.where(:id.in => @user.specialty_ids)
    @user_facilities = @user.facilities
    all_roles = JSON.parse(Global.send('user_roles').to_json)
    @user_roles = []
    @user.role_ids.each do |role_id|
      @user_roles << all_roles.select { |ele| ele[role_id.to_s] }.values[0]['label']
    end
  end

  def link_facilities_params
    @current_user = current_user
    @current_facility = current_facility
    @facilities_to_link = if params[:level] == 'facility'
                            Facility.where(:id.in => @current_user.facilities.pluck(:id))
                          else
                            Facility.where(organisation_id: params[:user][:organisation_id])
                          end
  end

  def update_user_ip_address(user_id, user_old_ips)
    user = User.find_by(id: user_id)
    new_ips = user.ip_address.where(:level.ne => 'facility').pluck(:remote_ip)
    user_common_ips = new_ips & user_old_ips
    user_new_added_ips = new_ips + user_common_ips - (new_ips & user_common_ips)
    user_ips_to_be_removed = user_old_ips + user_common_ips - (user_old_ips & user_common_ips)
    user_ips_to_be_removed.each do |ip|
      Redis::Master.new.lrem("user:#{user.id}:whitelisted-ips", 0, ip)
    end
    Redis::Master.new.rpush("user:#{user.id}:whitelisted-ips", user_new_added_ips)
    UserJobs::CreateIpAddressTrailJob.perform_later(user.id.to_s, current_user.id.to_s, 'update', user_ips_to_be_removed, user_new_added_ips)
  end

  def trusted_domains
    @trusted_domains = TrustedDomain.where(
      organisation_id: current_user.organisation_id, deleted: false, disabled: false
    )
  end

  def user_status_job
    return unless @user

    user_id = @user.id.to_s
    organisation_id = @user.organisation_id.to_s
    status = @user.status
    quota = @user.quota
    modified_by = current_user ? current_user.id.to_s : user_id

    UserStatusJob.perform_later(user_id, organisation_id, status, quota, modified_by)
  end
end
