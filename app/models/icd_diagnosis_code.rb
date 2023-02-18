class IcdDiagnosisCode
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :specialty_id, type: Integer
  field :template_id, type: Integer
  field :code, type: String
  field :name, type: String
  field :code_position, type: String
  field :tree_node, type: String
  field :tree_level, type: String
  field :tree_location, type: String
  field :has_attributes, type: String
  field :has_laterality, type: String
  field :laterality_position, type: String
end
