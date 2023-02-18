class SmsDispatch
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :deliverydate, type: Date
  field :deliverytime, type: Time
  field :sms_body, type: String
  field :extra_info, type: String
  field :mobilenumber, type: String
  field :delivery_status, type: String
  field :linecount, type: String
  field :billcredit, type: String
  field :sendondate, type: String
  field :third_party_msg_id, type: String
  field :is_deleted, type: Boolean, default: false
  field :resend_count, type: Integer, default: 0

  belongs_to :sms_in_queue
end
