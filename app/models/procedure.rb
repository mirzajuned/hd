class Procedure
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :procedurestage, type: String
  field :procedureregion, type: String
  field :procedureside, type: String
  field :procedurestatus, type: String
  field :order_status, type: String   # open/processing/closed
  field :order_created, type: Boolean, default: false
  field :order_display_id, type: String
  field :procedureapproach, type: String
  field :proceduretype, type: String
  field :procedurename, type: String
  field :procedurequalifier, type: String
  field :proceduresubqualifier, type: String
  field :counselling, type: Boolean, default: false
  field :billing, type: Boolean, default: false
  field :surgerydate, type: String
  field :procedure_type, type: String
  field :ot_checklist, type: Boolean, default: false
  field :ot_checklist_id, type: BSON::ObjectId
  field :has_complications, type: String, default: 'No'
  field :procedure_cnt, type: Integer

  # complication comment details
  field :complication_comment, type: String

  field :complication_comment_entered_by, type: String
  field :complication_comment_entered_by_id, type: BSON::ObjectId
  field :complication_comment_entered_at_facility, type: String
  field :complication_comment_entered_at_facility_id, type: BSON::ObjectId
  field :complication_comment_entered_datetime, type: DateTime

  field :complication_comment_updated_by, type: String
  field :complication_comment_updated_by_id, type: BSON::ObjectId
  field :complication_comment_updated_at_facility, type: String
  field :complication_comment_updated_at_facility_id, type: BSON::ObjectId
  field :complication_comment_updated_datetime, type: DateTime

  field :has_complication_created_by, type: String
  field :has_complication_created_by_id, type: BSON::ObjectId
  field :has_complication_created_by_datetime, type: DateTime
  field :has_complication_removed_by, type: String
  field :has_complication_removed_by_id, type: BSON::ObjectId
  field :has_complication_removed_by_datetime, type: DateTime

  # Fields June 2017

  # Case Fields
  field :record_id, type: BSON::ObjectId
  field :ipd_record_id, type: BSON::ObjectId
  field :opd_procedure_id, type: BSON::ObjectId
  field :ipd_procedure_ids, type: Hash, default: {}
  field :counsellor_procedure_ids, type: Hash, default: {}

  field :is_disabled, type: Boolean, default: false
  field :disabled_by, type: String
  field :disabled_by_id, type: BSON::ObjectId
  field :flow_in_ipd, type: Boolean, default: false

  field :performed_inline, type: Boolean, default: false

  # Used by OPDRECORD/IPDRECORD
  field :case_sheet_procedure_id, type: BSON::ObjectId

  # Entered Details
  field :entered_by, type: String
  field :entered_by_id, type: BSON::ObjectId
  field :entered_at_facility, type: String
  field :entered_at_facility_id, type: BSON::ObjectId
  field :entered_datetime, type: DateTime

  # Advised Details
  field :is_advised, type: Boolean, default: true
  field :advised_by, type: String
  field :advised_by_id, type: BSON::ObjectId
  field :advised_at_facility, type: String
  field :advised_at_facility_id, type: BSON::ObjectId
  field :advised_datetime, type: DateTime

  # Updated Details
  field :updated_by, type: String
  field :updated_by_id, type: BSON::ObjectId
  field :updated_at_facility, type: String
  field :updated_at_facility_id, type: BSON::ObjectId
  field :updated_datetime, type: DateTime

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

  # Converted Details
  field :is_converted, type: Boolean, default: false
  field :converted_from, type: String
  field :converted_by, type: String
  field :converted_by_id, type: BSON::ObjectId
  field :converted_at_facility, type: String
  field :converted_at_facility_id, type: BSON::ObjectId
  field :converted_datetime, type: DateTime

  field :in_admission, type: Boolean, default: false

  # Performed Details
  field :is_performed, type: Boolean, default: false
  field :performed_by, type: String
  field :performed_by_id, type: BSON::ObjectId
  field :performed_from, type: String
  field :performed_at_facility, type: String
  field :performed_at_facility_id, type: BSON::ObjectId
  # added new fields
  field :performed_date, type: Date
  field :performed_time, type: Time
  
  # Comment this during migration
  field :performed_datetime, type: DateTime
  # Uncomment this during migration
  # field :performed_datetime_bkp, type: DateTime
  field :performed_comment, type: String
  field :users_comment, type: String

  field :performed_note_id, type: BSON::ObjectId

  # Removed Details
  field :is_removed, type: Boolean, default: false
  field :removed_by_id, type: BSON::ObjectId
  field :removed_by, type: String
  field :removed_from, type: String
  field :removed_at_facility_id, type: BSON::ObjectId
  field :removed_at_facility, type: String
  field :removed_datetime, type: DateTime

  # IOL Fields
  field :iol_present, type: Boolean, default: false
  field :iol1_inventory_item_id, type: BSON::ObjectId
  field :iol2_inventory_item_id, type: BSON::ObjectId
  field :iol3_inventory_item_id, type: BSON::ObjectId
  field :iol_agreed, type: String
  field :iol_power, type: String

  # Comments
  field :procedure_comment, type: String # procedure_performed
  field :users_comment, type: String
  field :order_advised_id, type: BSON::ObjectId
  field :order_item_advised_id, type: BSON::ObjectId

  embedded_in :opdrecord, class_name: '::OpdRecord'
  embedded_in :patient_opd, class_name: '::PatientOpd'
  embedded_in :ipd_record, class_name: '::Inpatient::IpdRecord'
  embedded_in :counsellor_record, class_name: '::CounsellorRecord'
  embedded_in :appointment_record, class_name: '::AppointmentRecord'

  embedded_in :case_sheet, class_name: '::CaseSheet'
  embedded_in :clinical_report_ipd, class_name: '::MisClinical::Ipd::ClinicalReportIpd'

  # before_save :set_performed_date_time

  index({ order_item_advised_id: 1, order_advised_id: 1 })

  def get_label_for_procedure_side(eyesideoption)
    eyesideoptionlabel = ''
    Global.ophthalmologyprocedures.eyeside.each do |eyeside_option|
      eyesideoptionlabel = eyeside_option['side_abbr'] if eyeside_option['side_id'].to_i == eyesideoption.to_i
    end
    eyesideoptionlabel
  end

  def operative_note
    @ipdrecord = ipd_record
    @operative_note = @ipdrecord.operative_notes.find_by(id: operative_note_id)
  end

  # def set_performed_date_time
  #   puts '='*20
  #   puts performed_datetime.present?
  #   puts '='*20
  # end
end
