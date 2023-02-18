class Finance::StatisticCollectionTransactionData
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing
  field :organisation_id, type: String
  field :facility_id, type: String
  field :facility_name, type: String
  field :facility_country_id, type: String
  field :user_id, type: String
  field :user_name, type: String
  field :department_id, type: String
  field :department_name, type: String
  field :department_order, type: Integer
  field :receipt_date, type: Date

  field :advance_receipts_count, type: Integer
  field :advance_receipts_amount, type: Float
  field :advance_info, type: Array
  # advnace receipts payment breakup
  field :advance_receipts_cash_count, type: Integer, default: 0
  field :advance_receipts_card_count, type: Integer, default: 0
  field :advance_receipts_paytm_count, type: Integer, default: 0
  field :advance_receipts_google_pay_count, type: Integer, default: 0
  field :advance_receipts_phonepe_count, type: Integer, default: 0
  field :advance_receipts_online_transfer_count, type: Integer, default: 0
  field :advance_receipts_cheque_count, type: Integer, default: 0
  field :advance_receipts_others_count, type: Integer, default: 0

  field :advance_receipts_cash, type: Float, default: 0.0
  field :advance_receipts_card, type: Float, default: 0.0
  field :advance_receipts_paytm, type: Float, default: 0.0
  field :advance_receipts_google_pay, type: Float, default: 0.0
  field :advance_receipts_phonepe, type: Float, default: 0.0
  field :advance_receipts_online_transfer, type: Float, default: 0.0
  field :advance_receipts_cheque, type: Float, default: 0.0
  field :advance_receipts_others, type: Float, default: 0.0
  # EOF advnace receipts payment breakup

  field :refund_advance_count, type: Integer
  field :refund_advance_amount, type: Float
  field :refund_advance_info, type: Array
  # refund advnace receipts payment breakup
  field :refund_advance_receipts_cash_count, type: Integer, default: 0
  field :refund_advance_receipts_card_count, type: Integer, default: 0
  field :refund_advance_receipts_paytm_count, type: Integer, default: 0
  field :refund_advance_receipts_google_pay_count, type: Integer, default: 0
  field :refund_advance_receipts_phonepe_count, type: Integer, default: 0
  field :refund_advance_receipts_online_transfer_count, type: Integer, default: 0
  field :refund_advance_receipts_cheque_count, type: Integer, default: 0
  field :refund_advance_receipts_others_count, type: Integer, default: 0

  field :refund_advance_receipts_cash, type: Float, default: 0.0
  field :refund_advance_receipts_card, type: Float, default: 0.0
  field :refund_advance_receipts_paytm, type: Float, default: 0.0
  field :refund_advance_receipts_google_pay, type: Float, default: 0.0
  field :refund_advance_receipts_phonepe, type: Float, default: 0.0
  field :refund_advance_receipts_online_transfer, type: Float, default: 0.0
  field :refund_advance_receipts_cheque, type: Float, default: 0.0
  field :refund_advance_receipts_others, type: Float, default: 0.0
  # EOF refund advnace receipts payment breakup

  field :cash_bills_count, type: Integer
  field :cash_bills_amount, type: Float
  field :cash_bills_info, type: Array
  # cash bills payment breakup
  field :cash_bills_cash_count, type: Integer, default: 0
  field :cash_bills_card_count, type: Integer, default: 0
  field :cash_bills_paytm_count, type: Integer, default: 0
  field :cash_bills_google_pay_count, type: Integer, default: 0
  field :cash_bills_phonepe_count, type: Integer, default: 0
  field :cash_bills_online_transfer_count, type: Integer, default: 0
  field :cash_bills_cheque_count, type: Integer, default: 0
  field :cash_bills_others_count, type: Integer, default: 0

  field :cash_bills_cash, type: Float, default: 0.0
  field :cash_bills_card, type: Float, default: 0.0
  field :cash_bills_paytm, type: Float, default: 0.0
  field :cash_bills_google_pay, type: Float, default: 0.0
  field :cash_bills_phonepe, type: Float, default: 0.0
  field :cash_bills_online_transfer, type: Float, default: 0.0
  field :cash_bills_cheque, type: Float, default: 0.0
  field :cash_bills_others, type: Float, default: 0.0
  # EOF cash bills payment breakup
  field :cash_refund_bills_count, type: Integer
  field :cash_refund_bills_amount, type: Float
  field :cash_refund_bills_info, type: Array
  # cash refund bills payment breakup
  field :cash_refund_bills_cash_count, type: Integer, default: 0
  field :cash_refund_bills_card_count, type: Integer, default: 0
  field :cash_refund_bills_paytm_count, type: Integer, default: 0
  field :cash_refund_bills_google_pay_count, type: Integer, default: 0
  field :cash_refund_bills_phonepe_count, type: Integer, default: 0
  field :cash_refund_bills_online_transfer_count, type: Integer, default: 0
  field :cash_refund_bills_cheque_count, type: Integer, default: 0
  field :cash_refund_bills_others_count, type: Integer, default: 0

  field :cash_refund_bills_cash, type: Float, default: 0.0
  field :cash_refund_bills_card, type: Float, default: 0.0
  field :cash_refund_bills_paytm, type: Float, default: 0.0
  field :cash_refund_bills_google_pay, type: Float, default: 0.0
  field :cash_refund_bills_phonepe, type: Float, default: 0.0
  field :cash_refund_bills_online_transfer, type: Float, default: 0.0
  field :cash_refund_bills_cheque, type: Float, default: 0.0
  field :cash_refund_bills_others, type: Float, default: 0.0
  # EOF cash refund bills payment breakup

  field :credit_bills_count, type: Integer
  field :credit_bills_amount, type: Float
  field :credit_bills_info, type: Array
  # credit bills payment breakup
  field :credit_bills_cash_count, type: Integer, default: 0
  field :credit_bills_card_count, type: Integer, default: 0
  field :credit_bills_paytm_count, type: Integer, default: 0
  field :credit_bills_google_pay_count, type: Integer, default: 0
  field :credit_bills_phonepe_count, type: Integer, default: 0
  field :credit_bills_online_transfer_count, type: Integer, default: 0
  field :credit_bills_cheque_count, type: Integer, default: 0
  field :credit_bills_others_count, type: Integer, default: 0

  field :credit_bills_cash, type: Float, default: 0.0
  field :credit_bills_card, type: Float, default: 0.0
  field :credit_bills_paytm, type: Float, default: 0.0
  field :credit_bills_google_pay, type: Float, default: 0.0
  field :credit_bills_phonepe, type: Float, default: 0.0
  field :credit_bills_online_transfer, type: Float, default: 0.0
  field :credit_bills_cheque, type: Float, default: 0.0
  field :credit_bills_others, type: Float, default: 0.0
  # EOF credit bills payment breakup
  field :credit_refund_bills_count, type: Integer
  field :credit_refund_bills_amount, type: Float
  field :credit_refund_bills_info, type: Array
  # credit refund bills payment breakup
  field :credit_refund_bills_cash_count, type: Integer, default: 0
  field :credit_refund_bills_card_count, type: Integer, default: 0
  field :credit_refund_bills_paytm_count, type: Integer, default: 0
  field :credit_refund_bills_google_pay_count, type: Integer, default: 0
  field :credit_refund_bills_phonepe_count, type: Integer, default: 0
  field :credit_refund_bills_online_transfer_count, type: Integer, default: 0
  field :credit_refund_bills_cheque_count, type: Integer, default: 0
  field :credit_refund_bills_others_count, type: Integer, default: 0

  field :credit_refund_bills_cash, type: Float, default: 0.0
  field :credit_refund_bills_card, type: Float, default: 0.0
  field :credit_refund_bills_paytm, type: Float, default: 0.0
  field :credit_refund_bills_google_pay, type: Float, default: 0.0
  field :credit_refund_bills_phonepe, type: Float, default: 0.0
  field :credit_refund_bills_online_transfer, type: Float, default: 0.0
  field :credit_refund_bills_cheque, type: Float, default: 0.0
  field :credit_refund_bills_others, type: Float, default: 0.0
  # EOF credit refund bills payment breakup

  # sum of cash and credit info
  field :bills_count, type: Integer
  field :bills_amount, type: Float
  field :bills_info, type: Array
  # bills payment breakup
  field :bills_cash_count, type: Integer, default: 0
  field :bills_card_count, type: Integer, default: 0
  field :bills_paytm_count, type: Integer, default: 0
  field :bills_google_pay_count, type: Integer, default: 0
  field :bills_phonepe_count, type: Integer, default: 0
  field :bills_online_transfer_count, type: Integer, default: 0
  field :bills_cheque_count, type: Integer, default: 0
  field :bills_others_count, type: Integer, default: 0

  field :bills_cash, type: Float, default: 0.0
  field :bills_card, type: Float, default: 0.0
  field :bills_paytm, type: Float, default: 0.0
  field :bills_google_pay, type: Float, default: 0.0
  field :bills_phonepe, type: Float, default: 0.0
  field :bills_online_transfer, type: Float, default: 0.0
  field :bills_cheque, type: Float, default: 0.0
  field :bills_others, type: Float, default: 0.0
  # EOF bills payment breakup
  field :refund_bills_count, type: Integer
  field :refund_bills_amount, type: Float
  field :refund_bills_info, type: Array
  # refund bills payment breakup
  field :refund_bills_cash_count, type: Integer, default: 0
  field :refund_bills_card_count, type: Integer, default: 0
  field :refund_bills_paytm_count, type: Integer, default: 0
  field :refund_bills_google_pay_count, type: Integer, default: 0
  field :refund_bills_phonepe_count, type: Integer, default: 0
  field :refund_bills_online_transfer_count, type: Integer, default: 0
  field :refund_bills_cheque_count, type: Integer, default: 0
  field :refund_bills_others_count, type: Integer, default: 0

  field :refund_bills_cash, type: Float, default: 0.0
  field :refund_bills_card, type: Float, default: 0.0
  field :refund_bills_paytm, type: Float, default: 0.0
  field :refund_bills_google_pay, type: Float, default: 0.0
  field :refund_bills_phonepe, type: Float, default: 0.0
  field :refund_bills_online_transfer, type: Float, default: 0.0
  field :refund_bills_cheque, type: Float, default: 0.0
  field :refund_bills_others, type: Float, default: 0.0
  # EOF refund bills payment breakup

  field :advance_bills_refund_info, type: Array
  # refund advance bills payment breakup
  field :refund_advance_bills_cash_count, type: Integer, default: 0
  field :refund_advance_bills_card_count, type: Integer, default: 0
  field :refund_advance_bills_paytm_count, type: Integer, default: 0
  field :refund_advance_bills_google_pay_count, type: Integer, default: 0
  field :refund_advance_bills_phonepe_count, type: Integer, default: 0
  field :refund_advance_bills_online_transfer_count, type: Integer, default: 0
  field :refund_advance_bills_cheque_count, type: Integer, default: 0
  field :refund_advance_bills_others_count, type: Integer, default: 0

  field :refund_advance_bills_cash, type: Float, default: 0.0
  field :refund_advance_bills_card, type: Float, default: 0.0
  field :refund_advance_bills_paytm, type: Float, default: 0.0
  field :refund_advance_bills_google_pay, type: Float, default: 0.0
  field :refund_advance_bills_phonepe, type: Float, default: 0.0
  field :refund_advance_bills_online_transfer, type: Float, default: 0.0
  field :refund_advance_bills_cheque, type: Float, default: 0.0
  field :refund_advance_bills_others, type: Float, default: 0.0
  # EOF refund advance bills payment breakup

  field :net_collection, type: Float

  field :is_migrated, type: Boolean, default: true

  field :filter_fields, type: Hash
  field :search_fields, type: Hash
end

# db.finance_statistic_collection_transaction_data.createIndex({"receipt_date": -1, "facility_id": 1,
# "user_id": 1, "department_id": 1 });
# bills_info = all the MOP of cash and credit combined
# net_collection = ((advance_receipts_amount + bills_amount) - (refund_bills_amount + refund_advance_amount))
