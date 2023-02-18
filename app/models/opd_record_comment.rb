class OpdRecordComment
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :comment, type: String
  field :commentdate, type: Date, default: Date.current.strftime("%Y-%m-%d")
  field :commenttime, type: Time, default: Time.current.strftime("%I:%M %p")
  field :doctorname, type: String

  belongs_to :opd_record
  belongs_to :user

  scope :newest_comment_first, lambda { order("commenttime DESC") }
end
