class OtherHistory
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :medical_history, type: String
  field :family_history, type: String
  field :specialstatus, type: String

  embedded_in :opd_record, class_name: "::OpdRecord"
  embedded_in :patient, class_name: "::Patient"
end
