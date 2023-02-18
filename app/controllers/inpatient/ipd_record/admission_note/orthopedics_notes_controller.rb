class Inpatient::IpdRecord::AdmissionNote::OrthopedicsNotesController < Inpatient::IpdRecord::AdmissionNotesController
  before_action :department, only: ['new', 'edit']

  def new
    @url_path = "inpatient_ipd_record_admission_note_orthopedics_notes_path"
    super
  end

  def create
    super
  end

  def edit
    @url_path = "inpatient_ipd_record_admission_note_orthopedics_note_path"
    super
  end

  def update
    super
  end

  private

  def department
    @department = "Orthopedics"
    @department_id = "309989009"
    @department_notes = "orthopedics_notes"
  end

  # super calls inpatient/ipd_record/admission_notes_controller.rb
end
