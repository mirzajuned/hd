class PatientEmergencyContact
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  include MethodMissing

  embedded_in :patienthistory, class_name: "::PatientHistory"
end
