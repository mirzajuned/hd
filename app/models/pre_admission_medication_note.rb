class PreAdmissionMedicationNote
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :name, type: String
  field :text, type: String
  field :is_active, type: Boolean, default: true
  field :level, type: String # user, facility, organisation
  field :specialty_id, type: String
  field :is_migrated, type: Boolean, default: true

  belongs_to :organisation
  belongs_to :facility
  belongs_to :user

  validates :name, :presence => { :message => 'Name Cannot Be Blank' }
end
