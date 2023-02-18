class AdverseEventJobs::SendMailAdverseEventJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    @adverse_event_id = args[0]
    @current_user = args[1]
    @adverse_event = AdverseEvent.find_by(id: @adverse_event_id)
    if @adverse_event_id.present?
      @recipients = AdverseEventsMailSetting.where(organisation_id: @adverse_event.organisation_id, send_mail: true, is_removed: false)
      if @recipients.present?
        AdverseEvents::SendMailAdverseEventService.call(@adverse_event_id, @current_user)
      end
    end
  end
end
