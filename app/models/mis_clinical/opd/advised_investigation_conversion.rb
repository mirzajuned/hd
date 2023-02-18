class MisClinical::Opd::AdvisedInvestigationConversion
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :advised_at, type: Date
  field :investigation_type, type: String
  field :total_advised, type: Integer
  field :total_performed, type: Integer 
  field :average_conversion_days, type: Float 
  field :facility_id, type: BSON::ObjectId
  field :is_migrated, type: Boolean, default: true
end
