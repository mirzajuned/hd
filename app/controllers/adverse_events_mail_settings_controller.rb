class AdverseEventsMailSettingsController < ApplicationController
  before_action :authorize

  def index
    @adverse_event_mails = AdverseEventsMailSetting.where(organisation_id: current_user.organisation_id, is_removed: false)
  end

  def new
    @adverse_event_mail = AdverseEventsMailSetting.new

    @trusted_domains = TrustedDomain.where(
      organisation_id: current_user.organisation_id, deleted: false, disabled: false
    )
  end

  def create
    @existing_mail_setting = AdverseEventsMailSetting.where(organisation_id: params[:adverse_events_mail_setting][:organisation_id], recipient_mail: params[:adverse_events_mail_setting][:recipient_mail])
    if @existing_mail_setting.count >= 1
      @existing_mail_setting.update(send_mail: true, is_removed: false)
    else
      @adverse_event_mail = AdverseEventsMailSetting.new(adverse_event_mail_params)
      @adverse_event_mail.save!
    end
  end

  def edit_mail_setting
    @key = params[:key]
    @adverse_event_mail = AdverseEventsMailSetting.find_by(id: params[:adverse_event_mail_id])
    if @key == "send_mail"
      @adverse_event_mail.update!(send_mail: true, stop_mail: false)
    elsif @key == "stop_mail"
      @adverse_event_mail.update!(stop_mail: true, send_mail: false)
    end
  end

  def destroy
    @adverse_event_mail = AdverseEventsMailSetting.find_by(id: params[:id])
    @adverse_event_mail.update_attributes(is_removed: true)
  end

  private

  def adverse_event_mail_params
    params.require(:adverse_events_mail_setting).permit(:organisation_id, :facility_id, :user_id, :recipient_name, :recipient_mail, :stop_mail, :send_mail, :is_removed)
  end

end