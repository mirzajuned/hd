class OpticalMailer < ActionMailer::Base
  default from: Global.send('default_email_address').try('email_address')

  # noreply-accountactivity@accounts.google.com -- Google Dashboard: Your Account Activity
  # no-reply@accounts.google.com -- Google Account password changed, Google Billing: Verify your email address
  # billing-noreply@google.com -- Google Billing

  def customer_notification(email_body, email_id)
    @email_body = email_body
    mail to: email_id, subject: 'Order Ready'
  end
end
