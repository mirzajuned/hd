class PricingMaster
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :service_name, type: String
  field :service_type, type: String
  field :service_type_code, type: String
  field :service_type_code_name, type: String
  field :service_type_code_type, type: String
  field :amount, type: Float, default: 0.0
  field :discount_amount, type: Float, default: 0.0
  field :discount_percent, type: Float, default: 0.0
  field :contact_group_id, type: BSON::ObjectId
  field :is_active, type: Boolean, default: true
  field :activity_log, type: Hash, default: {}

  field :service_code, type: String
  field :facility_service_code, type: String
  field :internal_comment, type: String
  field :external_comment, type: String

  field :department_name, type: String
  field :department_id, type: String

  field :user_id, type: BSON::ObjectId
  field :consultant_user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :specialty_id, type: String
  field :sub_specialty_id, type: String

  field :is_migrated, type: Boolean, default: true

  field :has_exceptions, type: Boolean, default: false
  field :exceptions, type: Array, default: []

  belongs_to :service_master
  belongs_to :service_group
  belongs_to :service_sub_group, optional: true
  belongs_to :contact, optional: true
  belongs_to :payer_master, optional: true
  # belongs_to :organisation
  # belongs_to :facility
  # belongs_to :user

  embeds_many :pricing_exceptions

  accepts_nested_attributes_for :pricing_exceptions, allow_destroy: true

  validates_presence_of :service_name, :amount, :user_id, :facility_id, :organisation_id, :department_id

  # Indexes
  # index({ service_master_id: 1 }) # db.pricing_masters.createIndex({ service_master_id: 1 })
  # index({ facility_id: 1 }) # db.pricing_masters.createIndex({ facility_id: 1 })
end
