class LegacyPrescription
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  belongs_to :legacy_patient

  # HEALTHGRAPH PATIENT IDS AND IMPORTANT CONFIGURATIONS
  field :new_patient_id

  # MIGRATED PATIENT DETAILS
  field :prescriptiondate, type: Date
  field :patientnumber, type: String
  field :patientname, type: String
  field :doctor, type: String
  field :medicinename, type: String # "Drug Name" + "Drug Type" + "Dosage" + "Dosage Unit"
  field :medicinefrequency, type: String # Morning + Afternoon + Night
  field :medicinecontents, type: String # "Drug Name" + "Drug Type" + "Dosage" + "Dosage Unit"
  field :medicinequantity, type: String # "Tablet Per Day"
  field :medicineperday, type: String # "Tablet Per Day"
  field :medicineinstructions, type: String # instruction varchar(255)
  field :medicineduration, type: String # Duration
  field :medicinedurationoption, type: String # "Duration Unit"
end
