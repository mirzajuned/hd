class UserMailer < ActionMailer::Base
  default from: Global.send('default_email_address').try('email_address')

  # noreply-accountactivity@accounts.google.com -- Google Dashboard: Your Account Activity
  # no-reply@accounts.google.com -- Google Account password changed, Google Billing: Verify your email address
  # billing-noreply@google.com -- Google Billing

  def register_user(user)
    @user = user
    mail to: user.email, subject: 'User Registration Email'
  end

  def activate_user_account(user)
    @user = user
    mail to: user.email, subject: 'Activate Account - Foss EHR', bcc: org_emails(user)
  end

  def welcome_email(organisation, facility, user)
    @organisation = organisation
    @facility = facility
    @user = user
    mail to: user.email, subject: 'New Account Signup - Foss EHR', bcc: email_array
  end

  def verify_account(user)
    @user = user
    mail to: user.email, subject: 'User Verification - Foss EHR', bcc: email_array
  end

  def update_profile_user(user)
    @user = user
    mail to: user.email, subject: 'User Profile Updated'
  end

  def password_reset(email)
    @user = email.user
    mail to: @user.email, subject: 'User Password Reset - Foss EHR', bcc: org_emails(@user)
  end

  def password_reset_confirmation(user)
    @user = user
    mail to: user.email, subject: 'User Password Reset Confirmation'
  end

  def invitation(user, email)
    @user = user
    mail to: email, subject: 'Invitation'
  end

  private

  def email_array
    ['mohit.maniar@healthgraph.in', 'anoop.bajpai@healthgraph.in', 'babroo.chavan@healthgraph.in']
  end

  def org_emails(user)
    email_array + (user.organisation_settings_emails.presence || [])
  end
end
