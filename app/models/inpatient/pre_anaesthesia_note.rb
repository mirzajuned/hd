class Inpatient::PreAnaesthesiaNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :surgery_date, type: Date

  embeds_many :record_histories
  accepts_nested_attributes_for :record_histories, class_name: "::RecordHistory"
end
