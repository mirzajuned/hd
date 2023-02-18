class MisClinical::Opd::InvestigationConversion
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :investigation_date, type: Date
  field :investigation_type, type: String
  field :user_name, type: String #adviced by user name
  field :user_id, type: String #adviced by user id
  field :user_role_ids, type: Array #adviced by user role
  field :user_role_names, type: Array #adviced by user role name
  field :total_advised, type: Integer
  field :total_performed, type: Integer
  field :performed_from_advised, type: Integer
  field :conversion_time_days_avg, type: Integer

  field :conversion_time_days_total, type: Integer
  field :time_performed_from_advised, type: Integer

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :is_migrated, type: Boolean, default: true

  # segregating performed by information
  field :total_performed_by_self, type: Integer #adviced and performed by self
  field :time_performed_by_self, type: Integer

  field :total_performed_by_other, type: Integer #adviced by self, performed by other
  field :time_performed_by_other, type: Integer
end
