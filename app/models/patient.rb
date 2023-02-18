# 2  Metrics/AbcSize
# 2  Metrics/CyclomaticComplexity
# 2  Metrics/PerceivedComplexity
# 1  Metrics/ClassLength
# 1  Metrics/MethodLength
# --
# 8  Total
class Patient
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include MethodMissing
  extend Enumerize

  # include Mongoid::Paranoia

  after_create :generate_patient_identifiers
  after_update :update_appointment_views, :admission_list_view, :ot_list_view, :update_mobilenumber_for_sms,
               if: ->(obj) { patient_attributes_changed(obj) }
  after_update :delete_comment
  # Name
  field :salutation, type: String
  field :fullname, type: String
  field :firstname, type: String
  field :middlename, type: String
  field :lastname, type: String

  # Gender/Age
  field :gender, type: String
  field :age, type: Integer
  field :age_month, type: Integer
  field :exact_age, type: String
  field :displayage, type: Integer
  field :dob, type: Date
  field :dob_day, type: String
  field :dob_month, type: String
  field :dob_year, type: String
  field :is_approx_dob, type: Boolean

  # Contact Info
  field :county_code_mobile, type: String
  field :county_flag_mobile, type: String
  field :mobilenumber, type: String
  field :county_flag_whatsapp, type: String
  field :county_code_whatsapp, type: String
  field :whatsappnumber, type: String
  field :secondarymobilenumber, type: String
  field :contactnumber, type: String
  field :email, type: String
  field :same_as_mobilenumber, type: Boolean

  # Address
  field :address_1, type: String
  field :address_2, type: String
  field :district, type: String
  field :commune, type: String
  field :city, type: String
  field :state, type: String
  field :pincode, type: Integer
  # area fields
  field :location_id, type: BSON::ObjectId
  field :area_manager_id, type: BSON::ObjectId
  field :area_manager_name, type: String

  # Language
  field :primary_language, type: String
  field :secondary_language, type: String

  # Blood Group
  field :blood_group, type: String

  # Emergency Details
  field :emergencycontactname, type: String
  field :emergencymobilenumber, type: String
  field :emergency_relation, type: String

  # Relative Details
  field :relative_name, type: String
  field :relative_relation, type: Integer # Father, Mother

  # Other Info
  field :one_eyed, type: String
  field :maritalstatus, type: String
  field :specialstatus, type: String

  # Occupation Details
  field :occupation, type: String
  field :employee_id, type: String

  # Registered Info
  field :reg_status, type: Boolean, default: false
  field :reg_date, type: Date
  field :reg_time, type: Time
  field :reg_hosp_ids, type: Array
  field :reg_facility_id, type: String

  # Ids
  # India
  field :pan_number, type: String
  field :driving_license_number, type: String
  field :aadhar_card_number, type: String
  field :health_id_number, type: String
  field :gst_number, type: String

  # Vietnam
  field :social_security_number, type: String

  #Cambodia
  field :diff_wearing_glasses, type: String
  field :diff_hearing_aid, type: String
  field :diff_walking_climbing, type: String
  field :diff_remembring_concentrating, type: String
  field :diff_selfcare, type: String
  field :diff_communicate, type: String

  # Type Comment
  field :patient_type_comment, type: String
  field :patient_type_info, type: String

  field :opd_visit_count, type: Integer, default: 0

  # STATE MACHINE RUBY GEM VARIABLE AND NOT PART OF PATIENT PROFILE OR PATIENT OBJECT.
  # REFER STATE MACHINE GEM ON GITHUB FOR MORE INFO. STATE MACHINE IS STILL NOT IMPLEMENTED IN HG CODE.
  field :current_state, type: String

  # Rating
  field :rating, type: Float

  # ophthalmic slect
  field :speciality_histories, type: String
  field :personal_histories, type: String
  field :antimicrobial_agents, type: String
  field :drug_allergies, type: String
  field :drug_allergies_comment, type: String
  field :antifungal_agents, type: String
  field :antiviral_agents, type: String
  field :nsaids, type: String
  field :eye_drops, type: String
  field :contact_allergies, type: String
  field :contact_allergies_comment, type: String
  field :food_allergies, type: String
  field :food_allergies_comment, type: String

  #Paediatrics History
  field :nutritional_assessment, type: String
  field :nutritional_assessment_comment, type: String
  field :immunization_assessment, type: String
  field :immunization_assessment_comment, type: String

  #history check advised
  field :no_opthalmic_history_advised, type: Boolean, default: false
  field :no_systemic_history_advised, type: Boolean, default: false
  field :no_allergy_advised, type: Boolean, default: false

  field :is_migrated, type: Boolean, default: true
  field :case_sheet_order_migrated, type: Boolean, default: true
  field :camp_patient_identifier, type: String
  field :camp_patient_id, type: BSON::ObjectId
  # end
  # SPACING LEFT INTENTIONALLY. ----------------------------------------------------

  enumerize :relative_relation, in: { Mother: 0, Father: 1, Son: 2, Daughter: 3, Husband: 4, Wife: 5, Brother: 6, Sister: 7 }, predicates: true

  # ASSOCIATIONS DEFINE HERE.
  has_many :appointments
  has_many :insurances, class_name: '::PatientInsurance'
  has_many :invoices
  has_many :inventory_order, class_name: '::Invoice::InventoryOrder'
  has_many :admissions
  has_many :patientassets
  has_many :patient_identifiers
  has_one :patient_history
  embeds_many :patientemergencycontact, class_name: '::PatientEmergencyContact' # patientfamilyhistory
  has_many :patient_certificates
  has_many :patient_summary_asset_uploads
  has_many :opd_record_identifiers
  has_one :patient_registration_source
  belongs_to :referring_doctor, optional: true
  has_many :patient_management_followups
  belongs_to :patient_type, optional: true
  belongs_to :country, optional: true

  accepts_nested_attributes_for :invoices
  accepts_nested_attributes_for :appointments
  # accepts_nested_attributes_for :admissions
  accepts_nested_attributes_for :patient_history
  accepts_nested_attributes_for :patientemergencycontact # patientemergencycontact   # reject_if: :all_blank
  accepts_nested_attributes_for :patientassets
  accepts_nested_attributes_for :patient_registration_source
  # accepts_nested_attributes_for :referring_doctor

  # embeds of histories
  embeds_many :allergy_histories, class_name: '::AllergyHistory', cascade_callbacks: true
  embeds_many :personal_history_records, class_name: '::PersonalHistoryRecord', cascade_callbacks: true
  embeds_many :speciality_history_records, class_name: '::SpecialityHistoryRecord', cascade_callbacks: true
  embeds_one :other_history, class_name: '::OtherHistory', inverse_of: :project, autobuild: true, cascade_callbacks: true
  embeds_one :lens_history, class_name: '::LensHistory', inverse_of: :project, autobuild: true, cascade_callbacks: true
  embeds_one :paediatrics_history, class_name: '::PaediatricsHistory', autobuild: true, cascade_callbacks: true
  # end

  # vital_signs
  embeds_many :patient_vitals, class_name: '::PatientVital', cascade_callbacks: true
  # end
  # nested_attributes
  accepts_nested_attributes_for :personal_history_records, allow_destroy: true
  accepts_nested_attributes_for :speciality_history_records, allow_destroy: true
  accepts_nested_attributes_for :allergy_histories, allow_destroy: true
  accepts_nested_attributes_for :other_history, allow_destroy: true
  accepts_nested_attributes_for :lens_history, allow_destroy: true
  accepts_nested_attributes_for :paediatrics_history, allow_destroy: true
  # end

  # serialize :data, JSON

  has_many :patient_diagnoses
  has_many :patient_medications
  has_many :patient_prescriptions
  has_many :patient_investigations
  has_many :patient_radiology_investigations
  has_many :patient_laboratory_investigations
  has_many :patient_other_investigations
  has_many :patient_procedures
  has_many :patient_timelines

  index({ fullname: 1 }, background: true)

  validates :firstname, presence: { message: 'First Name cant be blank' }
  validates :mobilenumber, presence: { message: 'Mobile number cannot be blank' },
                           format: { with: /(?:\+?|\b)[0-9]\b/, message: 'Mobile number is invalid' }

  def delete_comment; end

  BLOODGROUPS = ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'].freeze
  HISTORYYESNO = [['No', '373067005'], ['Yes', '373066001']].freeze

  state_machine :current_state, initial: :appointment do
    event :admit do
      transition appointment: :admission
    end

    event :consult_radiology do
      transition appointment: :radiology
    end
  end
  # def initialize
  #   super() #to initialize the states
  # end

  # after_save {
  #   # self.create_patient_search
  #   self.admission_list_view
  #   self.ot_list_view
  # }

  def patient_identifier_id
    @patient_identifier_id = PatientIdentifier.find_by(patient_id: id).try(:patient_org_id)
  end

  def patient_mrn
    @patient_mrn = PatientOtherIdentifier.find_by(patient_id: id).try(:mr_no)
  end

  def patient_age_gender
    age = calculate_age.to_s
    gender = self.gender.to_s

    (age.present? ? age : '-') + ' / ' + (gender.present? ? gender : '-') # return
  end

  def patient_full_address
    if address_1.present? || address_2.present? || city.present? || state.present? || pincode.present? || commune.present? || district.present?
      full_address = address_1.to_s
      full_address += ((", #{address_2}" if address_1.present? && address_2.present?) || address_2.to_s)
      full_address += ((", #{district}" if full_address.present? && district.present?) || district.to_s)
      full_address += ((", #{commune}" if commune.present? && commune.present?) || commune.to_s)
      full_address += ((", #{city}" if full_address.present? && city.present?) || city.to_s)
      full_address += ((", #{state}" if full_address.present? && state.present?) || state.to_s)
      full_address += (("  #{pincode}" if full_address.present? && pincode.present?) || pincode.to_s)
      @full_address = full_address
    else
      @full_address = nil
    end
  end

  def emergency_contact
    return if emergencycontactname.nil? && emergencymobilenumber.nil?

    relation = emergency_relation.present? ? "(#{emergency_relation})" : ''
    contact_number = if emergencymobilenumber.present?
                       emergencycontactname.present? ? " - #{emergencymobilenumber}" : emergencymobilenumber
                     else
                       ''
                     end

    "#{emergencycontactname} #{relation}  #{contact_number}".strip # return
  end

  def get_exact_age(year, month)
    if year > 0
      @exact_age = if month > 0
                     year.to_s + ' ' + 'Year'.pluralize(year) + '-' + month.to_s + ' ' + 'Month'.pluralize(month)
                   else
                     year.to_s + ' ' + 'Year'.pluralize(year)
                   end
    elsif month > 0
      @exact_age = month.to_s + ' ' + 'Month'.pluralize(month)
    end
    update(exact_age: @exact_age)
  end

  def get_foodallergies_list_attribute(food = nil)
    Global.send('ehrcommon').send(food.to_sym).map do |foodallergies|
      foodallergies.map.with_index { |foodallergieshash, _foodallergiesindex| foodallergieshash[1] }
    end
  end

  def get_contactallergies_list_attribute(contact = nil)
    Global.send('ehrcommon').send(contact.to_sym).map do |contactallergies|
      contactallergies.map.with_index { |contactallergieshash, _contactallergiesindex| contactallergieshash[1] }
    end
  end

  def get_drugallergies_list_attribute(drug = nil)
    Global.send('ehrcommon').send(drug.to_sym).map do |drugallergies|
      drugallergies.map.with_index { |drugallergieshash, _drugallergiesindex| drugallergieshash[1] }
    end
  end

  def get_historydisorders_list_attribute(disorder = nil)
    Global.send('ehrcommon').send(disorder.to_sym).map do |historydisorder|
      historydisorder.map.with_index { |historydisorderhash, _historydisorderindex| historydisorderhash[1] }
    end
  end

  def checkboxes_checked(checked)
    checked&.split(',')
  end

  def get_label_for_allergy(drugallergy, allergyid)
    allergynametext = ''
    Global.send('ehrcommon').send(drugallergy.to_sym).each do |allergy|
      allergynametext = allergy['allergyname'] if allergy['allergysnomedid'].to_s == allergyid.to_s
    end
    allergynametext
  end

  def get_label_for_problem(historydisorders, problemid)
    problemnametext = ''
    Global.send('ehrcommon').send(historydisorders.to_sym).each do |problem|
      problemnametext = problem['problemname'] if problem['problemsnomedid'].to_i == problemid.to_i
    end
    problemnametext
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << column_names
      all.each do |patient|
        csv << patient.attributes.values_at(*column_names)
      end
    end
  end

  def generate_patient_identifiers
    # create_patient_iden(self)
    create_patient_birthday(self) if dob.present?
    # model method for exact_age
    # self.get_exact_age(self.age.to_i, self.age_month.to_i)
  end

  def create_patient_birthday(patient)
    patient_birthday = PatientBirthday.find_by(patient_id: patient.id)
    if patient_birthday
      patient_birthday.update(dob: patient.dob.strftime('%d%m'))
    else
      PatientBirthday.create(patient_id: patient.id, dob: patient.dob.strftime('%d%m'))
    end
  end

  # update old appointment and coulsellor
  def update_appointment_views
    # Job to update opd workflow view
    PatientJobs::UpdateViewJob.perform_later('workflow_list', id.to_s)
    # Job to update non workflow view
    PatientJobs::UpdateViewJob.perform_later('non_workflow_list', id.to_s)
    # Job to update counsellor view
    PatientJobs::UpdateViewJob.perform_later('counsellor_list', id.to_s)
  end

  # Update Old Admissions and Ot View with patient details
  def admission_list_view
    PatientJobs::UpdateViewJob.perform_later('admission_list', id.to_s)
  end

  def ot_list_view
    PatientJobs::UpdateViewJob.perform_later('ot_list', id.to_s)
  end

  def update_mobilenumber_for_sms
    smsinqueue = SmsInQueue.find_by(recipient_id: id.to_s, recipient_type: 'patient')
    return unless smsinqueue

    smsinqueue.update(recipient_mobilenumber: mobilenumber, recipient_name: fullname)
    smsinqueue.sms_dispatch&.update(mobilenumber: mobilenumber)
  end

  def patient_attributes_changed(obj)
    obj.mobilenumber_changed? || obj.fullname_changed? || obj.exact_age_changed? ||
      obj.gender_changed? || obj.patient_type_id_changed? || obj.city_changed? || obj.commune_changed? ||
      obj.pincode_changed? || obj.district_changed? || obj.state_changed? || obj.mobilenumber_changed? ||
      obj.age_changed?
  end

  def calculate_age(form = false)
    if dob_year.present?
      now = Date.current
      month_logic = (now.month > dob_month.to_i || (now.month == dob_month.to_i && now.day >= dob_day.to_i) ? 0 : 1)
      year = now.year - dob_year.to_i - month_logic
      month = now.month - dob_month.to_i
      day = now.day - dob_day.to_i

      if month == 0 && day < 0
        month = 11
      else
        month += 12 if month < 0
        month -= 1 if day < 0 && month != 0
      end
      # month += 12 if month < 0
      # month -= 1 if day < 0 && month != 0
      # month = 11 if day < 0 && month == 0
      age = if month == 0
              if year == 0
                month.to_s + (month.to_i > 1 ? ' Months ' : ' Month ')
              else
                year.to_s + (year.to_i > 1 ? ' Years ' : ' Year ')
              end
            elsif year <= 0
              month.to_s + (month.to_i > 1 ? ' Months ' : ' Month ')
            else
              year.to_s + (year.to_i > 1 ? ' Years ' : ' Year ') + month.to_s + (month.to_i > 1 ? ' Months' : ' Month')
            end
    end
    form ? [year, month] : age
  end

  def full_name
    self.fullname.gsub("`", '')
  end

  def history_present?
    speciality_history_records.count > 0 || personal_history_records.count > 0 || history_comments_present?
  end

  def history_comments_present?
    opthal_history_comment.present? || history_comment.present? ||
      other_history.medical_history.present? || other_history.family_history.present? ||
      (other_history.specialstatus.present? && other_history.specialstatus != 'None')
  end

  def allergy_present?
    allergy_histories.present? || others_allergies.present? || drug_allergies_comment.present? ||
      contact_allergies_comment.present? || food_allergies_comment.present?
  end
end
