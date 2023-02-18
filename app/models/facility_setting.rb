class FacilitySetting
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  after_save :update_redis_facility_settings

  field :sms_feature, type: Boolean, default: false
  field :user_sms_feature, type: Hash

  field :followup_sms_text, type: String, default: "Dear {PAT_NAME}, You have an appointment at {ORG_NAME} with Dr.{DOC_NAME} on {FOL_DATE} . For any queries call {SMS_NO}."
  field :followup_sms_time, type: Time # Time at which sms will be sent
  field :followup_sms_schedule, type: String, default: "1" # Time before the followup.
  field :followup_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :discharge_sms_text, type: String, default: "Dear {PAT_NAME}, Your discharge process has been  successfully completed, take rest and do regular exercises to stay healthy.Visit Dr. {DOC_NAME} in a week or two for routine checkup or if any complication arises. For any queries call {SMS_NO}."
  field :discharge_sms_time, type: Time # Time at which sms will be sent
  field :discharge_sms_schedule, type: String, default: "0" # Time before the discharge.
  field :discharge_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :missed_sms_text, type: String, default: "Dear {PAT_NAME}, You have an appointment at {ORG_NAME} with Dr.{DOC_NAME} on {FOL_DATE} . For any queries call {SMS_NO}."
  field :missed_sms_time, type: Time # Time at which sms will be sent
  field :missed_sms_schedule, type: String, default: "1" # Time before the missed.
  field :missed_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :long_overdue_sms_text, type: String, default: "Dear {PAT_NAME},You missed your appointment with Dr.{DOC_NAME} on {FOL_DATE} ,get in touch to avoid any complications.Thanks {ORG_NAME}"
  field :long_overdue_sms_time, type: Time # Time at which appointment sms will be sent
  field :long_overdue_sms_schedule, type: String, default: "30" # Time before the appointment.
  field :long_overdue_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :birthday_sms_text, type: String, default: "Dear {PAT_NAME}, {ORG_NAME} wishes you a very happy birthday. Have a fun-filled day and year ahead."
  field :birthday_sms_time, type: Time # Time at which birthday sms will be sent
  field :birthday_sms_schedule, type: String, default: "0" # Time before the birthday.
  field :birthday_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :appointment_sms_text, type: String, default: "Dear {PAT_NAME},  You have an appointment at {ORG_NAME} with Dr.{DOC_NAME} on {FOL_DATE} . For any queries call {SMS_NO}."
  field :appointment_sms_time, type: Time # Time at which appointment sms will be sent
  field :appointment_sms_schedule, type: String, default: "1" # Time before the appointment.
  field :appointment_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :campaign_sms_text, type: String, default: "Dear {PAT_NAME},  Thank you for visiting {DOC_NAME}. For any queries call {SMS_NO}."
  field :campaign_sms_time, type: Time # Time at which campaign sms will be sent
  field :campaign_start_date, type: Date # Time before the campaign.
  field :campaign_end_date, type: Date # Time before the campaign.
  field :campaign_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :visit_sms_text, type: String, default: "Dear {PAT_NAME},  Thank you for visiting {DOC_NAME}. For any queries call {SMS_NO}."
  field :visit_sms_time, type: Time # Time at which campaign sms will be sent
  field :visit_sms_schedule, type: String, default: "0" # Time before the campaign.
  field :visit_sms_active_inactive, type: Boolean, default: false # to enable or disable the particular type

  field :facility_name, type: String
  field :closing_time, type: String, default: "11:59 PM"
  # for facility's print setting
  field :all_print_setting, type: Hash
  field :pharmacy_print_setting, type: Hash
  field :optical_print_setting, type: Hash
  field :laboratory_print_setting, type: Hash
  field :radiology_print_setting, type: Hash
  field :ophthalmology_print_setting, type: Hash
  field :invoice_print_setting, type: Hash

  # for doctor's print setting eg: self.opd_print_setting['user_id']['setting']
  field :opd_print_setting, type: Hash
  field :ipd_print_setting, type: Hash

  # field :ipd_logo, type: String
  field :all_logo, type: String
  # field :opd_logo, type: String
  field :pharmacy_logo, type: String
  field :optical_logo, type: String
  field :lab_logo, type: String
  field :radio_logo, type: String
  field :invoice_logo, type: String
  field :ophthalmology_logo, type: String
  field :pharmacy_print_tagline, type: String
  field :optical_print_tagline, type: String

  # last_updated_by_field
  field :sms_feature_last_update, type: String
  field :visit_sms_last_update, type: String
  field :followup_sms_last_update, type: String
  field :long_overdue_sms_last_update, type: String
  field :missed_sms_last_update, type: String
  field :discharge_sms_last_update, type: String
  field :birthday_sms_last_update, type: String
  field :appointment_sms_last_update, type: String

  field :integration_enabled, type: Boolean, default: false

  field :invoice_show_package_breakup, type: Boolean, default: false
  field :template_font_size, type: String, default: "11"
  field :template_header_font_size, type: String, default: "9"
  field :bills_font_size, type: String, default: "8"

  field :queue_management, type: Boolean, default: false
  field :user_set_station, type: Boolean, default: false

  mount_uploader :logo, OrganisationUploader
  mount_uploader :all_logo, OrganisationUploader
  # mount_uploader :ipd_logo, OrganisationUploader
  # mount_uploader :opd_logo, OrganisationUploader
  mount_uploader :pharmacy_logo, OrganisationUploader
  mount_uploader :optical_logo, OrganisationUploader
  mount_uploader :laboratory_logo, OrganisationUploader
  mount_uploader :radiology_logo, OrganisationUploader
  mount_uploader :invoice_logo, OrganisationUploader
  mount_uploader :ophthalmology_logo, OrganisationUploader

  after_save :update_stations, if: :user_set_station_changed?
  def update_stations
    stations = QueueManagement::Station.where(facility_id: facility_id)
    stations.each do |station|
      QueueManagementJobs::StationJob.perform_later(station.id.to_s)

      station.sub_stations.each do |sub_station|
        remove_user_id = user_set_station ? sub_station.user_id : sub_station.active_user_id
        if remove_user_id
          QueueManagementJobs::SubStationJob.perform_later(sub_station.id.to_s, remove_user_id.to_s, 'remove')
        end

        update_user_id = user_set_station ? sub_station.active_user_id : sub_station.user_id
        if update_user_id
          QueueManagementJobs::SubStationJob.perform_later(sub_station.id.to_s, update_user_id.to_s, 'update')
        end
      end
    end
  end

  def store_previous_model_for_logo
    if logo.remove_previously_stored_files_after_update && logo_changed?
      @previous_model_for_logo ||= self.find_previous_model_for_logo
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

  # embeds_many :print_settings
  def update_redis_facility_settings
    self.user_sms_feature.keys.each do |k|
      # $REDIS.del("user_facility_settings:#{k}")
      Redis::Local.new.del("user_facility_settings:#{k}")
    end
  end

  belongs_to :facility
end
