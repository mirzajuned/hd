class Inpatient::IpdRecord::WardNote::PediatricNotesController < Inpatient::IpdRecord::WardNotesController
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
    @specialty = "Pediatric"
    @specialty_id = "394537008"
    @speciality_folder_name = "pediatric"
  end
  # super calls inpatient/ipd_record/ward_notes_controller.rb
end
