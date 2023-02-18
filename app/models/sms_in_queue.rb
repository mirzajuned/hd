class SmsInQueue
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  after_create :create_dispatch_sms

  field :organisation_id, type: String
  field :facility_id, type: String
  field :sender_id, type: String # user id
  field :sender_role, type: String # user role
  field :event_id, type: String
  field :event_class, type: String
  field :recipient_id, type: String # patient id / ref doc id
  field :recipient_name, type: String # patient name / ref doc name
  field :recipient_mobilenumber, type: String # patient mobile / ref doc mobile
  field :recipient_type, type: String # patient / ref doc
  field :message_body, type: String
  field :event_name, type: String
  field :third_party_msg_id, type: String
  field :linecount, type: String
  field :billcredit, type: String
  field :sendondate, type: String
  field :delivery_status, type: String
  field :extra_info, type: String
  field :is_deleted, type: Boolean, default: false
  field :is_checked, type: Boolean, default: false
  field :is_delivered, type: Boolean, default: false
  field :deliverydate, type: Date
  field :deliverytime, type: Time

  has_one :sms_dispatch
  index({ event_id: 1 }, { unique: true })

  def create_dispatch_sms
    @dispatch_sms = SmsDispatch.find_by(sms_in_queue_id: self.id)
    unless @dispatch_sms
      @dispatch_sms = SmsDispatch.new
      @dispatch_sms.sms_in_queue_id = self.id
      @dispatch_sms.sms_body = self.message_body
      @dispatch_sms.mobilenumber = self.recipient_mobilenumber
      @dispatch_sms.deliverydate = self.deliverydate
      @dispatch_sms.deliverytime = self.deliverytime
      @dispatch_sms.save
    end
  end
end
