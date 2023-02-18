class OtKit
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :name, type: String
  field :set_type, type: Integer
  field :data, type: String
  field :department, :type => Integer

  field :doctor, type: BSON::ObjectId

  belongs_to :user, index: { background: true }
  belongs_to :organisation, index: { background: true }
end
