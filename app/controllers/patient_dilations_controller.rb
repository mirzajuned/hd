class PatientDilationsController < ApplicationController
  before_action :authorize
  before_action :find_appointment, only: [:new, :create, :reset_dilation_timer, :stop_dilation]
  before_action :find_patient_dilation, only: [:reset_dilation_timer, :stop_dilation]

  def new
    # Patient
    @patient = @appointment.patient

    # Doctors
    @doctors = User.where(:facility_ids.in => [current_facility.id], role_ids: 158965000, is_active: true).pluck(:fullname, :id)

    # EyeDrops
    @eye_drops = @patient.get_drugallergies_list_attribute("dilationdrops")

    # Patient Allergies
    @eyedrop_allergy = @patient.allergy_histories.where(allergy_subtype: "eye_drops").pluck(:name).map(&:titleize) if @patient

    if params[:dilate_again]
      find_all_patient_dilation
      @last_dilation = @patient_dilation_list[0]
    end

    # PatientDilation
    @patient_dilation = PatientDilation.new
  end

  def create
    params[:patient_dilation][:start_time] = Time.current
    @patient_dilation = PatientDilation.new(patient_dilation_params)
    @patient_dilation.save!

    update_appointment # Update Dilation Fields in Appointment

    find_all_patient_dilation # All Dilation
  end

  def reset_dilation_timer
    if @patient_dilation.present?
      @patient_dilation.update(is_reseted: true, start_time: nil, end_time: nil)

      find_all_patient_dilation # All Dilation

      @patient_dilation = @patient_dilation_list[-1] # Take last Dilation with start_time Present

      update_appointment # Update Dilation Fields in Appointment

    end
  end

  def stop_dilation
    if @patient_dilation.present?
      @patient_dilation.update_attributes(end_time: Time.current) if @patient_dilation.start_time.present?

      update_appointment # Update Dilation Fields in Appointment

      find_all_patient_dilation
    end
  end

  private

  def patient_dilation_params
    params.require(:patient_dilation).permit(:user_id, :appointment_id, :patient_id, :start_time, :drops, :advised_by, :dilated_by, :comment, :eye_side)
  end

  def find_appointment
    @appointment = Appointment.find_by(id: params[:appointment_id])
  end

  def find_patient_dilation
    @patient_dilation = PatientDilation.find_by(id: params[:id])
  end

  def find_all_patient_dilation
    @patient_dilation_list = PatientDilation.where(appointment_id: @appointment.id.to_s, is_reseted: false).order(start_time: :desc)
  end

  def update_appointment
    @appointment.update(dilation_start_time: @patient_dilation.try(:start_time), dilation_end_time: @patient_dilation.try(:end_time))
  end
end
