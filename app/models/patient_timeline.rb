class PatientTimeline
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :encounterdate, type: DateTime
  field :doctor, type: BSON::ObjectId
  field :doctor_name, type: String
  field :specialty_id, type: String

  belongs_to :patient
  belongs_to :user
  belongs_to :facility

  def get_doctor_name(userid)
    fullname = User.find_by(:id => userid).fullname
  end
end
