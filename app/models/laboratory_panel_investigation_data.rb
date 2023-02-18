class LaboratoryPanelInvestigationData
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :investigation_val, type: String
  field :investigation_name, type: String
  field :normal_range, type: String
  field :lonic_code, type: String
  # validates :lonic_code, uniqueness: { scope: :specialty_id }
  has_and_belongs_to_many :laboratory_investigation_datas
end
