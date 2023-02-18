# used
class Inventory::Fitter
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :email, type: String
  field :company_name, type: String
  field :mobile_number, type: Integer
  field :secondary_mobile_number, type: Integer

  field :address, type: String
  field :city, type: String
  field :state, type: String
  field :pincode, type: Integer
  field :district, type: String
  field :commune, type: String

  field :is_deleted, type: Boolean, default: false
  field :facility_id, type: BSON::ObjectId
  field :store_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :is_disable, type: Boolean, default: false
  field :vendor_id, type: BSON::ObjectId
  field :store_ids, type: Array, default: []
end
