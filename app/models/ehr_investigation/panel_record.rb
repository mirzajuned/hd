class EhrInvestigation::PanelRecord
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :investigation_name, type: String
  field :investigation_val, type: String
  field :normal_range, type: String
  field :loinc_code, type: String

  embedded_in :laboratory_investigation, class_name: "::LaboratoryInvestigation"
  embedded_in :record, class_name: "::EhrInvestigation::Record"
end
