class Invoice::InventoryOrder
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  extend SearchType
  extend Enumerize

  field :order_number, type: String
  field :bkp_order_number, type: String
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
  field :advance_taken, type: Boolean, default: false
  field :prescription_id, type: String
  field :comments, type: String
  field :is_deleted, type: Boolean, default: false

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

  field :delivered, type: Boolean, default: false
  field :current_status, type: String # "Placed, Fitting, Ready, Delivered"

  field :cancelled_by_id, type: BSON::ObjectId
  field :cancelled_by_name, type: String
  field :cancelled_on, type: DateTime
  field :approved_by_id, type: BSON::ObjectId
  field :approved_by_name, type: String
  field :approved_on, type: DateTime
  field :status, type: Integer
  field :cancelled_reason, type: String
  field :approved_reason, type: String

  field :is_migrated, type: Boolean, default: true

  field :flag_type, type: String

  field :facility_id, type: BSON::ObjectId
  field :net_amount, type: Float
  field :organisation_id, type: BSON::ObjectId

  field :user_id, type: BSON::ObjectId
  field :entered_by, type: String
  field :canceled_by, type: String
  field :canceled_by_id, type: String
  field :is_canceled, type: Boolean, default: false
  field :cancel_date, type: Date
  field :refund_against_cancel, type: Float, default: 0.00

  field :search_type, type: String

  field :fresh_booking, type: Boolean # check wheather prescription has been converted on same day or not
  field :home_delivery, type: Boolean, default: false

  # field taken from invoice.rb
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

  field :refund_reason, type: String
  field :refunded_by, type: String
  field :refunded_by_id, type: String
  field :is_refunded, type: Boolean, default: false
  field :refund_date, type: Date
  field :refund_time, type: Time
  field :refund_amount, type: Float, default: 0.00
  
  field :version, type: String, default: 'v21.0'

  field :is_migrated, type: Boolean, default: true

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

  field :is_draft, type: Boolean, default: false
  field :converted_to_final_date, type: Date
  field :converted_to_final_datetime, type: Time
  field :converted_to_final_by, type: BSON::ObjectId
  field :is_deleted, type: Boolean, default: false
  field :deleted_date, type: Date
  field :deleted_datetime, type: Time
  field :deleted_by, type: BSON::ObjectId

  field :amount_received, type: Float, default: 0.00
  field :created_from_migration, type: Boolean, default: false

  field :is_invoice_created, type: Boolean, default: false
  field :invoice_created_on, type: Time
  field :invoice_created_by, type: BSON::ObjectId
  field :invoice_id, type: BSON::ObjectId
  field :is_invoice_cancelled, type: Boolean, default: false
  field :invoice_cancelled_on, type: Time

  # fields for SRN
  field :srn_pending, type: Boolean, default: false
  field :srn_required, type: Boolean, default: false
  field :srn_status, type: String # pending, completed
  field :srn_id, type: BSON::ObjectId
  field :srn_created, type: Boolean, default: false
  field :srn_created_by_id, type: BSON::ObjectId

  # fiels for requisition
  field :requisition_required, type: Boolean, default: false
  field :requisition_pending, type: Boolean, default: false
  field :requisition_id, type: BSON::ObjectId
  field :requisition_created_at, type: Time
  field :requisition_order_created_by_id, type: BSON::ObjectId

  # fields for optical order
  field :optical_order_id, type: BSON::ObjectId

  # fields related to prescription
  field :r_glassesprescriptions_distant_sph, type: String
  field :r_glassesprescriptions_distant_cyl, type: String
  field :r_glassesprescriptions_distant_axis, type: String
  field :r_glassesprescriptions_distant_vision, type: String
  field :r_glassesprescriptions_add_sph, type: String
  field :r_glassesprescriptions_add_cyl, type: String
  field :r_glassesprescriptions_add_axis, type: String
  field :r_glassesprescriptions_add_vision, type: String
  field :r_glassesprescriptions_near_sph, type: String
  field :r_glassesprescriptions_near_cyl, type: String
  field :r_glassesprescriptions_near_axis, type: String
  field :r_glassesprescriptions_near_vision, type: String
  field :l_glassesprescriptions_distant_sph, type: String
  field :l_glassesprescriptions_distant_cyl, type: String
  field :l_glassesprescriptions_distant_axis, type: String
  field :l_glassesprescriptions_distant_vision, type: String
  field :l_glassesprescriptions_add_sph, type: String
  field :l_glassesprescriptions_add_cyl, type: String
  field :l_glassesprescriptions_add_axis, type: String
  field :l_glassesprescriptions_add_vision, type: String
  field :l_glassesprescriptions_near_sph, type: String
  field :l_glassesprescriptions_near_cyl, type: String
  field :l_glassesprescriptions_near_axis, type: String
  field :l_glassesprescriptions_near_vision, type: String
  field :r_glassesprescriptions_dia, type: String
  field :l_glassesprescriptions_dia, type: String
  field :r_glassesprescriptions_size, type: String
  field :l_glassesprescriptions_size, type: String
  field :r_glassesprescriptions_fittingheight, type: String
  field :l_glassesprescriptions_fittingheight, type: String
  field :r_glassesprescriptions_prismbase, type: String
  field :l_glassesprescriptions_prismbase, type: String
  field :r_glassesprescriptions_typeoflens, type: String
  field :r_glassesprescriptions_ipd, type: String
  field :l_glassesprescriptions_typeoflens, type: String
  field :l_glassesprescriptions_lensmaterial, type: String
  field :r_glassesprescriptions_lensmaterial, type: String
  field :l_glassesprescriptions_framematerial, type: String
  field :r_glassesprescriptions_framematerial, type: String
  field :r_glassesprescriptions_lenstint, type: String
  field :l_glassesprescriptions_lenstint, type: String
  field :l_glassesprescriptions_ipd, type: String
  field :r_glassesprescriptions_distance_pd, type: String
  field :r_glassesprescriptions_near_pd, type: String
  field :l_glassesprescriptions_distance_pd, type: String
  field :l_glassesprescriptions_near_pd, type: String
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
  field :is_create_gst_bill, type: Boolean, default: false
  field :gstin, type: String
  field :legal_name, type: String

  field :vendor_id, type: BSON::ObjectId

  scope :newest_invoice_first, -> { order('updated_at DESC') }

  enumerize :status,
            in: { open: 0, approved: 1, cancelled: 2, inprocess: 3, completed: 4 },
            default: :open, predicates: true, scope: :having_status
  
  belongs_to :patient, optional: true, index: { background: true }
  belongs_to :user, optional: true, index: { background: true }
  belongs_to :appointment, optional: true, index: { background: true }
  belongs_to :admission, optional: true,  index: { background: true }
  belongs_to :contact_group, optional: true, index: {background: true}
  belongs_to :payer_master, optional: true, index: {background: true}
  belongs_to  :insurer_group, optional: true, index: {background: true}, class_name: "::ContactGroup"
  belongs_to  :insurer, optional: true, index: {background: true}, class_name: "::PayerMaster"

  has_many :refund_payments, class_name: '::RefundPayment', foreign_key: 'order_id'

  embeds_many :services, class_name: '::Invoice::Service'
  embeds_many :sequences, class_name: '::Invoice::Sequence'
  # embeds_many :record_histories

  embeds_many :advance_payment_breakups, class_name: '::Invoice::AdvancePaymentBreakup'
  embeds_many :payment_received_breakups, class_name: '::Invoice::PaymentReceivedBreakup'
  embeds_many :payment_pending_breakups, class_name: '::Invoice::PaymentPendingBreakup'

  accepts_nested_attributes_for :advance_payment_breakups,
                                reject_if: proc { |attributes| attributes['amount'].to_f == 0 },
                                allow_destroy: true
  accepts_nested_attributes_for :payment_received_breakups,
                                reject_if: proc { |attributes| attributes['amount'].to_f == 0 || attributes['mode_of_payment'].blank? },
                                allow_destroy: true
  accepts_nested_attributes_for :payment_pending_breakups,
                                reject_if: proc { |attributes| attributes['amount'].to_f == 0 },
                                allow_destroy: true

  accepts_nested_attributes_for :services
  accepts_nested_attributes_for :sequences
  resourcify
  include Authority::Abilities

  # validates :mode_of_payment, presence: { message: 'Mode of payment cannot be blank' }
  validates :total, presence: true
  # validates :tax, presence: true

  before_save :set_payment_completed, :set_payment_received_pending, :set_tax_breakup, :update_total_discount, :set_order_type, :set_amount_received
  after_create :checked_glassesprescriptions_present
  # after_save :save_payment_received_pending_model, unless: :migration

  def set_tax_breakup
    self.tax_breakup ||= []
  end

  def set_payment_received_pending
    self.payment_received_breakup ||= []
    self.payment_pending_breakup ||= []
  end

  def set_payment_completed
    self.payment_completed = (payment_pending.to_i == 0)
  end

  def save_payment_received_pending_model
    # PaymentReceivedPendingJob.perform_later(id.to_s)
  end

  def update_total_discount
    self.total_discount = additional_discount.to_f + services_discount.to_f
    services = self.services.select{|s| s['discount_amount'] <= 0 && s['discount_reason'] != ''}
    services.map{|s| s['discount_reason'] = ''}
  end

  def set_order_type
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


  # Customer Id and Table to be added later
  embeds_many :items, class_name: '::Invoice::InventoryItem'

  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: :all_blank

  has_many :state_transitions, :class_name => '::Invoice::InventoryOrderStateTransition', foreign_key: :order_id
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

  validates_presence_of :bkp_order_number, message: 'Order Number cannot be blank.'
  # validates_presence_of :order_number, message: 'Order Number cannot be blank.'

  [:cancelled, :approved].each do |method|
    define_method "set_#{method}" do |user, reason|
      self.update( status: method, "#{method}_by_id": user.id, "#{method}_reason": reason,
        "#{method}_by_name": user.fullname, "#{method}_on": DateTime.now )
    end
  end

  def checked_glassesprescriptions_present
    if r_glassesprescriptions_distant_sph.present? ||
      r_glassesprescriptions_distant_cyl.present? ||
      r_glassesprescriptions_distant_axis.present? ||
      r_glassesprescriptions_distant_vision.present? ||
      r_glassesprescriptions_add_sph.present? ||
      r_glassesprescriptions_add_cyl.present? ||
      r_glassesprescriptions_add_axis.present? ||
      r_glassesprescriptions_add_vision.present? ||
      r_glassesprescriptions_near_sph.present? ||
      r_glassesprescriptions_near_cyl.present? ||
      r_glassesprescriptions_near_axis.present? ||
      r_glassesprescriptions_near_vision.present? ||
      l_glassesprescriptions_distant_sph.present? ||
      l_glassesprescriptions_distant_cyl.present? ||
      l_glassesprescriptions_distant_axis.present? ||
      l_glassesprescriptions_distant_vision.present? ||
      l_glassesprescriptions_add_sph.present? ||
      l_glassesprescriptions_add_cyl.present? ||
      l_glassesprescriptions_add_axis.present? ||
      l_glassesprescriptions_add_vision.present? ||
      l_glassesprescriptions_near_sph.present? ||
      l_glassesprescriptions_near_cyl.present? ||
      l_glassesprescriptions_near_axis.present? ||
      l_glassesprescriptions_near_vision.present?
      CommunicationNotificationJob.perform_now('optical_glass_prescription_advised_patient', self.id.to_s, self.class.to_s)
      CommunicationNotificationJob.perform_now('optical_glass_prescription_advised_store', self.id.to_s, self.class.to_s)
    end
  end
end
