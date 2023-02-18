class MisClinical::Opd::OpdClinicalUserwise
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :user_display_fields, type: Hash
  field :patient_display_fields, type: Hash
  field :filtering_fields, type: Hash
  field :search_fields, type: Hash
  field :custom_fields, type: Hash
  field :organisation_id, type: String
  field :facility_id, type: String
  field :is_migrated, type: Boolean, default: true
end
