class PasswordResetsController < ApplicationController
  respond_to :js, :json, :html
  layout "loggedout"
  
  def recover
    @passowrd_reset_errors = PasswordReset.errors
    @recaptcha_site_key = ENVIRONMENT_CREDENTIALS['recaptcha']['recaptcha_site_key']
  end

  def verification
    if request.format.html?
      password_reset = PasswordReset.user_verification(params)
      if verify_recaptcha(model: password_reset.try(:user)) && password_reset.try(:user)
        password_reset.send_email
        # MailNotificationEvent.new(password_reset, "password_reset").fire!
        UserMailer.password_reset(password_reset).deliver_now
        redirect_to password_resets_password_reset_success_path
      elsif !verify_recaptcha(model: password_reset.try(:user)) && password_reset.try(:user)
        flash[:notice] = 'Please fill the Captcha'
        redirect_to password_resets_recover_path
      else
        flash[:notice] = 'Incorrect Username/Email/Please fill captcha'
        redirect_to password_resets_recover_path
      end
    else
      render :status => '401'
    end
  end

  def password_reset_success
  end

  def password_reset_failure
  end

  def change
    password_reset = PasswordReset.from_token(params[:reset])
    if password_reset.user.nil?
      redirect_to users_login_path, alert: "Password reset token is invalid."
    elsif password_reset.expired?
      redirect_to users_login_path, alert: "Password reset has expired."
    else
      @user = password_reset.user
      respond_to do |format|
        format.html { render "change" }
      end
    end
  end

  def update
    @user = User.find(params[:user][:id])
    @user.password = params[:user][:password]
    @user.password_reset_token = ''
    @user.password_reset_sent_at = ''
    @user.upsert
    if params[:user][:type].to_s == "admin_reset"
      respond_to do |format|
        format.js { render 'update.js.erb' }
      end
    else
      redirect_to users_login_path
    end
  end
end
