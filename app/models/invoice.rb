class Invoice
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  attr_accessor :migration

  field :total, type: Float
  field :tax, type: Float, default: 0.00

  # field :discount, type: Float
  field :additional_discount, type: Float, default: 0.00
  field :services_discount, type: Float, default: 0.00
  field :total_discount, type: Float, default: 0.00
  field :additional_discount_comment, type: String

  field :round, type: Float, default: 0.00
  field :advance_payment, type: Float, default: 0.00
  field :amount_remaining, type: Float, default: 0.00
  field :mode_of_payment, type: String
  field :cash, type: Float
  field :card, type: Float
  field :card_number, type: Integer
  field :comments, type: String
  field :patient_comment, type: String

  field :currency_symbol, type: String
  field :currency_id, type: BSON::ObjectId

  field :invoice_type, type: String, default: 'cash'
  field :contact_group_id, type: String
  field :contact_id, type: String
  field :payer_master_id, type: String
  field :bill_number, type: String
  
  field :canceled_by, type: String
  field :canceled_by_id, type: String
  field :is_canceled, type: Boolean, default: false
  field :cancel_date, type: Date
  field :refund_against_cancel, type: Float, default: 0.00

  field :refund_reason, type: String
  field :refunded_by, type: String
  field :refunded_by_id, type: String
  field :is_refunded, type: Boolean, default: false
  field :refund_date, type: Date
  field :refund_time, type: Time
  field :refund_amount, type: Float, default: 0.00
  
  field :version, type: String, default: 'v21.0'

  field :is_migrated, type: Boolean, default: true

  field :organisation_id, type: BSON::ObjectId

  # Fields for Credit/Full Payment Options
  field :invoice_payment_type, type: String, default: 'Full Payment'
  field :payment_completed, type: Boolean
  field :payment_received, type: Float, default: 0.00
  field :payment_received_breakup, type: Array, default: []
  field :payment_pending, type: Float, default: 0.00
  field :payment_pending_breakup, type: Array, default: []

  field :tax_breakup, type: Array, default: []
  field :tax_enabled, type: Boolean, default: false
  field :non_taxable_amount, type: Float, default: 0.0

  field :specialty_id, type: String
  field :role_id, type: String

  field :department_id, type: String
  field :department_name, type: String

  field :store_id, type: BSON::ObjectId

  field :is_free, type: Boolean, default: false # if billing amount is 0
  field :is_paid, type: Boolean, default: false # if total_discount is 0, and billing amount is > 0
  field :is_free_discounted, type: Boolean, default: false # if billing amount is > 0, but total_discount is 100%
  field :is_paid_discounted, type: Boolean, default: false # if billing amount is > 0, but total_discount > 0 but not 100%

  field :insurer_group_id, type: String
  field :insurer_id, type: String
  field :tpa_name, type: String
  field :tpa_id, type: String
  field :insurance_name, type: String
  field :insurance_id, type: String
  field :corporate_id, type: String
  field :corporate_name, type: String
  field :dispensary_id, type: String
  field :dispensary_name, type: String

  field :is_draft, type: Boolean, default: false
  field :converted_to_final_date, type: Date
  field :converted_to_final_datetime, type: Time
  field :converted_to_final_by, type: BSON::ObjectId
  field :is_deleted, type: Boolean, default: false
  field :deleted_date, type: Date
  field :deleted_datetime, type: Time
  field :deleted_by, type: BSON::ObjectId

  field :amount_received, type: Float, default: 0.00

  field :bkp_bill_number, type: String

  # Offer related fields
  field :offer_on_bill, type: Float, default: 0.00
  field :offer_on_services, type: Float, default: 0.00
  field :total_offer, type: Float, default: 0.00

  field :offer_manager_id, type: BSON::ObjectId
  field :offer_name, type: String
  field :offer_code, type: String
  field :offer_percentage, type: Integer

  field :offer_applied_at, type: BSON::ObjectId # facility
  field :offer_applied_at_name, type: String
  field :offer_applied_by, type: BSON::ObjectId
  field :offer_applied_by_name, type: String
  field :offer_applied_date, type: Date
  field :offer_applied_datetime, type: Time
  field :total_of_all_discount, type: Float, default: 0.00

  field :print_investigations_flag, type: Boolean, default: false
  field :print_diagnosis_flag, type: Boolean, default: false
  field :print_procedures_flag, type: Boolean, default: false

  scope :newest_invoice_first, -> { order('updated_at DESC') }
  
  belongs_to :patient, optional: true, index: { background: true }
  belongs_to :user, optional: true, index: { background: true }
  belongs_to :appointment, optional: true, index: { background: true }
  belongs_to :admission, optional: true,  index: { background: true }
  belongs_to :contact_group, optional: true, index: {background: true}
  belongs_to :payer_master, optional: true, index: {background: true}
  belongs_to  :insurer_group, optional: true, index: {background: true}, class_name: "::ContactGroup"
  belongs_to  :insurer, optional: true, index: {background: true}, class_name: "::PayerMaster"

  has_many :refund_payments, class_name: '::RefundPayment', foreign_key: 'invoice_id'

  embeds_many :patient_payer_data, class_name: '::Finance::PatientPayerData'
  embeds_many :services, class_name: '::Invoice::Service'
  embeds_many :record_histories

  embeds_many :advance_payment_breakups, class_name: '::Invoice::AdvancePaymentBreakup'
  embeds_many :payment_received_breakups, class_name: '::Invoice::PaymentReceivedBreakup'
  embeds_many :payment_pending_breakups, class_name: '::Invoice::PaymentPendingBreakup'

  embeds_many :sequences, class_name: '::Invoice::Sequence'

  accepts_nested_attributes_for :patient_payer_data,
                                reject_if: proc { |attributes| attributes['text_value'].blank? },
                                allow_destroy: true

  accepts_nested_attributes_for :advance_payment_breakups,
                                reject_if: proc { |attributes| attributes['amount'].to_f == 0 },
                                allow_destroy: true
  accepts_nested_attributes_for :payment_received_breakups,
                                reject_if: proc { |attributes| attributes['amount'].to_f < 0 },
                                allow_destroy: true
  accepts_nested_attributes_for :payment_pending_breakups,
                                reject_if: proc { |attributes| attributes['amount'].to_f == 0 },
                                allow_destroy: true

  accepts_nested_attributes_for :sequences
  accepts_nested_attributes_for :services

  resourcify
  include Authority::Abilities

  # validates :mode_of_payment, presence: { message: 'Mode of payment cannot be blank' }
  validates :total, presence: true
  # validates :tax, presence: true

  before_save :set_payment_completed, :set_payment_received_pending, :set_tax_breakup, :update_total_discount, :set_bill_type, :set_amount_received

  after_save :save_payment_received_pending_model, unless: :migration

  def set_tax_breakup
    self.tax_breakup ||= []
  end

  def set_payment_received_pending
    self.payment_received_breakup ||= []
    self.payment_pending_breakup ||= []
  end

  def set_payment_completed
    self.payment_completed = (payment_pending.to_i == 0) if _type != 'Invoice::Inventories::Department::OpticalInvoice'
  end

  def save_payment_received_pending_model
    PaymentReceivedPendingJob.perform_later(id.to_s)
  end

  def update_total_discount
    self.total_discount = additional_discount.to_f + services_discount.to_f
    services = self.services.select{|s| s['discount_amount'] <= 0 && s['discount_reason'] != ''}
    services.map{|s| s['discount_reason'] = ''}
    self.total_of_all_discount = total_offer.to_f + total_discount.to_f
  end

  def set_bill_type
    if self.try(:net_amount).present? && self.try(:total_discount).present?
      if self.net_amount.to_f > 0 && self.total_discount.to_f > 0
        self.is_paid_discounted = true
      elsif self.net_amount.to_f == 0  && self.total_discount.to_f > 0
        self.is_free_discounted = true
      elsif self.net_amount.to_f > 0 && self.total_discount.to_f == 0
        self.is_paid = true
      else
        self.is_free = true
      end
    end
  end

  def set_amount_received
    self.amount_received = self.payment_received_breakups.pluck(:amount_received).reject{|i| i.nil?}.inject(0, :+)
  end

  def final_received_amount
    self.amount_received.to_f + self.advance_payment.to_f
  end

  def invoice_department_type
    self._type.split('::')[1].to_s&.underscore&.downcase
  end

end

# db.invoices.createIndex({"created_at": 1, "organisation_id": 1, "services.price": 1, "is_migrated": 1 });
# db.invoices.createIndex({"created_at": 1, "organisation_id": 1, "services": 1, "is_migrated": 1 });
# db.invoices.createIndex({"created_at": 1, "organisation_id": 1 });
# db.invoices.createIndex({"updated_at": 1, "organisation_id": 1 });
