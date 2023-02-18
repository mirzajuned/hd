class LegacyPatient
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  # HEALTHGRAPH PATIENT IDS AND IMPORTANT CONFIGURATIONS
  field :new_patient_id
  field :reg_hosp_ids, type: Array

  # MIGRATED PATIENT IDS
  field :legacy_patient_id, type: String
  field :legacy_national_id, type: String

  # MIGRATED PATIENT DETAILS
  field :salutation, type: String
  field :fullname, type: String
  field :gender, type: String
  field :age, type: Integer
  field :dob, type: String
  field :mobilenumber, type: String
  field :secondarymobilenumber, type: String
  field :contactnumber, type: String
  field :email, type: String
  field :age, type: Integer
  field :address_1, type: String
  field :address_2, type: String
  field :city, type: String
  field :state, type: String
  field :pincode, type: Integer
  field :blood_group, type: String
  field :emergencycontactname, type: String
  field :emergencymobilenumber, type: String
  field :maritalstatus, type: String
  field :specialstatus, type: String
  field :occupation, type: String
  field :remarks, type: String
  field :history, type: String
  field :othercomments, type: String

  field :registration_date, type: Date
  field :registration_time, type: Time

  has_many :legacy_opd_clinical_notes
  has_many :legacy_prescriptions
end
