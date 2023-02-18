class MedicationKit
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :name, type: String
  field :set_type, type: Integer
  field :data, type: String
  field :specialty_id, type: Integer
  field :level, type: String # organisation, #user, #facility
  field :doctor, type: BSON::ObjectId
  field :is_migrated, type: Boolean, default: true
  field :pharmacy_item_id, type: String
  field :generic_display_name, type: String
  field :generic_display_ids, type: String
  field :medicine_from, type: String

  belongs_to :user, index: { background: true }, optional: true
  belongs_to :organisation, index: { background: true }
  belongs_to :facility, index: { background: true }, optional: true
end
