# require 'wisper/sidekiq'
# require 'celluloid/current'
# require 'sidekiq/api'
class Appointment::CreateService
  # include Wisper::Publisher
  def self.call(params, current_user, patient, current_facility, integration = false)
    # Create Additional Patient Params
    params[:patient_id] = patient.id.to_s
    params[:bkp_display_id] = CommonHelper::get_opd_record_identifier(current_user)
    
    if params[:opd_referral_id].present?
      appointment_referral_params(params)
    end

    # temporary solution for start_time nil, need to check js :anoop
    if params[:start_time].blank?
      params[:start_time] = Time.current
    end
    params[:scheduling_time] = params[:start_time]
    params[:scheduling_date] = params[:start_time]
    params[:integration_identifier] = BSON::ObjectId.new

    @appointment = Appointment.new(appointment_params(params))
    @appointment.skip_validation = integration

    if @appointment.save!
      @opd_referral.update(converted_to_appointment: true, converted_appointment_id: @appointment.id) if @opd_referral
      display_id = SequenceManagers::GenerateSequenceService.call('appointment', @appointment.id.to_s, {organisation_id: current_user.organisation._id.to_s, facility_id: current_facility.id.to_s, region_id: current_facility.try(:region_master_id).to_s, department_id: '485396012'})
      @appointment.update(display_id: display_id)

      create_appointment_asset(@appointment) unless params[:appointmentassets_attributes].present?

      Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "SCHEDULED", appointment_id: @appointment.id, user_id: current_user.id, user_name: current_user.fullname, workflow: current_facility.clinical_workflow })
      # broadcast(:create_agarwal_integration_appointment_data,@appointment.id)
      return @appointment
    end
  end

  private

  def self.appointment_referral_params(params)
    @opd_referral = OpdReferral.find(params[:opd_referral_id])
    params[:opd_referral_id] = params[:opd_referral_id]
    params[:referral] = true
    params[:referral_created_on] = @opd_referral.created_on
    params[:referring_doctor] = @opd_referral.from_doctor_name
    params[:referee_doctor] = @opd_referral.to_doctor_name
    params[:to_facility_name] = @opd_referral.to_facility_name
    params[:from_facility_name] = @opd_referral.from_facility_name
    params[:referral_note] = @opd_referral.referring_note
  end

  def self.appointment_params(params)
    params.permit! # (:facility_id, :doctor, :appointment_type_id, :appointmentdate, :start_time, :patient_id, :department_id, :organisation_id, :user_id, :display_id, :created_from, :opd_referral_id, :referral, :referral_created_on, :referring_doctor, :referee_doctor, :to_facility_name, :from_facility_name, :referral_note, :integration_identifier)
  end

  def self.create_appointment_asset(appointment)
    media = File.open(Rails.root + "app/assets/images/placeholder.png")
    Appointmentasset.create!(appointment_id: appointment.id, asset_path: media)
  end
end
