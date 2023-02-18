class CashRegister
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :total, type: Float

  field :bill_number, type: String

  field :cash_register_type, type: String
  field :facility_id, type: String
  field :cash_register_type_id, type: Integer
  field :comments, type: String

  scope :newest_register_first, lambda { order("updated_at DESC") }

  belongs_to :patient, index: { background: true }
  belongs_to :user, index: { background: true }
  belongs_to :appointment, index: { background: true }
  belongs_to :admission, index: { background: true }

  embeds_many :cash_register_details

  accepts_nested_attributes_for :cash_register_details
  include Authority::Abilities
end
