class IntraFacilityReferral
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :referraldate, type: Date
  field :referraltime, type: Time

  field :created_on, type: Date

  field :facility_id, type: BSON::ObjectId

  field :from_user, type: BSON::ObjectId # for now its only doc
  field :to_user, type: BSON::ObjectId # for now its only doc but can be lab also

  field :from_department, type: String
  field :to_department, type: String

  field :from_role, type: Array
  field :to_role, type: Array

  field :referral_appointment_type_id, type: BSON::ObjectId

  field :bookreferredappointment, type: Boolean, default: false

  field :referralnote, type: String

  embedded_in :opdrecord, class_name: "::OpdRecord"

  field :referral_appointment_category_id, type: String
end
