class OpdRecordAttribute
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :recordcreateduser, type: BSON::ObjectId # recordcreated date & time, use default create date and time.
  field :recordsignoffuser, type: BSON::ObjectId
  field :recordsignoffdate, type: Date
  field :recordsignofftime, type: Time
  field :recordtype, type: Integer, default: 440655000 # SNOMED code for OPD record
  field :recordstatus, type: Integer
  field :recordversion, type: String

  belongs_to :opd_record

  scope :opdPatient, ->(patientid) do
    find_by(:patient_id => patientid)
  end

  def self.setOdpRecordVersion(patientid, appointmentdate, appointmenttime)
    "#{patientid}-#{appointmentdate.strftime('%d%m%Y')}-#{appointmenttime.strftime('%I%M')}"
  end
end
