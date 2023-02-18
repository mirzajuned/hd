# No Offenses
class OtListView
  include Mongoid::Document
  include Mongoid::Timestamps

  # Patient
  field :patient_name, type: String
  field :patient_id, type: BSON::ObjectId
  field :patient_display_id, type: String
  field :patient_mr_no, type: String
  field :patient_age, type: String
  field :patient_gender, type: String
  field :patient_type, type: String
  field :patient_type_color, type: String
  field :city, type: String
  field :pincode, type: String
  field :state, type: String
  field :district, type: String
  field :commune, type: String
  field :patient_mobilenumber, type: String
  field :age, type: Integer

  # Admission
  field :admission_id, type: BSON::ObjectId
  field :admission_display_id, type: String
  field :admission_type, type: String, default: 'planned'
  field :reason_for_admission, type: String
  field :procedures, type: String, default: ''

  # OT
  field :ot_id, type: BSON::ObjectId
  field :ot_display_id, type: String
  field :operating_doctor, type: String
  field :operating_doctor_id, type: BSON::ObjectId
  field :ot_date, type: Date
  field :ot_time, type: Time
  field :ot_end_time, type: Time
  field :theatre_number, type: BSON::ObjectId
  field :theatre_name, type: String

  # Ward
  field :daycare, type: Boolean
  field :ward_name, type: String
  field :ward_code, type: String
  field :room_name, type: String
  field :room_code, type: String
  field :bed_name, type: String
  field :bed_code, type: String

  # Insurance
  field :insurance_state, type: String
  field :insurance_badge_color, type: String

  # Workflow
  field :current_state, type: String, default: 'Scheduled'
  field :current_state_color, type: String

  # AdmissionStage
  field :admission_stage, type: String, default: 'pre_admission'

  # Specialty
  field :specialty_id, type: String
  field :specialty_name, type: String

  field :is_migrated, type: Boolean, default: true

  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId

  embeds_many :admission_milestones

  def admission_type_insurance_state
    fa_insurance_state = insurance_state == 'Not Insured' ? 'fa fa-rupee' : 'fa fa-medkit'

    if admission_type == 'same_day'
      admission_type_hash = { abbr: 'SD', label: 'label label-pink' }
    elsif admission_type == 'emergency'
      admission_type_hash = { abbr: 'ER', label: 'label label-danger' }
    elsif admission_type == 'planned'
      admission_type_hash = { abbr: 'PD', label: 'label label-orange' }
    end

    admission_type_title = "#{insurance_state} - #{admission_type&.titleize}"

    [fa_insurance_state, admission_type_hash[:abbr], admission_type_hash[:label], admission_type_title]
  end
end
