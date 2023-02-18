class PatientDilation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :start_time, type: Time
  field :end_time, type: Time
  field :drops, type: String
  field :user_id, type: BSON::ObjectId
  field :dilated_by, type: BSON::ObjectId
  field :advised_by, type: BSON::ObjectId
  field :comment, type: String
  field :eye_side, type: String

  field :is_reseted, type: Boolean, default: false

  belongs_to :appointment
  belongs_to :patient

  def eye_side_value(eye_side_id)
    eye_side_hash = { '18944008' => 'Right Eye', '8966001' => 'Left Eye', '40638003' => 'Both Eye' }
    eye_side_hash[eye_side_id] # return
  end
end
