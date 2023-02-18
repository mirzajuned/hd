class DischargeSmsJob < ActiveJob::Base
  queue_as :delayed
  def perform(*args)
    admission = Admission.find_by(id: args[0])
    facility  = admission.facility
    facility_setting = admission.try(:facility).try(:facility_setting)
    @patient = Patient.find_by(id: admission.patient_id)
    @doctor = User.find_by(id: admission.user_id)
    doctor_name = @doctor.try(:fullname)
    patient_name = @patient.fullname.split(" ").map(&:capitalize).join(" ")
    patient_mobile = @patient.mobilenumber
    organisation = @doctor.organisation
    organisations_settings = organisation.organisations_setting
    raw_sms_body = organisations_settings.try(:discharge_sms_text)
    mobile_number = organisations_settings.present? && organisations_settings.try(:sms_contact_enabled) ? ((organisation.try(:sms_contact_number).present?) ? organisation.try(:sms_contact_number) : organisation.try(:telephone)) : ((facility.try(:sms_contact_number).present?) ? facility.try(:sms_contact_number) : facility.try(:telephone))
    sms_config = YAML.load_file("#{Rails.root}/config/sms_config.yml")
    send_message(raw_sms_body, patient_name, doctor_name, mobile_number, patient_mobile, facility.try(:name), organisation.try(:name), sms_config)

    CommunicationDetail.create(communication_type: "sms", communication_info: "discharge", communication_date: Date.current, user_id: @doctor.id, organisation_id: @doctor.organisation.id, patient_id: @patient.id, communication_month: Date.current.month, facility_id: admission.facility_id)
  end

  def send_message(raw_sms_body, patient_name, doctor_name, contact_mob, patient_mobile, facility_name, org_name, sms_config)
    sms_body = raw_sms_body.gsub("{PAT_NAME}", patient_name.try(:titleize)).gsub("{DOC_NAME}", doctor_name.try(:titleize)).gsub("{SMS_NO}", contact_mob).gsub("{FAC_NAME}", facility_name.try(:titleize)).gsub("{ORG_NAME}", org_name.try(:titleize))
    url = URI.parse("#{sms_config['sms_url']}?username=#{sms_config['username']}&&password=#{sms_config['password']}&sender=#{sms_config['sender']}&to=#{patient_mobile}&message=#{sms_body}&reqid=#{sms_config['reqid']}&format=#{sms_config['format']}&route_id=#{sms_config['route_id']}")
    open(url) do |http|
      response = http.read
    end
  end
end
