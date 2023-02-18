class ContactGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :color, type: String
  field :is_deleted, type: Boolean, default: false
  field :payer_master_present, type: Boolean, default: false
  field :contact_group_type, type: String, default: 'non_tpa'

  has_many :contacts
  # Relation
  belongs_to :organisation, optional: true

  # Validation
  validates_uniqueness_of :name, case_sensitive: false, scope: :organisation_id
end
