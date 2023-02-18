class PatientVital
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :temperature, type: String
  field :pulse, type: String
  field :height, type: String
  field :weight, type: String
  field :blood_pressure, type: String
  field :respiratory_rate, type: String
  field :vital_comment, type: String
  field :vital_trail, type: Hash, default: {}
  field :bmi, type: Float
  field :spo2, type: Integer

  embedded_in :patient, class_name: "::Patient"
end
