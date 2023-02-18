class Finance::PatientPayerData
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic


  field :patient_payer_data_master_id, type: String
  field :name, type: String
  field :text_value, type: String
  field :list_value, type: Array, default: []

  embedded_in :invoice, class_name: '::Invoice'
  embedded_in :patient, class_name: '::Patient'
end
