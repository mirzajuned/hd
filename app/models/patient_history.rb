class PatientHistory
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  belongs_to :patient

  embeds_one :patientallergyhistory, class_name: "::PatientAllergyHistory" # patientallergyhistory
  embeds_one :patientpersonalhistory, class_name: "::PatientPersonalHistory" # patientpersonalhistory
  embeds_one :patientfamilyhistory, class_name: "::PatientFamilyHistory" # patientfamilyhistory

  accepts_nested_attributes_for :patientallergyhistory # patientallergyhistory   # reject_if: :all_blank
  accepts_nested_attributes_for :patientpersonalhistory # patientpersonalhistory   # reject_if: :all_blank
  accepts_nested_attributes_for :patientfamilyhistory # patientfamilyhistory   # reject_if: :all_blank

  def initialize_nested_objects
    1.times do
      self.build_patientallergyhistory
      self.build_patientpersonalhistory
      self.build_patientfamilyhistory
    end
    # 2.times do
    #   self.patientemergencycontact_build
    # end
  end
end
