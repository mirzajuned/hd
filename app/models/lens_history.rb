class LensHistory
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :lens_history_comment, type: String
  field :profession, type: String
  field :lens_needed, type: String
  field :present_wearing_hour, type: String
  field :complaint_with_existing_lens, type: String
  field :hour_of_using_lens, type: String
  field :brand, type: String
  field :brand_duration, type: String
  field :brand_duration_unit, type: String
  field :comfort_level_time, type: String
  field :lens_weraing_duration, type: String
  field :lens_weraing_duration_unit, type: String

  embedded_in :opd_record, class_name: "::OpdRecord"
  embedded_in :patient, class_name: "::Patient"
end
