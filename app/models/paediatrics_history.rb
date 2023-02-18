class PaediatricsHistory
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :antenatal_maternal_vaccination, type: String
  field :antenatal_maternal_infection, type: String
  field :natal_history_normal, type: Boolean
  field :natal_history_forceps, type: Boolean
  field :natal_history_caesarean, type: Boolean
  field :natal_birth_weight, type: String
  field :post_natal_history, type: String
  field :ho_vaccination, type: String
  field :developmental_history, type: String

  embedded_in :opd_record, class_name: "::OpdRecord"
  embedded_in :patient, class_name: "::Patient"
end
