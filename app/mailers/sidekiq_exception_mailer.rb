class SidekiqExceptionMailer < ActionMailer::Base
  default from: Global.send('default_email_address').try('email_address')

  # noreply-accountactivity@accounts.google.com -- Google Dashboard: Your Account Activity
  # no-reply@accounts.google.com -- Google Account password changed, Google Billing: Verify your email address
  # billing-noreply@google.com -- Google Billing

  def send_mail(email_body)
    email_ids = ['hg.app.error@healthgraph.in']
    @email_body = email_body
    mail to: email_ids, subject: "[#{ENV['RAILS_ENV'].upcase}] Sidekiq Error"
  end
end
