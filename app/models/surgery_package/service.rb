class SurgeryPackage::Service
  include Mongoid::Document
  include Mongoid::Timestamps

  field :item_id, type: String
  field :item_name, type: String
  field :item_type, type: String
  field :item_code, type: String

  field :unit, type: Integer, default: 0
  field :unit_price, type: Float, default: 0.0
  field :total_price, type: Float, default: 0.0

  field :is_active, type: Boolean, default: true

  field :old, type: Boolean, default: false

  field :activity_log, type: Hash, default: {}

  # Old Fields
  field :service_name, type: String
  field :service_code, type: String
  field :internal_comment, type: String
  field :external_comment, type: String
  field :discount_amount, type: Float, default: 0.0
  field :discount_percent, type: Float, default: 0.0

  embedded_in :surgery_package

  validates_presence_of :item_id

  default_scope -> { where(old: false) }
end
