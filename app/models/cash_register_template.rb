class CashRegisterTemplate
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :template_details, type: String
  field :name, type: String

  belongs_to :user
end
