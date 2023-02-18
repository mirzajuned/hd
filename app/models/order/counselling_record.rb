class Order::CounsellingRecord
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing
  field :case_sheet_id, type: BSON::ObjectId
  field :appointment_id, type: BSON::ObjectId
  field :counselled_by, type: String
  field :counselled_by_id, type: BSON::ObjectId
  field :counselled_on, type: DateTime
  field :entered_by, type: String
  field :entered_by_id, type: BSON::ObjectId
  field :entered_on, type: DateTime
  field :comment, type: String
  field :display_id, type: String

  field :patient_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  embeds_many :orders_data, class_name: '::OrdersData'

  accepts_nested_attributes_for :orders_data, allow_destroy: true

  def self.build(*args)
    counselling_record = new(args[0].except(:order_advised_id))
    counselling_record.orders_data.build(order_advised_id: args[0][:order_advised_id], type: args[0][:type])
    counselling_record
  end
end