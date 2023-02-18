class Advice
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :advice_content, type: String
  field :opdfollowupdate, type: Date
  field :opdfollowuptime, type: Time
  field :appointment_specialty_id, type: String

  embedded_in :opdrecord, class_name: "::OpdRecord"
  embedded_in :operative_note, class_name: "::OperativeNote"
end
