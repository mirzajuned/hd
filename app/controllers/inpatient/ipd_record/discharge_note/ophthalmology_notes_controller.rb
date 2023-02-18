class Inpatient::IpdRecord::DischargeNote::OphthalmologyNotesController < Inpatient::IpdRecord::DischargeNotesController
  before_action :specialty_params, only: [:new, :create, :show, :edit, :update, :print]

  def new
    @url_path = "inpatient_ipd_record_discharge_note_ophthalmology_notes_path"
    super
  end

  def create
    super
  end

  def show
    # '58b6b43a6c55d3b8a5400a1e'(local), 
    # 5e21ffd6cd29ba0ce0bf5a1e (shankara)
    @is_shankara = (current_organisation['_id'] == '5e21ffd6cd29ba0ce0bf5a1e')
    super
  end

  def edit
    @url_path = "inpatient_ipd_record_discharge_note_ophthalmology_note_path"
    super
  end

  def update
    super
  end

  def print
    super
  end

  def print_medications
    super
  end

  private

  def specialty_params
    @specialty = "Ophthalmology"
    @specialty_id = "309988001"
    @speciality_folder_name = "ophthalmology"
  end

  # super calls inpatient/ipd_record/discharge_notes_controller.rb
end
