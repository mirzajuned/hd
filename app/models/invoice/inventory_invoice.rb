class Invoice::InventoryInvoice < Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  extend SearchType

  field :bill_number, type: String
  field :recipient, type: String
  field :recipient_mobile, type: String
  field :recipient_email, type: String
  field :age, type: Integer
  field :gender, type: String
  field :doctor_name, type: String
  field :doc_reg_no, type: String
  field :patient_id, type: String
  field :patient_identifier, type: String
  field :patient_mrn, type: String
  field :total_item, type: String
  field :department_name, type: String
  field :delivery_date, type: Date
  field :note, type: String
  field :notify, type: Boolean, default: false
  field :notify_type, type: String
  field :notified, type: Boolean, default: false
  field :called, type: Boolean, default: false
  field :sms, type: String
  field :email, type: String
  field :payment_completed, type: Boolean, default: false
  field :advance_taken, type: Boolean, default: false
  field :prescription_id, type: String
  field :comments, type: String
  field :tax_enabled, type: Boolean, default: true
  field :is_deleted, type: Boolean, default: false
  # field :tax_breakup, type: Array, default: []
  # field :non_taxable_amount, type: Float, default: 0.0

  field :order_date, type: Date
  field :order_date_time, type: Time
  field :estimated_delivery_date, type: DateTime
  field :last_estimated_delivery_date, type: DateTime
  field :last_date_change_user, type: String
  field :delivery_date_change_reason, type: String
  field :delivery_date, type: DateTime
  field :delivered_at, type: DateTime
  field :checkout_date, type: DateTime
  field :fitting_required, type: Boolean, default: false
  field :fitter_id, type: BSON::ObjectId
  field :fitter_name, type: String
  field :estimated_ready_date, type: DateTime
  field :payment_completed_date, type: Date

  field :delivered, type: Boolean, default: true
  field :current_status, type: String # "Placed, Fitting, Ready, Delivered"

  field :is_migrated, type: Boolean, default: true

  field :specialty_id, type: String

  field :store_id, type: BSON::ObjectId
  field :department_id, type: String
  field :flag_type, type: String

  field :facility_id, type: BSON::ObjectId
  field :net_amount, type: Float
  field :organisation_id, type: BSON::ObjectId

  field :payment_received, type: Float, default: 0.00
  field :payment_received_breakup, type: Array, default: []

  field :user_id, type: BSON::ObjectId
  field :entered_by, type: String
  field :canceled_by, type: String
  field :is_canceled, type: Boolean, default: false
  field :cancel_date, type: Date
  field :refund_reason, type: String # To store reason while cancelling invoice

  field :search_type, type: String

  field :fresh_booking, type: Boolean # check wheather prescription has been converted on same day or not
  field :home_delivery, type: Boolean, default: false

  field :order_id, type: BSON::ObjectId # this id is for inventory order id

  field :srn_id, type: BSON::ObjectId

  field :requisition_id, type: BSON::ObjectId

  # Customer Id and Table to be added later
  embeds_many :items, class_name: '::Invoice::InventoryItem'
  embeds_many :payment_received_breakups, class_name: '::Invoice::PaymentReceivedBreakup'
  embeds_many :advance_payment_breakups, class_name: '::Invoice::AdvancePaymentBreakup'

  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: :all_blank
  accepts_nested_attributes_for :payment_received_breakups,
                                reject_if: proc { |attributes| attributes['amount'].to_f == 0 || attributes['mode_of_payment'].blank? },
                                allow_destroy: true

  accepts_nested_attributes_for :advance_payment_breakups,
                                reject_if: proc { |attributes| attributes['amount'].to_f == 0 },
                                allow_destroy: true

  has_many :state_transitions, :class_name => 'Invoice::InventoryInvoiceStateTransition'
  # has_many :pending_advance_payments, class_name: 'AdvancePayment',foreign_key: 'invoice_id', inverse_of: :invoice

  # accepts_nested_attributes_for :pending_advance_payments,
  #                               reject_if: proc { |attributes| attributes['amount'].to_f == 0 },
  #                               allow_destroy: true

  # state machine
  state_machine initial: :placed, attribute: :state do
    audit_trail initial: false, context: [
      :department_id, :store_id, :order_date, :delivery_date, :estimated_delivery_date, :estimated_ready_date
    ]

    event :placed_to_delivered do
      transition placed: :delivered
    end
    event :placed_to_fitting do
      transition placed: :fitting
    end
    event :placed_to_ready do
      transition placed: :ready
    end

    event :fitting_to_ready do
      transition fitting: :ready
    end
    event :fitting_to_placed do
      transition fitting: :placed
    end

    event :ready_to_fitting do
      transition ready: :fitting
    end
    event :ready_to_placed do
      transition ready: :placed
    end
    event :ready_to_delivered do
      transition ready: :delivered
    end

    event :delivered_to_ready do
      transition delivered: :ready
    end
    event :delivered_to_placed do
      transition delivered: :placed
    end
  end

  def self.build(*args)
    sale = new
    sale.items.build(*args)
    sale
  end

  before_save do
    self[:delivered_at] = self[:delivery_date].blank? ? self[:estimated_delivery_date] : self[:delivery_date]
  end

  scope :newest_first, -> { order('created_at DESC') }
  scope :ordered_first, -> { order('order_date DESC') }
  scope :checkout_first, -> { order('checkout_date DESC') }
  scope :delivery_first, -> { desc(:delivered_at) }
end
