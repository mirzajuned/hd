class Api::V2::PasswordResetsController < ApiApplicationController
  def verification
    password_reset = PasswordReset.user_verification(params)
    if password_reset.try(:user)
      password_reset.send_email
      reset_token = password_reset.user.password_reset_token
      user_id =  password_reset.user.id.to_s
      UserMailer.password_reset(password_reset).deliver_now
      payload = { message: 'Verification mail sent', reset_token: reset_token, user_id: user_id }
      render json: payload, status: :ok
    else
      payload = { error: 'Given credentials not found' }
      render json: payload, status: :not_found
    end
  rescue StandardError => e
    render json: { error: e.message}, status: :unprocessable_entity
  end

  def change
    password_reset = PasswordReset.from_token(params[:reset])
    raise StandardError, 'Password reset token is invalid.' if password_reset.user.nil?
    raise StandardError, 'Password reset token has expired.' if password_reset.expired?

    user = password_reset.user
    payload = { message: 'Sucessfully initiated', user_id: user.id.to_s }
    render json: payload, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update
    user = User.find(params[:user][:id])
    raise StandardError, 'User not found' if user.blank?

    user.password = params[:user][:password]
    user.password_reset_token = ''
    user.password_reset_sent_at = ''
    user.upsert
    payload = { message: 'Password successfully changed.' }
    render json: payload, status: :ok
  rescue StandardError => e
    render json: { error: e.message, message: 'OPS SOMETHING WENT WRONG' }, status: :unprocessable_entity
  end
end
