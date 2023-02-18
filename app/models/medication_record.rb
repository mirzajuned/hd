class MedicationRecord
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :medicinename, type: String
  field :medicinetype, type: String
  field :medicinecontents, type: String
  field :medicinequantity, type: String
  field :medicinefrequency, type: String
  field :medicineduration, type: String
  field :medicinedurationoption, type: String
  field :medicineinstructions, type: String
  field :taper_id, type: String
  field :status, type: String
  field :date, type: Date
  field :time, type: Time
  field :generic_display_name, type: String
  field :generic_display_ids, type: String
  field :medicine_from, type: String

  embedded_in :opdrecord, class_name: "::OpdRecord"
  embedded_in :ipdrecord, class_name: "::Inpatient::IpdRecord"
  embedded_in :nursing_record, class_name: "::NursingRecord"
  embedded_in :pre_admission_record, class_name: "::Inpatient::PreAdmissionNote"
end
