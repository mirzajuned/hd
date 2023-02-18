class PatientSelfHistory
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  belongs_to :patient

  # embeds_one :patientallergyhistory, class_name: "::PatientAllergyHistory"  #patientallergyhistory
  # embeds_one :patientpersonalhistory, class_name: "::PatientPersonalHistory"  #patientpersonalhistory
  # embeds_one :patientfamilyhistory, class_name: "::PatientFamilyHistory"  #patientfamilyhistory

  # new history
  embeds_many :allergy_histories, class_name: "::AllergyHistory", cascade_callbacks: true
  embeds_many :personal_history_records, class_name: "::PersonalHistoryRecord", cascade_callbacks: true
  embeds_many :speciality_history_records, class_name: "::SpecialityHistoryRecord", cascade_callbacks: true
  embeds_many :chief_complaints, class_name: "::ChiefComplaint", inverse_of: :project, cascade_callbacks: true
  embeds_one :other_history, class_name: "::OtherHistory", inverse_of: :project, autobuild: true, cascade_callbacks: true

  accepts_nested_attributes_for :personal_history_records, allow_destroy: true
  accepts_nested_attributes_for :speciality_history_records, allow_destroy: true
  accepts_nested_attributes_for :allergy_histories, allow_destroy: true
  accepts_nested_attributes_for :chief_complaints, allow_destroy: true
  accepts_nested_attributes_for :other_history, allow_destroy: true

  # accepts_nested_attributes_for :patientallergyhistory    #patientallergyhistory   # reject_if: :all_blank
  # accepts_nested_attributes_for :patientpersonalhistory    #patientpersonalhistory   # reject_if: :all_blank
  # accepts_nested_attributes_for :patientfamilyhistory    #patientfamilyhistory   # reject_if: :all_blank

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
