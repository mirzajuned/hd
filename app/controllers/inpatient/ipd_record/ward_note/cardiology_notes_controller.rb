class Inpatient::IpdRecord::WardNote::CardiologyNotesController < Inpatient::IpdRecord::WardNotesController
  before_action :specialty_params

  def index
    super
  end

  def new
    @url_path = "inpatient_ipd_record_ward_note_#{@speciality_folder_name}_notes_path"
    super
  end

  def create
    super
  end

  def edit
    @url_path = "inpatient_ipd_record_ward_note_#{@speciality_folder_name}_note_path"
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
    @specialty = "Cardiology"
    @specialty_id = "394579002"
    @speciality_folder_name = "cardiology"
  end

  # super calls inpatient/ipd_record/ward_notes_controller.rb
end
