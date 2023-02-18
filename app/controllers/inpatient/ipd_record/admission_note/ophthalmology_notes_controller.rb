class Inpatient::IpdRecord::AdmissionNote::OphthalmologyNotesController < Inpatient::IpdRecord::AdmissionNotesController
  before_action :specialty_params, only: ['new', 'edit']

  def new
    @url_path = "inpatient_ipd_record_admission_note_ophthalmology_notes_path"
    super
  end

  def create
    super
  end

  def edit
    @url_path = "inpatient_ipd_record_admission_note_ophthalmology_note_path"
    super
  end

  def update
    super
  end

  private

  def specialty_params
    @department = "Ophthalmology"
    @department_id = "309988001"
    @department_notes = "ophthalmology_notes"
  end

  # super calls inpatient/ipd_record/admission_notes_controller.rb
end
