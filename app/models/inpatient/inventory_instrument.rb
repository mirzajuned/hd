class Inpatient::InventoryInstrument
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  embedded_in :ipdrecord, class_name: "::Inpatient::IpdRecord"
end
