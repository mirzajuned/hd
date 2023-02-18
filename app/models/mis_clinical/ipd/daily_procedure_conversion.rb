class MisClinical::Ipd::DailyProcedureConversion
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :procedure_date, type: Date
  field :procedure_id, type: String
  field :procedure_name, type: String
  field :advised, type: Integer
  field :performed, type: Integer
  field :performed_from_advised, type: Integer

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :is_migrated, type: Boolean, default: true
end
