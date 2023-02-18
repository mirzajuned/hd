class MisClinical::Opd::DailyInvestigationConversion
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :investigation_date, type: Date
  field :investigation_id, type: BSON::ObjectId
  field :investigation_type, type: String
  field :investigation_name, type: String
  field :investigation_specialization, type: String
  field :total_advised, type: Integer
  field :total_performed, type: Integer  
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :is_migrated, type: Boolean, default: true
end
