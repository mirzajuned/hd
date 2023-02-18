class UserJobs::CreateJob < ActiveJob::Base
  queue_as :urgent

  def perform(user_id)
    user = User.find_by(id: user_id)

    if user.present?

      # Create UsersSetting
      users_setting = UsersSetting.create(organisation_id: user.organisation_id, user_id: user.id, visit_sms_schedule: '0', followup_sms_schedule: '0', long_overdue_sms_schedule: '0')

      # Create AppointmentType
      AppointmentType.create([
                                 { label: "Fresh", duration: 10, background: "#3071a9", is_active: true, is_default: true, user_id: user.id },
                                 { label: "Followup", duration: 5, background: "#274E13", is_active: true, is_default: false, user_id: user.id }
                             ])


      # Signup Mail
      begin
        UserMailer.activate_user_account(user).deliver_now
      rescue
        #email error
      end


    end
  end
end
