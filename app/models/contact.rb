class Contact
  include Mongoid::Document
  include Mongoid::Timestamps

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

  # Group
  # field :contact_group_id, type: BSON::ObjectId
  # field :contact_group_name, type: String #Insurance, Army, etc.

  # Flags
  field :for_invoice, type: Boolean, default: false
  field :for_expense, type: Boolean, default: false
  field :is_deleted, type: Boolean, default: false
  field :update_facility_contact, type: Boolean, default: true

  # Others
  field :facility_ids, type: Array, default: []
  field :organisation_id, type: BSON::ObjectId

  # Validation
  validates :display_name, presence: true
  validates :contact_group_id, presence: true
  validates :organisation_id, presence: true

  # Relations
  belongs_to :contact_group
end
