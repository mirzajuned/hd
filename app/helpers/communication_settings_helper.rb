module CommunicationSettingsHelper

  def get_facility_list(cm_setting)
    Facility.where(organisation_id: current_organisation["_id"]).in(id: cm_setting.facility_ids).pluck(:display_name).join(', ')
  end

  def get_communication_template_titles(cm_setting)
    CommunicationTemplate.where(organisation_id: current_organisation["_id"]).in(id: cm_setting.communication_template_ids).pluck(:template_title).join(', ')
  end

  def get_event_type_details(event)
    if event.try(:event_type) == 'reminder'
      return event.try(:reminder_type).try(:titleize) + ',' + event.try(:event_reminder_time).try(:titleize) if event.try(:event_reminder_time).try(:titleize).present? && event.try(:reminder_type).try(:titleize).present?
      return event.try(:event_reminder_time).try(:titleize) if event.try(:event_reminder_time).try(:titleize).present? && event.try(:reminder_type).try(:titleize).nil?
      return event.try(:reminder_type).try(:titleize) if event.try(:reminder_type).try(:titleize).present? && event.try(:event_reminder_time).try(:titleize).nil?
    else
      event.try(:event_confirmation_time).try(:titleize) || 'Instantly'
    end
  end
end
