class CashRegisterDetail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :serial_number, type: Integer
  field :label, type: String
  field :description, type: String
  field :unit_price, type: Float
  field :total_units, type: Integer

  embedded_in :cash_register
  belongs_to :service
end
