class PatientType
  include Mongoid::Document
  include Mongoid::Timestamps

  field :label, type: String
  field :color, type: String
  field :is_active, type: Boolean, default: true
  field :is_default, type: Boolean, default: false

  belongs_to :organisation

  validates_presence_of :label, :color
end
