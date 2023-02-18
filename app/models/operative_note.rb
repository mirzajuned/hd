class OperativeNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :template_type, type: String, default: "Operative Note"
  field :template_id, type: String, default: "448826009"
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
  field :note_created_at, type: Time, default: Time.current
  field :surgerytype, type: String
  field :anesthesia, type: String
  field :complication, type: String
  field :complication_add_by, type: String
  field :complication_update_by, type: String
  field :procedure_note, type: String
  field :patient_entry_time, type: Time
  field :patient_exit_time, type: Time
  field :anesthesia_start_time, type: Time
  field :anesthesia_end_time, type: Time
  field :surgery_start_time, type: Time
  field :surgery_end_time, type: Time
  field :patient_position, type: String
  field :position_aid, type: String
  field :bed_attachments, type: String
  field :other_equipments, type: String
  field :skin_preparation, type: String
  field :theatre_diathermy, type: String
  field :diathermy_type, type: String
  field :diathermy_plate_site, type: String
  field :diathermy_applier, type: String
  field :theatre_tourniquet, type: String
  field :tourniquet_site, type: String
  field :tourniquet_pressure, type: String
  field :tourniquet_time, type: String
  field :theatre_biopsy, type: String
  field :biopsy_type, type: String
  field :biopsy_tests, type: String
  field :catheters_insitu, type: String
  field :closure, type: String
  field :theatre_comments, type: String
  field :correct_patient, type: String
  field :correct_procedure, type: String
  field :before_induction_valid_consent, type: String
  field :site_marked, type: String
  field :anesthesia_machine, type: String
  field :tourniquet_drills_suction, type: String
  field :implants_checked, type: String
  field :patient_allergy, type: String
  field :difficult_airway, type: String
  field :confirm_team_listed, type: String
  field :patient_checked, type: String
  field :valid_consent, type: String
  field :procedure_checked, type: String
  field :site_checked_and_marked, type: String
  field :imaging_checked, type: String
  field :antibiotic_prophylaxis_given, type: String
  field :xray_safety_check, type: String
  field :otchecklist_comments, type: String
  field :ot_note_procedures, type: Array, default: []
  field :devices, type: Array, default: []
  field :device_comment, type: String
  # consumable
  field :iol, type: String
  field :theatre_name, type: String
  field :theatre_section, type: String
  field :case_no, type: String
  field :site, type: String
  field :capsulotomy, type: String
  field :iridectomy, type: String

  field :bill_of_material_id, type: BSON::ObjectId

  embeds_one :advice
  embeds_many :record_histories
  embeds_many :inventorymedication, class_name: "::Inpatient::InventoryMedication"
  embeds_many :inventoryconsumables, class_name: "::Inpatient::InventoryConsumable"
  embeds_many :inventorypack, class_name: "::Inpatient::InventoryPack"
  embeds_many :inventoryprep, class_name: "::Inpatient::InventoryPrep"
  embeds_many :inventorydressings, class_name: "::Inpatient::InventoryDressing"
  embeds_many :inventoryinstrument, class_name: "::Inpatient::InventoryInstrument"
  embeds_many :inventoryimplants, class_name: "::Inpatient::InventoryImplant"
  embeds_many :inventoryswabs, class_name: "::Inpatient::InventorySwab"
  embedded_in :ipd_record, class_name: "::Inpatient::IpdRecord"

  accepts_nested_attributes_for :advice # reject_if: :all_blank  #advice
  accepts_nested_attributes_for :inventorymedication, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :inventoryconsumables, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :inventorypack, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :inventoryprep, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :inventorydressings, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :inventoryinstrument, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :inventoryimplants, reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :inventoryswabs, class_name: "::Inpatient::InventorySwab", reject_if: proc { |attributes| attributes['name'].blank? }, allow_destroy: true

  after_save {
    add_personnel
  }

  def checkboxes_checked(checked)
    checked&.split(',')
  end

  def procedures
    @ipdrecord = self.ipd_record
    @procedure = @ipdrecord.procedure.where(operative_note_id: self.id)
  end

  def add_personnel
    @user = User.find_by(id: self.user_id)
    personnels = ["surgeon1", "surgeon2", "surgeon3", "surgeon_assistant1", "surgeon_assistant2", "surgeon_assistant3", "anaesthetist1", "anaesthetist2", "anaesthetist3", "anesthetic_assistant1", "anesthetic_assistant2", "anesthetic_assistant3", "circulating_nurse1", "circulating_nurse2", "circulating_nurse3", "scrub_nurse1", "scrub_nurse2", "scrub_nurse3", "other_staff1", "other_staff2", "other_staff3"]

    personnels.each do |personnel|
      unless eval("self.read_attribute(:" + personnel + ")") == ""
        find_personnel = Inpatient::SurgeryPersonnel.find_by(name: eval("self.read_attribute(:" + personnel + ")"), :specialty_id => self._parent.specialty_id, :organisation_id => @user.try(:organisation_id).to_s)
        unless find_personnel
          Inpatient::SurgeryPersonnel.create(name: eval("self.read_attribute(:" + personnel + ")"), :specialty_id => self._parent.specialty_id, :organisation_id => @user.try(:organisation_id).to_s, facility_id: self._parent.facility_id)
        end
      end
    end
  end
end
