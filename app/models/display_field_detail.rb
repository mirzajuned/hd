class DisplayFieldDetail
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :name, type: String
  field :value, type: String
  field :record_created_date, type: DateTime
  field :record_updated_date, type: DateTime

  field :entered_by, type: String
  field :entered_by_id, type: BSON::ObjectId
  field :entered_datetime, type: DateTime
  field :entered_from, type: String

  embedded_in :sequence_manager, class_name: "::SequenceManager"
end
