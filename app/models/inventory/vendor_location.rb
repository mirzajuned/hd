class Inventory::VendorLocation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :vendor_id, type: BSON::ObjectId
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
  field :debit_amount, type: Float, default: 0.0 # amount after returning of item from store to seller
  field :facility_id, type: BSON::ObjectId
  field :contact_person, type: String
  field :pan_number, type: String
  field :cin_number, type: String
  field :msme_number, type: String
  field :account_holder_name, type: String
  field :account_number, type: String
  field :ifsc_code, type: String
  field :branch_name, type: String
  field :credit_days, type: Integer
  field :credit_limit, type: Integer
  field :country_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :dl_number, type: String
  field :gst_number, type: String
  field :po_expiry_days, type: Integer

  belongs_to :vendor, class_name: '::Inventory::Vendor', optional: true
end