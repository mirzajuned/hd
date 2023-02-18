class Investigation::Radiology < Investigation::InvestigationDetail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  # Investigation Details(LAB)
  field :name, type: String
  field :has_laterality, type: String
  field :laterality, type: String
  field :is_spine, type: String
  field :loinc_code, type: String
  field :radiology_options, type: String
  field :investigation_id, type: String
  field :investigation_full_code, type: String
  field :is_custom, type: Boolean
end
