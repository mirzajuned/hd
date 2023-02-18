class Investigation::Queue
  include Mongoid::Document
  include Mongoid::Timestamps

  field :patient_name, type: String
  field :appointment_date, type: Date, default: Date.current
  field :appointment_time, type: Time, default: Time.current
  field :appointment_id, type: BSON::ObjectId # If Created Via Worker
  field :user_id, type: BSON::ObjectId
  field :investigation_type, type: String # Radiology, Ophthal, Laboratory
  field :is_deleted, type: Boolean, default: false
  field :status, type: String, default: 'pending' # pending,completed,review
  field :status_updated_at, type: Date, default: Date.current
  field :payment_taken, type: Boolean, default: false
  field :my_queue, type: Boolean, default: false
  field :speciality_id, type: String
  field :with_user, type: String
  field :with_user_role, type: String
  field :user_ids, type: Array, default: [] # this field will be used only in case of QMS
  field :previous_user_ids, type: Array, default: [] # this field will be used only in case of QMS

  belongs_to :patient, optional: true
  belongs_to :facility, optional: true
  # belongs_to :department
  belongs_to :organisation

  scope :patient_search, -> (query) { where(patient_name: /#{Regexp.escape(query)}/i) }
  scope :by_appointment_date, -> (date) { where(appointment_date: date)}
  scope :order_by_appoinment, -> { order(appointment_time: :desc) }

  class << self
    def search( date = Date.today, type, query, filter)
      data = filter == 'Active' ? all.by_appointment_date(date) : all
      data.where(is_deleted: false, investigation_type: type).patient_search(query).order_by_appoinment
    end
  end
end
