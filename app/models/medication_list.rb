class MedicationList
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :med_type, type: String # Mohit Maniar, Added new type field. Fixed based on feedback from doctor.
  field :contents, type: String
  field :manufacturer, type: String
  field :administration, type: String
  field :cims_class, type: String
  field :cims_id, type: String
  field :presentation, type: String
  field :cost, type: String
  field :old_name, type: String # Saving previous name of the medicine
  field :old_presentation, type: String # Saving previous presentation in this field.

  index({ name: 1 }, { background: true })
end
