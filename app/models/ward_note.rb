class WardNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :template_type, type: String, default: "Ward Note"
  field :template_id, type: String, default: "225746001"
  field :organisation_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :admission_id, type: BSON::ObjectId
  field :patient_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :doctor_id, type: BSON::ObjectId
  field :department, type: String
  field :specalityname, type: String
  field :specalityid, type: String
  field :encountertype, type: String, default: "IPD"
  field :encountertypeid, type: String, default: "440654001"
  field :note_created_at, type: Time

  embeds_many :record_histories
  embedded_in :ipd_record, class_name: "::Inpatient::IpdRecord"

  def checkboxes_checked(checked)
    checked&.split(',')
  end
end
