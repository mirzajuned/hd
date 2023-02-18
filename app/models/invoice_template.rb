class InvoiceTemplate
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :total, type: Float, default: 0

  field :version, type: String, default: 'v21.0'
  field :is_migrated, type: Boolean, default: true
  field :is_active, type: Boolean, default: true

  field :template_details, type: String

  field :contact_id, type: String
  field :payer_master_id, type: String
  field :specialty_id, type: String
  field :department_id, type: String

  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
end
