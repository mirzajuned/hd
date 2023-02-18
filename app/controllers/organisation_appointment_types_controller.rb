class OrganisationAppointmentTypesController < ApplicationController
  before_action :authorize
  before_action :set_initial_params

  def organisation_appointment_type
    @appointment_types = OrganisationAppointmentType.where(organisation_id: @current_user.organisation_id).order({ default_set: :desc }, { is_default: :desc })
  end

  def save_appointment_types
    appointment_types = params[:appointment_types]
    appointment_types.each do |index, value|
      if params[:default] == index
        params[:appointment_types][params[:default]][:is_default] = true
      else
        params[:appointment_types][index.to_s][:is_default] = false
      end

      if value[:label] != '' && value[:duration] != '' && value[:is_updated] == "true"
        appointment_type_params = { label: value[:label], background: value[:background], organisation_id: value[:organisation_id], duration: value[:duration], is_default: value[:is_default], default_set: value[:default_set], s_no: value[:s_no], is_active: value[:is_active], specialty_ids: value[:specialty_ids].reject(&:blank?) }

        appointment_type_params[:id] = value[:id] if value[:id] != nil

        # duplicate_appointment = OrganisationAppointmentType.find_by(label: value[:label], background: value[:background], duration: value[:duration], organisation_id: @current_user.organisation_id, specialty_id: value[:specialty_id])
        # duplicate_appointment.try(:destroy)

        appointment_type = OrganisationAppointmentType.new(appointment_type_params)
        appointment_type.upsert
      end
    end

    @appointment_types = OrganisationAppointmentType.where(organisation_id: @current_user.organisation_id).order({ default_set: :desc }, { is_default: :desc })
    AppointmentTypeJobs::UpdateAppointmentTypeJob.perform_later(@current_user.organisation_id.to_s)
  end

  def organisation_sub_appointment_type
    @sub_appointment_types = OrganisationAppointmentCategoryType.where(organisation_id: current_user.organisation_id, is_active: true).order(created_at: :desc)
  end

  def save_sub_appointment_type
    appointment_types = params[:sub_appointment_types]
    appointment_types.try(:each) do |index, value|
      if value[:label] != '' && value[:is_updated] == "true"
        appointment_type_params = { label: value[:label], background: value[:background], organisation_id: @current_user.organisation_id, user_id: @current_user.id.to_s, specialty_ids: value[:specialty_ids].reject(&:blank?) , organisation_appointment_type_ids: value[:organisation_appointment_type_ids].reject(&:blank?) }

        appointment_type_params[:id] = value[:id] if value[:id] != nil
        appointment_type_params[:created_at] = value[:created_at] if value[:created_at] != nil

        if value[:id] != nil
          appointment_type = OrganisationAppointmentCategoryType.find_by(id: value[:id])
          appointment_type.update!(appointment_type_params) if appointment_type.present?
        else
          appointment_type = OrganisationAppointmentCategoryType.new(appointment_type_params)
          appointment_type.save
        end
      end
    end

    @sub_appointment_types = OrganisationAppointmentCategoryType.where(organisation_id: @current_user.organisation_id, is_active: true).order(created_at: :desc)
  end

  def deactivate_sub_appointment_type
    if params[:id].present?
      sub_appointment = OrganisationAppointmentCategoryType.find_by(id: params[:id])
      sub_appointment.update(is_active: false) if sub_appointment.present?
    end

    @sub_appointment_types = OrganisationAppointmentCategoryType.where(organisation_id: @current_user.organisation_id, is_active: true).order(created_at: :desc)
  end

  private

  def set_initial_params
    @current_user = current_user
    @available_specialties = Specialty.where(:id.in => current_organisation["specialty_ids"]).pluck(:name, :id)
    @available_organisation_appointment_types = OrganisationAppointmentType.where(organisation_id: @current_user.organisation_id, is_active: true).pluck(:label, :id).map{ |i| [i[0], i[1].to_s]}
  end
end
