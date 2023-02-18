class Order::Trail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing
  field :case_sheet_id, type: BSON::ObjectId
  field :appointment_id, type: BSON::ObjectId
  field :order_advised_id, type: BSON::ObjectId
  field :date, type: BSON::ObjectId
  field :action, type: String
  field :subaction, type: String
  field :metadata, type: Hash, default: {}
  belongs_to :order_advised, class_name: "Order::Advised", foreign_key: 'order_advised_id'

  def patient_comment
    metadata.try(:[], "patient_comment")
  end

  def counsellor_comment
    metadata.try(:[], "counsellor_comment")
  end
end