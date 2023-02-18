class ProvisionalAppointments::CreateService
  def self.call(params, current_user, current_facility, integration = false)
    if params[:start_time].blank?
      params[:start_time] = Time.current
    end
    params[:integration_identifier] = BSON::ObjectId.new if params[:integration_identifier].blank?

    # @provisional_appointment = ProvisionalAppointment.new(prov_appointment(params))
    @provisional_appointment = ProvisionalAppointment.new(params)
    @provisional_appointment.skip_validation = integration

    if @provisional_appointment.save!
      return @provisional_appointment
    end
  end

  private

  def self.prov_appointment(params)
    (params.require(:appointment).permit(
      :facility_id, :doctor, :appointment_type_id, :appointmentdate, :start_time, :patient_id, :department_id, :organisation_id, :user_id, :display_id, :created_from, :opd_referral_id, :referral, :referral_created_on, :referring_doctor, :referee_doctor, :to_facility_name, :from_facility_name, :referral_text, :referral_note, :integration_identifier, :specialty_id, :token_number, :consultant_id
    )
    ).merge(params.require(:patient).permit(:firstname, :lastname, :middlename, :mobilenumber, :salutation, :gender, :age, :dob, :email, :address_1, :address_2, :commune, :city, :state, :pincode))
  end
end
