class SynonymIcdDiagnosis
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :is_deleted, type: Boolean, default: false
  field :is_attached, type: Boolean, default: true
  field :fullname, type: String
  field :abbrevated_name, type: String
  field :search_icd_name, type: String
  field :code, type: String
  field :icd_type, type: String
  field :organisation_id, type: BSON::ObjectId
  field :children_has_laterality, type: Boolean, default: false
  field :has_children, type: Boolean, default: false
  field :specialty_id, type: String
  field :is_migrated, type: Boolean, default: true

  validates_uniqueness_of :fullname
end
