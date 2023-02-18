class OrdersData
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing
  field :patient_comment, type: String
  field :counsellor_comment, type: String
  field :status, type: String, default: "No Action Taken"
  field :recounselled, type: Boolean, default: false
  field :type, type: String
  field :order_advised_id, type: BSON::ObjectId
  embedded_in :counselling_record, class_name: 'Order::CounsellingRecord'
end