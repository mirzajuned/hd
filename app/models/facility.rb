class Facility
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  # Facility Details
  field :name, type: String
  field :display_name, type: String
  field :abbreviation, type: String

  # Adress
  field :address, type: String
  field :city, type: String
  field :state, type: String
  field :pincode, type: Integer
  field :commune, type: String
  field :district, type: String

  # Contact
  field :telephone, type: String
  field :fax, type: String
  field :email, type: String

  # Foss Internal
  field :is_hospital, type: Boolean, default: true

  field :is_active, type: Boolean, default: true
  field :type_id, type: Integer, default: 257622000
  field :integration_identifier, type: BSON::ObjectId

  # Facility Settings Can be moved to Settings in Future
  field :clinical_workflow, type: Boolean, default: true
  field :ipd_clinical_workflow, type: Boolean, default: false
  field :show_finances, type: Boolean, default: true
  field :show_user_state, type: Boolean, default: false
  field :show_language_support, type: Boolean, default: true
  field :admission_schedule_list_length, type: Integer, default: 0
  field :counsellor_counsels_investigation, type: Boolean, default: true
  field :consultancy_type_enabled, type: Boolean, default: false
  field :invoice_compulsory, type: Boolean, default: false
  field :hide_referral_note, type: Boolean, default: true
  # for migration purpose
  field :is_migrated, type: Boolean, default: false

  field :display_generic_name, type: Boolean, default: true # For displaying generic name in OPD
  field :description_comment, type: Boolean, default: false

  # Counters
  field :pricing_master_counter, type: Integer, default: 100000

  # TimeZone
  field :time_zone, type: String

  # Currency
  field :currency_id, type: String
  field :currency_symbol, type: String
  field :currency_ids, type: Array, default: []

  field :search_type, type: String
  field :assessment_search_type, type: String, default: 'all' # for clinical assessment search data - all/custom/standard

  # based on organisation country_id consultant_role_id
  field :consultant_role_ids, type: Array, default: []

  # sms contact number
  field :sms_contact_number, type: String

  # multi-specialty fields
  field :specialty_ids, type: Array, default: []

  # Integration Keys
  field :integration_keys, type: Array, default: []

  # cenrtral hub
  field :inventory_store_ids, type: Array, default: []

  field :is_prescription_migrated, type: Boolean, default: true
  # Preferred Number Format
  field :number_format, type: Integer, default: 0

  # Document Management Integration - Linking to an external document management system.
  # This setting "document_mgmt_enabled" was done primarly for Sankara but can be extended in other use cases.
  # Added 27th Nov 2020 Mohit.
  field :link_to_external_app, type: Boolean, default: false
  # Example - http://192.168.12.237/ilifeDMR/ImageViewer.aspx?PatientId= or
  # http://dmr.sankaraeye.com/ilifedmr/ImageViewer.aspx?PatientId=
  field :url_of_external_app, type: String, default: 'http://www.example.com/abc/xyz'

  field :region_master_id, type: BSON::ObjectId
  # whatsapp number
  field :communication_number_id, type: BSON::ObjectId

  embeds_many :ip_address, class_name: '::IpAddress'

  embeds_many :facility_log_trail, class_name: '::FacilityLogTrail'

  accepts_nested_attributes_for :ip_address, reject_if: proc { |attributes| attributes['remote_ip'].blank? },
                                             allow_destroy: true

  # Validations
  validates_presence_of :name, message: 'Facility Name cannot be blank'

  validates_uniqueness_of :integration_identifier
  validates_uniqueness_of :display_name, case_sensitive: false, message: 'Display Name Taken', scope: :organisation_id
  validates_uniqueness_of :abbreviation, case_sensitive: false, message: 'Code Taken', scope: :organisation_id

  # Relations
  belongs_to :organisation
  belongs_to :country, optional: true
  belongs_to :communication_number, optional: true

  has_and_belongs_to_many :departments, inverse_of: nil
  has_and_belongs_to_many :users

  has_many :patient_diagnoses
  has_many :patient_medications
  has_many :patient_prescriptions
  has_many :patient_investigations
  has_many :patient_radiology_investigations
  has_many :patient_laboratory_investigations
  has_many :patient_other_investigations
  has_many :patient_procedures
  has_many :patient_timelines
  has_many :wards
  has_many :appointment_types
  has_many :camps
  has_many :communication_event_setups
  has_many :investigation_queues, class_name: '::Investigation::Queue'

  has_one :facility_setting

  accepts_nested_attributes_for :departments

  after_save :clear_redis, :clear_redis_users
  after_save :update_domain_count, if: :email_changed?

  def update_domain_count
    old_domain = TrustedDomain.find_by(organisation_id: organisation_id, name: email_was.to_s.split('@')[1],
                                       deleted: false)
    old_domain.inc(use_count: -1) if old_domain && old_domain.use_count > 0

    new_domain = TrustedDomain.find_by(organisation_id: organisation_id, name: email.to_s.split('@')[1],
                                       deleted: false)
    new_domain&.inc(use_count: 1)
  end

  # Class Methods
  def clear_redis
    # $REDIS.del("facility:#{id}")
    # Redis::Local.new.del("facility:#{id}")
    Redis::Local.new.set("facility:#{id}", to_json)

    facility_json = { "facility:#{id}" => to_json }
    Redis::Master.new.xadd('ehr:redis_key', facility_json, id: '*')

    facility_hash = { "facility:#{id}" => self }
    Redis::Master.new.rpush('ehr:current:list', facility_hash.to_json)
  end

  def clear_redis_users
    user_ids.each do |user_id|
      # $REDIS.del("user_facilities:#{user_id}")
      # Redis::Local.new.del("user_facilities:#{user_id}")
      user = User.find_by(id: user_id)
      next if user.nil?

      user_facilities_value = user.facilities.includes(:facility_setting).to_json
      Redis::Local.new.set("user_facilities:#{user_id}", user_facilities_value)

      user_facilities_json = { "user_facilities:#{user_id}" => user_facilities_value }
      Redis::Master.new.xadd('ehr:redis_key', user_facilities_json, id: '*')

      user_facilities_hash = { "user_facilities:#{user_id}" => JSON.parse(user_facilities_value) }
      Redis::Master.new.rpush('ehr:current:list', user_facilities_hash.to_json)
    end
  end
end
