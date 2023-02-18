require 'ventable'

class MailNotificationEvent
  include Ventable::Event
  attr_accessor :email, :email_type

  def initialize(email, email_type)
    @email = email
    @email_type = email_type
  end
end
