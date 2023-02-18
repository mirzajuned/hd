class PatientReferralTypesController < ApplicationController
  before_action :find_referral_types, only: [:new, :edit]
  before_action :find_patient_referral_type, only: [:edit, :update]
  before_action :find_patient, only: [:update]
  before_action :find_appointment, only: [:update]

  def new
    @appointment = Appointment.find_by(id: params[:appointment_id])
    @patient_referral_type = PatientReferralType.new
  end

  def create
    create_sub_referral if params[:sub_referral_type].present?

    # Create PatientReferral
    params[:patient_referral_type][:facility_id] = current_facility.id.to_s
    params[:patient_referral_type][:organisation_id] = current_facility.organisation_id.to_s

    @user_notes_templates = UserNotesTemplate.where(
      organisation_id: current_facility.organisation_id.to_s, :specialty_id.in => current_user.specialty_ids,
      is_deleted: false, '$or' => [{ facility_id: current_facility.id.to_s, level: 'facility' },
                                   { user_id: current_user.id, level: 'user' }, { level: 'organisation' }]
    ).order(level: :DESC)
    @patient_referral_type = PatientReferralType.new(patient_referral_type_params)
    if @patient_referral_type.save

      find_patient
      find_appointment
      patient_referral_types
      set_new_analytics_params

      respond_to do |format|
        format.js { render 'refresh.js.erb' }
      end
    else
      render 'new'
    end
  end

  def edit; end

  def update
    set_update_analytics_params

    params[:patient_referral_type][:facility_id] = @appointment.facility_id.to_s
    params[:patient_referral_type][:organisation_id] = @appointment.organisation_id.to_s
    if params[:patient_referral_type][:referral_type_id].present?
      create_sub_referral if params[:sub_referral_type].present?

      @message = ('Success' if @patient_referral_type.update_attributes(patient_referral_type_params)) || 'Failure'
    else
      @appointment = @patient_referral_type.appointment

      @message = ('Success' if @patient_referral_type.update_attributes(is_deleted: true)) || 'Failure'
      @patient_referral_type = nil
    end

    @user_notes_templates = UserNotesTemplate.where(
      organisation_id: @appointment.organisation_id.to_s, :specialty_id.in => current_user.specialty_ids,
      is_deleted: false, '$or' => [{ facility_id: @appointment.facility_id.to_s, level: 'facility' },
                                   { user_id: current_user.id, level: 'user' }, { level: 'organisation' }]
    ).order(level: :DESC)
    Analytics::UpdateService.call(@analytics_params.to_json, nil, @appointment.facility_id.to_s, 'patient_referral_type')

    if @message == 'Success'
      patient_referral_types

      respond_to do |format|
        format.js { render 'refresh.js.erb' }
      end
    else
      render 'edit'
    end
  end

  private

  def find_referral_types
    @referral_types = ReferralType.where(is_active: true, :id.nin => ['FS-RT-0009'])
  end

  def find_patient_referral_type
    @patient_referral_type = PatientReferralType.find_by(id: params[:id])
  end

  def create_sub_referral
    # Create SubReferral, Case: Relative
    params[:sub_referral_type][:referral_type_id] = params[:patient_referral_type][:referral_type_id]
    params[:sub_referral_type][:facility_ids] = current_user.facility_ids
    if params[:sub_referral_type][:referral_type_id] == 'FS-RT-0001'
      @sub_referral_type = SubReferralType.find_by(referral_type_id: 'FS-RT-0001', organisation_id: current_user.organisation_id) # Case Self
    end
    unless @sub_referral_type.present?
      @sub_referral_type = SubReferralType.new(sub_referral_type_params)
      @sub_referral_type.save!
    end
    params[:patient_referral_type][:sub_referral_type_id] = @sub_referral_type.try(:id).to_s
  end

  def sub_referral_type_params
    params.require(:sub_referral_type).permit(:is_active, :existing_patient, :name, :mobile_number, :email, :relation, :comment, :facility_ids, :user_id, :referral_type_id, :organisation_id)
  end

  def patient_referral_type_params
    params.require(:patient_referral_type).permit(:referral_type_id, :sub_referral_type_id, :patient_id, :appointment_id, :is_deleted, :facility_id, :organisation_id)
  end

  def find_patient
    @patient = Patient.find_by(id: @patient_referral_type.patient_id)
  end

  def find_appointment
    @appointment = Appointment.find_by(id: @patient_referral_type.appointment_id)
  end

  def patient_referral_types
    @initial_referral_type = PatientReferralType.where(patient_id: @patient.id, is_deleted: false).order(created_at: :asc)[0]
    @deleted_patient_referral_type = PatientReferralType.find_by(appointment_id: @appointment.id, is_deleted: true)
  end

  def set_new_analytics_params
    @analytics_params = {}
    @analytics_params['appointment_id'] = @appointment.id.to_s
    @analytics_params['patient_referral_id'] = @patient_referral_type.id.to_s
    Analytics::CreateService.call(@analytics_params.to_json, nil, @appointment.facility_id.to_s, 'patient_referral_type')
  end

  def set_update_analytics_params
    @analytics_params = {}
    @analytics_params['appointment_id'] = @appointment.id
    @analytics_params['patient_referral_id'] = @patient_referral_type.id
    @analytics_params['before_referral_type_id'] = (@patient_referral_type.referral_type_id if @patient_referral_type.is_deleted == false) || nil
    @analytics_params['before_appointment_date'] = @appointment.appointmentdate
    @analytics_params['before_facility_id'] = @appointment.facility_id
  end
end
