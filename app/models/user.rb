class User
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  include Authority::UserAbilities
  include UsersHelper

  attr_accessor :password, :roleids, :expired, :skip_username_validation
  # attr_readonly :email

  # Callbacks
  before_save :encrypt_password
  before_upsert :encrypt_password
  after_upsert :clear_password
  after_save :clear_password, :update_redis

  after_create :create_integration_api
  after_update :update_integration_api

  # Personal Details
  field :salutation, type: String
  field :fullname, type: String
  field :username, type: String
  field :gender, type: String
  field :dob, type: Date
  field :age, type: Integer
  field :mobilenumber, type: String
  field :email, type: String
  field :alternate_telephone, type: String
  field :alternate_email, type: String
  field :telephone, type: String
  field :address, type: String
  field :city, type: String
  field :state, type: String
  field :pincode, type: Integer
  field :user_profile_pic, type: String
  field :user_signature, type: String
  field :digital_signature, type: Boolean, default: false
  field :include_designation, type: Boolean, default: false
  field :include_registration_number, type: Boolean, default: true
  field :include_specialty, type: Boolean, default: false
  field :commune, type: String
  field :district, type: String

  # Professional Details
  field :designation, type: String
  field :education_qualification, type: Array, default: []
  field :work_experience, type: Array, default: []
  field :licence_number, type: String
  field :registration_number, type: String
  field :employee_id, type: String
  field :qualification, type: String
  field :fellowship, type: String
  field :include_qualification, type: Boolean, default: false
  field :include_fellowship, type: Boolean, default: false
  field :include_print_datetime, type: Boolean, default: true

  # Security
  field :encrypted_password, type: String
  field :salt, type: String
  field :password_reset_token, type: String
  field :password_reset_sent_at, type: String

  # Foss Internal
  # Activation & Deactivation Fields - Starts
  field :is_active, type: Boolean, default: false # There were lot of other fields to track who updated / activated / deactivated user, Mohit had added but interest of time and Dr. Agarwal's pushing for this change, removed those changes. Go through the Commits to see those fields. This comment is added by Mohit on 11th Oct 2022.
  # Activation & Deactivation Fields - Ends
  field :user_selected_url, type: String
  field :account_expiry_date, type: Date
  field :sms_feature, type: Boolean, default: true
  field :ipd_logo, type: String
  field :opd_logo, type: String
  field :sub_department, type: String
  field :max_refers, type: Integer # max pat can be referred in a day.(Can be used in future)
  field :background_color, type: String, default: '#1920a5'
  field :integration_identifier, type: BSON::ObjectId
  field :external_identifier, type: String, default: '0'
  field :new_feature_seen, type: Boolean, default: true
  field :last_edited_by, type: String

  # multi-specialty fields
  field :department_ids, type: Array, default: []
  field :specialty_ids, type: Array, default: []
  field :specialty_names, type: Array, default: []
  field :sub_specialty_ids, type: Array, default: []
  field :sub_specialty_names, type: Array, default: []

  # Status Management
  field :is_set_state_done_manually, type: Boolean, default: false
  field :last_known_state_at_logout, type: String, default: "OPD"

  # Status
  field :status, type: String
  field :quota, type: String

  field :is_internal_user, type: Boolean, default: true

  field :updated, type: Boolean, default: true
  field :is_migrated, type: Boolean, default: true

  # Queue Management - Remove once work is done and methods not needed
  # field :station_fields, type: Hash, default: {}
  # field :sub_station_id, type: BSON::ObjectId
  # field :sub_station_code, type: String

  embeds_many :ip_address, class_name: '::IpAddress'

  embeds_many :user_log_trail, class_name: '::UserLogTrail'

  accepts_nested_attributes_for :ip_address,
                                reject_if: proc { |attributes| attributes['remote_ip'].blank? },
                                allow_destroy: true

  field :is_open_access_enabled, type: Boolean, default: true

  # Validation
  validates :email, presence: { message: 'Email cannot be blank.' },
                    format: { with: /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/,
                              message: 'Please enter a valid email' }

  validates :password, presence: { message: 'Please choose a strong password' },
                       format: { with: /\A(?=.*[A-Z])(?=.*[0-9])(?=.*[@#$%^&+=]).{8,}\z/,
                                 message: 'Must be at least 8 characters and include one number,one Capital letter and any of the following special characters @#$%^&+=' },
                       confirmation: { message: 'Passwords Do not Match' },
                       allow_nil: true

  validates :username, presence: { message: 'Username cannot be blank.' },
                       format: { with: /\A[A-Za-z0-9][A-Za-z0-9_.-]{0,24}\Z/,
                                 message: 'Username should only contain letters and numbers and no spaces.' }

  validates_presence_of :fullname, message: 'Name cannot be blank.'
  # validates_presence_of :department_id, message: "Please select a Department."

  validates_presence_of :facility_ids, message: 'Please select facility location'

  validates_presence_of :integration_identifier
  validates_uniqueness_of :username, message: 'Username already taken'
  validates_uniqueness_of :email, scope: :organisation_id, message: 'Account already exists with this email',
                                  unless: :allow_duplicate_email?
  validates_uniqueness_of :integration_identifier
  validates :employee_id, uniqueness: true, if: :employee_id_unique_within_organisation

  def employee_id_unique_within_organisation
    @employee_id = User.find_by(organisation_id: organisation_id, employee_id: employee_id, is_active: true).present?
  end

  def allow_duplicate_email?
    organisation&.allow_duplicate_user_email?
  end

  def print_bill_service_code?
    organisation&.print_bill_service_code?
  end

  # Uploader
  mount_uploader :user_profile_pic, UserUploader
  mount_uploader :user_signature, UserSignatureUploader
  mount_uploader :ipd_logo, UserUploader
  mount_uploader :opd_logo, UserUploader

  # Relations
  has_and_belongs_to_many :facilities, inverse_of: nil, index: { background: true }

  has_and_belongs_to_many :inventory_stores, class_name: '::Inventory::Store', inverse_of: nil

  belongs_to :country, optional: true
  belongs_to :organisation, index: { background: true }, optional: true

  has_many :users_medication_lists
  has_many :users_opd_records
  has_many :my_practice_medication_lists
  has_many :users_laboratory_lists
  has_many :vacations, class_name: '::User::Vacation'
  has_many :user_states
  has_many :user_statuses
  has_many :patient_diagnoses
  has_many :patient_medications
  has_many :patient_prescriptions
  has_many :patient_investigations
  has_many :patient_radiology_investigations
  has_many :patient_laboratory_investigations
  has_many :patient_other_investigations
  has_many :patient_procedures
  has_many :patient_timelines

  has_one :users_setting

  has_one :user_time_slot

  accepts_nested_attributes_for :my_practice_medication_lists,
                                reject_if: proc { |attributes| attributes['name'].blank? }
  embeds_many :inventories, class_name: '::User::Inventory'

  rolify

  after_save :update_domain_count
  after_destroy :update_domain_count

  USER_ROLES_SHORT_FORMS = {'doctor': 'Dr.', 'receptionist': 'Rcpt.','nurse': 'Nr.','counsellor': 'Cr.',
                            'optometrist': 'Opt.','pharmacist': 'Ph.','optician': 'OP.','radiologist': 'RA.',
                            'technician': 'LA.', 'ophthalmology_technician': 'OPH.','cashier': 'CA.','ar_nct': 'AR.',
                            'floormanager': 'FM.','tpa': 'TP.', 'laboratory_technician': 'LAB', 'center_head': 'Center Head',
                             'admin': 'Admin','resident': 'Resident', 'owner': 'Owner'}.with_indifferent_access

  def update_domain_count
    if email_changed?
      old_domain = TrustedDomain.find_by(organisation_id: organisation_id, name: email_was.to_s.split('@')[1],
                                         deleted: false)
      old_domain.inc(use_count: -1) if old_domain && old_domain.use_count > 0

      new_domain = TrustedDomain.find_by(organisation_id: organisation_id, name: email.to_s.split('@')[1],
                                         deleted: false)
      new_domain&.inc(use_count: 1)
    elsif destroyed?
      domain = TrustedDomain.find_by(organisation_id: organisation_id, name: email.to_s.split('@')[1],
                                     deleted: false)
      domain&.inc(use_count: -1)
    end
  end

  # MyPracticeMedication --> Needs Works
  def initialize_nested_objects
    (60 - my_practice_medication_lists.size).times do
      my_practice_medication_lists.build
    end
  end

  # Login Authentication
  def self.authenticate(username = '', login_password = '')
    user = User.find_by(username: username, is_active: true)
    return false unless user&.match_password(login_password)

    user
  end

  def match_password(login_password = '')
    encrypted_password == BCrypt::Engine.hash_secret(login_password, salt)
  end

  # Set Password (New User/ Forget Password)
  def encrypt_password
    return if password.blank?

    self.salt = BCrypt::Engine.generate_salt
    self.encrypted_password = BCrypt::Engine.hash_secret(password, salt)
  end

  def clear_password
    self.password = nil
  end

  # output will be "doctor,admin", "doctor,owner", "doctor" or "receptionist" or "nurse"
  def selected_role
    UsersHelper.get_user_roles_names(role_ids)
  end

  def primary_role
    UsersHelper.get_primary_role(role_ids)
  end

  def custom_name_format
    roles_short_form = roles.count > 1 ? roles.map(&:label).join(' ') : USER_ROLES_SHORT_FORMS[roles.first.try(:name)]
    name_with_role = roles_short_form.present? ? "#{fullname} -- #{roles_short_form}" : fullname
    return "#{name_with_role}  (#{employee_id}/#{designation})" if employee_id.present? && designation.present?
    return "#{name_with_role}  (#{employee_id})" if employee_id.present? && designation.blank?
    return "#{name_with_role}  (#{designation})" if employee_id.blank? && designation.present?
    return "#{name_with_role}" if employee_id.blank? && designation.blank?
  end

  def update_redis
    # To Delete Cache
    # $REDIS.del("user:#{id}")
    # Redis::Local.new.del("user:#{id}")
    # $REDIS.del("user_facilities:#{id}")
    # Redis::Local.new.del("user_facilities:#{id}")
    # $REDIS.del("user_facility_settings:#{id}")
    # Redis::Local.new.del("user_facility_settings:#{id}")
    user_value = to_json
    user_facilities_value = facilities.includes(:facility_setting).to_json
    user_facility_settings_value = FacilitySetting.where(:facility_id.in => facility_ids)
                                       .order('facility_name ASC').to_json

    Redis::Local.new.set("user:#{id}", user_value)
    Redis::Local.new.set("user_facilities:#{id}", user_facilities_value)
    Redis::Local.new.set("user_facility_settings:#{id}", user_facility_settings_value)

    user_xadd_json = {"user:#{id}" => user_value, "user_facilities:#{id}" => user_facilities_value, "user_facility_settings:#{id}" => user_facility_settings_value  }
    Redis::Master.new.xadd('ehr:redis_key', user_xadd_json, id: '*')
    user_hash = { "user:#{id}" => JSON.parse(user_value) }
    Redis::Master.new.rpush('ehr:current:list', user_hash.to_json)
    user_facilities_hash = { "user_facilities:#{id}" => JSON.parse(user_facilities_value) }
    Redis::Master.new.rpush('ehr:current:list', user_facilities_hash.to_json)
    user_facility_settings_hash = { "user_facility_settings:#{id}" => JSON.parse(user_facility_settings_value) }
    Redis::Master.new.rpush('ehr:current:list', user_facility_settings_hash.to_json)
  end

  def admin?
    role_ids.include?(6868009)
  end

  def doctor?
    role_ids.include?(158965000)
  end

  def doc_admin?
    (role_ids == [158965000, 6868009])
  end

  def receptionist?
    role_ids.include?( 159561009 )
  end

  def organisation_settings_emails
    organisation.try(:organisations_setting).try(:emails).presence || []
  end

  def create_integration_api
    # Call for External API's
    # if organisation_id.to_s == "5e1431e619e7da18c114b776" && role_ids.include?158965000
    # need to update for sankara medics
    if (role_ids.include? 158965000) && facility_ids.present? && (organisation_id.to_s == '5e21ffd6cd29ba0ce0bf5a1e')
      # need to update for sankara medics
      ApiIntegration::DoctorData.create(id, 'medics', facility_ids[0].to_s)
    end
  end

  def update_integration_api
    if (role_ids.include? 158965000) && facility_ids.present? && (organisation_id.to_s == '5e21ffd6cd29ba0ce0bf5a1e')
      # need to update for sankara medics
      ApiIntegration::DoctorData.update(id, 'medics', facility_ids[0].to_s)
    end
  end
end
