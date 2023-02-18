class Invoice::Opd::Opthal < Invoice
  include Mongoid::Document

  field :facility_id, type: String
  field :opdrecord_id, type: String
  field :display_id, type: String
end
