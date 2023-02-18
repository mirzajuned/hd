class Inpatient::IpdRecord::ClinicalNote::RheumatologyNotesController < Inpatient::IpdRecord::ClinicalNotesController
  before_action :specialty_params

  def new
    @opd_records = PatientTimeline.where(patient_id: @patient.id, specalityname: 'rheumatology', encountertype: 'OPD', :templatetype.nin => ["freeform"]).order('encounterdate DESC')
    @url = "/inpatient/ipd_record/clinical_note/#{@speciality_folder_name}_notes"
    @method = "POST"
    super
  end

  def create
    super
  end

  def show
    super
  end

  def edit
    @opd_records = PatientTimeline.where(patient_id: @patient.id, specalityname: 'rheumatology', encountertype: 'OPD', :templatetype.nin => ["freeform"]).order('encounterdate DESC')
    @url = "/inpatient/ipd_record/clinical_note/#{@speciality_folder_name}_notes/#{@ipdrecord.id}"
    @method = "PATCH"
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
    @current_user = current_user
    @current_facility = current_facility
    @specialty = "Rheumatology"
    @specialty_id = "394810000"
    @speciality_folder_name = "rheumatology"
  end
  # super calls inpatient/ipd_record/clinical_notes_controller.rb
end
