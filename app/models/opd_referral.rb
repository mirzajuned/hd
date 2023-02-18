class OpdReferral
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :referral_date, type: Date
  field :created_on, type: Date

  field :patient_id, type: BSON::ObjectId
  field :patient_name, type: String

  field :to_facility, type: BSON::ObjectId                         # facility id to patient is assigned/referred
  field :to_facility_name, type: String                            # not required as we are not showing it in notification
  field :to_facility_specialty, type: String

  field :from_facility, type: BSON::ObjectId                       # facility id from patient is assigned/referred
  field :from_facility_name, type: String                          # facility name from patient is assigned/referred
  field :from_facility_specialty, type: String

  field :from_doctor, type: BSON::ObjectId                       # Doctor's id from patient is assigned/referred
  field :from_doctor_name, type: String                          # Doctor's name from patient is assigned/referred

  field :to_doctor, type: BSON::ObjectId                         # Doctor's id from patient is assigned/referred
  field :to_doctor_name, type: String                            # Doctor's name from patient is assigned/referred

  field :referring_note, type: String

  field :is_seen, type: Boolean, default: false
  field :converted_to_appointment, type: Boolean, default: false # can be used in future
  field :converted_appointment_id, type: BSON::ObjectId # can be used in future

  field :is_deleted, type: Boolean, default: false # Used for soft delete

  field :opd_record_id, type: BSON::ObjectId # just for future use

  field :inter_facility_referral_id, type: BSON::ObjectId
  # belongs_to :user                                                  #Doctor's id to whom pat is assigned/referred
  belongs_to :organisation
end
