# 18  Metrics/LineLength
# 7   Metrics/MethodLength
# 4   Metrics/AbcSize
# 3   Metrics/BlockNesting
# 1   Metrics/ClassLength
# 1   Metrics/CyclomaticComplexity
# 1   Metrics/PerceivedComplexity
# 1   Naming/AccessorMethodName
# --
# 36  Total
class OpdRecords::OphthalmologyNotesController < OpdRecordsController
  before_action :authorize
  before_action :current_organisations_setting, only: [:new, :create, :edit, :update]

  def new
    @current_user = current_user
    @current_facility = current_facility
    @procedures = CommonProcedure::Ophthalmology.all
    @templatetype = params[:templatetype]
    @patient = Patient.find_by(id: params[:patientid])
    @patient_identifier_id = @patient.patient_identifier_id
    @patient_mrn = @patient.patient_mrn
    @appointment = Appointment.find_by(id: params[:appointmentid])
    @clone_record = params[:flag]
    @show_language_support = @current_facility.show_language_support
    @has_patient_prescription_history = PatientPrescription.where(patient_id: @patient.id).count > 0
    if @show_language_support == true
      @advice_sets = AdviceSet.where(organisation_id: @current_user.organisation_id, is_deleted: false, specialty_id: @appointment.specialty_id, '$or' => [
                                       { level: 'organisation' },
                                       { facility_id: @current_facility.id, level: 'facility' },
                                       { user_id: @current_user.id, level: 'user' }
                                     ]).order(counter: 'desc').map { |p| ["#{p[:name]} (#{p[:language_advice_subset].collect { |u| u[:language] }.join(' , ')})     by: #{p[:level].to_s.capitalize}", p.language_advice_subset[0][:content], { 'data-id' => (p[:id]).to_s }] } + Global.ophthal_advice_option.sets.map { |p| ["#{p[:name]} (English , Hindi , Bengali , Kannada , Tamil , Telugu , Gujarati)", { 'data-id' => (p[:id]).to_s }, (p[:content]).to_s] }

    else
      @advice_sets = AdviceSet.where(organisation_id: @current_user.organisation_id, is_deleted: false, specialty_id: @appointment.specialty_id, '$or' => [
                                       { level: 'organisation' },
                                       { facility_id: @current_facility.id, level: 'facility' },
                                       { user_id: @current_user.id, level: 'user' }
                                     ]).order(counter: 'desc').map { |p| ["#{p[:name]}  by: #{p[:level].to_s.capitalize}", p.language_advice_subset[0][:content], { 'data-id' => (p[:id]).to_s }] } + Global.ophthal_advice_option.sets.map { |p| [(p[:name]).to_s, { 'data-id' => (p[:id]).to_s }, (p[:content]).to_s] }
    end
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] }

    if @current_facility.clinical_workflow
      workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointmentid].to_s)
      @consultant_id = workflow.consultant_ids.last
    else
      @consultant_id = @appointment.consultant_id
    end
    if @clone_record == 'clone'
      @clone_record_id = params[:opd_record_id]
    elsif ['eye', 'quickeye', 'paediatrics', 'postop', 'optometrist', 'nursing', 'vision'].include? @templatetype
      @patient_self_history = PatientSelfHistory.where(patient_id: @patient.id.to_s).order_by('created_at DESC')[0]
      find_ipd_record_for_postop
      @opdrecord = OpdRecord.new
      @opdrecord.chief_complaints
      @opdrecord.speciality_history_records

      @optometrist_record = OpdRecord.where(templatetype: 'optometrist', specalityid: @appointment.specialty_id, patientid: @patient.id.to_s)

      @record = OpdRecord.where(:templatetype.in => ['optometrist', 'nursing', 'refraction', 'ar_nct'], :specalityid => @appointment.specialty_id, :patientid => @patient.id.to_s, :appointmentid => @appointment.id.to_s).order_by(created_at: 'asc')
      unless @record.empty?
        if @record.last
          @record_keys_values_n = {}
          if current_facility.country_id != 'VN_254'
            record_keys_values_r
            record_keys_values_l
          else
            refraction_keys_values_r
            refraction_keys_values_l
            refraction_keys_values_n
          end
          record_refraction_keys_values_other
          record_exam_keys_values_r
          record_exam_keys_values_l
          record_exam_keys_values_other
          record_vital_signs
          record_checkup
          record_keys_values_chiefcomplaint
          record_keys_values_other
          chief_complaints_comment
          @opdrecord.attributes = @record_keys_values_r.merge(@record_keys_values_l)
                                                       .merge(@record_keys_values_other)
                                                       .merge(@record_vital_signs)
                                                       .merge(@record_checkup_values)
                                                       .merge(@record_keys_values_n)
                                                       .merge(@record_refraction_keys_values_other)
                                                       .merge(@record_exam_keys_values_r)
                                                       .merge(@record_exam_keys_values_l)
                                                       .merge(@record_exam_keys_values_other)
          @opdrecord.complaints = record_keys_values_chiefcomplaint.pluck(:name).join(',')
          @opdrecord.chief_complaints = record_keys_values_chiefcomplaint
          @opdrecord.chiefcomplaint_comments = chief_complaints_comment
          @new_opt_view = 'optometrist' if @templatetype != 'optometrist' && @record.last.templatetype != 'nursing' && @opdrecord.templatetype == 'vision'
        end
      end
    elsif @templatetype == 'pmt'
      @opdrecord = OpdRecord.new
      @record = OpdRecord.where(:templatetype.in => ['eye', 'quickeye', 'paediatrics', 'vision'], :specalityid => @appointment.specialty_id, :patientid => @patient.id.to_s, :created_at.lt => Date.current).order_by(created_at: 'asc')
      unless @record.empty?
        if @record.last
          @record_keys_values_n = {}
          if current_facility.country_id != 'VN_254'
            record_keys_values_r
            record_keys_values_l
          else
            refraction_keys_values_r
            refraction_keys_values_l
            refraction_keys_values_n
          end
          record_refraction_keys_values_other
          record_exam_keys_values_r
          record_exam_keys_values_l
          record_exam_keys_values_other
          record_vital_signs
          record_checkup
          record_keys_values_other
          @opdrecord.attributes = @record_keys_values_l.merge(@record_keys_values_r)
                                                       .merge(@record_keys_values_other)
                                                       .merge(@record_vital_signs)
                                                       .merge(@record_checkup_values)
                                                       .merge(@record_keys_values_n)
                                                       .merge(@record_refraction_keys_values_other)
                                                       .merge(@record_exam_keys_values_r)
                                                       .merge(@record_exam_keys_values_l)
                                                       .merge(@record_exam_keys_values_other)
          # @new_opt_view = "optometrist"
        end
      end
    else
      # @optometrist_record = OpdRecord.where(:templatetype => "optometrist", :specalityid => @appointment.specialty_id, :patientid => @patient.id.to_s, :created_at => {'$lt' => Date.current })
      @optometrist_record = OpdRecord.where(templatetype: 'optometrist', specalityid: @appointment.specialty_id, patientid: @patient.id.to_s)
      @opdrecord = OpdRecord.new
    end

    @custom_ophthal_investigations = CustomOphthalInvestigation.where(organisation_id: @current_user.organisation_id, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id.to_s, level: 'facility' }], is_deleted: false)
    @url_path = 'opd_records_ophthalmology_notes_path'
    @url_method = 'post'
    super
  end

  def create
    @current_user = current_user
    @current_facility = current_facility
    @patient = Patient.find(params[:opdrecord][:patientid])
    @appointment = Appointment.find_by(id: params[:opdrecord][:appointmentid])
    @templatetype = params[:opdrecord][:templatetype]

    if @templatetype == 'express'
      params[:opdrecord][:chiefcomplaintselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:chiefcomplaintselectedtags], params[:opdrecord][:chiefcomplaintselectedtagnames], @appointment.specialty_id.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 33962009)
    elsif @templatetype == 'freeform'
      params[:opdrecord][:clincalevaluation] = '' if params[:opdrecord][:clincalevaluation] == '<br>'
      params[:opdrecord][:diagnosis] = '' if params[:opdrecord][:diagnosis] == '<br>'
      params[:opdrecord][:plan] = '' if params[:opdrecord][:plan] == '<br>'
    end
    super
  end

  def edit
    @current_user = current_user
    @current_facility = current_facility
    @procedures = CommonProcedure::Ophthalmology.all
    @patient = Patient.find(params[:patientid])
    @patient_identifier_id = @patient.patient_identifier_id
    @patient_mrn = @patient.patient_mrn
    @opdrecord = OpdRecord.find_by(id: params[:id])
    @appointment = Appointment.find_by(id: @opdrecord.appointmentid)
    @advice_sets = AdviceSet.where(organisation_id: @current_user.organisation_id, is_deleted: false, specialty_id: @appointment.specialty_id, '$or' => [
                                     { level: 'organisation' },
                                     { facility_id: current_facility.id, level: 'facility' },
                                     { user_id: @current_user.id, level: 'user' }
                                   ]).order(counter: 'desc').map { |p| ["#{p[:name]}  (#{p[:language_advice_subset].collect { |u| u[:language] }.join(' , ')}) by: #{p[:level].to_s.capitalize}", p.language_advice_subset[0][:content], { 'data-id' => (p[:id]).to_s }] } + Global.ophthal_advice_option.sets.map { |p| ["#{p[:name]} (English , Hindi , Bengali , Kannada , Tamil , Telugu , Gujarati)", { 'data-id' => (p[:id]).to_s }, (p[:content]).to_s] }
    @optometrist_record = OpdRecord.where(templatetype: 'optometrist', specalityid: @opdrecord.specalityid, patientid: @patient.id.to_s)
    @patient_self_history = PatientSelfHistory.where(patient_id: @patient.id.to_s).order_by('created_at DESC')[0]
    @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| [(p[:en]).to_s, (p[:id]).to_s] }

    @new_opt_view = 'optometrist' unless @opdrecord.templatetype == 'optometrist' || @opdrecord.templatetype == 'vision'
    find_ipd_record_for_postop if @opdrecord.templatetype == 'postop'
    @custom_ophthal_investigations = CustomOphthalInvestigation.where(organisation_id: @current_user.organisation_id, '$or' => [{ level: 'organisation' }, { facility_id: @current_facility.id.to_s, level: 'facility' }], is_deleted: false)
    @url_path = 'opd_records_ophthalmology_note_path'
    @url_method = 'patch'
    @has_patient_prescription_history = PatientPrescription.where(patient_id: @patient.id).count > 0
    super
  end

  def update
    @current_user = current_user
    @current_facility = current_facility
    @patient = Patient.find_by(id: params[:opdrecord][:patientid])
    @appointment = Appointment.find_by(id: params[:opdrecord][:appointmentid])
    @opdrecord = OpdRecord.find_by(id: params[:id])
    if @opdrecord.try(:treatmentmedication).present?
      @medication = 'true'
      @medication_groups = @opdrecord.treatmentmedication.group_by(&:status)
    end
    @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@opdrecord.try(:specalityid))
    @templatetype = params[:opdrecord][:templatetype]
    @specalityid = @opdrecord.try(:specalityid)
    @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(
      @speciality_folder_name, @templatetype
    )
    @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(
      @speciality_folder_name, @templatetype
    )
    if @templatetype == 'express'
      params[:opdrecord][:chiefcomplaintselectedtags] = OpdRecord.compute_mongoid_for_tags(
        params[:opdrecord][:chiefcomplaintselectedtags],
        params[:opdrecord][:chiefcomplaintselectedtagnames],
        @specalityid.to_i, @current_user.organisation.id.to_s,
        @current_user.id.to_s, 33962009
      )
    elsif @templatetype == 'freeform'
      params[:opdrecord][:clincalevaluation] = '' if params[:opdrecord][:clincalevaluation] == '<br>'
      params[:opdrecord][:diagnosis] = '' if params[:opdrecord][:diagnosis] == '<br>'
      params[:opdrecord][:plan] = '' if params[:opdrecord][:plan] == '<br>'
    end
    super
  end

  def fill_patient_self_history
    @patient_self_history = PatientSelfHistory.where(patient_id: params[:patient_id]).order_by('created_at DESC')[0]
  end

  def fill_refraction_data
    @flag = params[:flag]
    respond_to do |format|
      format.js { 'fill_refraction_data' }
    end
  end

  def fill_retinoscopy_data
    @flag = params[:flag]
  end

  def get_ipd_data
    @count = params[:row_count]
    @command = params[:command]
    if params[:ipd_record_id].present?

      @ipd_record = Inpatient::IpdRecord.find_by(id: params[:ipd_record_id])
      @procedures = if @ipd_record.present?
                      @ipd_record.procedure
                    else
                      []
                    end
    end

    respond_to do |format|
      format.js { render '/opd_records/ophthalmology_notes/get_ipd_data' }
    end
  end

  private

  def current_organisations_setting
    @organisations_setting = OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id))
  end

  def find_ipd_record_for_postop
    @ipd_records = Inpatient::IpdRecord.where(patient_id: @patient.id)
    @useful_ipd_records = []
    @ipd_records.where(is_deleted: false).each do |record|
      next unless record.procedure.count > 0

      @useful_ipd_records << record if record.procedure.where(procedurestage: 'Performed').count > 0
    end
  end

  def record_keys_values_r
    record = @record.find_by(templatetype: 'optometrist') || @record.last
    @record_keys_values_r = record.attributes.slice(
      :r_autorefraction_dry_sph, :r_autorefraction_dry_cyl, :r_autorefraction_dry_axis,
      :r_autorefraction_dry1_sph, :r_autorefraction_dry1_cyl, :r_autorefraction_dry1_axis,
      :r_autorefraction_dry2_sph, :r_autorefraction_dry2_cyl, :r_autorefraction_dry2_axis, :r_autorefraction_dilated1_sph,
      :r_autorefraction_dilated1_cyl, :r_autorefraction_dilated1_axis, :r_autorefraction_dilated2_sph,
      :r_autorefraction_dilated2_cyl, :r_autorefraction_dilated2_axis, :r_autorefraction_dilated3_sph,
      :r_autorefraction_dilated3_cyl, :r_autorefraction_dilated3_axis, :r_visualacuity_unaided, :no_right_va_advised,
      :r_visualacuity_unaided_comments, :r_visualacuity_ua_s, :r_visualacuity_ua_i, :r_visualacuity_ua_n,
      :r_visualacuity_ua_t, :r_visualacuity_unaided_p, :r_visualacuity_pinhole, :r_visualacuity_pinhole_comments,
      :r_visualacuity_pinhole_p, :r_visualacuity_pinhole_ni, :r_visualacuity_glasses, :r_visualacuity_glasses_comments,
      :r_visualacuity_glasses_p, :r_visualacuity_near, :r_visualacuity_near_comments, :r_visualacuity_near_p,
      :r_visualacuity_lens_p, :r_visualacuity_lens, :r_visualacuity_lens_comments, :r_visualacuity_ua_near,
      :r_visualacuity_ua_near_comments, :r_visualacuity_ua_near_p, :r_visualacuity_comments, :r_refraction_distant_sph,
      :r_refraction_distant_cyl, :r_refraction_distant_axis, :r_refraction_distant_vision, :r_refraction_add_sph,
      :r_refraction_add_cyl, :r_refraction_add_axis, :r_refraction_add_vision, :r_refraction_near_sph,
      :r_refraction_near_cyl, :r_refraction_near_axis, :r_refraction_near_vision, :r_refraction_comments,
      :r_dilatedrefraction_distant_sph, :r_dilatedrefraction_distant_cyl, :r_dilatedrefraction_distant_axis,
      :r_contrastsensitivity, :r_contrastsensitivity_comments, 
      :r_dilatedrefraction_distant_vision, :r_dilatedrefraction_add_sph,
      :r_dilatedrefraction_add_cyl, :r_dilatedrefraction_add_axis, :r_dilatedrefraction_add_vision,
      :r_dilatedrefraction_near_sph, :r_dilatedrefraction_near_cyl, :r_dilatedrefraction_near_axis,
      :r_dilatedrefraction_near_vision, :r_dilatedrefraction_drug_used, :r_dilatedrefraction_comments,
      :r_keratometry_distant_kh, :r_keratometry_distant_axis, :r_keratometry_near_kv, :r_keratometry_near_axis,
      :r_pgp_distant_sph, :r_pgp_distant_cyl, :r_pgp_distant_axis, :r_pgp_distant_vision, :r_pgp_near_sph,
      :r_pgp_near_cyl, :r_pgp_near_axis, :r_pgp_near_vision, :r_pgp_add_sph, :r_pgp_add_cyl, :r_pgp_add_axis,
      :r_pgp_add_vision, :r_pgp_typeoflens, :r_near_pgp_distant_sph, :r_near_pgp_distant_cyl, :r_near_pgp_distant_axis,
      :r_near_pgp_distant_vision, :r_near_pgp_near_sph, :r_near_pgp_near_cyl, :r_near_pgp_near_axis,
      :r_near_pgp_near_vision, :r_near_pgp_add_sph, :r_near_pgp_add_cyl, :r_near_pgp_add_axis, :r_near_pgp_add_vision,
      :r_near_pgp_typeoflens, :r_pgp_distant_sph2, :r_pgp_distant_cyl2, :r_pgp_distant_axis2, :r_pgp_distant_vision2,
      :r_pgp_near_sph2, :r_pgp_near_cyl2, :r_pgp_near_axis2, :r_pgp_near_vision2, :r_pgp_add_sph2, :r_pgp_add_cyl2,
      :r_pgp_add_axis2, :r_pgp_add_vision2, :r_pgp_typeoflens2, :r_near_pgp_distant_sph2, :r_near_pgp_distant_cyl2,
      :r_near_pgp_distant_axis2, :r_near_pgp_distant_vision2, :r_near_pgp_near_sph2, :r_near_pgp_near_cyl2,
      :r_near_pgp_near_axis2, :r_near_pgp_near_vision2, :r_near_pgp_add_sph2, :r_near_pgp_add_cyl2,
      :r_near_pgp_add_axis2, :r_near_pgp_add_vision2, :r_near_pgp_typeoflens2, :r_pgp_distant_sph3, :r_pgp_distant_cyl3,
      :r_pgp_distant_axis3, :r_pgp_distant_vision3, :r_pgp_near_sph3, :r_pgp_near_cyl3, :r_pgp_near_axis3,
      :r_pgp_near_vision3, :r_pgp_add_sph3, :r_pgp_add_cyl3, :r_pgp_add_axis3, :r_pgp_add_vision3, :r_pgp_typeoflens3,
      :r_near_pgp_distant_sph3, :r_near_pgp_distant_cyl3, :r_near_pgp_distant_axis3, :r_near_pgp_distant_vision3,
      :r_near_pgp_near_sph3, :r_near_pgp_near_cyl3, :r_near_pgp_near_axis3, :r_near_pgp_near_vision3,
      :r_near_pgp_add_sph3, :r_near_pgp_add_cyl3, :r_near_pgp_add_axis3, :r_near_pgp_add_vision3,
      :r_near_pgp_typeoflens3, :r_pgp_comments, :r_pgp_comments2, :r_pgp_comments3, :no_right_iop_advised,
      :r_intraocularpressure, :r_intraocularpressure_time, :r_intraocularpressure_comments,
      :r_glassesprescriptions_distant_vision, :r_glassesprescriptions_distant_sph, :r_glassesprescriptions_distant_cyl,
      :r_glassesprescriptions_distant_axis, :r_glassesprescriptions_add_sph, :r_glassesprescriptions_add_vision,
      :r_glassesprescriptions_near_vision, :r_glassesprescriptions_near_sph, :r_glassesprescriptions_near_cyl,
      :r_glassesprescriptions_near_axis, :r_acceptance_framematerial, :r_acceptance_ipd, :r_acceptance_lensmaterial,
      :r_acceptance_lenstint, :r_acceptance_typeoflens, :r_acceptance_comments, :r_contactlens_bc, :r_contactlens_dia,
      :r_contactlens_sph, :r_contactlens_cyl, :r_contactlens_axis, :r_contactlens_add, :r_contactlens_color,
      :r_contactlens_types, :r_contactlens_comments, :r_chiefcomplaint, :r_blurringdiminution_vision,
      :r_blurringdiminution_pain, :r_blurringdiminution_usingglasses, :r_deviationsquint_diplopia,
      :r_deviationsquint_trauma, :r_deviationsquint_pastsurgery, :r_othervisualsymptoms_glare,
      :r_othervisualsymptoms_floaters, :r_othervisualsymptoms_photophobia, :r_othervisualsymptoms_coloredhalos,
      :r_othervisualsymptoms_metamorphosia, :r_othervisualsymptoms_chromatopsia,
      :r_othervisualsymptoms_diminishednightvision, :r_othervisualsymptoms_diminisheddayvision,
      :r_subjective_duration_no, :r_subjective_duration_unit, :r_subjectivecomments, :r_dilated_retinoscopy_top_va1,
      :r_dilated_retinoscopy_bottom_va2, :r_dilated_retinoscopy_left_ha1, :r_dilated_retinoscopy_right_ha2,
      :r_dilated_retinoscopy_va, :r_dilated_retinoscopy_ha, :r_dilated_retinoscopy_distance, :r_retinoscopy_drug_used,
      :r_retinoscopy_comments, :r_dilatedretinoscopy_pmt_axis, :r_dilatedretinoscopy_pmt_sph,
      :r_dilatedretinoscopy_pmt_cyl, :r_dilatedretinoscopy_pmt_vision, :r_dilatedretinoscopy_pmt_axis_row2,
      :r_dilatedretinoscopy_pmt_sph_row2, :r_dilatedretinoscopy_pmt_cyl_row2, :r_dilatedretinoscopy_pmt_vision_row2,
      :r_dilatedretinoscopy_pmt_axis_row3, :r_dilatedretinoscopy_pmt_sph_row3, :r_dilatedretinoscopy_pmt_cyl_row3,
      :r_dilatedretinoscopy_pmt_vision_row3, :r_color_vision, :r_orthoptics,
      :r_intermediate_glasses_prescriptions_distant_sph, :r_intermediate_glasses_prescriptions_distant_cyl,
      :r_intermediate_glasses_prescriptions_distant_axis, :r_intermediate_glasses_prescriptions_distant_vision,
      :r_intermediate_glasses_prescriptions_add_sph, :r_intermediate_glasses_prescriptions_add_cyl,
      :r_intermediate_glasses_prescriptions_add_axis, :r_intermediate_glasses_prescriptions_add_vision,
      :r_intermediate_glasses_prescriptions_near_sph, :r_intermediate_glasses_prescriptions_near_cyl,
      :r_intermediate_glasses_prescriptions_near_axis, :r_intermediate_glasses_prescriptions_near_vision,
      :r_intermediate_acceptance_typeoflens, :r_intermediate_acceptance_ipd, :r_intermediate_acceptance_lensmaterial,
      :r_intermediate_acceptance_lenstint, :r_intermediate_acceptance_framematerial, :r_intermediate_acceptance_comments,
      :r_acceptance_dia, :r_acceptance_size, :r_acceptance_fitting_height, :r_acceptance_prism_base,
      :l_acceptance_fitting_height, :l_acceptance_prism_base, :l_acceptance_dia, :l_acceptance_size, 
    )
  end

  def record_keys_values_l
    record = @record.find_by(templatetype: 'optometrist') || @record.last
    @record_keys_values_l = record.attributes.slice(
      :l_autorefraction_dry_sph, :l_autorefraction_dry_cyl, :l_autorefraction_dry_axis,
      :l_autorefraction_dry1_sph, :l_autorefraction_dry1_cyl, :l_autorefraction_dry1_axis,
      :l_autorefraction_dry2_sph, :l_autorefraction_dry2_cyl, :l_autorefraction_dry2_axis, :l_autorefraction_dilated1_sph,
      :l_autorefraction_dilated1_cyl, :l_autorefraction_dilated1_axis, :l_autorefraction_dilated2_sph,
      :l_autorefraction_dilated2_cyl, :l_autorefraction_dilated2_axis, :l_autorefraction_dilated3_sph,
      :l_autorefraction_dilated3_cyl, :l_autorefraction_dilated3_axis, :l_visualacuity_unaided, :no_left_va_advised,
      :l_visualacuity_unaided_comments, :l_visualacuity_ua_s, :l_visualacuity_ua_i, :l_visualacuity_ua_n,
      :l_visualacuity_ua_t, :l_visualacuity_unaided_p, :l_visualacuity_pinhole, :l_visualacuity_pinhole_comments,
      :l_visualacuity_pinhole_p, :l_visualacuity_pinhole_ni, :l_visualacuity_glasses, :l_visualacuity_glasses_comments,
      :l_visualacuity_glasses_p, :l_visualacuity_near, :l_visualacuity_near_comments, :l_visualacuity_near_p,
      :l_visualacuity_lens_p, :l_visualacuity_lens, :l_visualacuity_lens_comments, :l_visualacuity_ua_near,
      :l_visualacuity_ua_near_comments, :l_visualacuity_ua_near_p, :l_visualacuity_comments, :l_refraction_distant_sph,
      :l_refraction_distant_cyl, :l_refraction_distant_axis, :l_refraction_distant_vision, :l_refraction_add_sph,
      :l_refraction_add_cyl, :l_refraction_add_axis, :l_refraction_add_vision, :l_refraction_near_sph,
      :l_refraction_near_cyl, :l_refraction_near_axis, :l_refraction_near_vision, :l_refraction_comments,
      :l_dilatedrefraction_distant_sph, :l_dilatedrefraction_distant_cyl, :l_dilatedrefraction_distant_axis,
      :l_contrastsensitivity, :l_contrastsensitivity_comments,
      :l_dilatedrefraction_distant_vision, :l_dilatedrefraction_add_sph,
      :l_dilatedrefraction_add_cyl, :l_dilatedrefraction_add_axis, :l_dilatedrefraction_add_vision,
      :l_dilatedrefraction_near_sph, :l_dilatedrefraction_near_cyl, :l_dilatedrefraction_near_axis,
      :l_dilatedrefraction_near_vision, :l_dilatedrefraction_drug_used, :l_dilatedrefraction_comments,
      :l_keratometry_distant_kh, :l_keratometry_distant_axis, :l_keratometry_near_kv, :l_keratometry_near_axis,
      :l_pgp_distant_sph, :l_pgp_distant_cyl, :l_pgp_distant_axis, :l_pgp_distant_vision, :l_pgp_near_sph,
      :l_pgp_near_cyl, :l_pgp_near_axis, :l_pgp_near_vision, :l_pgp_add_sph, :l_pgp_add_cyl, :l_pgp_add_axis,
      :l_pgp_add_vision, :l_pgp_typeoflens, :l_near_pgp_distant_sph, :l_near_pgp_distant_cyl, :l_near_pgp_distant_axis,
      :l_near_pgp_distant_vision, :l_near_pgp_near_sph, :l_near_pgp_near_cyl, :l_near_pgp_near_axis,
      :l_near_pgp_near_vision, :l_near_pgp_add_sph, :l_near_pgp_add_cyl, :l_near_pgp_add_axis, :l_near_pgp_add_vision,
      :l_near_pgp_typeoflens, :l_pgp_distant_sph2, :l_pgp_distant_cyl2, :l_pgp_distant_axis2, :l_pgp_distant_vision2,
      :l_pgp_near_sph2, :l_pgp_near_cyl2, :l_pgp_near_axis2, :l_pgp_near_vision2, :l_pgp_add_sph2, :l_pgp_add_cyl2,
      :l_pgp_add_axis2, :l_pgp_add_vision2, :l_pgp_typeoflens2, :l_near_pgp_distant_sph2, :l_near_pgp_distant_cyl2,
      :l_near_pgp_distant_axis2, :l_near_pgp_distant_vision2, :l_near_pgp_near_sph2, :l_near_pgp_near_cyl2,
      :l_near_pgp_near_axis2, :l_near_pgp_near_vision2, :l_near_pgp_add_sph2, :l_near_pgp_add_cyl2,
      :l_near_pgp_add_axis2, :l_near_pgp_add_vision2, :l_near_pgp_typeoflens2, :l_pgp_distant_sph3, :l_pgp_distant_cyl3,
      :l_pgp_distant_axis3, :l_pgp_distant_vision3, :l_pgp_near_sph3, :l_pgp_near_cyl3, :l_pgp_near_axis3,
      :l_pgp_near_vision3, :l_pgp_add_sph3, :l_pgp_add_cyl3, :l_pgp_add_axis3, :l_pgp_add_vision3, :l_pgp_typeoflens3,
      :l_near_pgp_distant_sph3, :l_near_pgp_distant_cyl3, :l_near_pgp_distant_axis3, :l_near_pgp_distant_vision3,
      :l_near_pgp_near_sph3, :l_near_pgp_near_cyl3, :l_near_pgp_near_axis3, :l_near_pgp_near_vision3,
      :l_near_pgp_add_sph3, :l_near_pgp_add_cyl3, :l_near_pgp_add_axis3, :l_near_pgp_add_vision3,
      :l_near_pgp_typeoflens3, :l_pgp_comments, :l_pgp_comments2, :l_pgp_comments3,
      :l_intraocularpressure, :l_intraocularpressure_time, :l_intraocularpressure_comments, :no_left_iop_advised,
      :l_glassesprescriptions_distant_vision, :l_glassesprescriptions_distant_sph, :l_glassesprescriptions_distant_cyl,
      :l_glassesprescriptions_distant_axis, :l_glassesprescriptions_add_sph, :l_glassesprescriptions_add_vision,
      :l_glassesprescriptions_near_vision, :l_glassesprescriptions_near_sph, :l_glassesprescriptions_near_cyl,
      :l_glassesprescriptions_near_axis, :l_acceptance_framematerial, :l_acceptance_ipd, :l_acceptance_lensmaterial,
      :l_acceptance_lenstint, :l_acceptance_typeoflens, :l_acceptance_comments, :l_contactlens_bc, :l_contactlens_dia,
      :l_contactlens_sph, :l_contactlens_cyl, :l_contactlens_axis, :l_contactlens_add, :l_contactlens_color,
      :l_contactlens_types, :l_contactlens_comments, :l_chiefcomplaint, :l_blurringdiminution_vision,
      :l_blurringdiminution_pain, :l_blurringdiminution_usingglasses, :l_deviationsquint_diplopia,
      :l_deviationsquint_trauma, :l_deviationsquint_pastsurgery, :l_othervisualsymptoms_glare,
      :l_othervisualsymptoms_floaters, :l_othervisualsymptoms_photophobia, :l_othervisualsymptoms_coloredhalos,
      :l_othervisualsymptoms_metamorphosia, :l_othervisualsymptoms_chromatopsia,
      :l_othervisualsymptoms_diminishednightvision, :l_othervisualsymptoms_diminisheddayvision,
      :l_subjective_duration_no, :l_subjective_duration_unit, :l_subjectivecomments, :l_dilated_retinoscopy_top_va1,
      :l_dilated_retinoscopy_bottom_va2, :l_dilated_retinoscopy_left_ha1, :l_dilated_retinoscopy_right_ha2,
      :l_dilated_retinoscopy_va, :l_dilated_retinoscopy_ha, :l_dilated_retinoscopy_distance, :l_retinoscopy_drug_used,
      :l_retinoscopy_comments, :l_dilatedretinoscopy_pmt_axis, :l_dilatedretinoscopy_pmt_sph,
      :l_dilatedretinoscopy_pmt_cyl, :l_dilatedretinoscopy_pmt_vision, :l_dilatedretinoscopy_pmt_axis_row2,
      :l_dilatedretinoscopy_pmt_sph_row2, :l_dilatedretinoscopy_pmt_cyl_row2, :l_dilatedretinoscopy_pmt_vision_row2,
      :l_dilatedretinoscopy_pmt_axis_row3, :l_dilatedretinoscopy_pmt_sph_row3, :l_dilatedretinoscopy_pmt_cyl_row3,
      :l_dilatedretinoscopy_pmt_vision_row3, :l_color_vision, :l_orthoptics,
      :l_intermediate_glasses_prescriptions_distant_sph, :l_intermediate_glasses_prescriptions_distant_cyl,
      :l_intermediate_glasses_prescriptions_distant_axis, :l_intermediate_glasses_prescriptions_distant_vision,
      :l_intermediate_glasses_prescriptions_add_sph, :l_intermediate_glasses_prescriptions_add_cyl,
      :l_intermediate_glasses_prescriptions_add_axis, :l_intermediate_glasses_prescriptions_add_vision,
      :l_intermediate_glasses_prescriptions_near_sph, :l_intermediate_glasses_prescriptions_near_cyl,
      :l_intermediate_glasses_prescriptions_near_axis, :l_intermediate_glasses_prescriptions_near_vision,
      :l_intermediate_acceptance_typeoflens, :l_intermediate_acceptance_ipd, :l_intermediate_acceptance_lensmaterial,
      :l_intermediate_acceptance_lenstint, :l_intermediate_acceptance_framematerial, :l_intermediate_acceptance_comments,
      :r_acceptance_dia, :r_acceptance_size, :r_acceptance_fitting_height, :r_acceptance_prism_base,
      :l_acceptance_fitting_height, :l_acceptance_prism_base, :l_acceptance_dia, :l_acceptance_size,
    )
  end

  def refraction_keys_values_r
    record = @record.find_by(templatetype: 'optometrist') || @record.find_by(templatetype: 'refraction') || @record.last
    @record_keys_values_r = record.attributes.slice(
      :r_autorefraction_dry_sph, :r_autorefraction_dry_cyl, :r_autorefraction_dry_axis,
      :r_autorefraction_dry1_sph, :r_autorefraction_dry1_cyl, :r_autorefraction_dry1_axis,
      :r_autorefraction_dry2_sph, :r_autorefraction_dry2_cyl, :r_autorefraction_dry2_axis,
      :r_visualacuity_unaided_comments, :r_visualacuity_unaided, :r_visualacuity_unaided_p,
      :r_visualacuity_ua_near_comments, :r_visualacuity_ua_near, :r_visualacuity_ua_near_p, :r_visualacuity_ua_s,
      :r_visualacuity_ua_i, :r_visualacuity_ua_n, :r_visualacuity_ua_t, :r_visualacuity_pinhole_comments,
      :r_visualacuity_pinhole, :r_visualacuity_pinhole_p, :r_visualacuity_pinhole_ni, :r_visualacuity_glasses_comments,
      :r_visualacuity_glasses, :r_visualacuity_glasses_p, :r_visualacuity_near_comments, :r_visualacuity_near,
      :r_visualacuity_near_p, :r_visualacuity_lens_comments, :r_visualacuity_lens, :r_visualacuity_lens_p,
      :r_visualacuity_comments, :r_pgp_distant_sph, :r_pgp_distant_cyl, :r_pgp_distant_axis, :r_pgp_distant_vision,
      :r_pgp_near_sph, :r_pgp_near_cyl, :r_pgp_near_axis, :r_pgp_near_vision, :r_pgp_add_sph, :r_pgp_add_cyl,
      :r_pgp_add_axis, :r_pgp_add_vision, :r_pgp_typeoflens, :r_near_pgp_distant_sph, :r_near_pgp_distant_cyl,
      :r_near_pgp_distant_axis, :r_near_pgp_distant_vision, :r_near_pgp_near_sph, :r_near_pgp_near_cyl,
      :r_near_pgp_near_axis, :r_near_pgp_near_vision, :r_near_pgp_add_sph, :r_near_pgp_add_cyl, :r_near_pgp_add_axis,
      :r_near_pgp_add_vision, :r_near_pgp_typeoflens, :r_pgp_distant_sph2, :r_pgp_distant_cyl2, :r_pgp_distant_axis2,
      :r_pgp_distant_vision2, :r_pgp_near_sph2, :r_pgp_near_cyl2, :r_pgp_near_axis2, :r_pgp_near_vision2,
      :r_pgp_add_sph2, :r_pgp_add_cyl2, :r_pgp_add_axis2, :r_pgp_add_vision2, :r_pgp_typeoflens2, :r_near_pgp_distant_sph2,
      :r_near_pgp_distant_cyl2, :r_near_pgp_distant_axis2, :r_near_pgp_distant_vision2, :r_near_pgp_near_sph2,
      :r_near_pgp_near_cyl2, :r_near_pgp_near_axis2, :r_near_pgp_near_vision2, :r_near_pgp_add_sph2, :r_near_pgp_add_cyl2,
      :r_near_pgp_add_axis2, :r_near_pgp_add_vision2, :r_near_pgp_typeoflens2, :r_pgp_distant_sph3, :r_pgp_distant_cyl3,
      :r_pgp_distant_axis3, :r_pgp_distant_vision3, :r_pgp_near_sph3, :r_pgp_near_cyl3, :r_pgp_near_axis3,
      :r_pgp_near_vision3, :r_pgp_add_sph3, :r_pgp_add_cyl3, :r_pgp_add_axis3, :r_pgp_add_vision3, :r_pgp_typeoflens3,
      :r_near_pgp_distant_sph3, :r_near_pgp_distant_cyl3, :r_near_pgp_distant_axis3, :r_near_pgp_distant_vision3,
      :r_near_pgp_near_sph3, :r_near_pgp_near_cyl3, :r_near_pgp_near_axis3, :r_near_pgp_near_vision3,
      :r_near_pgp_add_sph3, :r_near_pgp_add_cyl3, :r_near_pgp_add_axis3, :r_near_pgp_add_vision3,
      :r_near_pgp_typeoflens3, :r_pgp_comments, :r_pgp_comments2, :r_pgp_comments3,
      :r_retinoscopy_sph, :r_retinoscopy_cyl, :r_retinoscopy_axis, :r_retinoscopy_reflex,
      :r_retinoscopy_distance, :r_retinoscopy_drug_used, :r_retinoscopy_comments, :r_refraction_distant_ucva, :r_refraction_distant_sph, :r_refraction_distant_cyl, :r_refraction_distant_axis,
      :r_refraction_distant_vision, :r_refraction_distant_va_ph, :r_refraction_add_ucva, :r_refraction_add_sph,
      :r_refraction_add_cyl, :r_refraction_add_axis, :r_refraction_add_vision, :r_refraction_add_va_ph,
      :r_refraction_near_ucva, :r_refraction_near_sph, :r_refraction_near_cyl, :r_refraction_near_axis,
      :r_refraction_near_vision, :r_refraction_near_va_ph, :r_refraction_comments, :r_autorefraction_dilated1_sph,
      :r_autorefraction_dilated1_cyl, :r_autorefraction_dilated1_axis, :r_autorefraction_dilated2_sph,
      :r_autorefraction_dilated2_cyl, :r_autorefraction_dilated2_axis, :r_autorefraction_dilated3_sph,
      :r_autorefraction_dilated3_cyl, :r_autorefraction_dilated3_axis, :r_retinoscopy_dilated_sph,
      :r_retinoscopy_dilated_cyl, :r_retinoscopy_dilated_axis, :r_retinoscopy_dilated_reflex,
      :r_retinoscopy_dilated_distance, :r_retinoscopy_dilated_drug_used, :r_retinoscopy_dilated_comments,
      :r_dilatedrefraction_distant_ucva, :r_dilatedrefraction_distant_sph, :r_dilatedrefraction_distant_cyl,
      :r_dilatedrefraction_distant_axis, :r_dilatedrefraction_distant_vision, :r_dilatedrefraction_distant_va_ph,
      :r_dilatedrefraction_add_ucva, :r_dilatedrefraction_add_sph, :r_dilatedrefraction_add_cyl,
      :r_dilatedrefraction_add_axis, :r_dilatedrefraction_add_vision, :r_dilatedrefraction_add_va_ph,
      :r_dilatedrefraction_near_ucva, :r_dilatedrefraction_near_sph, :r_dilatedrefraction_near_cyl,
      :r_dilatedrefraction_near_axis, :r_dilatedrefraction_near_vision, :r_dilatedrefraction_near_va_ph,
      :r_dilatedrefraction_comments, :r_autorefraction_pmt_sph, :r_autorefraction_pmt_cyl, :r_autorefraction_pmt_axis,
      :r_autorefraction_pmt1_sph, :r_autorefraction_pmt1_cyl, :r_autorefraction_pmt1_axis,
      :r_autorefraction_pmt2_sph, :r_autorefraction_pmt2_cyl, :r_autorefraction_pmt2_axis,
      :r_retinoscopy_pmt_sph, :r_retinoscopy_pmt_cyl, :r_retinoscopy_pmt_axis, :r_retinoscopy_pmt_reflex,
      :r_retinoscopy_pmt_distance, :r_retinoscopy_pmt_drug_used, :r_retinoscopy_pmt_comments,
      :r_pmtrefraction_distant_ucva, :r_pmtrefraction_distant_sph, :r_pmtrefraction_distant_cyl,
      :r_pmtrefraction_distant_axis, :r_pmtrefraction_distant_vision, :r_pmtrefraction_distant_va_ph,
      :r_pmtrefraction_add_ucva, :r_pmtrefraction_add_sph, :r_pmtrefraction_add_cyl, :r_pmtrefraction_add_axis,
      :r_pmtrefraction_add_vision, :r_pmtrefraction_add_va_ph, :r_pmtrefraction_near_ucva, :r_pmtrefraction_near_sph,
      :r_pmtrefraction_near_cyl, :r_pmtrefraction_near_axis, :r_pmtrefraction_near_vision, :r_pmtrefraction_near_va_ph,
      :r_pmtrefraction_comments, :r_glassesprescriptions_distant_sph, :r_glassesprescriptions_distant_cyl,
      :r_glassesprescriptions_distant_axis, :r_glassesprescriptions_distant_vision, :r_glassesprescriptions_add_sph,
      :r_glassesprescriptions_add_cyl, :r_glassesprescriptions_add_axis, :r_glassesprescriptions_add_vision,
      :r_glassesprescriptions_near_sph, :r_glassesprescriptions_near_cyl, :r_glassesprescriptions_near_axis,
      :r_glassesprescriptions_near_vision, :r_acceptance_typeoflens, :r_acceptance_ipd, :r_acceptance_lensmaterial,
      :r_acceptance_lenstint, :r_acceptance_framematerial, :r_acceptance_comments,
      :r_intermediate_acceptance_typeoflens, :r_intermediate_acceptance_ipd, :r_intermediate_acceptance_lensmaterial,
      :r_intermediate_acceptance_lenstint, :r_intermediate_acceptance_framematerial,
      :r_intermediate_acceptance_comments, :r_amsler, :r_amsler_comment, :r_corneal_sensation, :r_pupilsize,
      :r_fluorescein_staining, :r_acceptance_dia, :r_acceptance_size, :r_acceptance_fittingheight, :r_acceptance_prismbase,
      :l_acceptance_fittingheight, :l_acceptance_prism_base, :l_acceptance_dia, :l_acceptance_size,  
    )
  end

  def refraction_keys_values_l
    record = @record.find_by(templatetype: 'optometrist') || @record.find_by(templatetype: 'refraction') || @record.last
    @record_keys_values_l = record.attributes.slice(
      :l_autorefraction_dry_sph, :l_autorefraction_dry_cyl, :l_autorefraction_dry_axis,
      :l_autorefraction_dry1_sph, :l_autorefraction_dry1_cyl, :l_autorefraction_dry1_axis,
      :l_autorefraction_dry2_sph, :l_autorefraction_dry2_cyl, :l_autorefraction_dry2_axis,
      :l_visualacuity_unaided_comments, :l_visualacuity_unaided, :l_visualacuity_unaided_p,
      :l_visualacuity_ua_near_comments, :l_visualacuity_ua_near, :l_visualacuity_ua_near_p, :l_visualacuity_ua_s,
      :l_visualacuity_ua_i, :l_visualacuity_ua_n, :l_visualacuity_ua_t, :l_visualacuity_pinhole_comments,
      :l_visualacuity_pinhole, :l_visualacuity_pinhole_p, :l_visualacuity_pinhole_ni, :l_visualacuity_glasses_comments,
      :l_visualacuity_glasses, :l_visualacuity_glasses_p, :l_visualacuity_near_comments, :l_visualacuity_near,
      :l_visualacuity_near_p, :l_visualacuity_lens_comments, :l_visualacuity_lens, :l_visualacuity_lens_p,
      :l_visualacuity_comments, :l_pgp_distant_sph, :l_pgp_distant_cyl, :l_pgp_distant_axis, :l_pgp_distant_vision,
      :l_pgp_near_sph, :l_pgp_near_cyl, :l_pgp_near_axis, :l_pgp_near_vision, :l_pgp_add_sph, :l_pgp_add_cyl,
      :l_pgp_add_axis, :l_pgp_add_vision, :l_pgp_typeoflens, :l_near_pgp_distant_sph, :l_near_pgp_distant_cyl,
      :l_near_pgp_distant_axis, :l_near_pgp_distant_vision, :l_near_pgp_near_sph, :l_near_pgp_near_cyl,
      :l_near_pgp_near_axis, :l_near_pgp_near_vision, :l_near_pgp_add_sph, :l_near_pgp_add_cyl, :l_near_pgp_add_axis,
      :l_near_pgp_add_vision, :l_near_pgp_typeoflens, :l_pgp_distant_sph2, :l_pgp_distant_cyl2, :l_pgp_distant_axis2,
      :l_pgp_distant_vision2, :l_pgp_near_sph2, :l_pgp_near_cyl2, :l_pgp_near_axis2, :l_pgp_near_vision2,
      :l_pgp_add_sph2, :l_pgp_add_cyl2, :l_pgp_add_axis2, :l_pgp_add_vision2, :l_pgp_typeoflens2,
      :l_near_pgp_distant_sph2, :l_near_pgp_distant_cyl2, :l_near_pgp_distant_axis2, :l_near_pgp_distant_vision2,
      :l_near_pgp_near_sph2, :l_near_pgp_near_cyl2, :l_near_pgp_near_axis2, :l_near_pgp_near_vision2,
      :l_near_pgp_add_sph2, :l_near_pgp_add_cyl2, :l_near_pgp_add_axis2, :l_near_pgp_add_vision2,
      :l_near_pgp_typeoflens2, :l_pgp_distant_sph3, :l_pgp_distant_cyl3, :l_pgp_distant_axis3, :l_pgp_distant_vision3,
      :l_pgp_near_sph3, :l_pgp_near_cyl3, :l_pgp_near_axis3, :l_pgp_near_vision3, :l_pgp_add_sph3, :l_pgp_add_cyl3,
      :l_pgp_add_axis3, :l_pgp_add_vision3, :l_pgp_typeoflens3, :l_near_pgp_distant_sph3, :l_near_pgp_distant_cyl3,
      :l_near_pgp_distant_axis3, :l_near_pgp_distant_vision3, :l_near_pgp_near_sph3, :l_near_pgp_near_cyl3,
      :l_near_pgp_near_axis3, :l_near_pgp_near_vision3, :l_near_pgp_add_sph3, :l_near_pgp_add_cyl3,
      :l_near_pgp_add_axis3, :l_near_pgp_add_vision3, :l_near_pgp_typeoflens3, :l_pgp_comments, :l_pgp_comments2,
      :l_pgp_comments3, :l_retinoscopy_sph, :l_retinoscopy_cyl,
      :l_retinoscopy_axis, :l_retinoscopy_reflex, :l_retinoscopy_distance, :l_retinoscopy_drug_used,
      :l_retinoscopy_comments, :l_refraction_distant_ucva, :l_refraction_distant_sph, :l_refraction_distant_cyl,
      :l_refraction_distant_axis, :l_refraction_distant_vision, :l_refraction_distant_va_ph, :l_refraction_add_ucva,
      :l_refraction_add_sph, :l_refraction_add_cyl, :l_refraction_add_axis, :l_refraction_add_vision,
      :l_refraction_add_va_ph, :l_refraction_near_ucva, :l_refraction_near_sph, :l_refraction_near_cyl,
      :l_refraction_near_axis, :l_refraction_near_vision, :l_refraction_near_va_ph, :l_refraction_comments,
      :l_autorefraction_dilated1_sph, :l_autorefraction_dilated1_cyl, :l_autorefraction_dilated1_axis,
      :l_autorefraction_dilated2_sph, :l_autorefraction_dilated2_cyl, :l_autorefraction_dilated2_axis,
      :l_autorefraction_dilated3_sph, :l_autorefraction_dilated3_cyl, :l_autorefraction_dilated3_axis,
      :l_retinoscopy_dilated_sph, :l_retinoscopy_dilated_cyl, :l_retinoscopy_dilated_axis, :l_retinoscopy_dilated_reflex,
      :l_retinoscopy_dilated_distance, :l_retinoscopy_dilated_drug_used, :l_retinoscopy_dilated_comments,
      :l_dilatedrefraction_distant_ucva, :l_dilatedrefraction_distant_sph, :l_dilatedrefraction_distant_cyl,
      :l_dilatedrefraction_distant_axis, :l_dilatedrefraction_distant_vision, :l_dilatedrefraction_distant_va_ph,
      :l_dilatedrefraction_add_ucva, :l_dilatedrefraction_add_sph, :l_dilatedrefraction_add_cyl,
      :l_dilatedrefraction_add_axis, :l_dilatedrefraction_add_vision, :l_dilatedrefraction_add_va_ph,
      :l_dilatedrefraction_near_ucva, :l_dilatedrefraction_near_sph, :l_dilatedrefraction_near_cyl,
      :l_dilatedrefraction_near_axis, :l_dilatedrefraction_near_vision, :l_dilatedrefraction_near_va_ph,
      :l_dilatedrefraction_comments, :l_autorefraction_pmt_sph, :l_autorefraction_pmt_cyl, :l_autorefraction_pmt_axis,
      :l_autorefraction_pmt1_sph, :l_autorefraction_pmt1_cyl, :l_autorefraction_pmt1_axis,
      :l_autorefraction_pmt2_sph, :l_autorefraction_pmt2_cyl, :l_autorefraction_pmt2_axis,
      :l_retinoscopy_pmt_sph, :l_retinoscopy_pmt_cyl, :l_retinoscopy_pmt_axis, :l_retinoscopy_pmt_reflex,
      :l_retinoscopy_pmt_distance, :l_retinoscopy_pmt_drug_used, :l_retinoscopy_pmt_comments,
      :l_pmtrefraction_distant_ucva, :l_pmtrefraction_distant_sph, :l_pmtrefraction_distant_cyl,
      :l_pmtrefraction_distant_axis, :l_pmtrefraction_distant_vision, :l_pmtrefraction_distant_va_ph,
      :l_pmtrefraction_add_ucva, :l_pmtrefraction_add_sph, :l_pmtrefraction_add_cyl, :l_pmtrefraction_add_axis,
      :l_pmtrefraction_add_vision, :l_pmtrefraction_add_va_ph, :l_pmtrefraction_near_ucva, :l_pmtrefraction_near_sph,
      :l_pmtrefraction_near_cyl, :l_pmtrefraction_near_axis, :l_pmtrefraction_near_vision, :l_pmtrefraction_near_va_ph,
      :l_pmtrefraction_comments, :l_glassesprescriptions_distant_sph, :l_glassesprescriptions_distant_cyl,
      :l_glassesprescriptions_distant_axis, :l_glassesprescriptions_distant_vision, :l_glassesprescriptions_add_sph,
      :l_glassesprescriptions_add_cyl, :l_glassesprescriptions_add_axis, :l_glassesprescriptions_add_vision,
      :l_glassesprescriptions_near_sph, :l_glassesprescriptions_near_cyl, :l_glassesprescriptions_near_axis,
      :l_glassesprescriptions_near_vision, :l_acceptance_typeoflens, :l_acceptance_ipd, :l_acceptance_lensmaterial,
      :l_acceptance_lenstint, :l_acceptance_framematerial, :l_acceptance_comments,
      :l_intermediate_acceptance_typeoflens, :l_intermediate_acceptance_ipd, :l_intermediate_acceptance_lensmaterial,
      :l_intermediate_acceptance_lenstint, :l_intermediate_acceptance_framematerial,
      :l_intermediate_acceptance_comments, :l_amsler, :l_amsler_comment, :l_pupilsize, :l_fluorescein_staining,
      :l_corneal_sensation, :r_acceptance_dia, :r_acceptance_size, :r_acceptance_fittingheight, :r_acceptance_prismbase,
      :l_acceptance_fittingheight, :l_acceptance_prismbase, :l_acceptance_dia, :l_acceptance_size
    )
  end

  def record_exam_keys_values_r
    record = @record.find_by(templatetype: 'optometrist') || @record.find_by(templatetype: 'refraction') || @record.last
    @record_exam_keys_values_r = record.attributes.slice(
      :r_local_examination_normal, :r_appearance, :r_appearance_phthisisbulbi, :r_appearance_anophthalmos,
      :r_appearance_micropththalmos, :r_appearance_artificial, :r_appearance_proptosis, :r_appearance_dystopia,
      :r_appearance_injured, :r_appearance_swollen, :r_appearance_comments, :r_scleracommon, :r_scleracommon_comments, :r_appendages, :r_appendages_tests,
      :r_appendages_eyelids_chalazion, :r_appendages_eyelids_ptosis, :r_appendages_eyelids_swelling,
      :r_appendages_eyelids_entropion, :r_appendages_eyelids_ectropion, :r_appendages_eyelids_mass,
      :r_appendages_eyelids_meibomitis, :r_appendages_eyelashes_trichiasis, :r_appendages_eyelashes_dystrichiasis,
      :r_appendages_lacrimalsac_swelling, :r_appendages_lacrimalsac_regurgitation, :r_appendages_syringing,
      :r_appendages_comments, :r_appendages_diagram_present, :r_appendages_diagram, :r_appendages_diagram_full,
      :r_appendages_diagram_thumb, :r_appendages_temp_asset_id, :r_conjunctiva, :r_conjunctiva_congestion,
      :r_conjunctiva_tear, :r_conjunctiva_conjuctival_blib, :r_conjunctiva_congestion_lgc,
      :r_conjunctiva_subconjunctival_haemorrhage, :r_conjunctiva_foreign_body, :r_conjunctiva_follicles,
      :r_conjunctiva_papillae, :r_conjunctiva_pinguecula, :r_conjunctiva_pterygium, :r_conjunctiva_phlycten,
      :r_conjunctiva_discharge, :r_conjunctiva_comments, :r_cornea, :r_cornea_size, :r_cornea_shape, :r_cornea_surface,
      :r_cornea_schirmer_dimension1, :r_cornea_schirmer_time1, :r_cornea_schirmer_dimension2, :r_cornea_schirmer_time2,
      :r_corneal_sensation, :r_cornea_comments, :r_cornea_diagram_present, :r_cornea_diagram, :r_cornea_diagram_full,
      :r_cornea_diagram_thumb, :r_cornea_temp_asset_id,  :r_corneaslit_diagram_present, :r_corneaslit_diagram,
      :r_corneaslit_diagram_full, :r_corneaslit_diagram_thumb, :r_corneaslit_temp_asset_id, :r_fluorescein_staining,
      :r_anteriorchamber, :r_anteriorchamber_depth, :r_anteriorchamber_depth_comment, :r_anteriorchamber_cells,
      :r_anteriorchamber_cells_comment, :r_anteriorchamber_flare, :r_anteriorchamber_flare_comment,
      :r_anteriorchamber_hyphema, :r_anteriorchamber_hyphema_comment, :r_anteriorchamber_hypopyon,
      :r_anteriorchamber_hypopyon_comment, :r_anteriorchamber_foreignbody, :r_anteriorchamber_foreignbody_comment,
      :r_anteriorchamber_comments, :r_pupil, :r_pupil_shape, :r_pupil_reaction_to_light_direct, :r_pupilsize,
      :r_pupil_reaction_to_light_consensual, :r_pupil_rapd, :r_pupil_comments, :r_iris, :r_iris_shape,
      :r_iris_neovascularisation, :r_iris_synechiae, :r_iris_comments, :r_lens, :r_lens_nature, :r_lens_position,
      :r_lens_size, :r_lens_grading_no, :r_lens_grading_c, :r_lens_grading_p, :r_lens_diagram_present, :r_lens_diagram,
      :r_lens_diagram_full, :r_lens_diagram_thumb, :r_lens_temp_asset_id, :r_lens_comments,
      :r_extraocularmovements, :r_extraocularmovements_uniocular, :r_extraocularmovements_binocular,
      :r_extraocularmovements_comments, :r_extraocularmovements_prism, :r_extraocularmovements_squint,
      :r_extraocularmovements_squint_tropia, :r_extraocularmovements_squint_tropia_horizontal,
      :r_extraocularmovements_squint_tropia_horizontal_esotropia,
      :r_extraocularmovements_squint_tropia_horizontal_exotropia, :r_extraocularmovements_squint_tropia_vertical,
      :r_extraocularmovements_squint_tropia_paralytic, :r_extraocularmovements_squint_phoria, :r_iop, :r_iop_method,
      :r_iop_comments, :r_gonioscopy, :r_gonioscopy_eye_superior_d1, :r_gonioscopy_eye_superior_d2,
      :r_gonioscopy_eye_superior_d3, :r_gonioscopy_eye_temporal_d1, :r_gonioscopy_eye_temporal_d2,
      :r_gonioscopy_eye_temporal_d3, :r_gonioscopy_eye_nasal_d1, :r_gonioscopy_eye_nasal_d2,
      :r_gonioscopy_eye_nasal_d3, :r_gonioscopy_eye_inferior_d1, :r_gonioscopy_eye_inferior_d2,
      :r_gonioscopy_eye_inferior_d3, :r_gonioscopy_comment, :r_fundus_normal, :r_fundus, :r_fundus_media_select,
      :r_fundus_media_comment, :r_fundus_pvd_select, :r_fundus_optdiscsize_select, :r_fundus_cup_disc_ratio_select,
      :r_fundus_cupratio_comment, :r_fundus_opticdisc_comment, :r_fundus_bloodvessel_select, :r_fundus_macula_fovealreflex,
      :r_fundus_bloodvessel_comment, :r_fundus_macula_select, :r_fundus_macula_comment, :r_fundus_vitreous_select,
      :r_fundus_vitreous_comment, :r_fundus_retinal_detachment_select, :r_fundus_retinal_detachment_comment,
      :r_fundus_peripheral_lesions_select, :r_fundus_peripheral_lesions_comment, :r_fundus_lattice_degeneration_select,
      :r_fundustext_comment, :r_fundus_diagram_present, :r_fundus_diagram, :r_fundus_diagram_full,
      :r_fundus_diagram_thumb, :r_fundus_temp_asset_id, :r_fundus_comments, :r_iris_peripheraliridotomy,
      :r_acceptance_dia, :r_acceptance_size, :r_acceptance_fittingheight, :r_acceptance_prismbase,
      :l_acceptance_fittingheight, :l_acceptance_prismbase, :l_acceptance_dia, :l_acceptancesize
    )
  end

  def record_exam_keys_values_l
    record = @record.find_by(templatetype: 'optometrist') || @record.find_by(templatetype: 'refraction') || @record.last
    @record_exam_keys_values_l = record.attributes.slice(
      :l_local_examination_normal, :l_appearance, :l_appearance_phthisisbulbi, :l_appearance_anophthalmos,
      :l_appearance_micropththalmos, :l_appearance_artificial, :l_appearance_proptosis, :l_appearance_dystopia,
      :l_appearance_injured, :l_appearance_swollen, :l_appearance_comments, :l_scleracommon, :l_scleracommon_comments, :l_appendages, :l_appendages_tests,
      :l_appendages_eyelids_chalazion, :l_appendages_eyelids_ptosis, :l_appendages_eyelids_swelling,
      :l_appendages_eyelids_entropion, :l_appendages_eyelids_ectropion, :l_appendages_eyelids_mass,
      :l_appendages_eyelids_meibomitis, :l_appendages_eyelashes_trichiasis, :l_appendages_eyelashes_dystrichiasis,
      :l_appendages_lacrimalsac_swelling, :l_appendages_lacrimalsac_regurgitation, :l_appendages_syringing,
      :l_appendages_comments, :l_appendages_diagram_present, :l_appendages_diagram, :l_appendages_diagram_full,
      :l_appendages_diagram_thumb, :l_appendages_temp_asset_id, :l_conjunctiva, :l_conjunctiva_congestion,
      :l_conjunctiva_tear, :l_conjunctiva_conjuctival_blib, :l_conjunctiva_congestion_lgc,
      :l_conjunctiva_subconjunctival_haemorrhage, :l_conjunctiva_foreign_body, :l_conjunctiva_follicles,
      :l_conjunctiva_papillae, :l_conjunctiva_pinguecula, :l_conjunctiva_pterygium, :l_conjunctiva_phlycten,
      :l_conjunctiva_discharge, :l_conjunctiva_comments, :l_cornea, :l_cornea_size, :l_cornea_shape, :l_cornea_surface,
      :l_cornea_schirmer_dimension1, :l_cornea_schirmer_time1, :l_cornea_schirmer_dimension2, :l_cornea_schirmer_time2,
      :r_corneal_sensation, :l_cornea_comments, :l_cornea_diagram_present, :l_cornea_diagram, :l_cornea_diagram_full,
      :l_cornea_diagram_thumb, :l_cornea_temp_asset_id, :l_corneaslit_diagram_present, :l_corneaslit_diagram,
      :l_corneaslit_diagram_full, :l_corneaslit_diagram_thumb, :l_corneaslit_temp_asset_id, :l_fluorescein_staining,
      :l_anteriorchamber, :l_anteriorchamber_depth, :l_anteriorchamber_depth_comment, :l_anteriorchamber_cells,
      :l_anteriorchamber_cells_comment, :l_anteriorchamber_flare, :l_anteriorchamber_flare_comment,
      :l_anteriorchamber_hyphema, :l_anteriorchamber_hyphema_comment, :l_anteriorchamber_hypopyon,
      :l_anteriorchamber_hypopyon_comment, :l_anteriorchamber_foreignbody, :l_anteriorchamber_foreignbody_comment,
      :l_anteriorchamber_comments, :l_pupil, :l_pupil_shape, :l_pupil_reaction_to_light_direct, :l_pupilsize,
      :l_pupil_reaction_to_light_consensual, :l_pupil_rapd, :l_pupil_comments, :l_iris, :l_iris_shape,
      :l_iris_neovascularisation, :l_iris_synechiae, :l_iris_comments, :l_lens, :l_lens_nature, :l_lens_position,
      :l_lens_size, :l_lens_grading_no, :l_lens_grading_c, :l_lens_grading_p, :l_lens_diagram_present, :l_lens_diagram,
      :l_lens_diagram_full, :l_lens_diagram_thumb, :l_lens_temp_asset_id, :l_lens_comments,
      :l_extraocularmovements, :l_extraocularmovements_uniocular, :l_extraocularmovements_binocular,
      :l_extraocularmovements_comments, :l_extraocularmovements_prism, :l_extraocularmovements_squint,
      :l_extraocularmovements_squint_tropia, :l_extraocularmovements_squint_tropia_horizontal,
      :l_extraocularmovements_squint_tropia_horizontal_esotropia,
      :l_extraocularmovements_squint_tropia_horizontal_exotropia, :l_extraocularmovements_squint_tropia_vertical,
      :l_extraocularmovements_squint_tropia_paralytic, :l_extraocularmovements_squint_phoria, :l_iop, :l_iop_method,
      :l_iop_comments, :l_gonioscopy, :l_gonioscopy_eye_superior_d1, :l_gonioscopy_eye_superior_d2,
      :l_gonioscopy_eye_superior_d3, :l_gonioscopy_eye_temporal_d1, :l_gonioscopy_eye_temporal_d2,
      :l_gonioscopy_eye_temporal_d3, :l_gonioscopy_eye_nasal_d1, :l_gonioscopy_eye_nasal_d2,
      :l_gonioscopy_eye_nasal_d3, :l_gonioscopy_eye_inferior_d1, :l_gonioscopy_eye_inferior_d2,
      :l_gonioscopy_eye_inferior_d3, :l_gonioscopy_comment, :l_fundus_normal, :l_fundus, :l_fundus_media_select,
      :l_fundus_media_comment, :l_fundus_pvd_select, :l_fundus_optdiscsize_select, :l_fundus_cup_disc_ratio_select,
      :l_fundus_cupratio_comment, :l_fundus_opticdisc_comment, :l_fundus_bloodvessel_select, :l_fundus_macula_fovealreflex,
      :l_fundus_bloodvessel_comment, :l_fundus_macula_select, :l_fundus_macula_comment, :l_fundus_vitreous_select,
      :l_fundus_vitreous_comment, :l_fundus_retinal_detachment_select, :l_fundus_retinal_detachment_comment,
      :l_fundus_peripheral_lesions_select, :l_fundus_peripheral_lesions_comment, :l_fundus_lattice_degeneration_select,
      :l_fundustext_comment, :l_fundus_diagram_present, :l_fundus_diagram, :l_fundus_diagram_full,
      :l_fundus_diagram_thumb, :l_fundus_temp_asset_id, :l_fundus_comments, :l_iris_peripheraliridotomy,
      :r_acceptance_dia, :r_acceptance_size, :r_acceptance_fittingheight, :r_acceptance_prismbase,
      :l_acceptance_fittingheight, :l_acceptance_prismbase, :l_acceptance_dia, :l_acceptance_size,
    )
  end

  def record_exam_keys_values_other
    record = @record.find_by(templatetype: 'optometrist') || @record.find_by(templatetype: 'refraction') || @record.last
    @record_exam_keys_values_other = record.attributes.slice(
      :generalexamination, :generalexaminationcomments
    )
  end

  def record_refraction_keys_values_other
    record = @record.find_by(templatetype: 'optometrist') || @record.find_by(templatetype: 'refraction') || @record.last
    @record_refraction_keys_values_other = record.attributes.slice(
      :refractioncommoncomment
    )
  end

  def refraction_keys_values_n
    record = @record.find_by(templatetype: 'optometrist') || @record.find_by(templatetype: 'refraction') || @record.last
    @record_keys_values_n = record.attributes.slice(
      :pgp_duration, :pgp_duration_option, :pgp_frame_condition, :pgp_glasses, :pgp_dboc, :pgp_lens_condition,
      :pgp_frame_material, :pgp_lens_material, :dry_refraction_advice, :duochrome, :jcc, :dilate_patient,
      :dilation_drop, :dilated_refraction_advice, :perform_pmt, :pmt_refraction_advice, :add_pgp_near
    )
  end

  def record_vital_signs
    record = @record.find_by(templatetype: 'nursing') || @record.last
    @record_vital_signs = record.attributes.slice(
      :vital_signs_bp, :vital_signs_comments, :vital_signs_pulse, :vital_signs_rr, :vital_signs_temperature,
      :vital_signs_spo2, :anthropometry_height, :anthropometry_weight, :anthropometry_bmi, :r_intraocularpressure,
      :r_intraocularpressure_time, :l_intraocularpressure, :l_intraocularpressure_time, :r_iop_method,
      :l_iop_method, :r_iop_comments, :l_iop_comments
    )
  end

  def record_checkup
    record = @record.find_by(templatetype: 'optometrist') || @record.find_by(templatetype: 'nursing') || @record.last
    @record_checkup_values = record.attributes.slice(:checkuptype, :checkuptypecomments)
  end

  def record_keys_values_chiefcomplaint
    record = @record.find_by(templatetype: 'optometrist') || @record.find_by(templatetype: 'nursing') || @record.last
    @record_keys_values_chiefcomplaint = record.chief_complaints
  end

  def chief_complaints_comment
    record = @record.find_by(templatetype: 'optometrist') || @record.find_by(templatetype: 'nursing') || @record.last
    @record_keys_values_chiefcomplaint = record.chiefcomplaint_comments
  end

  def record_keys_values_other
    record = @record.find_by(templatetype: 'optometrist') || @record.find_by(templatetype: 'nursing') || @record.last
    @record_keys_values_other = record.attributes.slice(:advise_glasses, :be_subjectivecomments, :no_chief_complaints_advised,
    :no_opthalmic_history_advised, :no_systemic_history_advised, :no_allergy_advised)
  end
end
