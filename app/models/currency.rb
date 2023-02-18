class Currency
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :name_plural, type: String

  field :code, type: String
  field :symbol, type: String

  field :decimal_digits, type: Integer
end
