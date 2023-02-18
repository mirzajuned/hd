class Order::Followup
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic
    include Mongoid::Timestamps
    include MethodMissing

   field :order_advised_ids, type: Array, default: []
   field :followup_date, type: Date
   field :followup_time, type: String
   field :followup_for_id, type: BSON::ObjectId
   field :counselled_by_id, type: BSON::ObjectId
   field :appointment_id, type: BSON::ObjectId
   field :followup_notes, type: String
   field :followup_type, type: String
   field :followup_reasons, type: Array, default: []
   field :counsellor_workflow_id, type: BSON::ObjectId
   field :create_appointment, type: Boolean, default: false
end