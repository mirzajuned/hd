# 14  Metrics/LineLength
# 2   Style/GuardClause
# 1   Metrics/ClassLength
# --
# 17  Total
class OrganisationsSetting
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  after_create :update_all_print_setting
  timing_hash = { '0' => { 'from' => '09:00', 'to' => '17:00' } }
  weekday_hash = { '404684003' => timing_hash, '307145004' => timing_hash, '307147007' => timing_hash,
                   '307148002' => timing_hash, '307149005' => timing_hash, '307150005' => timing_hash,
                   '307151009' => timing_hash }

  field :org_type, type: String
  field :org_type_id, type: String
  field :weekday_setting, type: Hash, default: weekday_hash
  field :everyday_same_timings, type: Boolean
  field :multi_auth, type: Boolean, default: false

  field :sms_feature, type: Boolean, default: false

  # sms fields for the customised message and time scheduling to send the sms.
  field :followup_sms_text, type: String, default: 'Dear {PAT_NAME}, You have an appointment at {ORG_NAME} with Dr.{DOC_NAME} on {FOL_DATE} . For any queries call {SMS_NO}.'
  field :followup_sms_time, type: Time # Time at which sms will be sent
  field :followup_sms_schedule, type: String # Time before the followup.
  field :followup_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :long_overdue_sms_text, type: String, default: 'Dear {PAT_NAME},It has been a while since you have visited Dr.{DOC_NAME} ,get in touch for a routine checkup.Thanks {ORG_NAME}'
  field :long_overdue_sms_time, type: Time # Time at which appointment sms will be sent
  field :long_overdue_sms_schedule, type: String # Time before the appointment.
  field :long_overdue_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :birthday_sms_text, type: String, default: 'Dear {PAT_NAME}, {ORG_NAME} wishes you a very happy birthday. Have a fun-filled day and year ahead.'
  field :birthday_sms_time, type: Time # Time at which birthday sms will be sent
  field :birthday_sms_schedule, type: String # Time before the birthday.
  field :birthday_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :appointment_sms_text, type: String, default: 'Dear {PAT_NAME},  You have an appointment at {ORG_NAME} with Dr.{DOC_NAME} on {FOL_DATE} . For any queries call {SMS_NO}.'
  field :appointment_sms_time, type: Time # Time at which appointment sms will be sent
  field :appointment_sms_schedule, type: String # Time before the appointment.
  field :appointment_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :missed_sms_text, type: String, default: 'Dear {PAT_NAME},  You have an missed at {ORG_NAME} with Dr.{DOC_NAME} on {FOL_DATE} . For any queries call {SMS_NO}.'
  field :missed_sms_time, type: Time # Time at which missed sms will be sent
  field :missed_sms_schedule, type: String # Time before the missed.
  field :missed_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :discharge_sms_text, type: String, default: 'Dear {PAT_NAME}, Your discharge process has been  successfully completed, take rest and do regular exercises to stay healthy.Visit Dr. {DOC_NAME} in a week or two for routine checkup or if any complication arises. For any queries call {SMS_NO}.'
  field :discharge_sms_time, type: Time # Time at which sms will be sent
  field :discharge_sms_schedule, type: String # Time before the discharge.
  field :discharge_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :campaign_sms_text, type: String, default: 'Dear {PAT_NAME},  Thank you for visiting {DOC_NAME}. For any queries call {SMS_NO}.'
  field :campaign_sms_time, type: Time # Time at which campaign sms will be sent
  field :campaign_sms_schedule, type: String # Time before the campaign.
  field :campaign_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :visit_sms_text, type: String, default: 'Dear {PAT_NAME},  Thank you for visiting {DOC_NAME}. For any queries call {SMS_NO}.'
  field :visit_sms_time, type: Time # Time at which campaign sms will be sent
  field :visit_sms_schedule, type: String # Time before the campaign.
  field :visit_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  # email fields for the customised message and time scheduling to send the email.
  field :followup_email_subject, type: String, default: 'Followup Reminder'
  field :followup_email_body, type: String, default: "Greetings %pat_name%!, \nThis is just a gentle reminder for your appointment at %org_name% with Dr.%doc_name% \nDate: %fol_date% \nIn case of any queries please call %doc_no%. \nFor more information please visit %org_web%.\nRegards,\nDr.%doc_name%"
  field :followup_email_time, type: Time # Time at which email will be sent
  field :followup_email_schedule, type: String # Time before the followup.
  field :followup_email_active_inactive, type: Boolean, default: true # to enable or disable the particular

  field :birthday_email_subject, type: String, default: 'Happy Birthday'
  field :birthday_email_body, type: String, default: "Greetings %pat_name%!,\n %org_name% wishes you a very happy birthday. Have a fun-filled day and year ahead."
  field :birthday_email_time, type: Time # Time at which email will be sent
  field :birthday_email_schedule, type: String # Time before the birthday.
  field :birthday_email_active_inactive, type: Boolean, default: true # to enable or disable the particular

  field :appointment_email_subject, type: String, default: 'Appointment Reminder'
  field :appointment_email_body, type: String, default: "Greetings %pat_name%!, \nThis is just a gentle reminder for your appointment at %org_name% with Dr.%doc_name% \nDate: %fol_date%\nIn case of any queries please call %doc_no%. \nFor more information please visit %org_web%.\nRegards,\nDr.%doc_name%"
  field :appointment_email_time, type: Time # Time at which email will be sent
  field :appointment_email_schedule, type: String # Time before the appointment.
  field :appointment_email_active_inactive, type: Boolean, default: true # to enable or disable the particular

  field :campaign_email_subject, type: String, default: '%org_name%'
  field :campaign_email_body, type: String, default: "Dear %pat_name%,\n Thank you for visiting %doc_name%. For any queries call %doc_no%."
  field :campaign_email_time, type: Time # Time at which email will be sent
  field :campaign_email_schedule, type: String # Time before the campaign.
  field :campaign_email_active_inactive, type: Boolean, default: true # to enable or disable the particular

  field :long_overdue_email_body, type: String, default: "Dear %pat_name%,\nYou have missed your followup visit with Dr. %doc_name% on %fol_date% , get in touch as soon as possible to avoid any complications. \n Thanks %org_name%"
  field :long_overdue_email_subject, type: String, default: 'Missed Followup'
  field :long_overdue_email_time, type: Time # Time at which email will be sent
  field :long_overdue_email_schedule, type: String # Time before the appointment.
  field :long_overdue_email_active_inactive, type: Boolean, default: true # to enable or disable the particular type

  field :visit_email_body, type: String, default: "Dear %pat_name%,\n Thank you for visiting %doc_name%. For any queries call %doc_no%."
  field :visit_email_subject, type: String, default: '%org_name%'
  field :visit_email_time, type: Time # Time at which email will be sent
  field :visit_email_schedule, type: String # Time before the appointment.
  field :visit_email_active_inactive, type: Boolean, default: true # to enable or disable the particular type
  # field :clinical_workflow,type: Boolean,default: false
  field :cin, type: String
  field :emails, type: Array, default: []
  belongs_to :organisation, index: { background: true }
  belongs_to :facility, optional: true, index: { background: true }
  belongs_to :communication_number, optional: true, index: { background: true }

  field :all_print_setting, type: Hash
  field :pharmacy_print_setting, type: Hash
  field :optical_print_setting, type: Hash
  field :laboratory_print_setting, type: Hash
  field :radiology_print_setting, type: Hash
  field :ophthalmology_print_setting, type: Hash
  field :invoice_print_setting, type: Hash

  field :custom_template_header_options, type: Hash
  field :custom_invoice_header_title, type: Hash
  # for doctor's print setting eg: self.opd_print_setting['user_id']['setting']
  field :opd_print_setting, type: Hash
  field :ipd_print_setting, type: Hash

  field :ipd_org_logo, type: String
  # field :all_org_logo, type: String
  field :opd_org_logo, type: String
  field :pharmacy_org_logo, type: String
  field :optical_org_logo, type: String
  field :lab_org_logo, type: String
  field :radio_org_logo, type: String
  field :invoice_org_logo, type: String
  field :ophthalmology_org_logo, type: String

  field :patient_card_enabled, type: Boolean, default: false
  field :enable_auto_evaluation, type: Boolean, default: false
  field :disable_add_referral, type: Boolean, default: false

  field :pricing_discount_enabled, type: Boolean, default: false
  field :sms_contact_enabled, type: Boolean, default: false

  field :disable_default_diagnosis, type: Boolean, default: false
  field :disable_default_procedure, type: Boolean, default: false
  field :disable_default_investigation, type: Boolean, default: false
  field :disable_default_medicine, type: Boolean, default: false
  field :edit_bill_unit_price_enabled, type: Boolean, default: false

  field :ot_procedure_sort_order, type: String, default: 'ASC'
  field :disable_add_medicine, type: Boolean, default: false

  field :disable_clone_old_template, type: Boolean, default: false
  field :print_only_todays_peformed_investigations, type: Boolean, default: false

  # Disable selected Opd Templates post discharge for N number of days
  field :disable_opd_templates, type: Boolean, default: false
  field :disable_opd_templates_duration, type: Integer
  field :allowed_opd_templates, type: Hash, default: {}

  # OrganisationNotification
  field :organisation_notification_enabled, type: Boolean, default: false
  # OrganisationWhatsappNotification
  field :organisation_whatsapp_enabled, type: Boolean, default: false
  field :communication_number_id, type: BSON::ObjectId
  field :organisation_account_sid, type: String
  # OPD Templates Mandatory
  field :mandatory_opd_templates, type: Boolean, default: false

  # OPD Consultant Freeze
  field :consultant_freeze, type: Boolean, default: false
  # Patient Form Validation
  field :validate_patient, type: Array, default: ['patient-firstname', 'patient-mobilenumber']

  field :active_advise_order_rule, type: String, default: 'FIFO'
  # Organisation Time Setting
  field :time_slots_enabled, type: Boolean, default: false
  field :mandatory_invoice, type: Boolean, default: false

  field :allow_duplicate_user_email, type: Boolean, default: false
  field :print_bill_service_code, type: Boolean, default: false

  # ROL fields
  field :auto_requisition_enabled, type: Boolean, default: false
  field :auto_requisition_type, type: String
  field :auto_requisition_value, type: String
  field :auto_requisition_auto_approval, type: Boolean, default: true

  field :disable_visit_fields, type: Boolean, default: true

  # mount_uploader :all_org_logo, OrganisationUploader
  mount_uploader :ipd_org_logo, OrganisationUploader
  mount_uploader :opd_org_logo, OrganisationUploader
  mount_uploader :pharmacy_org_logo, OrganisationUploader
  mount_uploader :optical_org_logo, OrganisationUploader
  mount_uploader :laboratory_org_logo, OrganisationUploader
  mount_uploader :radiology_org_logo, OrganisationUploader
  mount_uploader :invoice_org_logo, OrganisationUploader
  mount_uploader :ophthalmology_org_logo, OrganisationUploader

  validates_presence_of :disable_opd_templates_duration, if: :disable_opd_templates
  validates_presence_of :allowed_opd_templates, if: :disable_opd_templates

  before_validation :clear_disable_opd_templates_fields, if: -> { disable_opd_templates_changed? && !disable_opd_templates }
  validate :organisation_account_sid_checked

  def clear_disable_opd_templates_fields
    self.disable_opd_templates_duration = nil
    self.allowed_opd_templates = {}
  end

  def organisation_account_sid_checked
    if organisation_account_sid_changed?
      @response = CommunicationNotifications::WhatsappNotificationValidateService.call(nil, self)
      if @response == "Notification sent successfully"
      else
        self.errors.add(:base, @response)
      end
    end
  end

  def store_previous_model_for_logo
    if logo.remove_previously_stored_files_after_update && logo_changed?
      @previous_model_for_logo ||= find_previous_model_for_logo
    end
  end

  def find_previous_model_for_logo
    self.class.find(to_key.first)
  end

  def remove_previously_stored_logo
    if @previous_model_for_logo && @previous_model_for_logo.logo.path != logo.path && !logo.path.nil?
      @previous_model_for_logo.logo.remove!
      @previous_model_for_logo = nil
    end
  end

  def update_all_print_setting
    print_hash = { header_height: '3', footer_height: '2', left_margin: '1', right_margin: '1',
                   logo_location: '', header_location: '', right: '', left: '', header: '',
                   customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }

    update(all_print_setting: print_hash, opd_print_setting: print_hash, ipd_print_setting: print_hash,
           pharmacy_print_setting: print_hash, optical_print_setting: print_hash, laboratory_print_setting: print_hash,
           radiology_print_setting: print_hash, ophthalmology_print_setting: print_hash,
           invoice_print_setting: print_hash, custom_template_header_options: custom_template_header_hash,
           custom_invoice_header_title: custom_invoice_header_title_hash)
  end

  def custom_invoice_header_title_hash
    opd = { invoices: [{ 'cash_header_title': 'OutPatient Bill', 'credit_header_title': 'OutPatient Bill' }] }
    ipd = { invoices: [{ 'cash_header_title': 'InPatient Bill', 'credit_header_title': 'InPatient Bill' }] }
    inventory = { invoices: [{ 'cash_header_title': 'Pharmacy Bill', 'credit_header_title': 'Pharmacy Bill' }] }
    optical = { invoices: [{ 'cash_header_title': 'Optical Bill', 'credit_header_title': 'Optical Bill' }] }
    { opd_invoices_title: opd, ipd_invoices_title: ipd, pharmacy_invoices_title: inventory, optical_invoices_title: optical }
  end

  def custom_template_header_hash
    opd = { templates: [{ 'fullname': true, 'consultant_name': true, 'calculate_age_gender': true,
                          'facility_name': true, 'patient_identifier': true, 'display_id': true, 'mobilenumber': true,
                          'appointment_date': true, 'mr_no': true, 'created_at': true, 'referring_doctor': true,
                          'address': true, 'patient_type': true }],
            invoices: [{ 'fullname': true, 'doctor_name': true, 'patient_type': true, 'patient_identifier': true,
                         'mobilenumber': true, 'mr_no': true, 'created_at': true, 'calculate_age_gender': true,
                         'facility_name': true, 'display_id': true, 'appointment_date': true, 'bill_number': true,
                         'bill_type': true, 'address': true }] }

    ipd = { templates: [{ 'fullname': true, 'admitting_doctor': true, 'patient_identifier': true, 'mobilenumber': true,
                          'admission_date': true, 'facility_name': true, 'calculate_age_gender': true, 'display_id': true,
                          'ward_bed_code': true, 'mr_no': true, 'referring_doctor': true, 'address': true, 'patient_type': true }],
            invoices: [{ 'fullname': true, 'doctor_name': true, 'patient_type': true, 'patient_identifier': true,
                         'mobilenumber': true, 'mr_no': true, 'created_at': true, 'calculate_age_gender': true,
                         'facility_name': true, 'display_id': true, 'admission_date': true, 'bill_number': true,
                         'bill_type': true, 'address': true }] }

    optical = { invoices: [{'recipient': true, 'doctor_name': true, 'bill_number': true,
                            'patient_identifier': true, 'mr_no': true, 'date_time': true, 'address': true,
                            'mobilenumber': true, 'calculate_age_gender': true }],
                templates: [{ 'recipient': true, 'doctor_name': true, 'invoice_number': true,
                              'patient_identifier': true, 'mr_no': true, 'date_time': true, 'mobilenumber': true,
                              'order_on': true, 'order_no': true, 'gstin': true, 'address': true,
                              'calculate_age_gender': true}] }

    pharmacy = { invoices: [{'recipient': true, 'doctor_name': true, 'bill_number': true,
                          'patient_identifier': true, 'mr_no': true, 'date_time': true, 'address': true,
                          'mobilenumber': true, 'calculate_age_gender': true  }] }   

               { opd_settings: opd, ipd_settings: ipd, pharmacy_settings: pharmacy, optical_settings: optical }
  end
end
