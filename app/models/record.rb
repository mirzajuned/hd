class Record
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :creationtime, type: DateTime
  field :encounterdate, type: DateTime
  field :templatetype, type: String
  field :facility_id, type: String
  field :doctor_name, type: String
  field :specalityid, type: String
  field :specalityname, type: String
  field :appointment_id, type: String
  field :history, type: Hash
  field :examination, type: Hash
  field :investigation, type: Hash
  field :freeform, type: Hash

  embedded_in :patient_opd, class_name: "::PatientOpd"
  embeds_many :ophthal_investigations_list, class_name: "::OphthalmologyInvestigation" # OphthalmologyInvestigation
  embeds_many :radiology_investigations_list, class_name: "::RadiologyInvestigation" # rads
  embeds_many :laboratory_investigations_list, class_name: "::LaboratoryInvestigation" # labs

  accepts_nested_attributes_for :ophthal_investigations_list, reject_if: proc { |attributes| attributes['investigationname'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :radiology_investigations_list, reject_if: proc { |attributes| attributes['investigationname'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :laboratory_investigations_list, reject_if: proc { |attributes| attributes['investigationname'].blank? }, allow_destroy: true
end
