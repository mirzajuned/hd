class Inventory::TaxInvoice
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  extend Enumerize

  field :type, type: String
  field :created_on, type: Time
  field :transaction_display_id, type: String # system generated
  field :transaction_date, type: Date
  field :transaction_date_time, type: Time
  field :note, type: String
  field :gst_type, type: String

  field :created_by, type: String
  field :created_by_id, type: BSON::ObjectId

  field :cancelled_by_id, type: BSON::ObjectId
  field :cancelled_by_name, type: String
  field :cancelled_on, type: DateTime
  field :cancelled_reason, type: String

  field :approved_by_id, type: BSON::ObjectId
  field :approved_by_name, type: String
  field :approved_on, type: DateTime
  field :status, type: Integer

  field :is_active, type: Boolean, default: true

  field :transfer_ids, type: Array, default: []

  field :created_against_store_id, type: BSON::ObjectId # Tax invoice created against which store
  field :store_id, type: BSON::ObjectId # Store from where invoice is getting created

  # dispatch details
  field :transportation_mode, type: String
  field :transportation_mode_name, type: BSON::ObjectId
  field :delivery_date, type: Date
  field :dispatch_remarks, type: String
  field :transportation_transaction_id, type: String # ID which user enter

  field :taxable_amount, type: Float
  field :tax_amount, type: Float
  field :total_amount, type: Float
  field :tax_breakup, type: Array, default: []

  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :tax_type, type: String

  enumerize :status, in: { open: 0, approved: 1, cancelled: 2, completed: 3 }, default: :open, predicates: true

  validates :transaction_display_id, presence: true
  validates :transfer_ids, presence: true
  validates :total_amount, presence: true
  validates :type, presence: true
  validates :created_against_store_id, presence: true

  [:cancelled, :approved].each do |method|
    define_method "set_#{method}" do |user,reason|
      self.update(status: method, "#{method}_by_id": user.id,
        "#{method}_by_name": user.fullname, "#{method}_on": DateTime.now, "#{method}_reason": reason )
    end
  end
end
