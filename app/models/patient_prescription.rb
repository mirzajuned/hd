class PatientPrescription
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :medications, type: Array, default: []
  field :encounterdate, type: DateTime

  field :prescription_date, type: Date
  field :prescription_datetime, type: DateTime
  field :consultant_id, type: BSON::ObjectId
  field :consultant_name, type: String
  field :dispatched_from_pharmacy, type: Boolean, default: false

  field :converted, type: Boolean
  field :converted_date, type: Date
  field :converted_datetime, type: DateTime
  field :mark_converted_by, type: BSON::ObjectId

  field :pharmacy_comment, type: String
  field :medication_comment, type: String
  field :is_deleted, type: Boolean, default: false
  field :my_queue, type: Boolean, default: false
  field :appointment_id, type: String
  field :patient_name, type: String
  field :search, type: String
  field :mobile_number, type: Integer
  field :patient_identifier_id, type: String
  field :mr_no, type: String
  field :patient_identifier_id_search, type: String
  field :mr_no_search, type: String
  field :patient_name_search, type: String
  field :reg_hosp_ids, type: Array
  field :is_migrated, type: Boolean, default: true
  field :is_prescription_migrated, type: Boolean, default: true
  field :store_id, type: BSON::ObjectId
  field :store_name, type: String
  field :store_present, type: Boolean, default: false
  field :with_user, type: String
  field :with_user_role, type: String
  field :user_ids, type: Array, default: [] # this field will be used only in case of QMS
  field :previous_user_ids, type: Array, default: [] # this field will be used only in case of QMS

  field :admission_id, type: String
  field :invoice_id, type: BSON::ObjectId
  field :order_id, type: BSON::ObjectId
  field :mark_patient_visited, type: Boolean, default: false
  # field for such prescription who has been marked as not converted and later on they are converting same prescription.
  field :not_converted_to_converted, type: Boolean, default: false

  belongs_to :patient
  belongs_to :user
  belongs_to :facility
  belongs_to :author, class_name: '::User', foreign_key: :authorid, optional: true
  # db.patient_prescriptions.createIndex({ reg_hosp_ids: 1 })
  def get_doctor_name(userid)
    fullname = User.find_by(:id => userid).fullname
  end
end

# db.patient_prescriptions.createIndex({"facility_id": 1, "created_at": 1 });
# db.patient_prescriptions.dropIndex("facility_id_1_created_at_1");
