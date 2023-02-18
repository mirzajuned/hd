class PatientOpticalPrescription
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  # Fields From GP
  field :r_glassesprescriptions_distant_sph
  field :r_glassesprescriptions_distant_cyl
  field :r_glassesprescriptions_distant_axis
  field :r_glassesprescriptions_distant_vision

  field :r_glassesprescriptions_add_sph
  field :r_glassesprescriptions_add_cyl
  field :r_glassesprescriptions_add_axis
  field :r_glassesprescriptions_add_vision

  field :r_glassesprescriptions_near_sph
  field :r_glassesprescriptions_near_cyl
  field :r_glassesprescriptions_near_axis
  field :r_glassesprescriptions_near_vision

  field :l_glassesprescriptions_distant_sph
  field :l_glassesprescriptions_distant_cyl
  field :l_glassesprescriptions_distant_axis
  field :l_glassesprescriptions_distant_vision

  field :l_glassesprescriptions_add_sph
  field :l_glassesprescriptions_add_cyl
  field :l_glassesprescriptions_add_axis
  field :l_glassesprescriptions_add_vision

  field :l_glassesprescriptions_near_sph
  field :l_glassesprescriptions_near_cyl
  field :l_glassesprescriptions_near_axis
  field :l_glassesprescriptions_near_vision

  field :glassesprescriptions_show_add, type: Boolean, default: false

  # Fields From Acceptance
  field :r_acceptance_framematerial
  field :r_acceptance_ipd
  field :r_acceptance_distance_pd
  field :r_acceptance_near_pd
  field :r_acceptance_lensmaterial
  field :r_acceptance_lenstint
  field :r_acceptance_typeoflens
  field :r_acceptance_comments
  field :r_acceptance_dia
  field :r_acceptance_size
  field :r_acceptance_fittingheight
  field :r_acceptance_prismbase

  field :l_acceptance_framematerial
  field :l_acceptance_ipd
  field :l_acceptance_distance_pd
  field :l_acceptance_near_pd
  field :l_acceptance_lensmaterial
  field :l_acceptance_lenstint
  field :l_acceptance_typeoflens
  field :l_acceptance_comments
  field :l_acceptance_dia
  field :_acceptance_size
  field :l_acceptance_fittingheight
  field :l_acceptance_prismbase

  field :encounterdate, type: DateTime

  field :prescription_date, type: Date
  field :prescription_datetime, type: DateTime
  field :consultant_id, type: BSON::ObjectId
  field :consultant_name, type: String
  field :dispatched_from_optical, type: Boolean, default: false

  field :display_id, type: String
  field :advance_amount, type: Array, default: []
  field :advance_reason, type: Array, default: []

  field :converted, type: Boolean
  field :converted_date, type: Date
  field :converted_datetime, type: DateTime
  field :mark_converted_by, type: BSON::ObjectId

  field :order_count, type: Integer, default: 0 # count total no. of order for particular prescription
  field :re_converted, type: Boolean, default: false # true if more than one order for same prescription
  field :mark_patient_visited, type: Boolean, default: false

  field :optical_comment, type: String
  field :comment_flag, type: Integer
  field :reason_one, type: String
  field :reason_two, type: String
  field :reason_three, type: String
  field :reason_four, type: String
  field :reason_five, type: String
  field :reason_six, type: String
  field :reason_seven, type: String
  field :reason_eight, type: String
  field :reason_nine, type: String
  field :advise_glasses, type: String

  field :patient_name, type: String
  field :search, type: String
  field :mobile_number, type: Integer
  field :patient_identifier_id, type: String
  field :mr_no, type: String
  field :patient_identifier_id_search, type: String
  field :mr_no_search, type: String
  field :patient_name_search, type: String
  field :reg_hosp_ids, type: Array
  field :integration_identifier, type: BSON::ObjectId, default: BSON::ObjectId.new
  field :is_deleted, type: Boolean, default: false
  field :my_queue, type: Boolean, default: false
  field :is_migrated, type: Boolean, default: true
  field :is_prescription_migrated, type: Boolean, default: true
  field :store_id, type: BSON::ObjectId
  field :store_name, type: String
  field :store_present, type: Boolean, default: false
  field :with_user, type: String
  field :with_user_role, type: String
  field :user_ids, type: Array, default: [] # this field will be used only in case of QMS
  field :previous_user_ids, type: Array, default: [] # this field will be used only in case of QMS
  field :invoice_id, type: BSON::ObjectId
  field :order_id, type: BSON::ObjectId
  # field for such prescription who has been marked as not converted and later on they are converting same prescription.
  field :not_converted_to_converted, type: Boolean, default: false
  field :templatetype, type: String

  belongs_to :patient, optional: true, index: { background: true }
  belongs_to :user, optional: true, index: { background: true }
  belongs_to :facility
  # db.patient_optical_prescriptions.createIndex({ reg_hosp_ids: 1 })

  def get_doctor_name(userid)
    fullname = User.find_by(:id => userid).fullname
  end
end

# db.patient_optical_prescriptions.createIndex({"facility_id": 1, "created_at": 1 });
# db.patient_optical_prescriptions.dropIndex("facility_id_1_created_at_1");