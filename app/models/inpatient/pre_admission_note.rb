class Inpatient::PreAdmissionNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :template_type, type: String
  field :template_id, type: String
  field :fullname, type: String

  field :investigation_note, type: String
  field :special_note, type: String
  field :medication_note, type: String
  field :instruction_note, type: String

  field :admission_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :specalityid, type: String
  field :specalityname, type: String
  field :patient_id, type: BSON::ObjectId
  field :encountertype, type: String, default: "WARD"
  field :encountertypeid, type: String, default: "444950001"






  # authorization field we thought to given these field but now we have added record histories
  # field :nurse_name, type: String
  # field :template_date, type: Date, default: Date.current
  # field :template_time, type: Time, default: Time.current
  field :received_by, type: String
  field :received_date, type: Date, default: Date.current
  field :received_time,  type: Time, default: Time.current
  field :medicationsets, type: Array

  # inventory store
  # field :store_name, type: String
  # field :store_id, type: BSON::ObjectId

  embeds_many :treatmentmedication, class_name: "::MedicationRecord" # medications
  embeds_many :sedation, class_name: "::SedationRecord" # sedations
  embeds_many :record_histories
  embeds_many :generic_names, class_name: '::Inventory::Item::GenericName'

  accepts_nested_attributes_for :treatmentmedication, reject_if: proc { |attributes| attributes['medicinename'].blank? }, allow_destroy: true # medications
  accepts_nested_attributes_for :sedation, reject_if: proc { |attributes| attributes['date'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :record_histories, class_name: "::RecordHistory"
  accepts_nested_attributes_for :generic_names, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
end
