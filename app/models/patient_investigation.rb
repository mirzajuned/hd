class PatientInvestigation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  field :ophthal_investigations, type: Array, default: []
  field :laboratory_investigations, type: Array, default: []
  field :radiology_investigations, type: Array, default: []
  field :encounterdate, type: DateTime
  field :doctor, type: BSON::ObjectId
  field :doctor_name, type: String
  field :investigation_type, type: String
  field :specalityname, type: String

  belongs_to :patient
  belongs_to :user
  belongs_to :facility

  # validation when all the arrays are empty, record should not be generated.
  validate :at_least_one_field

  def at_least_one_field
    if [self.ophthal_investigations, self.laboratory_investigations, self.radiology_investigations].reject(&:blank?).size == 0
      errors[:base] << ("It must have atleast one investigation.")
    end
  end
end
