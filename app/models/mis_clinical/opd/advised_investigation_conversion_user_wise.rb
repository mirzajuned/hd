class MisClinical::Opd::AdvisedInvestigationConversionUserWise
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :advised_at, type: Date
  field :user_id, type: BSON::ObjectId #only doctors
  field :user_name, type: String
  field :total_advised, type: Integer
  field :total_performed, type: Integer 
  field :facility_id, type: BSON::ObjectId
  field :is_migrated, type: Boolean, default: true
end