class Inpatient::IpdRecord::DischargeNote::CardiologyNotesController < Inpatient::IpdRecord::DischargeNotesController
  before_action :specialty_params, only: [:new, :create, :show, :edit, :update, :print]

  def new
    @url_path = "inpatient_ipd_record_discharge_note_#{@speciality_folder_name}_notes_path"
    super
  end

  def create
    super
  end

  def show
    super
  end

  def edit
    @url_path = "inpatient_ipd_record_#{@speciality_folder_name}_note_ophthalmology_note_path"
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
    @specialty = "Cardiology"
    @specialty_id = "394579002"
    @speciality_folder_name = "cardiology"
  end

  # super calls inpatient/ipd_record/discharge_notes_controller.rb
end
