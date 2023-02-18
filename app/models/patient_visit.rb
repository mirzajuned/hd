class PatientVisit
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :doctor, type: BSON::ObjectId
  field :encounter_type, type: String # OPD or IPD
  field :encounter_date, type: Date
  field :sms_sent, type: Boolean, default: false

  belongs_to :organisation
  belongs_to :facility
  belongs_to :patient
  belongs_to :user
end
