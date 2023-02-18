class FacilitiesController < ApplicationController
  before_action :authorize
  before_action :find_facility, only: [:show, :edit, :update, :destroy, :activate, :display_font_size , :set_font_size, :update_font_size]
  before_action :form_params, :trusted_domains, only: [:new, :edit]
  before_action :facility_departments, only: [:show]
  
  include FacilitiesHelper

  def new
    @facility = Facility.new
    @communication_numbers = CommunicationNumber.where.in(
      organisation_id: [current_organisation['_id'].to_s, nil], is_disable: false
    )
  end

  def create
    @communication_numbers = CommunicationNumber.where.in(
      organisation_id: [current_organisation['_id'].to_s, nil], is_disable: false
    )
    @facility = Facility.new(facility_params)
    if @facility.country_id ==  "KH_039"
      @facility.consultant_role_ids = [28229004]
    else
      @facility.consultant_role_ids = [158965000]
    end
    if @facility.save
      facility_departments
      @country = Country.find_by(id: @facility.country_id)
      @currency = Currency.find_by(id: @facility.currency_id)

      render 'show'

      update_organisation_specialties
      facility_settings = params[:facility_settings].to_unsafe_h
      FacilityJobs::CreateJob.perform_later(@facility.id.to_s, facility_settings, current_user.id.to_s)
      FacilityJobs::CreateIpAddressTrailJob.perform_later(@facility.id.to_s, current_user.id.to_s, 'create', [], [])
      AppointmentTypeJobs::AppointmentTypeJob.perform_later(@facility.id.to_s, params[:facility][:organisation_id])
    else
      form_params
      render 'new'
    end
  end

  def show
    @communication_numbers = CommunicationNumber.where.in(
      organisation_id: [current_organisation['_id'].to_s, nil], is_disable: false
    )
    @token_setting = TokenSetting.find_by(facility_id: @facility.id.to_s)
  end

  def display_font_size
    @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id)
  end

  def set_font_size
    @type = params[:type]
    @department = params[:department]
    @current_font_size = params[:current_font_size]
  end

  def update_font_size
    update_params = {
      "template_font_size" => { template_font_size: params[:user_fonts][:font_size] },
      "bills_font_size" => { bills_font_size: params[:user_fonts][:font_size] },
      "template_header_font_size" => { template_header_font_size: params[:user_fonts][:font_size] }

    }
    @facility_setting = @facility.facility_setting
    @facility_setting.update!(update_params[params[:user_fonts][:type]])
    respond_to do |format|
      format.html { render :nothing => true }
      format.js 
    end
  end

  def edit
    # Get Timezone
    country = Country.find_by(id: @facility.country_id)
    @zones_array = country.get_time_zones if country.present?

    @currency = Currency.find_by(id: @facility.currency_id)

    @token_setting = TokenSetting.find_by(facility_id: @facility.id.to_s)
    @facility_setting = FacilitySetting.find_by(facility_id: @facility.id.to_s)
    @cidr_notation_ips = []
    @communication_numbers = CommunicationNumber.where.in(
      organisation_id: [current_organisation['_id'].to_s, nil], is_disable: false
    )
  end

  def update
    if @facility.country_id == "KH_039"
      @facility.consultant_role_ids = [28229004]
    else
      @facility.consultant_role_ids = [158965000]
    end
    @facility.ip_address.delete_all
    @communication_numbers = CommunicationNumber.where.in(
      organisation_id: [current_organisation['_id'].to_s, nil], is_disable: false
    )

    if @facility.update(facility_params)
      facility_departments
      @country = Country.find_by(id: @facility.country_id)
      @currency = Currency.find_by(id: @facility.currency_id)

      render 'show'

      update_organisation_specialties
      facility_settings = params[:facility_settings].to_unsafe_h
      FacilityJobs::UpdateJob.perform_later(@facility.id.to_s, facility_settings, current_user.id.to_s)
      FacilityJobs::UpdateIpAddressJob.perform_later(@facility.id.to_s, current_user.id.to_s)
      FacilityJobs::UpdateQmSettingJob.perform_later(@facility.id.to_s, facility_settings)
    else
      form_params
      render 'edit'
    end
  end

  def destroy
    @facility.update_attributes(is_active: false)

    users = User.where(facility_ids: params[:id])
    user_ids = users.pluck(:id).map(&:to_s)
    facility_ips = Redis::Master.new.lrange("facility:#{@facility.id}:whitelisted-ips", 0, -1)
    FacilityJobs::UpdateUsersJob.perform_later(user_ids, facility_ips, @facility.id.to_s) unless users.empty?
    @facility.ip_address.delete_all
    Redis::Master.new.del("facility:#{@facility.id}:whitelisted-ips")

    MisFilters::ManageFacilityFiltersService.call(@facility.organisation_id.to_s)
  end

  def activate
    @facility.update_attributes(is_active: true)

    @users = User.where(:id.in => @facility.user_ids)
    @users.each do |user|
      user.add_to_set(facility_ids: @facility.id)
    end
    MisFilters::ManageFacilityFiltersService.call(@facility.organisation_id.to_s)
    SequenceManagers::UpdateSequenceService.call('facility', @facility.id.to_s)
  end

  def validate_facility
    facility = params[:facility]
    if facility.present?
      if facility[:display_name].present?
        if params[:existing_display_name] != facility[:display_name]
          @facility = Facility.find_by(display_name: facility[:display_name], organisation_id: params[:organisation_id])
        end
      end
      if facility[:abbreviation].present?
        if params[:existing_abbreviation] != facility[:abbreviation]
          @facility = Facility.find_by(abbreviation: facility[:abbreviation], organisation_id: params[:organisation_id])
        end
      end
    end

    respond_to do |format|
      format.json { render json: !@facility.present? }
    end
  end

  def data # Manage Organisation
    @current_user = current_user
    @current_facility = current_facility
    @facilities = if params[:level] == 'facility'
                    Facility.where(:id.in => @current_user.facilities.pluck(:id))
                  else
                    Facility.where(organisation_id: params[:organisation_id])
                  end
    @total_facilities_count = @facilities.count
    @found_facilities = @facilities.where(name: /#{Regexp.escape(params[:sSearch])}/i)
    @facilities_count = @found_facilities.count
    @facilities = @found_facilities.limit(params[:iDisplayLength])
                                   .offset(params[:iDisplayStart])
                                   .order('name ' + params[:sSortDir_0])
    # @facility_wise_roles = get_facility_users_roles(@found_facilities.pluck(:id), params[:organisation_id])
    @facility_wise_roles = get_roles_name(params[:organisation_id])
  end

  # Move these Methods to OnboardingController in Future
  # Onboarding --> Needs Work when onboarding Starts
  def org_fetch
    @facility_id = current_user.facilities.first.id
    @facilities_count = Facility.where(organisation_id: params[:parent_id], is_active: true).count
    @facilities = Facility.where(organisation_id: params[:parent_id], is_active: true)
    @total_facilities_count = Facility.where(organisation_id: params[:parent_id], is_active: true).count
  end

  # Onboarding --> Needs Work when onboarding Starts
  def get_list
    @facilities = Facility.where(organisation_id: current_user.organisation_id, is_active: true)
    respond_to do |format|
      format.html { render layout: false }
    end
  end

  def convert_into_cidr
    @cidr_notation_ips = []
    ipstart = params[:q]
    unless (begin
              IPAddr.new(ipstart)
            rescue StandardError
              nil
            end).nil?
      startR = if ipstart.is_a?(String)
                 ip2long(ipstart)
               else
                 ipstart
               end

      result = []

      maxSize = 32
      while maxSize > 0
        mask = iMask(maxSize - 1)
        maskBase = startR & mask
        break if maskBase != startR

        maxSize -= 1
      end
      x = Math.log(startR + 1) / Math.log(2)
      maxDiff = (32 - x.floor).floor

      maxSize = maxDiff if maxSize < maxDiff

      ip = long2ip(startR)
      cidr = [ip, maxSize].join('/')
      result.push cidr
      startR += 2**(32 - maxSize)

      (maxSize..32).each do |num|
        @cidr_notation_ips << num
      end
    end
  end

  def iMask(s)
    (2**32 - 2**(32 - s))
  end

  def long2ip(num)
    IPAddr.new(num, Socket::AF_INET).to_s
  end

  def ip2long(ip)
    IPAddr.new(ip).to_i
  end

  private

  def facility_params
    params.require(:facility).permit(
      :name, :integration_identifier, :organisation_id, :display_name, :abbreviation, 
      :country_id, :time_zone, :currency_id, :currency_symbol, :address, :city, :state,
      :pincode, :sms_contact_number, :email, :telephone, :is_hospital, :communication_number_id,
      :clinical_workflow, :ipd_clinical_workflow, :show_finances, :hide_referral_note, 
      :show_user_state, :fax, 
      :district, :commune, :consultant_role_ids, :region_master_id,
      :number_format, :display_generic_name, department_ids: [], currency_ids: [], 
      specialty_ids: [], ip_address_attributes: [:remote_ip, :remote_ip_name]
    )
  end

  def find_facility
    @facility = Facility.find_by(id: params[:id])
    @organisation = Organisation.find_by(id: current_user.organisation_id)
  end

  def form_params
    @current_user = current_user
    @organisation = current_user.organisation

    @countries = Country.all

    @supported_currencies = Currency.where(:id.in => @organisation.currency_ids)
    @other_currencies = Currency.where(:id.nin => @organisation.currency_ids)

    @department = Department.all
    @specialties = Specialty.all
    @enable_region = current_organisation['enable_region']
    @col_length = (@enable_region.present?) ? 'col-sm-4' : 'col-sm-6'
    @region_masters = RegionMaster.where(organisation_id: current_organisation['_id'], country_id: current_facility['country_id']).uniq
  end

  def facility_departments
    @facility_departments = @facility.departments
    @region_master = RegionMaster.find_by(id: @facility.region_master_id)
  end

  def update_organisation_specialties
    current_org = Organisation.find_by(id: current_user.organisation_id)
    current_org_facilities = Facility.where(organisation_id: current_org['_id'])
    specialty_ids = current_org_facilities.pluck(:specialty_ids).flatten.uniq
    current_org.update_attributes(specialty_ids: specialty_ids)
  end

  def trusted_domains
    @trusted_domains = TrustedDomain.where(
      organisation_id: current_user.organisation_id, deleted: false, disabled: false
    )
  end
end
