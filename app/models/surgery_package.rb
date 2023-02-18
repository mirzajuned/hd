class SurgeryPackage
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :amount, type: Float, default: 0.0

  field :valid_from, type: Date, default: Date.today
  field :valid_till, type: Date, default: Date.today

  field :display_name, type: String

  field :service_type, type: String
  field :service_type_code, type: String
  field :service_type_code_name, type: String

  field :contact_group_id, type: String
  field :contact_id, type: String
  field :payer_master_id, type: String

  field :room_type, type: String

  field :type, type: String, default: 'domestic' # Domestic/International
  field :no_of_days, type: Integer, default: 0

  field :service_group_id, type: BSON::ObjectId
  field :service_sub_group_id, type: BSON::ObjectId

  field :package_group_id, type: String # Group Id for the Packages with the same Package Definition
  field :package_uniq_id, type: String # Uniq Id for the Package across Facilities

  field :specialty_id, type: String
  field :sub_specialty_id, type: String
  field :department_id, type: String
  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :activity_log, type: Hash, default: {}

  field :activated, type: Boolean, default: false
  field :is_active, type: Boolean, default: true
  field :is_migrated, type: Boolean, default: true

  # OLD FIELDS
  field :pricing_amount, type: Float, default: 0.0
  field :discount_amount, type: Float, default: 0.0
  field :discount_percent, type: Float, default: 0.0

  field :user_package_code, type: String

  embeds_many :services, class_name: '::SurgeryPackage::Service'

  accepts_nested_attributes_for :services, allow_destroy: true

  validates_presence_of :name, :display_name, :contact_group_id, :specialty_id, :department_id, :user_package_code,
                        :user_id, :facility_id, :organisation_id

  before_save :set_package_uniq_id

  def set_package_uniq_id
    self.package_uniq_id ||= BSON::ObjectId.new
  end

  # Indexes
  # index({ facility_id: 1 }) # db.surgery_packages.createIndex({ facility_id: 1 })
end
