# require 'action_mailer'
#
# ActionMailer::Base.raise_delivery_errors = true
# ActionMailer::Base.delivery_method = :smtp
# ActionMailer::Base.smtp_settings = {
#   :address => "smtp.gmail.com",
#   :port => 587,
#   :domain => "domain.com.ar",
#   :authentication => :plain,
#   :user_name => "test@domain.com.ar",
#   :password => "passw0rd",
#   :enable_starttls_auto => true
# }
# ActionMailer::Base.view_paths = File.dirname(__FILE__)
#
# class HealthCheckMailer < ActionMailer::Base
#   default from: "abc@gmail.com"
#
#   # noreply-accountactivity@accounts.google.com -- Google Dashboard: Your Account Activity
#   # no-reply@accounts.google.com -- Google Account password changed, Google Billing: Verify your email address
#   # billing-noreply@google.com -- Google Billing
#
#   def send_mail(email_body)
#     email_ids = [
#       'anoop.bajpai@healthgraph.in', 'mohit.maniar@healthgraph.in',
#       'ranjeet.raj@healthgraph.in', 'cs@healthgraph.in', 'chirag.ojha@healthgraph.in', 'somya.singhal0797@gmail.com', 'dhara.pathak@healthgraph.in', 'mashood.healthgraph@gmail.com'
#     ]
#
#     @email_body = email_body
#     mail to: email_ids, subject: ENV['RAILS_ENV'].capitalize + ' Health Check Error'
#   end
# end
