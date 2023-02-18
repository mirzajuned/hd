class GenericClass
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :name, type: String
  field :company_name, type: String
  field :category, type: String

  validates_presence_of :name
end
