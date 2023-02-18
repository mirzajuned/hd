class PayerMaster
  include Mongoid::Document
  include Mongoid::Timestamps

  # Payer Info
  # field :payer_type, type: String #eg Insurance, TPA, Panel
  field :payer_type_id, type: String
  field :tpa_insurer_type_id, type: String
  field :patient_payer_data_details, type: String

  # Primary Contact
  field :display_name, type: String
  field :salutation, type: String
  field :first_name, type: String
  field :middle_name, type: String
  field :last_name, type: String
  field :contact_type, type: String
  field :provided_by, type: String

  # Company Details
  field :company_name, type: String
  field :abbreviation, type: String
  field :designation, type: String
  field :department, type: String
  field :website, type: String

  # Contact
  field :contact_group_id, type: BSON::ObjectId
  field :contact_group_name, type: String
  field :mobile_number, type: Integer
  field :work_number, type: Integer
  field :email, type: String

  # Address
  field :address_line_1, type: String
  field :address_line_2, type: String
  field :city, type: String
  field :state, type: String
  field :country, type: String
  field :pincode, type: Integer
  field :commune, type: String
  field :district, type: String

  # Tariff Fields
  field :mou_date, type: Date
  field :tariff_start_date, type: Date
  field :tariff_end_date, type: Date
  field :tariff_revised_date, type: Date
  field :mou_information, type: String
  field :tariff_comment, type: String

  field :payer_uniq_id, type: String

  field :is_active, type: Boolean, default: true

  # Reference
  field :user_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  # Validation
  validates :display_name, presence: true
  validates :contact_group_id, presence: true
  validates :user_id, presence: true
  validates :facility_id, presence: true
  validates :organisation_id, presence: true

  belongs_to :contact_group

  before_save :set_payer_uniq_id

  def set_payer_uniq_id
    self.payer_uniq_id ||= SecureRandom.hex(5)
  end

  def checkboxes_checked(checked)
    checked&.split(',')
  end

end
