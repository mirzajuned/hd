class CustomCommonProcedure
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :procedure_type, type: String, default: 'CustomCommonProcedure'
  field :is_deleted, type: Boolean, default: false
  field :is_attached, type: Boolean, default: false
  field :is_migrated, type: Boolean, default: true
  field :is_uploaded, type: Boolean, default: false
  field :region, type: Array
  field :organisation_id, type: String
  field :facility_id, type: String
  field :name, type: String
  field :display_name, type: String
  field :code, type: String
  field :level, type: String, default: 'organisation'

  field :has_laterality, type: Boolean, default: false
  field :laterality, type: Array

  field :speciality_id, type: String
  field :speciality_name, type: String
end
