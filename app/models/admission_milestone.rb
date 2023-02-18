class AdmissionMilestone
  include Mongoid::Document
  include Mongoid::Timestamps

  field :label, type: String
  field :position, type: Integer
  field :start_time, type: DateTime, default: Time.current
  field :user_id, type: BSON::ObjectId

  # For Stages with OT
  field :ot_id, type: BSON::ObjectId

  embedded_in :admission
  embedded_in :admission_list_view
  embedded_in :ot_list_view
end
