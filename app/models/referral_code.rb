class ReferralCode
  include Mongoid::Document
  include Mongoid::Timestamps

  field :code, type: String
  field :new_users_limit, type: Integer # Limit for no. of Users that can be Added
  field :referring_user, type: String # Referral Code User
  field :free_trial_period, type: Integer # days # Free trial period
  field :code_expiry_date, type: Date # Expire Code
  field :code_release_date, type: Date

  # No. of User who can use this code
  field :use_count, type: Integer, default: 0
  field :use_limit, type: Integer, default: 10000

  field :organisation_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId

  validates_uniqueness_of :code

  def success_message(code = nil)
    @message = 'Referral Code Applied Succesfully.Enjoy Your ' + self.free_trial_period.to_s + ' Days Free Trial.'
    @color = "#1CAF9A"

    return @message, @color
  end

  def failure_message(code = nil)
    @message = "Sorry! Referral Code Expired."
    @color = "#d9534f"

    return @message, @color
  end
end
