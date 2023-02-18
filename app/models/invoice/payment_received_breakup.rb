class Invoice::PaymentReceivedBreakup
  include Mongoid::Document
  include Mongoid::Timestamps

  field :amount, type: Float
  field :date, type: Date
  field :time, type: Time
  field :received_by, type: BSON::ObjectId
  field :received_from, type: BSON::ObjectId
  field :mode_of_payment, type: String
  field :cash, type: Float
  field :card, type: Float
  field :card_number, type: Integer
  field :card_transaction_note, type: String
  field :paytm_transaction_id, type: String
  field :paytm_transaction_note, type: String
  field :gpay_transaction_id, type: String
  field :gpay_transaction_note, type: String
  field :phonepe_transaction_id, type: String
  field :phonepe_transaction_note, type: String
  field :transfer_date, type: String # for Online transfer
  field :transfer_note, type: String # for Online transfer
  field :cheque_date, type: String
  field :cheque_note, type: String
  field :other_transaction_id, type: String
  field :other_note, type: String
  field :is_settled, type: Boolean, default: false
  field :receipt_id, type: String
  field :currency_id, type: BSON::ObjectId
  field :currency_symbol, type: String

  # fields added HEAL-4346
  field :amount_received, type: Float, default: 0
  field :has_tax_deducted, type: Boolean, default: false
  field :tax_deducted, type: Float, default: 0
  field :has_payer_difference, type: Boolean, default: false
  field :payer_difference, type: Float, default: 0
  field :has_other_revenue_spilage, type: Boolean, default: false
  field :other_revenue_spilage, type: Float, default: 0
  field :internal_comment, type: String

  before_save :set_extra_payments, :set_amount

  embedded_in :invoice
  embedded_in :finance_report_data, class_name: '::Finance::ReportData'

  def set_extra_payments
    unless self.try(:has_tax_deducted).present?
      self.tax_deducted = 0
    end
    unless self.try(:has_payer_difference).present?
      self.payer_difference = 0
    end
    unless self.try(:has_other_revenue_spilage).present?
      self.other_revenue_spilage = 0
    end
    if self.tax_deducted == 0 && self.payer_difference == 0 && self.other_revenue_spilage == 0
      self.internal_comment = ''
    end
  end

  def set_amount
    # self.amount = self.amount_received.to_f + self.tax_deducted.to_f + self.payer_difference.to_f + self.other_revenue_spilage.to_f
  end

  def payer_master
    PayerMaster.find_by(id: received_from)
  end

  def self.any_payer_master?
    all.detect { |breakup| breakup.payer_master.present? }.blank?
  end
end
