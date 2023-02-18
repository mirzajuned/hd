class Speciality
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :is_launched, type: Boolean, default: false
end
