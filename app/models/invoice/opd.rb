class Invoice::Opd < Invoice
  field :consultant_user_id, type: String
  field :service_type, type: String  #consultation
  field :facility_id, type: String
  field :net_amount, type: Float
  field :organisation_id, type: BSON::ObjectId
end
