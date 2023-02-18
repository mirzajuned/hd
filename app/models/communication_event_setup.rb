class CommunicationEventSetup
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Enumerize

  field :module_name, type: Integer
  field :feature_type, type: Integer
  field :facility_id, type: BSON::ObjectId
  field :is_disable, type: Boolean, default: false
  field :organisation_id, type: BSON::ObjectId
  enumerize :module_name, in: { opd: 0, ipd: 1, optical: 2, pharmacy: 3 }, predicates: true
  enumerize :feature_type, in: { appointment_scheduled: 0, patient_arrived: 1 }, predicates: true
  enumerize :feature_type, in: {
    appointment_scheduled: 0, patient_arrived: 1, appointment_cancellation: 2
  }, predicates: true
  belongs_to :facility
end
