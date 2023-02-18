json.set! "patients" do
  json.array!(@patients) do |patient|
    if !patient.blank?
      json.id patient.id.to_s
      json.display_id PatientIdentifier.where(:organisation_id => @organisation.id.to_s, :patient_id => patient.id).first.try(:patient_org_id)
      json.name patient.fullname
      json.mobilenumber patient.mobilenumber
      json.email patient.email
      json.picthumb patient.patientassets.present? ? patient.patientassets.last.asset_path_url(:api_thumb) : ''
      json.picactual patient.patientassets.present? ? patient.patientassets.last.asset_path_url : ''
      json.age patient.age
      json.gender patient.gender
      json.address_1 patient.address_1
      json.address_2 patient.address_2
      json.city patient.city
      json.state patient.state
      json.pincode patient.pincode
      json.dob patient.dob
    end
  end
end
json.set! "appointments" do
  json.array!(@appointment_list) do |appointment|
    if !appointment.blank?
      json.id appointment.id.to_s
      json.appointment_type appointment.appointment_type.label
      json.doctor_id appointment.consultant_id
      json.doctor_name User.find_by(:id => Appointment.last.doctor.to_s).try(:fullname)
      json.facility_id appointment.facility.id.to_s
      json.appointment_type_id appointment.appointment_type.id.to_s
      json.appointment_type_background appointment.appointment_type.background
      json.patient_id appointment.patient.try(:id)
      json.patient_identifier_id appointment.patient.patient_identifiers.where(:organisation_id => @organisation.id.to_s).first.try(:patient_org_id)
      json.patient_name appointment.patient.fullname
      json.patient_age (appointment.patient.age.nil? ? "" : appointment.patient.age)
      json.patient_gender (appointment.patient.gender.nil? ? "" : appointment.patient.gender)
      json.appointment_date "#{Date.strptime("#{appointment.appointmentdate}", "%Y-%m-%d").strftime("%Y-%m-%d")}"
      json.appointment_time "#{Time.strptime("#{appointment.start_time}", "%Y-%m-%d %H:%M:%S").strftime("%H:%M")}"
      json.facility_id appointment.facility.id.to_s
    end
  end
end
if @user.selected_role.split(",")[0] == "doctor"
  user = @user
  @appointment_types = AppointmentType.where(:user_id => user.id.to_s, :is_active => true)
  json.set! "appointment_types" do
    json.doctors [{ "#{user.id}": @appointment_types.map { |appointment_type| { label: appointment_type.label, id: appointment_type.id, duration: appointment_type.duration, background: appointment_type.background } } }]
  end
elsif @user.selected_role.split(",")[0] == "receptionist"
  json.set! "appointment_types_doctors" do
    @user.facilities.each { |facility|
      @users = Common.new.fetch_users(:org_type => @user.organisation.type, :organisation_id => @user.organisation.id, :facility_id => facility.id, :department_id => @user.department_id)
      @users.each { |user|
        @appointment_types = AppointmentType.where(:user_id => user.id.to_s, :is_active => true)
        json.doctors [{ "#{user.id}": @appointment_types.map { |appointment_type| { label: appointment_type.label, id: appointment_type.id, duration: appointment_type.duration } } }]
      }
    }
  end
end
