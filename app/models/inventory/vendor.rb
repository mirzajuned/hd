# used
class Inventory::Vendor
  include Mongoid::Document
  # include Mongoid::Attributes::Dynamic
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
  field :debit_amount, type: Float, default: 0.0 # amount after returning of item from store to seller
  field :facility_id, type: BSON::ObjectId
  field :vendor_group_id, type: BSON::ObjectId
  field :vendor_group_name, type: String
  field :store_id, type: BSON::ObjectId
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
  field :store_ids, type: Array, default: []
  field :country_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :dl_number, type: String
  field :gst_number, type: String
  field :category_ids, type: Array, default: []
  field :po_expiry_days, type: Integer
  field :is_fitter, type: Boolean, default: false
  field :fitting_charges, type: Integer

  embeds_many :debit_amount_breakups, class_name: '::Inventory::DebitNote'
  has_many :assets, class_name: '::Inventory::Vendor::AssetUpload', inverse_of: :vendor
  has_many :vendor_locations, class_name: '::Inventory::VendorLocation'

  accepts_nested_attributes_for :debit_amount_breakups,
                                reject_if: proc { |attributes| attributes['amount'].to_f == 0 },
                                allow_destroy: true

  belongs_to :vendor_group, optional: true

  # default_scope -> { where(is_deleted: false) } 
  scope :by_store_id, -> (store_id) { where(:store_ids.in => [store_id]) }

end