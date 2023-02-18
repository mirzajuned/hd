class SubSpecialty
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :is_default, type: Boolean, default: false

  field :specialty_name, type: String

  belongs_to :specialty
end
