class PricingException
  include Mongoid::Document
  include Mongoid::Timestamps

  field :room_exception_id, type: String
  field :room_exception_name, type: String

  field :user_exception_id, type: String
  field :user_exception_name, type: String

  field :amount, type: Float, default: 0.0

  field :sequence, type: Array, default: []
  field :is_active, type: Boolean, default: true

  embedded_in :pricing_master
end
