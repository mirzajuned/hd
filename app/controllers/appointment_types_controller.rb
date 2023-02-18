class AppointmentTypesController < ApplicationController
  before_action :authorize
  before_action :set_initial_params

  def facility_appointment_type
    @appointment_types = AppointmentType.where(facility_id: @current_facility.id, is_active: true).order_by({ is_default: :desc }, { created_at: :asc })
  end

  def save_facility_appointment_type
    @appointment_types = params[:appointment_type]
    @appointment_types.try(:each) do |index, value|
      if value[:label] != '' && value[:duration] != '' && value[:is_updated] == "true"
        params_values = { label: value[:label], background: value[:background], is_default: value[:is_default], is_active: value[:is_active], duration: value[:duration], organisation_id: value[:organisation_id], comment: value[:comment], facility_id: value[:facility_id], organisation_appointment_type_id: value[:organisation_appointment_type_id] }

        params_values[:id] = value[:id] if value[:id] != nil

        appointment_type = AppointmentType.find_by(id: params_values[:id])
        appointment_type.update(params_values) if appointment_type.present?
      end
    end

    @appointment_types = AppointmentType.where(facility_id: @current_facility.id, is_active: true).order_by({ is_default: :desc }, { created_at: :asc })
  end

  private

  def set_initial_params
    @current_facility = current_facility
    @available_specialties = Specialty.where(:id.in => current_organisation["specialty_ids"]).pluck(:name, :id)
  end
end
