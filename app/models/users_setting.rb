class UsersSetting
  include Mongoid::Document
  include Mongoid::Timestamps

  weekday_hash = { "404684003" => { "0" => { "from" => "09:00", "to" => "17:00" } }, "307145004" => { "0" => { "from" => "09:00", "to" => "17:00" } }, "307147007" => { "0" => { "from" => "09:00", "to" => "17:00" } }, "307148002" => { "0" => { "from" => "09:00", "to" => "17:00" } }, "307149005" => { "0" => { "from" => "09:00", "to" => "17:00" } }, "307150005" => { "0" => { "from" => "09:00", "to" => "17:00" } }, "307151009" => { "0" => { "from" => "09:00", "to" => "17:00" } } }

  field :org_type, type: String
  field :schedule, type: Hash
  field :facility_timing, type: Array
  field :org_type_id, type: String
  field :weekday_setting, type: Hash, default: weekday_hash
  field :custom_timings, type: Hash
  field :everyday_same_timings, type: Boolean

  # sms fields for the customised message and time scheduling to send the sms.
  field :followup_sms_text, type: String, default: "Dear %pat_name%, You have an appointment at %org_name% with Dr.%doc_name% on %fol_date% . For any queries call %doc_no%."
  field :followup_sms_time, type: Time # Time at which sms will be sent
  field :followup_sms_schedule, type: String # Time before the followup.
  field :followup_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :discharge_sms_text, type: String, default: "Dear %pat_name%, You have an appointment at %org_name% with Dr.%doc_name% on %fol_date% . For any queries call %doc_no%."
  field :discharge_sms_time, type: Time # Time at which sms will be sent
  field :discharge_sms_schedule, type: String # Time before the discharge.
  field :discharge_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :missed_sms_text, type: String, default: "Dear %pat_name%, You have an appointment at %org_name% with Dr.%doc_name% on %fol_date% . For any queries call %doc_no%."
  field :missed_sms_time, type: Time # Time at which sms will be sent
  field :missed_sms_schedule, type: String # Time before the missed.
  field :missed_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :long_overdue_sms_text, type: String, default: "Dear %pat_name%,You missed your appointment with Dr.%doc_name% on %fol_date% ,get in touch to avoid any complications.Thanks %org_name%"
  field :long_overdue_sms_time, type: Time # Time at which appointment sms will be sent
  field :long_overdue_sms_schedule, type: String # Time before the appointment.
  field :long_overdue_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :birthday_sms_text, type: String, default: "Dear %pat_name%, %org_name% wishes you a very happy birthday. Have a fun-filled day and year ahead."
  field :birthday_sms_time, type: Time # Time at which birthday sms will be sent
  field :birthday_sms_schedule, type: String # Time before the birthday.
  field :birthday_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :appointment_sms_text, type: String, default: "Dear %pat_name%,  You have an appointment at %org_name% with Dr.%doc_name% on %fol_date% . For any queries call %doc_no%."
  field :appointment_sms_time, type: Time # Time at which appointment sms will be sent
  field :appointment_sms_schedule, type: String # Time before the appointment.
  field :appointment_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :campaign_sms_text, type: String, default: "Dear %pat_name%,  Thank you for visiting %doc_name%. For any queries call %doc_no%."
  field :campaign_sms_time, type: Time # Time at which campaign sms will be sent
  field :campaign_sms_schedule, type: String # Time before the campaign.
  field :campaign_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :visit_sms_text, type: String, default: "Dear %pat_name%,  Thank you for visiting %doc_name%. For any queries call %doc_no%."
  field :visit_sms_time, type: Time # Time at which campaign sms will be sent
  field :visit_sms_schedule, type: String # Time before the campaign.
  field :visit_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  # email fields for the customised message and time scheduling to send the email.
  field :followup_email_subject, type: String, default: "Followup Reminder"
  field :followup_email_body, type: String, default: "Greetings %pat_name%!, \nThis is just a gentle reminder for your appointment at %org_name% with Dr.%doc_name% \nDate: %fol_date% \nIn case of any queries please call %doc_no%. \nFor more information please visit %org_web%.\nRegards,\nDr.%doc_name%"
  field :followup_email_time, type: Time # Time at which email will be sent
  field :followup_email_schedule, type: String # Time before the followup.
  field :followup_email_active_inactive, type: Boolean, default: true # to enable or disable the particular

  field :birthday_email_subject, type: String, default: 'Happy Birthday'
  field :birthday_email_body, type: String, default: "Greetings %pat_name%!,\n %org_name% wishes you a very happy birthday. Have a fun-filled day and year ahead."
  field :birthday_email_time, type: Time # Time at which email will be sent
  field :birthday_email_schedule, type: String # Time before the birthday.
  field :birthday_email_active_inactive, type: Boolean, default: true # to enable or disable the particular

  field :appointment_email_subject, type: String, default: "Appointment Reminder"
  field :appointment_email_body, type: String, default: "Greetings %pat_name%!, \nThis is just a gentle reminder for your appointment at %org_name% with Dr.%doc_name% \nDate: %fol_date%\nIn case of any queries please call %doc_no%. \nFor more information please visit %org_web%.\nRegards,\nDr.%doc_name%"
  field :appointment_email_time, type: Time # Time at which email will be sent
  field :appointment_email_schedule, type: String # Time before the appointment.
  field :appointment_email_active_inactive, type: Boolean, default: true # to enable or disable the particular

  field :campaign_email_subject, type: String, default: "%org_name%"
  field :campaign_email_body, type: String, default: "Dear %pat_name%,\n Thank you for visiting %doc_name%. For any queries call %doc_no%."
  field :campaign_email_time, type: Time # Time at which email will be sent
  field :campaign_email_schedule, type: String # Time before the campaign.
  field :campaign_email_active_inactive, type: Boolean, default: true # to enable or disable the particular

  field :long_overdue_email_body, type: String, default: "Dear %pat_name%,\nYou have missed your followup visit with Dr. %doc_name% on %fol_date% , get in touch as soon as possible to avoid any complications. \n Thanks %org_name%"
  field :long_overdue_email_subject, type: String, default: "Missed Followup"
  field :long_overdue_email_time, type: Time # Time at which email will be sent
  field :long_overdue_email_schedule, type: String # Time before the appointment.
  field :long_overdue_email_active_inactive, type: Boolean, default: true # to enable or disable the particular type

  field :visit_email_body, type: String, default: "Dear %pat_name%,\n Thank you for visiting %doc_name%. For any queries call %doc_no%."
  field :visit_email_subject, type: String, default: "%org_name%"
  field :visit_email_time, type: Time # Time at which email will be sent
  field :visit_email_schedule, type: String # Time before the appointment.
  field :visit_email_active_inactive, type: Boolean, default: true # to enable or disable the particular type
  field :refering_sms_text, type: String, default: "Dear %doc_name%,Thank you for refering %pat_name% to us. We will be happy to return the favour ."
  field :refering_sms_time, type: Time # Time at which campaign sms will be sent
  field :refering_sms_schedule, type: String # Time before the campaign.
  field :refering_sms_active_inactive, type: Boolean, default: true

  field :font_style, type: String, default: "Verdana"
  belongs_to :organisation, index: { background: true }
  belongs_to :user, optional: true, index: { background: true }
  belongs_to :facility, optional: true, index: { background: true }

  def get_min_max_time(user_id, facility_id, day_id)
    day_schedule = UsersSetting.find_by(:user_id => user_id, :facility_id => facility_id).weekday_setting[day_id.to_s]
  end

  def set_weekday_setting
    others_hash = { "404684003" => { "0" => { "from" => "07:00", "to" => "23:00" } }, "307145004" => { "0" => { "from" => "07:00", "to" => "23:00" } }, "307147007" => { "0" => { "from" => "07:00", "to" => "23:00" } }, "307148002" => { "0" => { "from" => "07:00", "to" => "23:00" } }, "307149005" => { "0" => { "from" => "07:00", "to" => "23:00" } }, "307150005" => { "0" => { "from" => "07:00", "to" => "23:00" } }, "307151009" => { "0" => { "from" => "07:00", "to" => "23:00" } } }
    self.weekday_setting = others_hash
    self.save
  end

  def self.nurse_setting
    return { "404684003" => { "0" => { "from" => "07:00", "to" => "23:00" } }, "307145004" => { "0" => { "from" => "07:00", "to" => "23:00" } }, "307147007" => { "0" => { "from" => "07:00", "to" => "23:00" } }, "307148002" => { "0" => { "from" => "07:00", "to" => "23:00" } }, "307149005" => { "0" => { "from" => "07:00", "to" => "23:00" } }, "307150005" => { "0" => { "from" => "07:00", "to" => "23:00" } }, "307151009" => { "0" => { "from" => "07:00", "to" => "23:00" } } }
  end

  def self.doctor_setting
    return { "404684003" => { "0" => { "from" => "09:00", "to" => "17:00" } }, "307145004" => { "0" => { "from" => "09:00", "to" => "17:00" } }, "307147007" => { "0" => { "from" => "09:00", "to" => "17:00" } }, "307148002" => { "0" => { "from" => "09:00", "to" => "17:00" } }, "307149005" => { "0" => { "from" => "09:00", "to" => "17:00" } }, "307150005" => { "0" => { "from" => "09:00", "to" => "17:00" } }, "307151009" => { "0" => { "from" => "09:00", "to" => "17:00" } } }
  end
end
