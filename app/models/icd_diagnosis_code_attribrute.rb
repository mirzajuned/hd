class IcdDiagnosisCodeAttribrute
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :specialty_id, type: Integer
  field :template_id, type: Integer
  field :code, type: String
  field :computed_attribute_code, type: String
  field :attribute_code_position, type: String
  field :attribute_display_label, type: String
  field :attribute_display_value, type: String
  field :attribute_code, type: String
  field :is_custom, type: String
  field :is_laterality, type: String
  field :is_preselected, type: String
  field :is_displayed, type: String
end
