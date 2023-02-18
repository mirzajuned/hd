class Inventory::Transaction::PurchaseBill
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  extend Enumerize

  field :transaction_date, type: Date
  field :transaction_time, type: Time
  field :invoice_number, type: String
  field :invoice_date, type: Date
  field :invoice_date_time, type: Time
  field :purchase_bill_display_id, type: String
  field :note, type: String

  field :is_deleted, type: Boolean, default: false

  field :department_id, type: String
  field :department_name, type: String

  field :total_cost, type: Float
  field :discount, type: Float
  field :net_amount, type: Float
  field :create_against, type: String

  field :tax_breakup, type: Array, default: []
  field :purchase_taxable_amount, type: Float
  field :tax_amount, type: Float

  field :user_id, type: BSON::ObjectId
  field :store_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :created_by, type: String
  field :created_by_id, type: BSON::ObjectId

  field :cancelled_by_id, type: BSON::ObjectId
  field :cancelled_by_name, type: String
  field :cancelled_on, type: DateTime
  field :cancelled_reason, type: String

  field :approved_by_id, type: BSON::ObjectId
  field :approved_by_name, type: String
  field :approved_on, type: DateTime  

  field :status, type: Integer #enum
  field :vendor_gst_number, type: String

  field :purchase_transaction_ids, type: Array, default: []
  field :total_other_charges_amount, type: Float
  field :amt_before_tax, type: Float
  field :gst_type, type: String
  field :tax_type, type: String

  field :vendor_id, type: BSON::ObjectId
  field :vendor_name, type: String
  field :vendor_address, type: String
  field :vendor_location_id, type: BSON::ObjectId
  field :vendor_location_name, type: String
  field :vendor_location_address, type: String
  field :vendor_gst_number, type: String
  field :vendor_location_email, type: String
  field :vendor_location_mobile, type: String
  field :store_gst_number, type: String

  enumerize :status, in: { open: 0, approved: 1, cancelled: 2, completed: 3 }, default: :open, predicates: true
  # enumerize :create_against, in: { grn_with_bill_no: 0, grn_with_challan_no: 1}, predicates: { prefix: true }

  belongs_to :store, class_name: '::Inventory::Store', optional: true
  belongs_to :vendor, class_name: '::Inventory::Vendor', optional: true
  belongs_to :cancelled_by, class_name: '::User', optional: true, foreign_key: :cancelled_by_id
  belongs_to :approved_by, class_name: '::User', optional: true, foreign_key: :approved_by_id

  has_many :purchase_bill_assets, class_name: "::Inventory::Transaction::PurchaseBillAssetUpload", inverse_of: :purchase_bill

  validates :invoice_number, :invoice_date, presence: true
  [:cancelled, :approved].each do |method|
    define_method "set_#{method}" do |user, reason|
      self.update( status: method, "#{method}_by_id": user.id,
        "#{method}_by_name": user.fullname, "#{method}_on": DateTime.now, "#{method}_reason": reason )
    end
  end
end