class Finance::BillTypeStats
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :receipt_date, type: Date
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :facility_name, type: String
  field :facility_timezone, type: String

  field :department_id, type: Integer
  field :department_name, type: String
  field :department_order, type: Integer

  field :bill_type, type: String # free/paid/discounted
  
  field :user_id, type: BSON::ObjectId
  field :user_name, type: String

  field :patient_age_fields, type: Hash
  field :patient_gender_fields, type: Hash
  field :gender_wise_age, type: Hash
end
