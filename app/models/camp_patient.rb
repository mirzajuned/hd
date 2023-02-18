class CampPatient
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  # user details
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :outreach_patient_id, type: BSON::ObjectId
  # field :camp_id, type: BSON::ObjectId
  field :camp_name, type: String
  field :camp_username, type: String
  # patients details
  field :fullname, type: String
  field :email, type: String
  field :gender, type: String
  field :age, type: String
  field :dob, type: DateTime
  field :commune, type: String
  field :district, type: String
  field :city, type: String
  field :address1, type: String
  field :address2, type: String
  field :phone_number, type: String
  field :complaints, type: String
  field :patient_id, type: BSON::ObjectId
  field :camp_patient_identifier, type: String
  field :converted, type: Boolean, default: false

  # clinical details
  field :visual_acuity_r, type: String
  field :visual_acuity_l, type: String

  field :anetrior_segment_r, type: String
  field :anetrior_segment_l, type: String

  field :fundus_r, type: String
  field :fundus_l, type: String

  field :iol_r, type: String
  field :iol_l, type: String

  field :duct_r, type: String
  field :duct_l, type: String

  field :diagnosis_r, type: String
  field :diagnosis_l, type: String

  field :glass_prescription_r, type: String
  field :glass_prescription_l, type: String

  field :r_glassesprescriptions_distant_sph, type: String
  field :r_glassesprescriptions_add_sph, type: String
  field :r_glassesprescriptions_near_sph, type: String
  field :r_glassesprescriptions_distant_cyl, type: String
  field :r_glassesprescriptions_add_cyl, type: String
  field :r_glassesprescriptions_near_cyl, type: String
  field :r_glassesprescriptions_distant_axis, type: String
  field :r_glassesprescriptions_add_axis, type: String
  field :r_glassesprescriptions_near_axis, type: String
  field :r_glassesprescriptions_distant_vision, type: String
  field :r_glassesprescriptions_add_vision, type: String
  field :r_glassesprescriptions_near_vision, type: String

  field :l_glassesprescriptions_distant_sph, type: String
  field :l_glassesprescriptions_add_sph, type: String
  field :l_glassesprescriptions_near_sph, type: String
  field :l_glassesprescriptions_distant_cyl, type: String
  field :l_glassesprescriptions_add_cyl, type: String
  field :l_glassesprescriptions_near_cyl, type: String
  field :l_glassesprescriptions_distant_axis, type: String
  field :l_glassesprescriptions_add_axis, type: String
  field :l_glassesprescriptions_near_axis, type: String
  field :l_glassesprescriptions_distant_vision, type: String
  field :l_glassesprescriptions_add_vision, type: String
  field :l_glassesprescriptions_near_vision, type: String

  # fitness details

  field :bp, type: String
  field :us, type: String
  field :pulse, type: String
  field :cvs, type: String
  field :rs, type: String
  field :temperature, type: String
  field :rs, type: String

  # counselling and advice
  field :surgery, type: String
  field :surgery_eye, type: String
  field :advice, type: String
  field :advice_purpose, type: String
  field :medication, type: String
  field :follow_up_date, type: DateTime
  field :refer_to_facility, type: String
  field :sub_referral_type_id, type: String

  # belongs_to :camp

  before_save :downcase_fullname

  # index({ camp_user_id: 1 }, background: true)
  validates_presence_of :facility_id, message: 'facility_id cannot be blank.'
  validates_presence_of :organisation_id, message: 'organisation_id cannot be blank.'

  def downcase_fullname
    self.fullname = self.fullname.downcase
  end
end
