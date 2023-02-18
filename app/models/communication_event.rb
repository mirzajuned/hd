class CommunicationEvent
  include Mongoid::Document
  include Mongoid::Timestamps
  extend Enumerize

  field :name, type: String
  field :module_name, type: Integer
  field :feature_type, type: Integer
  field :communication_template_id, type: BSON::ObjectId
  field :message_format, type: String
  field :is_disable, type: Boolean, default: false
  field :is_deleted, type: Boolean, default: false
  field :status, type: Boolean, default: true
  field :event_type, type: Integer
  field :organisation_id, type: BSON::ObjectId
  enumerize :module_name, in: { opd: 0, ipd: 1, optical: 2, pharmacy: 3 }, predicates: true
  enumerize :event_type, in: { reminder: 0, confirmation: 1 }, predicates: true
  enumerize :feature_type, in: {
    appointment_scheduled: 0,
    appointment_cancellation: 1,
    reschedule_appointment: 2,
    patient_arrived: 3,
    mark_as_completed: 4,
    missed_appointment: 5,
    follow_up_appointment: 6,
    same_day_or_emergency: 7,
    planned_admission: 8,
    admission_rescheduled: 9,
    admission_cancelled: 10,
    discharge_message: 11,
    optical_glass_prescription_advised_patient: 12,
    optical_glass_prescription_advised_store: 13,
    optical_order_placed: 14,
    optical_fitting: 15,
    optical_ready: 16,
    optical_delivered: 17,
    optical_order_cancelled: 18,
    optical_return: 19,
    optical_bill_cancelled: 20,
    pharmacy_patient: 21,
    pharmacy_store: 22,
    pharmacy_sale_invoice: 23,
    pharmacy_bill_cancel: 24,
    pharmacy_return: 25,
    pharmacy_bill_creation: 26,
    optical_bill_creation: 27,
    pharmacy_order_placed: 28
  }, predicates: true
  field :reminder_type, type: String
  field :event_reminder_time, type: String
  field :event_reminder_days, type: String
  field :event_reminder_hour, type: String
  field :confirmation_type, type: String
  field :event_confirmation_time, type: String
  field :event_confirmation_days, type: String
  field :trigger_instantly, type: Boolean, default: false
  # scope :active, -> { where(is_deleted: false) }
  belongs_to :communication_template
  field :template_disabled_status, type: Boolean, default: false
  field :number_disabled_status, type: Boolean, default: false
end
