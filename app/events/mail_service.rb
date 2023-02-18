class MailService
  def self.handle_mail_notification event
    UserMailer.send("#{event.email_type}", event.email).deliver
  end
end
