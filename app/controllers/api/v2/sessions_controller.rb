class Api::V2::SessionsController < ApiApplicationController
  def login
    @user = User.authenticate(params[:username], params[:password])
    user_expiry_date = @user.try(:account_expiry_date)
    if @user.present? && user_expiry_date.present? && (user_expiry_date < Date.current)
      payload = { error: 'your account is expired. Please contact admin' }
      render(json: payload, status: :unprocessable_entity) && return
    end

    if @user
      @api_key = ApiKey.new(user: @user, access_token: generate_key, expiry_time: DateTime.current + 900)
      @api_key.save!
    else
      payload = { error: 'email or password is invalid' }
      render json: payload, status: :unprocessable_entity
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def logout
    api_key = ApiKey.find_by(access_token: request.headers['Token'])
    raise StandardError, 'User not found' if api_key.blank?

    api_key.destroy!
    render json: { message: 'Succesfully logged out' }, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def generate_key
    SecureRandom.hex
  end
end
