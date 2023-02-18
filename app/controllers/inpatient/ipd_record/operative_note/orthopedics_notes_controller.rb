class Inpatient::IpdRecord::OperativeNote::OrthopedicsNotesController < Inpatient::IpdRecord::OperativeNotesController
  before_action :specialty_params, only: [:new, :create, :show, :edit, :update, :print]

  def new
    @url_path = "inpatient_ipd_record_operative_note_orthopedics_notes_path"
    @procedurenotes = ProcedureNote.where(:organisation_id => current_user.organisation_id.to_s, is_active: true, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id, level: 'facility' }, { user_id: current_user.id, level: 'user' }])
    super
  end

  def create
    super
  end

  def show
    super
  end

  def edit
    @url_path = "inpatient_ipd_record_operative_note_orthopedics_note_path"
    @procedurenotes = ProcedureNote.where(:organisation_id => current_user.organisation_id, is_active: true, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id, level: 'facility' }, { user_id: current_user.id, level: 'user' }])
    super
  end

  def update
    super
  end

  def print
    super
  end

  private

  def specialty_params
    @specialty = "Orthopedics"
    @specialty_id = "309989009"
    @speciality_folder_name = "orthopedics"
  end

  # super calls inpatient/ipd_record/operative_notes_controller.rb
end
