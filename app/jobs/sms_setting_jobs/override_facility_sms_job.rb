class SmsSettingJobs::OverrideFacilitySmsJob < ActiveJob::Base
  queue_as :urgent
  def perform(user_id)
    sms_logger = Logger.new("#{Rails.root}/log/sms_logger.log")
    user = User.find_by(id: user_id)
    organisation_id = user.try(:organisation).try(:id)
    organisation_settings = OrganisationsSetting.find_by(organisation_id: organisation_id)
    facilities = Facility.where(organisation_id: organisation_id).pluck(:id)
    facility_settings = FacilitySetting.where(:facility_id.in => facilities)
    if facility_settings.present?
      facility_settings.each do |fac_setting|
        fac_setting.sms_feature = organisation_settings.try(:sms_feature)

        fac_setting.followup_sms_text = organisation_settings.try(:followup_sms_text)
        fac_setting.followup_sms_time = organisation_settings.try(:followup_sms_time)
        fac_setting.followup_sms_schedule = organisation_settings.try(:followup_sms_schedule)
        fac_setting.followup_sms_active_inactive = organisation_settings.try(:followup_sms_active_inactive)

        fac_setting.long_overdue_sms_text = organisation_settings.try(:long_overdue_sms_text)
        fac_setting.long_overdue_sms_time = organisation_settings.try(:long_overdue_sms_time)
        fac_setting.long_overdue_sms_schedule = organisation_settings.try(:long_overdue_sms_schedule)
        fac_setting.long_overdue_sms_active_inactive = organisation_settings.try(:long_overdue_sms_active_inactive)

        fac_setting.birthday_sms_text = organisation_settings.try(:birthday_sms_text)
        fac_setting.birthday_sms_time = organisation_settings.try(:birthday_sms_time)
        fac_setting.birthday_sms_schedule = organisation_settings.try(:birthday_sms_schedule)
        fac_setting.birthday_sms_active_inactive = organisation_settings.try(:birthday_sms_active_inactive)

        fac_setting.appointment_sms_text = organisation_settings.try(:appointment_sms_text)
        fac_setting.appointment_sms_time = organisation_settings.try(:appointment_sms_time)
        fac_setting.appointment_sms_schedule = organisation_settings.try(:appointment_sms_schedule)
        fac_setting.appointment_sms_active_inactive = organisation_settings.try(:appointment_sms_active_inactive)

        fac_setting.missed_sms_text = organisation_settings.try(:missed_sms_text)
        fac_setting.missed_sms_time = organisation_settings.try(:missed_sms_time)
        fac_setting.missed_sms_schedule = organisation_settings.try(:missed_sms_schedule)
        fac_setting.missed_sms_active_inactive = organisation_settings.try(:missed_sms_active_inactive)

        fac_setting.discharge_sms_text = organisation_settings.try(:discharge_sms_text)
        fac_setting.discharge_sms_time = organisation_settings.try(:discharge_sms_time)
        fac_setting.discharge_sms_schedule = organisation_settings.try(:discharge_sms_schedule)
        fac_setting.discharge_sms_active_inactive = organisation_settings.try(:discharge_sms_active_inactive)

        fac_setting.campaign_sms_text = organisation_settings.try(:campaign_sms_text)
        fac_setting.campaign_sms_time = organisation_settings.try(:campaign_sms_time)
        fac_setting.campaign_start_date = organisation_settings.try(:campaign_start_date)
        fac_setting.campaign_end_date = organisation_settings.try(:campaign_end_date)
        fac_setting.campaign_sms_active_inactive = organisation_settings.try(:campaign_sms_active_inactive)

        fac_setting.visit_sms_text = organisation_settings.try(:visit_sms_text)
        fac_setting.visit_sms_time = organisation_settings.try(:visit_sms_time)
        fac_setting.visit_sms_schedule = organisation_settings.try(:visit_sms_schedule)
        fac_setting.visit_sms_active_inactive = organisation_settings.try(:visit_sms_active_inactive)
        # last updated by
        user_fullname = user.try(:fullname)
        fac_setting.sms_feature_last_update = user_fullname
        fac_setting.visit_sms_last_update = user_fullname
        fac_setting.followup_sms_last_update = user_fullname
        fac_setting.long_overdue_sms_last_update = user_fullname
        fac_setting.missed_sms_last_update = user_fullname
        fac_setting.discharge_sms_last_update = user_fullname
        fac_setting.birthday_sms_last_update = user_fullname
        fac_setting.appointment_sms_last_update = user_fullname

        fac_setting.save
        create_audit_for_each_row(user, fac_setting)
      end
    else
      sms_logger.info('============== Facility Settings not present')
    end
  end

  def create_audit_for_each_row(user, fac_setting)
    identifiers = all_identifiers
    identifiers.each do |identifier|
      audit = SettingsAudit.new
      audit.user_id = user.id
      audit.organisation_id = user.organisation_id
      audit.facility_id = fac_setting.try(:facility_id)
      audit.level = "facility"
      audit.controller_name = "sms_settings"
      audit.action_name = "override_facility_sms_setting"
      audit.user_name = user.try(:fullname)
      audit.identifier = identifier
      audit.save
    end
  end

  def all_identifiers
    identifier = ["visit_sms_setting", "followup_sms_setting", "long_overdue_sms_setting", "missed_sms_setting", "appointment_sms_setting", "discharge_sms_setting", "birthday_sms_setting"]
    return identifier
  end
end
