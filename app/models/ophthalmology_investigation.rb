class OphthalmologyInvestigation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :investigationstage, type: String
  field :investigationname, type: String
  field :investigationside, type: String

  field :counselling, type: Boolean, default: false
  field :billing, type: Boolean, default: false

  # Case Fields
  field :record_id, type: BSON::ObjectId
  field :appointment_id, type: BSON::ObjectId
  field :opd_investigation_id, type: BSON::ObjectId
  field :detail_investigation_id, type: BSON::ObjectId
  field :counsellor_investigation_ids, type: Hash, default: {}
  field :ipd_record_id, type: BSON::ObjectId
  field :ipd_investigation_ids, type: Hash, default: {}

  field :is_disabled, type: Boolean, default: false
  field :disabled_by, type: String
  field :disabled_by_id, type: BSON::ObjectId

  # Used by OPDRECORD/IPDRECORD
  field :case_sheet_investigation_id, type: BSON::ObjectId

  # Entered Details
  field :entered_by_id, type: BSON::ObjectId
  field :entered_by, type: String
  field :entered_at_facility_id, type: BSON::ObjectId
  field :entered_at_facility, type: String
  field :entered_datetime, type: DateTime

  # Advised Details
  field :is_advised, type: Boolean, default: true
  field :advised_by_id, type: BSON::ObjectId
  field :advised_by, type: String
  field :advised_at_facility_id, type: BSON::ObjectId
  field :advised_at_facility, type: String
  field :advised_datetime, type: DateTime

  # Counselled Details
  field :is_counselled, type: Boolean, default: false
  field :counselled_from, type: String
  field :counselled_by, type: String
  field :counselled_by_id, type: BSON::ObjectId
  field :counselled_at_facility, type: String
  field :counselled_at_facility_id, type: BSON::ObjectId
  field :counselled_datetime, type: DateTime

  # Agreed Details
  field :has_agreed, type: Boolean, default: false
  field :agreed_from, type: String
  field :agreed_by, type: String
  field :agreed_by_id, type: BSON::ObjectId
  field :agreed_at_facility, type: String
  field :agreed_at_facility_id, type: BSON::ObjectId
  field :agreed_datetime, type: DateTime

  # Declined Details
  field :has_declined, type: Boolean, default: false
  field :declined_from, type: String
  field :declined_by, type: String
  field :declined_by_id, type: BSON::ObjectId
  field :declined_at_facility, type: String
  field :declined_at_facility_id, type: BSON::ObjectId
  field :declined_datetime, type: DateTime

  # Payment Taken Details
  field :payment_taken, type: Boolean, default: false
  field :payment_taken_from, type: String
  field :payment_taken_by, type: String
  field :payment_taken_by_id, type: BSON::ObjectId
  field :payment_taken_at_facility, type: String
  field :payment_taken_at_facility_id, type: BSON::ObjectId
  field :payment_taken_datetime, type: DateTime

  # Sent Outside Details
  field :sent_outside, type: Boolean, default: false
  field :sent_outside_from, type: String
  field :sent_outside_by, type: String
  field :sent_outside_by_id, type: BSON::ObjectId
  field :sent_outside_at_facility, type: String
  field :sent_outside_at_facility_id, type: BSON::ObjectId
  field :sent_outside_datetime, type: DateTime

  # Test Started Details
  field :test_started, type: Boolean, default: false
  field :test_started_from, type: String
  field :test_started_by, type: String
  field :test_started_by_id, type: BSON::ObjectId
  field :test_started_at_facility, type: String
  field :test_started_at_facility_id, type: BSON::ObjectId
  field :test_started_datetime, type: DateTime

  # Converted Details
  field :is_converted, type: Boolean, default: false
  field :converted_from, type: String
  field :converted_by, type: String
  field :converted_by_id, type: BSON::ObjectId
  field :converted_at_facility, type: String
  field :converted_at_facility_id, type: BSON::ObjectId
  field :converted_datetime, type: DateTime

  # Performed Details
  field :is_performed_outside, type: Boolean, default: false
  field :performed_outside_by, type: String

  field :is_performed, type: Boolean, default: false
  field :performed_from, type: String
  field :performed_by_id, type: BSON::ObjectId
  field :performed_by, type: String
  field :performed_at_facility_id, type: BSON::ObjectId
  field :performed_at_facility, type: String
  field :performed_datetime, type: DateTime
  field :performed_comment, type: String

  # Template Created Details
  field :template_created, type: Boolean, default: false
  field :template_created_from, type: String
  field :template_created_by, type: String
  field :template_created_by_id, type: BSON::ObjectId
  field :template_created_at_facility, type: String
  field :template_created_at_facility_id, type: BSON::ObjectId
  field :template_created_datetime, type: DateTime

  # Reviewed Details
  field :is_reviewed, type: Boolean, default: false
  field :reviewed_from, type: String
  field :reviewed_by, type: String
  field :reviewed_by_id, type: BSON::ObjectId
  field :reviewed_at_facility, type: String
  field :reviewed_at_facility_id, type: BSON::ObjectId
  field :reviewed_datetime, type: DateTime

  # Removed Details
  field :is_removed, type: Boolean, default: false
  field :removing_reason, type: String
  field :removed_by_id, type: BSON::ObjectId
  field :removed_by, type: String
  field :removed_from, type: String
  field :removed_at_facility_id, type: BSON::ObjectId
  field :removed_at_facility, type: String
  field :removed_datetime, type: DateTime

  # Kranti
  field :created_from_template, type: Boolean
  field :findings, type: String
  field :normal_range, type: String
  field :investigation_side_name, type: String
  field :investigation_detail_id, type: BSON::ObjectId
  field :investigation_comment, type: String
  field :investigation_val, type: String
  field :doctors_remark, type: String
  field :order_advised_id, type: BSON::ObjectId
  field :order_item_advised_id, type: BSON::ObjectId

  embedded_in :records, class_name: '::Record'
  embedded_in :ipd_record, class_name: '::Inpatient::IpdRecord'
  embedded_in :opdrecord, class_name: '::OpdRecord'
  embedded_in :appointment_record, class_name: '::AppointmentRecord'
  embedded_in :counsellor_record, class_name: '::CounsellorRecord'

  embedded_in :case_sheet, class_name: '::CaseSheet'
  embedded_in :clinical_report_ipd, class_name: '::MisClinical::Ipd::ClinicalReportIpd'

  index({ order_item_advised_id: 1 })

  def get_label_for_ophthal_investigation_side(eyesideoption)
    eyesideoptionlabel = ''
    Global.ophthalmologyinvestigations.eyeside.each do |eyeside_option|
      eyesideoptionlabel = eyeside_option['side_abbr'] if eyeside_option['side_id'].to_i == eyesideoption.to_i
    end
    eyesideoptionlabel
  end
end
