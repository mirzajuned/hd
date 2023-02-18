class Finance::TpaMaster::CorporateDetail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing


  field :insurance_master_id, type: String
  field :insurance_master_name, type: String

  field :corporate_master_id, type: String
  field :corporate_master_name, type: String

  embedded_in :tpa_master, class_name: '::Finance::TpaMaster'
end