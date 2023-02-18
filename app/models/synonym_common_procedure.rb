class SynonymCommonProcedure
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :is_deleted, type: Boolean, default: false
  field :is_attached, type: Boolean, default: true
  field :organisation_id, type: String
  field :name, type: String
  field :code, type: String
  field :procedure_type, type: String
  field :region, type: Array
  field :search_procedure_name, type: String
  field :has_laterality, type: Boolean, default: false
  field :is_migrated, type: Boolean, default: true
  field :specialty_id, type: String

  validates_uniqueness_of :name
end
