class UserJobs::UserAddAdverseMailSettingJob < ActiveJob::Base
  queue_as :urgent

  def perform(user_id, action)
    user = User.find_by(id: user_id)
    @adverse_mail_setting = AdverseEventsMailSetting.where(user_id: user.id)
    if user.present?
      if action == 'update'
        if @adverse_mail_setting.count >= 1
          @adverse_mail_setting.update(send_mail: true, is_removed: false)
        else
          AdverseEvents::AddUserMailSettingService.call(user, action)
        end
      elsif action == 'destroy' && @adverse_mail_setting.count >= 1
        @adverse_mail_setting.update(is_removed: true)
      else
        AdverseEvents::AddUserMailSettingService.call(user, action)
      end
    end
  end
end