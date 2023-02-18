class LegacyOpdClinicalNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  belongs_to :legacy_patient
  # embeds_many :legacy_prescriptions, class_name: "::LegacyPrescription"
  # accepts_nested_attributes_for :legacy_prescriptions #, reject_if: proc { |attributes| attributes['medicinename'].blank? }

  # HEALTHGRAPH PATIENT IDS AND IMPORTANT CONFIGURATIONS
  field :new_patient_id

  # MIGRATED PATIENT DETAILS
  field :clinicalnotedate, type: Date
  field :patientnumber, type: String
  field :patientname, type: String
  field :doctor, type: String
  field :complaints, type: String
  field :complaintcomments, type: String
  field :history, type: String
  field :historycomments, type: String
  field :examination, type: String
  field :examinationcomments, type: String
  field :diagnosis, type: String
  field :diagnosiscomments, type: String
  field :investigations, type: String
  field :investigationcomments, type: String
  field :plan, type: String
  field :plancomments, type: String
  field :followup, type: String
  field :othercomments, type: String
  field :allergies, type: String
  field :pasthistory, type: String
  field :familyhistory, type: String
  field :surgicalhistory, type: String
  field :medicationhistory, type: String
  field :advise, type: String
  field :instruction, type: String
  field :notes, type: String

  field :opto_readings, type: Hash
end
