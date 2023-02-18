class RecentIcd
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :specialty_id, type: Integer
  field :template_id, type: Integer
  field :code, type: String
  field :originalname, type: String
  field :doctor, type: BSON::ObjectId
  field :counter, type: Integer
  field :icd_type, type: String
end
