class Order::Advised
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :procedurestage, type: String
  field :procedureregion, type: String
  field :procedureside, type: String
  field :procedurestatus, type: String
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
  field :agreed_notes, type: String
  field :followup_notes, type: String
  field :followup_datetime, type: DateTime
  field :followup_by_id, type: DateTime
  field :followup_reasons, type: String

  # Declined Details
  field :has_declined, type: Boolean, default: false
  field :declined_from, type: String
  field :declined_by, type: String
  field :declined_by_id, type: BSON::ObjectId
  field :declined_at_facility, type: String
  field :declined_at_facility_id, type: BSON::ObjectId
  field :declined_datetime, type: DateTime
  field :declined_reasons, type: String

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
  field :iol_agreed, type: String
  field :iol_power, type: String

  # Comments
  field :procedure_comment, type: String 
  field :users_comment, type: String

  field :appointment_id, type: BSON::ObjectId
  field :procedure_id, type: BSON::ObjectId
  field :procedureoriginalside, type: String
  field :procedurefullcode, type: String
  field :user_id, type: BSON::ObjectId
  field :consultant_id, type: BSON::ObjectId
  field :consultant_name, type: String
  field :template_type, type: String
  field :entered_from, type: String
  field :advised_from, type: String
  field :performed_at, type: DateTime

  # Ophthal Investigation

  field :investigationstage, type: String
  field :investigationname, type: String
  field :investigationside, type: String
  field :opd_investigation_id, type: BSON::ObjectId
  field :case_sheet_id, type: BSON::ObjectId
  field :detail_investigation_id, type: BSON::ObjectId
  field :counsellor_investigation_ids, type: Hash, default: {}
  field :case_sheet_investigation_id, type: BSON::ObjectId
  field :sent_outside, type: Boolean, default: false
  field :sent_outside_from, type: String
  field :sent_outside_by, type: String
  field :sent_outside_by_id, type: BSON::ObjectId
  field :sent_outside_at_facility, type: String
  field :sent_outside_at_facility_id, type: BSON::ObjectId
  field :sent_outside_datetime, type: DateTime
  field :test_started, type: Boolean, default: false
  field :test_started_from, type: String
  field :test_started_by, type: String
  field :test_started_by_id, type: BSON::ObjectId
  field :test_started_at_facility, type: String
  field :test_started_at_facility_id, type: BSON::ObjectId
  field :test_started_datetime, type: DateTime
  field :is_performed_outside, type: Boolean, default: false
  field :performed_outside_by, type: String
  field :template_created, type: Boolean, default: false
  field :template_created_from, type: String
  field :template_created_by, type: String
  field :template_created_by_id, type: BSON::ObjectId
  field :template_created_at_facility, type: String
  field :template_created_at_facility_id, type: BSON::ObjectId
  field :template_created_datetime, type: DateTime
  field :is_reviewed, type: Boolean, default: false
  field :reviewed_from, type: String
  field :reviewed_by, type: String
  field :reviewed_by_id, type: BSON::ObjectId
  field :reviewed_at_facility, type: String
  field :reviewed_at_facility_id, type: BSON::ObjectId
  field :reviewed_datetime, type: DateTime
  field :removing_reason, type: String
  field :created_from_template, type: Boolean
  field :findings, type: String
  field :normal_range, type: String
  field :investigation_side_name, type: String
  field :investigation_detail_id, type: BSON::ObjectId
  field :investigation_comment, type: String
  field :investigation_val, type: String
  field :doctors_remark, type: String
  field :investigation_id, type: BSON::ObjectId
  field :investigationoriginalside, type: String
  field :investigationfullcode, type: String
  field :investigation_type, type: String
  field :status, type: String
  field :order_item_advised_id, type: BSON::ObjectId

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :patient_id, type: BSON::ObjectId


  field :active, type: Boolean, default: true


  # Radiology Fields

  field :loinccode, type: String
  field :laterality, type: String
  field :is_spine, type: String
  field :investigationadviseddate, type: String
  field :radiologyoptions, type: String
  field :radiologyoptions_collection, type: Array
  field :ipd_investigation_ids, type: Hash, default: {}
  field :haslaterality, type: Boolean, default: false
  field :type, type: String
  field :quantity, type: Integer
  field :is_cancelled, type: Boolean
  field :cancelled_from, type: String
  field :cancelled_by, type: String
  field :cancelled_by_id, type: BSON::ObjectId
  field :cancelled_at_facility, type: String
  field :cancelled_at_facility_id, type: BSON::ObjectId
  field :cancelled_datetime, type: DateTime

  index({ order_item_advised_id: 1 })

  has_many :order_trails, class_name: "Order::Trail", foreign_key: 'order_advised_id'

  def get_label_for_side(side)
    if side == '40638003'
      'B/E'
    elsif side == '18944008'
      'RE'
    elsif side == '8966001'
      'LE'
    else
      ''
    end
  end

  def get_label_for_radiology_option(radiologyoption)
    radiologyoptionlabel = ""
    Global.ehrcommon.radiologyattributes.each do |radiology_option|
      if radiology_option['id'].to_i == radiologyoption.to_i
        radiologyoptionlabel = radiology_option['displayname']
      end
    end
    radiologyoptionlabel
  end

  def get_counselled_by_status
    case status
    when "Agreed"
      agreed_by
    when "Declined"
      declined_by
    when "Payment Taken"
      payment_taken_by
    when "Advised"
      advised_by
    when "Scheduled"
      entered_by
    else
      advised_by
    end
  end

  def get_counselled_datetime_by_status
    return order_trails.last.created_at if order_trails.present?
    case status
    when "Agreed"
      agreed_datetime || counselled_datetime
    when "Declined"
      declined_datetime
    when "Payment Taken"
      payment_taken_datetime
    when "Advised"
      advised_datetime
    when "Scheduled"
      entered_datetime
    else
      advised_datetime
    end
  end
end