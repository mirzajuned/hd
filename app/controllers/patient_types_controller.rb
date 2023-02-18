class PatientTypesController < ApplicationController
  def index
    @patient_types = PatientType.where(is_active: true, organisation_id: current_user.organisation_id)
  end

  def create
    organisation_id = current_user.organisation_id
    removed_patient_type = params[:removed_patient_type].split(',')

    # Remove all Cancel PatientType
    PatientType.where(:id.in => removed_patient_type).update_all(is_active: false)

    # Params PatientType
    params[:patient_types].try(:each) do |key, value|
      @patient_type = PatientType.find_by(id: value[:id])
      options = { label: value[:label], color: value[:color], organisation_id: organisation_id }

      # Create/Update PatientType
      (PatientType.create(options) if @patient_type.nil?) || @patient_type.update(options)
    end
  end
end
