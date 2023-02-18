class OpdRecords::OrthopedicsNotesController < OpdRecordsController
  before_action :authorize

  def new
    @current_user = current_user
    @current_facility = current_facility
    @templatetype = params[:templatetype]
    @patient = Patient.find(params[:patientid])
    @patient_mrn = @patient.patient_mrn
    @appointment = Appointment.find_by(id: params[:appointmentid])
    @clone_record = params[:flag]
    @show_language_support = @current_facility.show_language_support
    @has_patient_prescription_history = PatientPrescription.where(patient_id: @patient.id).count > 0
    if @show_language_support == true
      @advice_sets = AdviceSet.where(organisation_id: @current_user.organisation_id, is_deleted: false, specialty_id: @appointment.specialty_id, '$or' => [
                                       { level: "organisation" },
                                       { facility_id: @current_facility.id, level: "facility" },
                                       { user_id: @current_user.id, level: "user" }
                                     ]).order(counter: "desc").map { |p| ["#{p[:name]} (#{p[:language_advice_subset].collect { |u| u[:language] }.join(' , ')})     by: #{p[:level].to_s.capitalize}", p.language_advice_subset[0][:content], { 'data-id' => (p[:id]).to_s }] } + Global.ophthal_advice_option.sets.map { |p| ["#{p[:name]} (English , Hindi , Bengali , Kannada , Tamil , Telugu , Gujarati)", { 'data-id' => (p[:id]).to_s }, (p[:content]).to_s] }
    else
      @advice_sets = AdviceSet.where(organisation_id: @current_user.organisation_id, is_deleted: false, specialty_id: @appointment.specialty_id, '$or' => [
                                       { level: "organisation" },
                                       { facility_id: @current_facility.id, level: "facility" },
                                       { user_id: @current_user.id, level: "user" }
                                     ]).order(counter: "desc").map { |p| ["#{p[:name]}  by: #{p[:level].to_s.capitalize}", p.language_advice_subset[0][:content], { 'data-id' => (p[:id]).to_s }] } + Global.ophthal_advice_option.sets.map { |p| [(p[:name]).to_s, { 'data-id' => (p[:id]).to_s }, (p[:content]).to_s] }
    end
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| ["#{p[:en]}", "#{p[:id]}"] }
    if @current_facility.clinical_workflow
      workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointmentid].to_s)
      @consultant_id = workflow.consultant_ids.last
    else
      @consultant_id = @appointment.consultant_id
    end

    if @clone_record == "clone"
      @clone_record_id = params[:opd_record_id]
    else
      @opdrecord = OpdRecord.new
    end
    @url_path = "opd_records_orthopedics_notes_path"
    @url_method = "post"
    super
  end

  def create
    @current_user = current_user
    @current_facility = current_facility
    @patient = Patient.find(params[:opdrecord][:patientid])
    @appointment = Appointment.find(params[:opdrecord][:appointmentid])
    @templatetype = params[:opdrecord][:templatetype]

    if (@templatetype == "express")
      params[:opdrecord][:chiefcomplaintselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:chiefcomplaintselectedtags], params[:opdrecord][:chiefcomplaintselectedtagnames], @appointment.specialty_id.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 33962009)
      params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags], params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtagnames], @appointment.specialty_id.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 413334001)
      params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags], params[:opdrecord][:advice_attributes][:otherprecautionsselectedtagnames], @appointment.specialty_id.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 413334001)
    elsif (@templatetype == "trauma")
      params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags], params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtagnames], @appointment.specialty_id.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 413334001)
      params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags], params[:opdrecord][:advice_attributes][:otherprecautionsselectedtagnames], @appointment.specialty_id.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 413334001)
    elsif (@templatetype == "freeform")
      params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags], params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtagnames], @appointment.specialty_id.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 413334001)
      params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags], params[:opdrecord][:advice_attributes][:otherprecautionsselectedtagnames], @appointment.specialty_id.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 413334001)
      if params[:opdrecord][:clincalevaluation] == "<br>"
        params[:opdrecord][:clincalevaluation] = ""
      end
      if params[:opdrecord][:diagnosis] == "<br>"
        params[:opdrecord][:diagnosis] = ""
      end
      if params[:opdrecord][:plan] == "<br>"
        params[:opdrecord][:plan] = ""
      end
    end
    super
  end

  def edit
    @current_user = current_user
    @current_facility = current_facility
    @patient = Patient.find_by(id: params[:patientid])
    @patient_mrn = @patient.patient_mrn
    @opdrecord = OpdRecord.find_by(id: params[:opdrecordid])
    @appointment = Appointment.find_by(id: @opdrecord.appointmentid)
    if @show_language_support == true
      @advice_sets = AdviceSet.where(organisation_id: @current_user.organisation_id, is_deleted: false, specialty_id: @appointment.specialty_id, '$or' => [
                                       { level: "organisation" },
                                       { facility_id: @current_facility.id, level: "facility" },
                                       { user_id: @current_user.id, level: "user" }
                                     ]).order(counter: "desc").map { |p| ["#{p[:name]} (#{p[:language_advice_subset].collect { |u| u[:language] }.join(' , ')})     by: #{p[:level].to_s.capitalize}", p.language_advice_subset[0][:content], { 'data-id' => (p[:id]).to_s }] } + Global.ophthal_advice_option.sets.map { |p| ["#{p[:name]} (English , Hindi , Bengali , Kannada , Tamil , Telugu , Gujarati)", { 'data-id' => (p[:id]).to_s }, (p[:content]).to_s] }
    else
      @advice_sets = AdviceSet.where(organisation_id: @current_user.organisation_id, is_deleted: false, '$or' => [
                                       { level: "organisation" },
                                       { facility_id: @current_facility.id, level: "facility" },
                                       { user_id: @current_user.id, level: "user" }
                                     ]).order(counter: "desc").map { |p| ["#{p[:name]}  by: #{p[:level].to_s.capitalize}", p.language_advice_subset[0][:content], { 'data-id' => (p[:id]).to_s }] } + Global.ophthal_advice_option.sets.map { |p| [(p[:name]).to_s, { 'data-id' => (p[:id]).to_s }, (p[:content]).to_s] }
    end
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| ["#{p[:en]}", "#{p[:id]}"] }
    @url_path = "opd_records_orthopedics_note_path"
    @url_method = "patch"
    @has_patient_prescription_history = PatientPrescription.where(patient_id: @patient.id).count > 0
    super
  end

  def update
    @current_user = current_user
    @current_facility = current_facility
    @templatetype = params[:opdrecord][:templatetype]
    @opdrecord = OpdRecord.find_by(id: params[:opdrecord][:opdrecordid])
    @appointment = Appointment.find_by(id: params[:opdrecord][:appointmentid])
    @patient = Patient.find_by(id: params[:opdrecord][:patientid])
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@opdrecord.specalityid)
    @specalityid = @opdrecord.specalityid
    @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
    @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
    if (@templatetype == "express")
      params[:opdrecord][:chiefcomplaintselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:chiefcomplaintselectedtags], params[:opdrecord][:chiefcomplaintselectedtagnames], @specalityid.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 33962009)
      params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags], params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtagnames], @specalityid.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 413334001)
      params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags], params[:opdrecord][:advice_attributes][:otherprecautionsselectedtagnames], @specalityid.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 413334001)
    elsif (@templatetype == "trauma")
      params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags], params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtagnames], @specalityid.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 413334001)
      params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags], params[:opdrecord][:advice_attributes][:otherprecautionsselectedtagnames], @specalityid.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 413334001)
    elsif (@templatetype == "freeform")
      params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags], params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtagnames], @specalityid.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 413334001)
      params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags], params[:opdrecord][:advice_attributes][:otherprecautionsselectedtagnames], @specalityid.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 413334001)
      if params[:opdrecord][:clincalevaluation] == "<br>"
        params[:opdrecord][:clincalevaluation] = ""
      end
      if params[:opdrecord][:diagnosis] == "<br>"
        params[:opdrecord][:diagnosis] = ""
      end
      if params[:opdrecord][:plan] == "<br>"
        params[:opdrecord][:plan] = ""
      end
    end
    super
  end
end
