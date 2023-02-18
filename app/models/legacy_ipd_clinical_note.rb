class LegacyIpdClinicalNote
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
  field :mr_no, type: String
  field :ip_no, type: String
  field :patientnumber, type: String
  field :patientname, type: String
  field :doctor, type: String
  field :surgeon, type: String
  field :anescode, type: String
  field :anesthetist, type: String
  field :anatype, type: String
  field :otnote, type: String
  field :ananote, type: String
  field :postop, type: String
  field :locality, type: String
  field :intime, type: String
  field :outtime, type: String
  field :surgery_date, type: Date

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

  field :doa, type: Date # date of arrival
  field :dod, type: Date # date of dep
  field :doo, type: Date # date of operation
  field :ipd_notes, type: String
  field :surgery, type: String

  field :othercomments, type: String
  field :allergies, type: String
  field :pasthistory, type: String
  field :familyhistory, type: String
  field :surgicalhistory, type: String
  field :medicationhistory, type: String
end
