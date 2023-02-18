class Diagnosis
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :diagnosisregions, type: String
  field :diagnosisname, type: String
  field :icddiagnosiscodelength, type: Integer
  field :icddiagnosiscode, type: String
  field :position_1, type: String
  field :position_2, type: String
  field :position_3, type: String
  field :position_4, type: String
  field :position_5, type: String
  field :position_6, type: String
  field :position_7, type: String
  field :icddiagnosisfullcode, type: String
  field :icddagnosisdate, type: String

  # Case Fields
  field :record_id, type: BSON::ObjectId
  field :ipd_record_id, type: BSON::ObjectId
  field :opd_diagnosis_id, type: BSON::ObjectId
  field :ipd_diagnosis_ids, type: Hash, default: {}
  field :counsellor_diagnosis_ids, type: Hash, default: {}

  field :is_disabled, type: Boolean, default: false
  field :disabled_by, type: String
  field :disabled_by_id, type: BSON::ObjectId
  field :flow_in_ipd, type: Boolean, default: false

  # Used by OPDRECORD/IPDRECORD
  field :case_sheet_diagnosis_id, type: BSON::ObjectId

  # fields after structure change
  field :diagnosisoriginalname, type: String
  field :saperatedicddiagnosiscode, type: String
  field :entered_by, type: String
  field :entered_by_id, type: BSON::ObjectId
  field :updated_by, type: String
  field :updated_by_id, type: BSON::ObjectId
  field :diagnosis_comment, type: String
  field :users_comment, type: String
  field :entry_datetime, type: DateTime
  field :entered_datetime, type: DateTime
  field :updated_datetime, type: DateTime
  field :entered_at_facility, type: String
  field :entered_at_facility_id, type: BSON::ObjectId
  field :updated_at_facility, type: String
  field :updated_at_facility_id, type: BSON::ObjectId
  field :icd_type, type: String

  # Fields for AppointmentRecord
  field :record_id, type: BSON::ObjectId
  field :opd_diagnosis_id, type: BSON::ObjectId
  field :counsellor_diagnosis_id, type: BSON::ObjectId

  # Advised Details
  field :advised_by, type: String
  field :advised_by_id, type: BSON::ObjectId
  field :advised_at_facility, type: String
  field :advised_at_facility_id, type: BSON::ObjectId
  field :advised_datetime, type: DateTime

  embedded_in :opdrecord, class_name: '::OpdRecord'
  embedded_in :patient_opd, class_name: '::PatientOpd'
  embedded_in :ipd_record, class_name: '::Inpatient::IpdRecord'
  embedded_in :counsellor_record
  embedded_in :appointment_record

  embedded_in :case_sheet, class_name: '::CaseSheet'
  embedded_in :clinical_report_ipd, class_name: '::MisClinical::Ipd::ClinicalReportIpd'

  def get_diagnosis_icd_label(icdcode, attribute_code, position)
    icdattributes = IcdDiagnosisCodeAttribrute.where(computed_attribute_code: icdcode.to_s,
                                                     attribute_code_position: position.to_s,
                                                     attribute_code: attribute_code.to_s)
    icdattributes[0].attribute_display_label
  end

  def get_diagnosis_icd_attributes(icdcode, position)
    # puts icdcode
    icdattributes = IcdDiagnosisCodeAttribrute.where(computed_attribute_code: icdcode.to_s,
                                                     attribute_code_position: position.to_s)
    icdattributes.map do |icdattr|
      Array[icdattr.attribute_display_label, icdattr.attribute_code]
    end
  end
end
