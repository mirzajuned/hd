class AdverseEvents::AddUserMailSettingService
  class << self
    def call(user, action)
      @user_id = user.id
      @organisation_id = user.organisation_id
      AdverseEventsMailSetting.create!(organisation_id: @organisation_id, user_id: @user_id, recipient_name: user.fullname, recipient_mail: user.email)
    end

  end
end