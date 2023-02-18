class SedationRecord
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :date, type: Date
  field :time, type: Time
  field :respiration_rate, type: Integer
  field :blood_pressure, type: String
  field :pulse, type: String
  field :sedation_score, type: String
  field :medication, type: String
  field :bolus_ml, type: String
  field :bolus_mg, type: String
  field :o2_saturation, type: Integer
  field :comments, type: String
  field :name, type: String

  embedded_in :nursing_record, class_name: "::NursingRecord"
end
