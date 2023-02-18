class Common
  attr_accessor :users, :facilities, :departments

  def initialize
  end

  def fetch_facilities(options = {})
    @facilities = options[:user].facilities.where(is_active: true)
  end

  def fetch_referred_facilities(options = {})
    facility_with_no_doc = []
    current_user_facilities = options[:current_user].organisation.facilities.where(is_active: true)
    current_user_facilities.each do |facility|
      if User.where(facility_ids: facility.id.to_s, role_ids: 158965000, is_active: true).count == 0
        facility_with_no_doc << facility
      end
    end
    @referral_facilities = current_user_facilities - [options[:facility_id]] - facility_with_no_doc
  end

  def fetch_departments(options = {})
    facility = options[:facilities].includes(:departments).first
    @departments = facility.departments.where(:is_launched => true)
  end

  def fetch_users(options = {})
    if options[:org_type] == 'individual'
      @users = fetch_users_for_org_individual(:organisation_id => options[:organisation_id], :facility_id => options[:facility_id])
    elsif options[:org_type] == 'hospital'
      @users = fetch_users_for_org_hospital_fac_dept(:organisation_id => options[:organisation_id], :facility_id => options[:facility_id], :department_id => options[:department_id])
    end
  end

  private

  def fetch_users_for_org_individual(options = {})
    facility_ids = [options[:facility_id]]
    users = User.where(:organisation_id => options[:organisation_id], :facility_ids.in => facility_ids, :is_active => true).with_all_roles(:doctor)
  end

  def fetch_users_for_org_hospital_fac_dept(options = {})
    facility_ids = [options[:facility_id]]
    users = User.where(:organisation_id => options[:organisation_id], is_active: true, :facility_ids.in => facility_ids, :department_id => options[:department_id]).with_all_roles(:doctor)
  end
end
