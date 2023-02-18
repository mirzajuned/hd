class PostOpRecord
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :surgery_name, type: String
  field :surgery_code, type: String
  field :eye_side, type: String
  field :surgery_date, type: DateTime
  field :post_operative_day, type: String
  field :comment, type: String

  embedded_in :opdrecord, class_name: "::OpdRecord"
end
