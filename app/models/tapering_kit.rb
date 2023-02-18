class TaperingKit
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :medicine_name, type: String
  field :keyword, type: String
  field :taperingtype, type: String
  field :taper_by, type: String
  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId

  belongs_to :user
  embeds_many :tapering_set, class_name: "::TaperingSet"

  accepts_nested_attributes_for :tapering_set, reject_if: proc { |attributes| attributes['number_of_days'].blank? }, allow_destroy: true
end
