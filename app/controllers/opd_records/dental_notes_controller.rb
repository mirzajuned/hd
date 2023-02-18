class OpdRecords::DentalNotesController < OpdRecordsController
  before_action :authorize
  before_action :set_init_params

  def new
    @templatetype = params[:templatetype]
    @patient = Patient.find_by(id: params[:patientid])
    @patient_mrn = @patient.patient_mrn
    @appointment = Appointment.find_by(id: params[:appointmentid])
    @clone_record = params[:flag]

    get_advice_and_medication_sets

    if @current_facility.clinical_workflow
      @consultant_id = OpdClinicalWorkflow.find_by(appointment_id: params[:appointmentid].to_s).consultant_ids.last
    else
      @consultant_id = @appointment.consultant_id
    end

    if @clone_record == "clone"
      @clone_record_id = params[:opd_record_id]
    else
      @opdrecord = OpdRecord.new
    end

    @url_path = "opd_records_dental_notes_path"
    @url_method = "post"
    super
  end

  def create
    @patient = Patient.find_by(id: params[:opdrecord][:patientid])
    @appointment = Appointment.find_by(id: params[:opdrecord][:appointmentid])
    @templatetype = params[:opdrecord][:templatetype]

    if (@templatetype == "freeform")
      params[:opdrecord][:clincalevaluation] = "" if params[:opdrecord][:clincalevaluation] == "<br>"
      params[:opdrecord][:diagnosis] = "" if params[:opdrecord][:diagnosis] == "<br>"
      params[:opdrecord][:plan] = "" if params[:opdrecord][:plan] == "<br>"
    end

    super
  end

  def edit
    @patient = Patient.find_by(id: params[:patientid])
    @patient_mrn = @patient.patient_mrn
    @opdrecord = OpdRecord.find_by(id: params[:opdrecordid])
    @appointment = Appointment.find_by(id: @opdrecord.appointmentid)

    get_advice_and_medication_sets

    @url_path = "opd_records_dental_note_path"
    @url_method = "patch"

    super
  end

  def update
    @patient = Patient.find_by(id: params[:opdrecord][:patientid])
    @appointment = Appointment.find_by(id: params[:opdrecord][:appointmentid])
    @opdrecord = OpdRecord.find_by(id: params[:id])
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@opdrecord.specalityid)
    @templatetype = params[:opdrecord][:templatetype]
    @specalityid = @opdrecord.specalityid
    @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
    @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)

    if (@templatetype == "freeform")
      params[:opdrecord][:clincalevaluation] = "" if params[:opdrecord][:clincalevaluation] == "<br>"
      params[:opdrecord][:diagnosis] = "" if params[:opdrecord][:diagnosis] == "<br>"
      params[:opdrecord][:plan] = "" if params[:opdrecord][:plan] == "<br>"
    end

    super
  end

  private

  def set_init_params
    @current_user = current_user
    @current_facility = current_facility
  end

  def get_advice_and_medication_sets
    @advice_sets = AdviceSet.where(organisation_id: @current_user.organisation_id, is_deleted: false, specialty_id: @appointment.specialty_id, '$or' => [{ level: "organisation" }, { facility_id: @current_facility.id, level: "facility" }, { user_id: @current_user.id, level: "user" }]).order(counter: "desc")

    if @current_facility.show_language_support
      @advice_sets = @advice_sets.map { |p| ["#{p[:name]} (#{p[:language_advice_subset].collect { |u| u[:language] }.join(" , ")})  by: #{p[:level].to_s.capitalize}", p.language_advice_subset[0][:content], { 'data-id' => "#{p[:id]}" }] }
    else
      @advice_sets = @advice_sets.map { |p| ["#{p[:name]} by: #{p[:level].to_s.capitalize}", p.language_advice_subset[0][:content], { 'data-id' => "#{p[:id]}" }] }
    end

    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| ["#{p[:en]}", "#{p[:id]}"] }
  end
end
