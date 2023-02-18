class PasswordReset
  attr_reader :user
  attr_reader :errors

  def initialize(user)
    @user = user
  end

  def self.errors
    @errors = ActiveModel::Errors.new(self)
  end

  def self.user_verification(options)
    if (User.where(email: options[:emailaddress], username: options[:username]).exists?)
      new User.find_by(username: options[:username])
    end
  end

  def self.from_username(username)
    new User.find_by(username: username)
  end

  def self.from_token(token)
    new User.find_by(password_reset_token: token)
  end

  def send_email
    generate_token
    user.password_reset_sent_at = Time.zone.now
    user.save!
  end

  def self.validate_password(params)
    q1_flag, q2_flag = false
    password_secret1 = Passwordsecret.find_by_id(params["question1"])
    password_secret2 = Passwordsecret.find_by_id(params["question2"])
    if (params["anwser1"].downcase == password_secret1.answer)
      q1_flag = true
    end

    if (params["anwser2"].downcase == password_secret2.answer)
      q2_flag = true
    end

    if (q1_flag && q2_flag)
      return true
    else
      return false
    end
  end

  def expired?
    user.password_reset_sent_at.present? && user.password_reset_sent_at < 2.hours.ago
  end

  private

  def generate_token
    begin
      user.password_reset_token = SecureRandom.hex
    end while User.where(password_reset_token: user.password_reset_token).exists?
  end
end
