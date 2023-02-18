class OpdRecordReview
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :authoruser, type: BSON::ObjectId
  field :revieweruser, type: BSON::ObjectId
  field :reviewsubmissiondate, type: Date, default: Date.current.strftime("%Y-%m-%d")
  field :reviewsubmissiontime, type: Time, default: Time.current.strftime("%I:%M %p")

  belongs_to :opd_record
end
