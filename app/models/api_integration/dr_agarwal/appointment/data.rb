class ApiIntegration::DrAgarwal::Appointment::Data
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include MethodMissing

  store_in database: 'hg_integration_development'

  # Patient
  field :first_name, type: String
  field :middle_name, type: String
  field :last_name, type: String
  field :mobile_number, type: String
  field :email, type: String
  field :age, type: Integer
  field :age_month, type: Integer
  field :gender, type: String
  field :mr_no, type: String
  field :referral_type, type: String

  # Appointment
  field :appointment_date, type: String
  field :appointment_integration_identifier, type: String # Client PrimaryKey
  field :appointment_integration_identifier_bson, type: BSON::ObjectId # HG PrimaryKey

  # User
  field :employee_id, type: String
  field :doctor_employee_id, type: String

  # Facility
  field :abbreviation, type: String

  # Received DateTime
  field :received_date, type: Date
  field :received_time, type: DateTime

  # Sent DateTime
  field :sent_date, type: Date
  field :sent_time, type: DateTime

  # Flag
  field :request_type, type: String

  # Request State
  field :method_type, type: String
  field :status, type: String
  field :status_code, type: Integer
  field :message, type: String

  field :number_of_retries, type: Integer
end
