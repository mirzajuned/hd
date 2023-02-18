class Organisation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  after_update :update_redis

  # BASIC INFO
  field :name, type: String
  field :tagline, type: String
  field :telephone, type: String
  field :fax, type: String
  field :email, type: String
  field :address1, type: String
  field :address2, type: String
  field :city, type: String
  field :state, type: String
  field :pincode, type: Integer
  field :website, type: String
  field :logo, type: String
  field :query_contact, type: String
  field :commune, type: String
  field :district, type: String

  # TYPE (Hospital|Private Practice)
  field :type, type: String
  field :type_id, type: String

  # LETTER HEAD SETTINGS
  field :customised_letter_head, type: Boolean, default: false
  field :customised_footer, type: Boolean, default: false
  field :onboarding_completed, type: Boolean, default: false
  field :letter_head_customisations, type: Hash

  # ID PREFIX FOR USER(Ex. HGI)
  field :identifier_prefix, type: String

  # TERMS ACCEPTANCE
  field :acceptancy_name, type: String
  field :acceptance_date, type: DateTime

  # PAID FOR DATA
  field :paid_for_data, type: Boolean, default: false

  # TAX IDENTIFICATION NUMBERS
  field :pan_no, type: String
  field :st_no, type: String

  # COUNTERS
  field :ophthal_investigations_counter, type: Integer, default: 10000
  field :radiology_investigations_counter, type: Integer, default: 10000
  field :laboratory_investigations_counter, type: Integer, default: 10000
  field :laboratory_investigations_id_counter, type: Integer, default: 130000111
  field :procedures_counter, type: Integer, default: 10000
  field :procedures_order_counter, type: Integer, default: 100000
  field :investigations_order_counter, type: Integer, default: 100000
  field :diagnosis_counter, type: Integer, default: 10000
  field :invoice_counter, type: Integer, default: 200001
  field :advance_counter, type: Integer, default: 10001
  field :refund_counter, type: Integer, default: 10001
  field :cash_register_counter, type: Integer, default: 10001
  field :patient_counter, type: Integer, default: 100001
  field :opd_counter, type: Integer, default: 200001
  field :ipd_counter, type: Integer, default: 200001
  field :service_master_counter, type: Integer, default: 100000
  field :case_counter, type: Integer, default: 1000001
  
  field :purchase_order_counter, type: Integer, default: 100000
  field :sales_order_counter, type: Integer, default: 100000
  field :purchase_transaction_counter, type: Integer, default: 100000
  field :sales_transaction_counter, type: Integer, default: 100000
  field :purchase_bill_counter, type: Integer, default: 100000
  field :purchase_return_transaction_counter, type: Integer, default: 100000
  field :opening_stock_counter, type: Integer, default: 100000
  field :indent_order_counter, type: Integer, default: 100000
  field :requisition_order_counter, type: Integer, default: 100000
  field :requisition_received_order_counter, type: Integer, default: 200000
  field :direct_stock_counter, type: Integer, default: 100000
  field :transfer_transaction_counter, type: Integer, default: 100000
  field :issue_transaction_counter, type: Integer, default: 100000
  field :receive_transaction_counter, type: Integer, default: 100000
  field :tray_transaction_counter, type: Integer, default: 100000
  field :store_consumption_transaction_counter, type: Integer, default: 100000
  field :srn_counter, type: Integer, default: 100000
  field :stock_adjustment_counter, type: Integer, default: 100000
  field :tax_invoice_counter, type: Integer, default: 100000
  field :delivery_challan_counter, type: Integer, default: 100000
  
  field :optical_prescription_counter, type: Integer, default: 100001
  field :contract_counter, type: Integer, default: 1
  field :footer_text, type: String, default: 'Thank You!'

  # ORGANIZATION ACCOUNT DETAILS
  field :account_counter, type: Integer, default: 180820141
  field :account_no, type: String
  field :account_expiry_date, type: Date

  # INVOICE AUTHORIZE
  field :invoice_accessible, type: Boolean, default: false
  field :invoice_access_code, type: String

  # CURRENCY
  field :currency_ids, type: Array, default: []

  # IDEAMED INTEGRATION BY KRANTI
  field :integration, type: Boolean, default: false
  field :publisher_name, type: String
  field :integration_identifier, type: BSON::ObjectId

  # SETUP TYPE
  field :setup_type, type: String

  # TRIAL STATUS
  field :payed_user, type: Boolean, default: false

  # REFERRAL CODE
  field :referral_code, type: String # Code used by Organisation while signing up
  field :my_referral_code, type: String # Organisation Referral Code

  # sms contact number
  field :sms_contact_number, type: String
  # whatsapp number
  field :whatsapp_number, type: String

  # multi - specialties field
  field :specialty_ids, type: Array, default: []

  field :is_migrated, type: Boolean, default: false

  # Preferred Number Format
  field :number_format, type: Integer, default: 0

  # IP Whitelisting
  field :is_ip_whitelisted, type: Boolean, default: false

  # Status Management
  field :auto_offline_on_logout, type: Boolean, default: false
  field :assign_patients_to_offline_user, type: Boolean, default: false
  field :clear_my_queue_before_offline, type: Boolean, default: false
  field :assign_patients_to_ot_user, type: Boolean, default: false
  field :clear_my_queue_before_ot, type: Boolean, default: false

  # enable/disable region
  field :enable_region, type: Boolean, default: false
  # enable/disable entity_group
  field :enable_entity_group, type: Boolean, default: false

  # This is for QMS. Specifically for agarwal to disable all QMS things
  field :workflow_waiting_disable, type: Boolean, default: false

  embeds_many :organisation_log_trail, class_name: '::OrganisationLogTrail'

  attr_accessor :terms

  mount_uploader :logo, OrganisationUploader

  # VALIDATIONS BY KRANTI
  validates_presence_of :integration_identifier, :my_referral_code
  validates_uniqueness_of :integration_identifier, :my_referral_code

  validates :name, presence: { message: 'Hospital Name cannot be blank.' }
  # validates :type, :length => { :minimum => 2, wrong_length: 'Please select an Organisation Type.'}
  # validates_acceptance_of :type, :message => 'Please select an Organisation Type.'
  validates_acceptance_of :terms, message: 'Terms and Conditions must be accepted'

  # validate :organisation_type_presence
  #
  # def organisation_type_presence
  #   if type.blank?
  #     errors.add(:type, "Please select an Organisation Type.")
  #   end
  # end

  index({ name: 1 }, background: true)

  has_many :facilities
  has_many :users
  has_many :patient_identifiers
  has_one :organisations_setting
  has_many :users_settings
  has_many :opd_record_identifiers
  has_many :entity_groups

  belongs_to :country, optional: true

  # accepts_nested_attributes_for :facilities
  # accepts_nested_attributes_for :users

  def allow_duplicate_user_email?
    organisations_setting&.allow_duplicate_user_email
  end

  def print_bill_service_code?
    organisations_setting&.print_bill_service_code
  end

  # Hack for carrierwave-mongoid to work https://github.com/carrierwaveuploader/carrierwave-mongoid/issues/142#issuecomment-110130129
  def store_previous_model_for_logo
    return unless logo.remove_previously_stored_files_after_update && logo_changed?

    @previous_model_for_logo ||= find_previous_model_for_logo
  end

  def find_previous_model_for_logo
    self.class.find(to_key.first)
  end

  def remove_previously_stored_logo
    return unless @previous_model_for_logo && @previous_model_for_logo.logo.path != logo.path && !logo.path.nil?

    @previous_model_for_logo.logo.remove!
    @previous_model_for_logo = nil
  end

  def update_redis
    # $REDIS.del("organisation:#{self.id.to_s}", self.to_json)
    # Redis::Local.new.del("organisation:#{id}", to_json)
    Redis::Local.new.set("organisation:#{id}", to_json)
    organisation_json = { "organisation:#{id}" => self.to_json }
    Redis::Master.new.xadd('ehr:redis_key', organisation_json, id: '*')
    organisation_hash = { "organisation:#{id}" => self }
    Redis::Master.new.rpush('ehr:current:list', organisation_hash.to_json)
  end

  def update_expiry(expiry_date)
    return 'Please provide argument in Class::Date.' if expiry_date.class != Date

    if expiry_date > Date.current
      update(account_expiry_date: expiry_date)

      users = User.where(organisation_id: id)
      users.update_all(account_expiry_date: expiry_date)
      if(SequenceManager.where(organisation_id: id.to_s).count == 0)
        SequenceManagers::CreateSequenceService.call(id.to_s)
      end

      'Expiry Date Updated Successfully.New expiry Date is ' + expiry_date.strftime('%d/%m/%Y')
    else
      'Expiry Date cant be less than Current Date(' + Date.current.strftime('%d/%m/%Y') + ').'
    end
  end

  def user_roles
    users.map { |user| user.roles.pluck(:id, :label) }.flatten.uniq
  end
end
