class OutsideOrganisationReferral
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :referraldate, type: Date
  field :referraltime, type: Time

  field :created_on, type: Date

  field :from_facility, type: BSON::ObjectId
  field :to_facility, type: String

  field :from_user, type: BSON::ObjectId # for now its only doc
  field :to_user, type: String

  field :from_department, type: String
  field :to_department, type: String

  field :from_role, type: Array
  field :to_role, type: Array

  field :referralnote, type: String
  embedded_in :opdrecord, class_name: "::OpdRecord"
end
