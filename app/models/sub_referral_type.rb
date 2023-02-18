class SubReferralType
  include Mongoid::Document
  include Mongoid::Timestamps

  # All (Doctor Referral | Staff Referral | Relative | Campaign | Camp | Intitutional Referral | Agency)
  field :name, type: String
  field :comment, type: String
  field :is_active, type: Boolean, default: true
  field :is_deleted, type: Boolean, default: false

  field :facility_ids, type: Array, default: []

  # Doctor Referral
  field :speciality, type: String

  # Staff Referral
  field :designation, type: Integer

  # Relative
  field :existing_patient, type: Boolean
  field :relation, type: String

  # Campaign
  field :campaign_type, type: String

  # Camp
  field :camp_date, type: Date
  field :doctor, type: String

  # Institutional Referral
  field :department, type: String

  # Agency
  field :agency_name, type: String

  # Doctor Referral | Staff Referral | Relative
  field :email, type: String

  # Doctor Referral | Staff Referral | Relative | Agency
  field :mobile_number, type: String

  # Doctor Referral | Staff Referral | Camp | Institutional Referral | Agency
  field :location, type: String

  # Doctor Referral | Staff Referral | Camp | Campaign | Institutional Referral | Agency
  field :city, type: String
  field :state, type: String

  # Search
  field :search, type: String
  # for camp unique id
  field :camp_unique_id, type: String
  field :is_disabled, type: Boolean

  # Relation
  belongs_to :user
  belongs_to :referral_type
  belongs_to :organisation

  # has_and_belongs_to_many :facilities

  # Validation
  validates_presence_of :name

  # Indexes
  # db.sub_referral_types.createIndex({ referral_type_id: 1, facility_ids: 1 })
  # db.sub_referral_types.createIndex({ referral_type_id: 1, organisation_id: 1 })
end
