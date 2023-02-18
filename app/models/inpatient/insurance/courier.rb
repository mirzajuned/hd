class Inpatient::Insurance::Courier
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :sent_day, type: Date
  field :courier_number, type: String
  field :courier_company, type: String
  field :courier_collected, type: String
  field :courier_handed, type: String
  field :contact_number, type: String
  field :comment, type: String
  field :current_status, type: String
  field :patient_id, type: BSON::ObjectId
  field :tpa_id, type: BSON::ObjectId

  belongs_to :admission
end
