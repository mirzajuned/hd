class TaperingSet
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :number_of_days, type: String
  field :start_date, type: Date
  field :end_date, type: Date
  field :start_time, type: Time
  field :end_time, type: Time
  field :frequency, type: String
  field :dosage, type: String

  embedded_in :taperingkit, class_name: "::TaperingKit"
end
