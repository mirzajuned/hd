class Investigation::Ophthal < Investigation::InvestigationDetail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  # Investigation Details(LAB)
  field :name, type: String
  field :investigation_side, type: String
  field :investigation_id, type: String
  field :investigation_full_code, type: String
  field :is_custom, type: Boolean
end
