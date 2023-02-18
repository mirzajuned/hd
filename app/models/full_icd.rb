class FullIcd
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :code, type: String
  field :abbrevated_name, type: String
  field :root, type: Integer
  field :fullname, type: String
  field :originalname, type: String
  field :converted, type: Boolean, default: false
end
