class Invoice::Ipd < Invoice
  field :facility_id, type: String
  field :net_amount, type: Float
  field :organisation_id, type: BSON::ObjectId
  field :bill_of_material_breakup, type: Boolean, default: false
end
