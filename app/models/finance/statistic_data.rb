class Finance::StatisticData
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :organisation_id, type: String
  field :facility_id, type: String
  field :facility_name, type: String
  field :department_id, type: String
  field :department_name, type: String
  field :department_order, type: Integer
  field :receipt_date, type: Date

  # revenue
  field :has_revenue_data, type: Boolean, default: false
  field :total_bill_count, type: Integer
  field :total_bill_amount, type: Float
  field :total_bill_discount, type: Float
  field :total_bill_offer, type: Float
  field :refund_bill_count, type: Integer
  field :refund_bill_charges, type: Float
  field :refund_bill_amount, type: Float

  field :cash_bill_created_count, type: Integer
  field :cash_bill_count, type: Integer
  field :cash_bill_created_amount, type: Float
  field :cash_bill_settled_amount, type: Float
  field :cash_bill_created_discount, type: Float
  field :cash_bill_discount, type: Float
  field :cash_bill_created_offer, type: Float
  field :cash_bill_offer, type: Float
  field :cash_refund_bill_count, type: Integer
  field :cash_refund_bill_charges, type: Float
  field :cash_refund_bill_amount, type: Float

  field :cash_bill_created_advance_payment, type: Float
  field :cash_bill_advance_payment, type: Float

  field :cash_bill_amount, type: Float

  field :credit_bill_created_count, type: Integer
  field :credit_bill_count, type: Integer
  field :credit_bill_created_amount, type: Float
  field :credit_bill_amount, type: Float
  field :credit_bill_created_discount, type: Float
  field :credit_bill_discount, type: Float
  field :credit_bill_created_offer, type: Float
  field :credit_bill_offer, type: Float
  field :credit_bill_settled_amount, type: Float
  field :credit_pending_created_amount, type: Float
  field :credit_pending_amount, type: Float
  field :credit_refund_bill_count, type: Integer
  field :credit_refund_bill_charges, type: Float
  field :credit_refund_bill_amount, type: Float

  field :cancelled_bill_count, type: Integer
  field :cancelled_bill_amount, type: Float

  field :advance_refund_bill_count, type: Integer
  field :advance_refund_bill_charges, type: Float
  field :advance_refund_bill_amount, type: Float
  
  # collection
  field :has_collection_data, type: Boolean, default: false
  field :cashsale_amount, type: Float
  field :advance_amount, type: Float
  field :creditsale_settle, type: Float

  field :collection_total, type: Float

  field :receivable_self_amount, type: Float
  field :receivable_other_amount, type: Float
  field :receivable_total, type: Float

  field :cancelled_amount, type: Float

  field :refund_cashsale_amount, type: Float
  field :refund_creditsale_amount, type: Float
  field :refund_advance_amount, type: Float
  field :refund_total, type: Float
  
  field :refund_cashsale_charges, type: Float
  field :refund_creditsale_charges, type: Float
  field :refund_advance_charges, type: Float
  field :refund_charges, type: Float
  
  field :total_profit, type: Float
  field :is_migrated, type: Boolean, default: true

  field :filter_fields, type: Hash
  field :search_fields, type: Hash
end

# db.finance_statistic_data.createIndex({"receipt_date": -1, "facility_id": 1 });
