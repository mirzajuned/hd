class ReferralType
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :label, type: String
  field :code, type: String

  field :is_manageable, type: Boolean, default: true
  field :is_active, type: Boolean, default: true

  # default_scope -> { where(is_active: true) }
end
