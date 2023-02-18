class UserJobs::ResendConfirmationMailJob < ActiveJob::Base
  queue_as :urgent

  def perform(user_id)
    user = User.find_by(id: user_id)

    if user.present?
      UserMailer.activate_user_account(user).deliver_now
    end
  end
end
