class Inpatient::InventoryMedication
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :quantity, type: String
  field :used, type: String
  field :remaining, type: String

  embedded_in :ipdrecord, class_name: "::Inpatient::IpdRecord"
end
