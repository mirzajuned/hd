class Language
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :name, type: String
  field :locale, type: String
  field :lcid_code, type: String
  field :lcid_string, type: String
  field :country, type: String

  validates_presence_of :name, :locale, :lcid_code, :lcid_string # , :country
  validates_uniqueness_of :locale, :lcid_code, :lcid_string

  has_and_belongs_to_many :countries
end
