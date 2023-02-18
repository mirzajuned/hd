# require 'date'
# require 'time'
# require 'open-uri'
# require 'net/http'
# require 'uri'

# class TemplatesController < ApplicationController

# # **********************************************************************
# #   this controller is not working no routes of this controller
# # **********************************************************************

#   include TemplatesHelper
#   before_action :authorize
#   before_action :setup_view_only_flag, only: [:new_opd_record, :save_opd_record, :edit_opd_record, :update_opd_record]
#   before_action :setup_print_only_flag, only: [:print_opd_record]
#   respond_to :js, :json, :html

#   def new_opd_record
#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @templatetype = params[:templatetype]
#     @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     @patient = Patient.find(params[:patientid])
#     @appointment = Appointment.find(params[:appointmentid])
#     if current_facility.clinical_workflow
#       workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointmentid].to_s)
#       @doctor = workflow.doctor_ids.last
#     else
#       @doctor = @appointment.doctor
#     end
#     @facility_id = current_facility.id
#     @date = Date.current
#     @user = User.find(@doctor)
#     @facilities = Common.new.fetch_facilities(:user => @user)
#     if current_user.has_role?(:doctor)
#       @appointment_types = AppointmentType.where(:user_id => current_user.id,:is_active => true)
#     else
#       @appointment_types = AppointmentType.where(:user_id => @user.id,:is_active => true)
#     end

#     @formbuttons = Global.ehrcommon.newepisode.formbuttons
#     @savepath = Global.ehrcommon.newepisode.savepath
#     if params[:flag] == "clone"
#       opd_record = OpdRecord.find_by(:id => params[:opd_record_id])
#       @opdrecord=opd_record.clone
#       @opdrecord.created_at = Time.current.utc
#       @opdrecord.updated_at = Time.current.utc
#       @opdrecord.record_type = "clone"
#       @opdrecord.record_histories.delete_all
#       @opdrecord.appointmentid = @appointment.id
#       unless @opdrecord.templatetype == 'optometrist'
#         @opdrecord.advice.followupappointment_id = nil
#         @opdrecord.advice.opdfollowupdate = nil
#       end
#       @opdrecord.save
#     elsif @speciality_folder_name == "ophthalmology"
#       if (@templatetype == "eye" || @templatetype == "quickeye")
#         @opdrecord = OpdRecord.new
#         @optometrist_record = OpdRecord.where(:templatetype => "optometrist", :specalityid => current_user.department_id.to_s, :patientid => @patient.id.to_s, :appointmentid => @appointment.id.to_s).order_by(created_at: "asc")
#         if @optometrist_record.size > 0
#           if @optometrist_record.last
#             optometrist_record_keys_values = @optometrist_record.last.attributes.slice(:r_autorefraction_dry_sph,:r_autorefraction_dry_cyl,:r_autorefraction_dry_axis,:r_autorefraction_dilated1_sph,:r_autorefraction_dilated1_cyl,:r_autorefraction_dilated1_axis,:r_autorefraction_dilated2_sph,:r_autorefraction_dilated2_cyl,:r_autorefraction_dilated2_axis,:r_autorefraction_dilated3_sph,:r_autorefraction_dilated3_cyl,:r_autorefraction_dilated3_axis,  :r_visualacuity_unaided, :r_visualacuity_ua_s, :r_visualacuity_ua_i, :r_visualacuity_ua_n, :r_visualacuity_ua_t, :r_visualacuity_unaided_p, :r_visualacuity_ua_near,:r_visualacuity_ua_near_p, :r_visualacuity_pinhole,:r_visualacuity_pinhole_p, :r_visualacuity_glasses,:r_visualacuity_glasses_p,:r_visualacuity_near,:r_visualacuity_near_p, :r_refraction_distant_sph, :r_refraction_distant_cyl, :r_refraction_distant_axis,:r_refraction_distant_vision, :r_refraction_add_sph, :r_refraction_add_cyl, :r_refraction_add_axis,:r_refraction_add_vision, :r_refraction_near_sph, :r_refraction_near_cyl, :r_refraction_near_axis,:r_refraction_near_vision,:r_refraction_comments, :r_dilatedrefraction_distant_sph, :r_dilatedrefraction_distant_cyl, :r_dilatedrefraction_distant_axis,:r_dilatedrefraction_distant_vision, :r_dilatedrefraction_add_sph, :r_dilatedrefraction_add_cyl, :r_dilatedrefraction_add_axis,:r_dilatedrefraction_add_vision, :r_dilatedrefraction_near_sph, :r_dilatedrefraction_near_cyl, :r_dilatedrefraction_near_axis,:r_dilatedrefraction_near_vision,:r_dilatedrefraction_drug_used,:r_dilatedrefraction_comments, :r_keratometry_distant_kh, :r_keratometry_distant_axis, :r_keratometry_near_kv, :r_keratometry_near_axis, :r_pgp_distant_sph, :r_pgp_distant_cyl, :r_pgp_distant_axis, :r_pgp_near_sph, :r_pgp_near_cyl, :r_pgp_near_axis, :r_pgp_add_sph, :r_pgp_add_cyl, :r_pgp_add_axis,:r_pgp_typeoflens, :r_intraocularpressure,:r_intraocularpressure_time, :r_intraocularpressure_comments, :r_glassesprescriptions_distant_vision, :r_glassesprescriptions_distant_sph, :r_glassesprescriptions_distant_cyl, :r_glassesprescriptions_distant_axis, :r_glassesprescriptions_near_vision, :r_glassesprescriptions_near_sph, :r_glassesprescriptions_near_cyl, :r_glassesprescriptions_near_axis,  :l_autorefraction_dry_sph,:l_autorefraction_dry_cyl,:l_autorefraction_dry_axis,:l_autorefraction_dilated1_sph,:l_autorefraction_dilated1_cyl,:l_autorefraction_dilated1_axis,:l_autorefraction_dilated2_sph,:l_autorefraction_dilated2_cyl,:l_autorefraction_dilated2_axis,:l_autorefraction_dilated3_sph,:l_autorefraction_dilated3_cyl,:l_autorefraction_dilated3_axis,  :l_visualacuity_unaided,:l_visualacuity_ua_s, :l_visualacuity_ua_i, :l_visualacuity_ua_n, :l_visualacuity_ua_t,:l_visualacuity_unaided_p, :l_visualacuity_pinhole,:l_visualacuity_pinhole_p, :l_visualacuity_glasses,:l_visualacuity_glasses_p,:l_visualacuity_near,:l_visualacuity_near_p,:l_visualacuity_ua_near,:l_visualacuity_ua_near_p, :l_refraction_distant_sph, :l_refraction_distant_cyl, :l_refraction_distant_axis,:l_refraction_distant_vision, :l_refraction_add_sph, :l_refraction_add_cyl, :l_refraction_add_axis,:l_refraction_add_vision, :l_refraction_near_sph, :l_refraction_near_cyl, :l_refraction_near_axis,:l_refraction_near_vision,:l_refraction_comments, :l_dilatedrefraction_distant_sph, :l_dilatedrefraction_distant_cyl, :l_dilatedrefraction_distant_axis,:l_dilatedrefraction_distant_vision, :l_dilatedrefraction_add_sph, :l_dilatedrefraction_add_cyl, :l_dilatedrefraction_add_axis,:l_dilatedrefraction_add_vision, :l_dilatedrefraction_near_sph, :l_dilatedrefraction_near_cyl, :l_dilatedrefraction_near_axis,:l_dilatedrefraction_near_vision,:l_dilatedrefraction_drug_used, :l_dilatedrefraction_comments, :l_keratometry_distant_kh, :l_keratometry_distant_axis, :l_keratometry_near_kv, :l_keratometry_near_axis, :l_pgp_distant_sph, :l_pgp_distant_cyl, :l_pgp_distant_axis, :l_pgp_near_sph, :l_pgp_near_cyl, :l_pgp_near_axis,:l_pgp_add_sph, :l_pgp_add_cyl, :l_pgp_add_axis, :l_pgp_typeoflens, :l_intraocularpressure, :l_intraocularpressure_time,:l_intraocularpressure_comments, :l_glassesprescriptions_distant_vision, :l_glassesprescriptions_distant_sph, :l_glassesprescriptions_distant_cyl, :l_glassesprescriptions_distant_axis, :l_glassesprescriptions_near_vision, :l_glassesprescriptions_near_sph, :l_glassesprescriptions_near_cyl, :l_glassesprescriptions_near_axis, :l_acceptance_framematerial, :l_acceptance_ipd, :l_acceptance_lensmaterial, :l_acceptance_lenstint, :l_acceptance_typeoflens,:l_acceptance_comments, :l_contactlens_bc, :l_contactlens_dia, :l_contactlens_sph,:l_contactlens_cyl, :l_contactlens_axis, :l_contactlens_add, :l_contactlens_color, :l_contactlens_types,:l_contactlens_comments,:r_acceptance_framematerial, :r_acceptance_ipd, :r_acceptance_lensmaterial, :r_acceptance_lenstint, :r_acceptance_typeoflens,:r_acceptance_comments , :r_contactlens_bc, :r_contactlens_dia, :r_contactlens_sph,:r_contactlens_cyl, :r_contactlens_axis, :r_contactlens_add, :r_contactlens_color, :r_contactlens_types, :r_contactlens_comments, :r_contrastsensitivity,:l_contrastsensitivity,:checkuptype,:checkuptypecomments,:r_chiefcomplaint,:r_blurringdiminution_vision,:r_blurringdiminution_pain,:r_blurringdiminution_usingglasses,:r_deviationsquint_diplopia,:r_deviationsquint_trauma,:r_deviationsquint_pastsurgery,:r_othervisualsymptoms_glare,:r_othervisualsymptoms_floaters,:r_othervisualsymptoms_photophobia,:r_othervisualsymptoms_coloredhalos,:r_othervisualsymptoms_metamorphosia,:r_othervisualsymptoms_chromatopsia,:r_othervisualsymptoms_diminishednightvision,:r_othervisualsymptoms_diminisheddayvision,:r_subjective_duration_no,:r_subjective_duration_unit,:r_subjectivecomments,:l_chiefcomplaint,:l_blurringdiminution_vision,:l_blurringdiminution_pain,:l_blurringdiminution_usingglasses,:l_deviationsquint_diplopia,:l_deviationsquint_trauma,:l_deviationsquint_pastsurgery,:l_othervisualsymptoms_glare,:l_othervisualsymptoms_floaters,:l_othervisualsymptoms_photophobia,:l_othervisualsymptoms_coloredhalos,:l_othervisualsymptoms_metamorphosia,:l_othervisualsymptoms_chromatopsia,:l_othervisualsymptoms_diminishednightvision,:l_othervisualsymptoms_diminisheddayvision,:l_subjective_duration_no,:l_subjective_duration_unit,:l_subjectivecomments,:be_subjectivecomments, :l_dilated_retinoscopy_top_va1, :l_dilated_retinoscopy_bottom_va2, :l_dilated_retinoscopy_left_ha1, :l_dilated_retinoscopy_right_ha2, :l_dilated_retinoscopy_va, :l_dilated_retinoscopy_ha, :l_dilated_retinoscopy_distance, :l_retinoscopy_drug_used, :l_dilatedretinoscopy_pmt_axis, :l_dilatedretinoscopy_pmt_sph, :l_dilatedretinoscopy_pmt_cyl,:l_dilatedretinoscopy_pmt_vision,:l_dilatedretinoscopy_pmt_axis_row2, :l_dilatedretinoscopy_pmt_sph_row2, :l_dilatedretinoscopy_pmt_cyl_row2,:l_dilatedretinoscopy_pmt_vision_row2,:l_dilatedretinoscopy_pmt_axis_row3, :l_dilatedretinoscopy_pmt_sph_row3, :l_dilatedretinoscopy_pmt_cyl_row3,:l_dilatedretinoscopy_pmt_vision_row3, :r_dilated_retinoscopy_top_va1, :r_dilated_retinoscopy_bottom_va2, :r_dilated_retinoscopy_left_ha1, :r_dilated_retinoscopy_right_ha2, :r_dilated_retinoscopy_va, :r_dilated_retinoscopy_ha, :r_dilated_retinoscopy_distance, :r_retinoscopy_drug_used, :r_dilatedretinoscopy_pmt_axis, :r_dilatedretinoscopy_pmt_sph, :r_dilatedretinoscopy_pmt_cyl,:r_dilatedretinoscopy_pmt_vision,:r_dilatedretinoscopy_pmt_axis_row2, :r_dilatedretinoscopy_pmt_sph_row2, :r_dilatedretinoscopy_pmt_cyl_row2,:r_dilatedretinoscopy_pmt_vision_row2, :r_dilatedretinoscopy_pmt_axis_row3, :r_dilatedretinoscopy_pmt_sph_row3, :r_dilatedretinoscopy_pmt_cyl_row3,:r_dilatedretinoscopy_pmt_vision_row3,:chiefcomplaint_blurringdiminution,:chiefcomplaint_blurringdiminution_side,:chiefcomplaint_blurringdiminution_duration,:chiefcomplaint_blurringdiminution_duration_unit,:chiefcomplaint_blurringdiminution_comment,:chiefcomplaint_blurringdiminution_options, :chiefcomplaint_redness,:chiefcomplaint_redness_side,:chiefcomplaint_redness_duration,:chiefcomplaint_redness_duration_unit,:chiefcomplaint_redness_comment,:chiefcomplaint_pain,:chiefcomplaint_pain_side,:chiefcomplaint_pain_duration,:chiefcomplaint_pain_duration_unit,:chiefcomplaint_pain_comment,:chiefcomplaint_injury,:chiefcomplaint_injury_side,:chiefcomplaint_injury_duration,:chiefcomplaint_injury_duration_unit,:chiefcomplaint_injury_comment, :chiefcomplaint_wateringdischarge,:chiefcomplaint_wateringdischarge_side,:chiefcomplaint_wateringdischarge_duration,:chiefcomplaint_wateringdischarge_duration_unit,:chiefcomplaint_wateringdischarge_comment, :chiefcomplaint_dryness,:chiefcomplaint_dryness_side,:chiefcomplaint_dryness_duration,:chiefcomplaint_dryness_duration_unit,:chiefcomplaint_dryness_comment, :chiefcomplaint_itichingfbsensation,:chiefcomplaint_itichingfbsensation_side,:chiefcomplaint_itichingfbsensation_duration,:chiefcomplaint_itichingfbsensation_duration_unit,:chiefcomplaint_itichingfbsensation_comment, :chiefcomplaint_deviationsquint,:chiefcomplaint_deviationsquint_side,:chiefcomplaint_deviationsquint_duration,:chiefcomplaint_deviationsquint_duration_unit,:chiefcomplaint_deviationsquint_comment,:chiefcomplaint_deviationsquint_options, :chiefcomplaint_headachestrain,:chiefcomplaint_headachestrain_side,:chiefcomplaint_headachestrain_duration,:chiefcomplaint_headachestrain_duration_unit,:chiefcomplaint_headachestrain_comment, :chiefcomplaint_changeinsizeshape,:chiefcomplaint_changeinsizeshape_side,:chiefcomplaint_changeinsizeshape_duration,:chiefcomplaint_changeinsizeshape_duration_unit,:chiefcomplaint_changeinsizeshape_comment, :chiefcomplaint_othervisualsymptoms,:chiefcomplaint_othervisualsymptoms_side,:chiefcomplaint_othervisualsymptoms_duration,:chiefcomplaint_othervisualsymptoms_duration_unit,:chiefcomplaint_othervisualsymptoms_comment,:chiefcomplaint_othervisualsymptoms_options,:chiefcomplaint_shadowdefect,:chiefcomplaint_shadowdefect_side,:chiefcomplaint_shadowdefect_duration,:chiefcomplaint_shadowdefect_duration_unit,:chiefcomplaint_shadowdefect_comment, :chiefcomplaint_discolorationeye,:chiefcomplaint_discolorationeye_side,:chiefcomplaint_discolorationeye_duration,:chiefcomplaint_discolorationeye_duration_unit,:chiefcomplaint_discolorationeye_comment,:chiefcomplaint_comments,:r_color_vision,:l_color_vision)
#             @opdrecord.attributes = optometrist_record_keys_values
#             @new_opt_view = "optometrist"
#           end
#         end
#       else
#         #@optometrist_record = OpdRecord.where(:templatetype => "optometrist", :specalityid => current_user.department_id.to_s, :patientid => @patient.id.to_s, :created_at => {'$lt' => Date.current })
#         @optometrist_record = OpdRecord.where(:templatetype => "optometrist", :specalityid => current_user.department_id.to_s, :patientid => @patient.id.to_s)
#         @opdrecord = OpdRecord.new
#       end
#     else
#       @opdrecord = OpdRecord.new
#     end
#     @opdspeciality = TemplateOpdRecord.new(@patient, @opdrecord, @speciality_folder_name, @specalityid, @templatetype, @templateid, current_user.department_id).new_record
#     # end

#     @post_operation = OtSchedule.where(patient_id: @patient.id, operation_done: true, is_deleted: false)
#     if @post_operation.size > 0
#       @post_operative_day = @post_operation.order_by(otdate: "asc").last.otdate.strftime("%d/%m/%Y")
#     end

#     if params[:flag] == "clone"
#       redirect_to templates_edit_opd_record_path(:opdrecordid=> @opdrecord.id, :patientid=> @opdrecord.patientid, :appointmentid=> @opdrecord.appointmentid, :templatetype=> @opdrecord.templatetype),:flash => { :notice => "Message" }
#     else
#       respond_to do |format|
#         format.html{}
#         format.js {render "new_opd_record", :layout => false}
#       end
#     end
#   end

#   def save_opd_record
#     @patient = Patient.find(params[:opdrecord][:patientid])
#     @appointment = Appointment.find(params[:opdrecord][:appointmentid])
#     @templatetype = params[:opdrecord][:templatetype]
#     appointmentdate = @appointment.appointmentdate
#     appointmenttime = @appointment.start_time

#     # Code for Follow Up from Advice Starts Here

#     @doctor = @appointment.doctor
#     @user = User.find(@doctor)
#     if record_params[:bookappointment] == 'true'

#       if record_params[:advice_attributes][:opdfollowupdate] != "" && record_params[:advice_attributes][:opdfollowupdate] != nil

#         opdfollowupdate = Time.zone.parse(record_params[:advice_attributes][:opdfollowupdate]).strftime("%d/%m/%Y")
#         opdfollowuptime = record_params[:advice_attributes][:opdfollowuptime]

#         if opdfollowuptime.split(" ")[1] == "AM"
#           unless opdfollowuptime.split(":")[0] == "12"
#             @hours = opdfollowuptime.split(":")[0]
#           else
#             @hours = 00
#           end
#         else
#           unless opdfollowuptime.split(":")[0] == "12"
#             @hours = opdfollowuptime.split(":")[0].to_i + 12
#           else
#             @hours = opdfollowuptime.split(":")[0]
#           end
#         end
#         @minutes = opdfollowuptime.split(":")[1].to_i
#         @date = opdfollowupdate.split("/")[0]
#         @month = opdfollowupdate.split("/")[1]
#         @year = opdfollowupdate.split("/")[2]
#         @followup_date_time = Time.new(@year, @month, @date, @hours, @minutes, 0)

#         @appointment_type_id = params[:appointment_type]
#         new_appointment = Appointment.new(:appointmentdate => @followup_date_time, :start_time => @followup_date_time, :patient_id => @patient.id,:appointment_type_id => record_params[:advice_attributes][:appointment_type_id],:doctor => record_params[:advice_attributes][:appointment_doctor],:user_id => current_user.id,:facility_id => record_params[:advice_attributes][:appointment_facility],:department_id => @user.department_id.to_s, :departmenttype => params[:opdrecord][:encountertypeid], :appointmentstatus => 416774000,:display_id => CommonHelper::get_opd_record_identifier(@user),patient_name: @patient.fullname)
#         if new_appointment.save
#           new_appointment.update(end_time: new_appointment.start_time + 10.minutes)
#           @followupappointment_id = new_appointment.id
#           @temp_appointment = new_appointment
#           # start_cinical_workflow
#           # get_daily_reports
#           # Reports::Opd::Appointment.new(@appointment).call
#           # Code for Tracker
#           @patient_tracker = PatientTracker.find_by(patient_id: new_appointment.patient_id, tracker_removed: false)
#           unless @patient_tracker.nil?
#             if @patient_tracker.tracker_type == "Session"
#               @new_array = @patient_tracker.session_dates << Date.current
#               @patient_tracker.update(current_session: @patient_tracker.current_session.to_i + 1, session_dates: @new_array)
#             end
#           end
#         else
#           @followupappointment_id = ""
#         end
#       end
#       record_params[:advice_attributes][:followupappointment_id] = @followupappointment_id
#     end
#     # Code for Follow Up from Advice Ends Here

#     # Code for management plan advice.

#     @patient_notes = record_params[:advicemanagementplan]
#     @patient_notes_to_rec = record_params[:advicemanagementplantoreceptionist]

#     if @patient_notes_to_rec == "true"
#       @newnote = PatientNote.new()
#       @newnote.organisation_id = current_user.organisation_id.to_s
#       @newnote.user_id = current_user.id.to_s
#       @newnote.patient_id = @patient.id.to_s
#       @newnote.comment = @patient_notes
#       @newnote.save
#     end

#     # Code for management plan advice ends.

#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     unless (@templatetype == "freeform" || @templatetype=="express" || @templatetype == "trauma" || @templatetype == "pmt" || @templatetype == "postop")
#       @patient.update_attributes(history_params)
#     end

#     if @speciality_folder_name == "orthopedics"
#       if (@templatetype == "express")
#         params[:opdrecord][:chiefcomplaintselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:chiefcomplaintselectedtags], params[:opdrecord][:chiefcomplaintselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 33962009)
#         params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags], params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 413334001)
#         params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags], params[:opdrecord][:advice_attributes][:otherprecautionsselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 413334001)
#       elsif (@templatetype == "trauma")
#         params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags], params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 413334001)
#         params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags], params[:opdrecord][:advice_attributes][:otherprecautionsselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 413334001)
#       elsif (@templatetype == "freeform")
#         params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags], params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 413334001)
#         params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags], params[:opdrecord][:advice_attributes][:otherprecautionsselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 413334001)
#         if params[:opdrecord][:clincalevaluation] == "<br>"
#           params[:opdrecord][:clincalevaluation] = ""
#         end
#         if params[:opdrecord][:diagnosis] == "<br>"
#           params[:opdrecord][:diagnosis] = ""
#         end
#         if params[:opdrecord][:plan] == "<br>"
#           params[:opdrecord][:plan] = ""
#         end
#       end
#     elsif @speciality_folder_name == "ophthalmology"
#       if (@templatetype == "express")
#         params[:opdrecord][:chiefcomplaintselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:chiefcomplaintselectedtags], params[:opdrecord][:chiefcomplaintselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 33962009)
#       elsif (@templatetype == "freeform")
#         if params[:opdrecord][:clincalevaluation] == "<br>"
#           params[:opdrecord][:clincalevaluation] = ""
#         end
#         if params[:opdrecord][:diagnosis] == "<br>"
#           params[:opdrecord][:diagnosis] = ""
#         end
#         if params[:opdrecord][:plan] == "<br>"
#           params[:opdrecord][:plan] = ""
#         end
#       end
#     end

#     @opdrecord = OpdRecord.new(record_params)
#     @opdcomments = @opdrecord.opd_record_comments
#     if (@opdrecord.save)
#       @opdrecord.record_histories.create(:user_id => current_user.id, :action => "C", :actiontime => Time.current , :template_type => @templatetype)
#       OpdRecordIdentifier.create(:patient_id => @patient.id,:organisation_id => current_user.organisation_id,:opd_record_org_id => CommonHelper::get_opd_record_identifier(current_user))
#       @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Save")
#       @opdrecordattribute = @opdrecord.create_opd_record_attribute(:recordcreateduser => session[:user_id], :recordstatus =>  Global.opd.unapproved_opdrecord.status)
#       @users = User.where(:department_id => current_user.department_id, :facility_ids.in => [@appointment.facility_id])
#       if @opdrecord.advice.present?
#         @followupappointment = Appointment.find(@opdrecord.advice.followupappointment_id.to_s)
#       end
#       respond_to do |format|
#         format.js {render "save_opd_record", :layout => false}
#       end

#       unless @opdrecord.diagnosislist == [] || @opdrecord.diagnosislist== nil || @opdrecord.diagnosislist == ""
#         @opdrecord.diagnosislist.each do |diagnosislist|
#           @presencerecenticd = RecentIcd.find_by(:code=>diagnosislist.icddiagnosiscode, :doctor=> Appointment.find(@opdrecord.appointmentid).doctor )
#           if @presencerecenticd == nil
#             @recenticd = RecentIcd.new(:specialty_id=> diagnosislist.specialty_id, :template_id=>diagnosislist.template_id, :code=>diagnosislist.icddiagnosiscode, :name=>diagnosislist.diagnosisname, :doctor=> Appointment.find(@opdrecord.appointmentid).doctor, :counter=>"1")
#             @recenticd.save
#           else
#             counter = @presencerecenticd.counter + 1
#             @presencerecenticd.update(:counter=> counter)
#             @presencerecenticd.save
#           end
#         end
#       end

#       OpdRecordJob.perform_later(@opdrecord.id.to_s)
#       DataForIpdJob.perform_later(@opdrecord.id.to_s)

#     end
#   end

#   def edit_opd_record
#     @patient = Patient.find(params[:patientid])
#     @opdrecord = OpdRecord.find(params[:opdrecordid])
#     @optometrist_record = OpdRecord.where(:templatetype => "optometrist", :specalityid => current_user.department_id.to_s, :patientid => @patient.id.to_s)
#     unless @opdrecord.templatetype == "optometrist"
#       @new_opt_view = "optometrist"
#     end
#     # if @opdrecord.advice.present?
#     #   if @opdrecord.advice.followupappointment_id
#     #     @appointment = Appointment.find(@opdrecord.advice.followupappointment_id.to_s)
#     #   else
#     #     @appointment = Appointment.find(@opdrecord.appointmentid)
#     #   end
#     # else
#       @appointment = Appointment.find(@opdrecord.appointmentid)
#     # end
#     @doctor = @appointment.try(:doctor)
#     @user = User.find(@doctor)
#     @date = @appointment.appointmentdate
#     @facility_id = @appointment.facility_id
#     @facilities = Common.new.fetch_facilities(:user => @user)
#     @appointment_types = AppointmentType.where(:user_id => @appointment.doctor.to_s,:is_active => true)
#     @formbuttons = Global.ehrcommon.ongoingepisode.formbuttons
#     @savepath = Global.ehrcommon.ongoingepisode.savepath
#     @templatetype = params[:templatetype]
#     appointmentdate = @appointment.appointmentdate
#     appointmenttime = @appointment.start_time
#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Edit")
#     @post_operation = OtSchedule.where(patient_id: @patient.id, operation_done: true, is_deleted: false)
#     if @post_operation.size > 0
#       @post_operative_day = @post_operation.order_by(otdate: "asc").last.otdate.strftime("%d/%m/%Y")
#     end
#     respond_to do |format|
#       format.js {render "edit_opd_record", :layout => false}
#     end
#   end

#   def update_opd_record

#     if params[:opdrecord][:distalneurovasculardeficit].to_s == "Absent"
#       params[:opdrecord][:sensorydeficit] = ""
#       params[:opdrecord][:motordeficit] = ""
#       params[:opdrecord][:vascualardeficit] =""
#     end
#     @patient = Patient.find(params[:opdrecord][:patientid])
#     @opdrecord = OpdRecord.find(params[:opdrecord][:opdrecordid])

#     @appointment = Appointment.find(params[:opdrecord][:appointmentid])
#     @templatetype = params[:opdrecord][:templatetype]
#     appointmentdate = @appointment.appointmentdate
#     appointmenttime = @appointment.start_time

#     # Code for Follow Up from Advice Starts Here

#     @doctor = @appointment.doctor
#     @user = User.find(@doctor)
#     if record_params[:bookappointment] == 'true'

#       if record_params[:advice_attributes][:opdfollowupdate] != "" && record_params[:advice_attributes][:opdfollowupdate] != nil
#         @followup_appointment_time =  record_params[:advice_attributes][:opdfollowuptime]
#         opdfollowupdate = Time.zone.parse(record_params[:advice_attributes][:opdfollowupdate]).strftime("%d/%m/%Y")
#         opdfollowuptime = @followup_appointment_time

#         if opdfollowuptime.split(" ")[1] == "AM"
#           unless opdfollowuptime.split(":")[0] == "12"
#             @hours = opdfollowuptime.split(":")[0]
#           else
#             @hours = 00
#           end
#         else
#           unless opdfollowuptime.split(":")[0] == "12"
#             @hours = opdfollowuptime.split(":")[0].to_i + 12
#           else
#             @hours = opdfollowuptime.split(":")[0]
#           end
#         end
#         @minutes = opdfollowuptime.split(":")[1].to_i
#         @date = opdfollowupdate.split("/")[0]
#         @month = opdfollowupdate.split("/")[1]
#         @year = opdfollowupdate.split("/")[2]
#         @followup_date_time = Time.new(@year, @month, @date, @hours, @minutes, 0)

#         if @opdrecord.advice.followupappointment_id == nil || @opdrecord.advice.followupappointment_id == ""
#           new_appointment = Appointment.new(:appointmentdate => @followup_date_time, :start_time => @followup_date_time, :patient_id => @patient.id,:appointment_type_id => record_params[:advice_attributes][:appointment_type_id],:doctor => Appointment.find(params[:opdrecord][:appointmentid]).doctor,:user_id => current_user.id,:facility_id => record_params[:advice_attributes][:appointment_facility],:department_id => @user.department_id.to_s, :departmenttype => params[:opdrecord][:encountertypeid], :appointmentstatus => 416774000,:display_id => CommonHelper::get_opd_record_identifier(@user),patient_name: @patient.fullname)
#           if new_appointment.save
#             new_appointment.update(end_time: new_appointment.start_time + 10.minutes)
#             @followupappointment_id = new_appointment.id
#             @temp_appointment = new_appointment
#             # start_cinical_workflow
#             # get_daily_reports
#             # Reports::Opd::Appointment.new(@appointment).call
#             # Code for Tracker
#             @patient_tracker = PatientTracker.find_by(patient_id: new_appointment.patient_id, tracker_removed: false)
#             unless @patient_tracker.nil?
#               if @patient_tracker.tracker_type == "Session"
#                 @new_array = @patient_tracker.session_dates << Date.current
#                 @patient_tracker.update(current_session: @patient_tracker.current_session.to_i + 1, session_dates: @new_array)
#               end
#             end
#           else
#             @followupappointment_id = ""
#           end

#         else
#           @followupappointment_id = @opdrecord.advice.followupappointment_id

#           @followupappointment = Appointment.find(@followupappointment_id)
#           unless @followupappointment == nil
#             new_appointment = @followupappointment.update(:appointmentdate => @followup_date_time, :start_time => @followup_date_time,end_time:Time.zone.parse(opdfollowuptime) + 10.minutes,:facility_id => record_params[:advice_attributes][:appointment_facility],:appointment_type_id => record_params[:advice_attributes][:appointment_type_id], :doctor =>record_params[:advice_attributes][:appointment_doctor] )
#           end
#           @followup_workflow = OpdClinicalWorkflow.find_by(appointment_id: @followupappointment_id.to_s)
#           unless @followup_workflow == nil
#             @followup_workflow.update(:appointmentdate => @followup_date_time,:facility_id => record_params[:advice_attributes][:appointment_facility])
#           end

#         end

#       end
#       record_params[:advice_attributes][:followupappointment_id] = @followupappointment_id
#     end

#     # Code for Follow Up from Advice Ends Here

#     # Code for management plan advice.

#     @patient_notes = record_params[:advicemanagementplan]
#     @patient_notes_to_rec = record_params[:advicemanagementplantoreceptionist]

#     if @patient_notes_to_rec == "true"
#       @newnote = PatientNote.new()
#       @newnote.organisation_id = current_user.organisation_id.to_s
#       @newnote.user_id = current_user.id.to_s
#       @newnote.patient_id = @patient.id.to_s
#       @newnote.comment = @patient_notes
#       @newnote.save
#     end

#     # Rails.logger.info"===================================*************************===================================#{@patient_notes}"

#     # Code for management plan advice ends.

#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     unless (@templatetype == "freeform" || @templatetype=="express" || @templatetype == "trauma" || @templatetype == "pmt" || @templatetype == "postop")
#       @patient.update_attributes(history_params)
#     end

#     if @speciality_folder_name == "orthopedics"
#       if (@templatetype == "express")
#         params[:opdrecord][:chiefcomplaintselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:chiefcomplaintselectedtags], params[:opdrecord][:chiefcomplaintselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 33962009)
#         params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags], params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 413334001)
#         params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags], params[:opdrecord][:advice_attributes][:otherprecautionsselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 413334001)
#       elsif (@templatetype == "trauma")
#         params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags], params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 413334001)
#         params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags], params[:opdrecord][:advice_attributes][:otherprecautionsselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 413334001)
#       elsif (@templatetype == "freeform")
#         params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtags], params[:opdrecord][:advice_attributes][:physiotherapyadviceselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 413334001)
#         params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:advice_attributes][:otherprecautionsselectedtags], params[:opdrecord][:advice_attributes][:otherprecautionsselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 413334001)
#         if params[:opdrecord][:clincalevaluation] == "<br>"
#           params[:opdrecord][:clincalevaluation] = ""
#         end
#         if params[:opdrecord][:diagnosis] == "<br>"
#           params[:opdrecord][:diagnosis] = ""
#         end
#         if params[:opdrecord][:plan] == "<br>"
#           params[:opdrecord][:plan] = ""
#         end
#       end
#     elsif @speciality_folder_name == "ophthalmology"
#       if (@templatetype == "express")
#         params[:opdrecord][:chiefcomplaintselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:chiefcomplaintselectedtags], params[:opdrecord][:chiefcomplaintselectedtagnames], current_user.department_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, 33962009)
#       elsif (@templatetype == "freeform")
#         if params[:opdrecord][:clincalevaluation] == "<br>"
#           params[:opdrecord][:clincalevaluation] = ""
#         end
#         if params[:opdrecord][:diagnosis] == "<br>"
#           params[:opdrecord][:diagnosis] = ""
#         end
#         if params[:opdrecord][:plan] == "<br>"
#           params[:opdrecord][:plan] = ""
#         end
#       end
#     end
#     @opdcomments = @opdrecord.opd_record_comments

#     unless @opdrecord.diagnosislist == [] || @opdrecord.diagnosislist== nil || @opdrecord.diagnosislist == ""
#       @opdrecord.diagnosislist.each do |diagnosislist|
#         @presencerecenticd = RecentIcd.find_by(:code=>diagnosislist.icddiagnosiscode, :doctor=> Appointment.find(@opdrecord.appointmentid).doctor )
#         if @presencerecenticd == nil
#         else
#           counter = @presencerecenticd.counter - 1
#           @presencerecenticd.update(:counter=> counter)
#           @presencerecenticd.save
#         end
#       end
#     end

#     #if (@opdrecord.update_attributes(record_params))
#     #if (@opdrecord.update!(record_params))
#     if (@opdrecord.update(record_params))

#       @opdrecord.record_histories.create(:user_id => current_user.id, :action => "U", :actiontime => Time.current , :template_type => @templatetype)
#       @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Update")
#       @users = User.where(:department_id => current_user.department_id,:facility_ids.in => [@appointment.facility_id])
#       respond_to do |format|
#         format.js {render "update_opd_record", :layout => false}
#       end

#       unless @opdrecord.diagnosislist == [] || @opdrecord.diagnosislist== nil || @opdrecord.diagnosislist == ""
#         @opdrecord.diagnosislist.each do |diagnosislist|
#           @presencerecenticd = RecentIcd.find_by(:code=>diagnosislist.icddiagnosiscode, :doctor=> Appointment.find(@opdrecord.appointmentid).doctor )
#           if @presencerecenticd == nil
#             @recenticd = RecentIcd.new(:specialty_id=> diagnosislist.specialty_id, :template_id=>diagnosislist.template_id, :code=>diagnosislist.icddiagnosiscode, :name=>diagnosislist.diagnosisname, :doctor=> Appointment.find(@opdrecord.appointmentid).doctor, :counter=>"1")
#             @recenticd.save
#           else
#             counter = @presencerecenticd.counter + 1
#             @presencerecenticd.update(:counter=> counter)
#             @presencerecenticd.save
#           end
#         end
#       end

#       OpdRecordJob.perform_later(@opdrecord.id.to_s)
#       DataForIpdJob.perform_later(@opdrecord.id.to_s)
#     end
#   end

#   def review_opd_record
#     @opdrecord = OpdRecord.find(params[:review_opd_record][:opdrecordid])
#     @patient = Patient.find(params[:review_opd_record][:patientid])
#     @templatetype = params[:review_opd_record][:templatetype]
#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     appointmentid = @patient.appointments.last.id
#     @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Review")
#     @opdrecordreview = @opdrecord.opd_record_reviews.create(:authoruser => params[:review_opd_record][:opd_record_author_user], :revieweruser => params[:review_opd_record][:opd_record_reviewer_user])
#     respond_to do |format|
#       format.js {render "review_opd_record", :layout => false}
#     end
#   end

#   def sign_off_opd_record
#     @patient = Patient.find(params[:patientid])
#     appointmentid = @patient.appointments.last.id
#     appointmentdate = @patient.appointments.last.appointmentdate
#     appointmenttime = @patient.appointments.last.appointmenttime
#     @opdrecord = OpdRecord.find(params[:opdrecordid])
#     @templatetype = params[:templatetype]
#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Signoff")
#     @opdrecordattribute = @opdrecord.create_opd_record_attribute(:recordsignoffuser => session[:user_id], :recordsignoffdate => Date.current.strftime("%Y-%m-%d"), :recordsignofftime =>  Time.current.strftime("%I:%M %p"), :recordstatus =>  Global.opd.signoff_opdreocrd.status)
#     respond_to do |format|
#       format.js {render "sign_off_opd_record", :layout => false}
#     end
#   end

#   def delete_opd_record

#   end

#   def download_pdf_opd_record
#     @opdrecord = OpdRecord.find(params[:opdrecordid])
#     @appointment = Appointment.find(params[:appointmentid])
#     @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Download")
#     @patient = Patient.find(params[:patientid])
#     @speciality_folder_name = params[:specality]
#     @templatetype = params[:templatetype]
#     filename = "OpdSummary_#{@patient.fullname}_#{Date.current.strftime("%d-%B-%Y")}"
#     respond_to do |format|
#       format.pdf {render :template => "templates/#{@speciality_folder_name}/download/opd_summary_download", :pdf => "#{filename}", :layout => 'pdfgen', :disposition => 'inline', :margin => { :bottom => 30 }}
#     end
#   end

#   def print_opd_record
#     @opdrecord = OpdRecord.find(params[:opdrecordid])
#     @appointment = Appointment.find(params[:appointmentid])
#     @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Print")
#     @patient = Patient.find(params[:patientid])
#     @speciality_folder_name = params[:specality]
#     @templatetype = params[:templatetype]
#     @organisation = current_user.organisation
#     @user = User.find(@opdrecord.userid)
#     @opdrecord.record_histories.create(:user_id => current_user.id, :action => "P", :actiontime => Time.current , :template_type => @templatetype)
#     @height= @organisation.letter_head_customisations[:header_height]

#     filename = "OpdSummary_#{@patient.fullname}_#{Date.current.strftime("%d-%B-%Y")}"
#     setting_service = PrintSettingService.new(current_facility_id,current_user.id.to_s,"all")
#     @print_settings = setting_service.select_print_setting
#     @logo = @print_settings[1]
#     respond_to do |format|
#       # format.html {render "templates/#{@speciality_folder_name}/print/opd_summary_print", :layout => "print"}
#       format.pdf {render :template => "templates/#{@speciality_folder_name}/download/opd_summary_download", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => {:spacing => 4,:html => {:template => 'layouts/pdf-header.html'}},:footer => {:html => { :template=>  'layouts/pdf-footer.html' },:spacing => 10, }, :margin => {left: @print_settings[0]['left_margin'].to_f * 10,right: @print_settings[0]['right_margin'].to_f * 10,:top=> @print_settings[0]['header_height'].to_f * 10, :bottom =>  @print_settings[0]['footer_height'].to_f * 10} }
#     end
#   end

#   def print_contactlens_prescription
#     @opdrecord = OpdRecord.find(params[:opdrecordid])
#     @appointment = Appointment.find(params[:appointmentid])
#     @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Print")
#     @patient = Patient.find(params[:patientid])
#     @speciality_folder_name = params[:specality]
#     @templatetype = params[:templatetype]
#     @organisation = current_user.organisation
#     @user = User.find(@opdrecord.userid)
#     @flag = 'print'
#     filename = "OpdSummary_#{@patient.fullname}_#{Date.current.strftime("%d-%B-%Y")}"
#     respond_to do |format|
#       # format.html {render "templates/#{@speciality_folder_name}/print/opd_summary_print", :layout => "print"}
#       format.pdf {render :template => "templates/#{@speciality_folder_name}/download/contactlens_opd_summary_download", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => {:spacing => 4,:html => {:template => 'layouts/pdf-header.html'}},:footer => {:html => { :template=>  'layouts/pdf-footer.html' },:spacing => 10, }, :margin => {left: @organisation.letter_head_customisations[:left_margin].to_i * 10,right: @organisation.letter_head_customisations[:right_margin].to_i * 10,:top=> @organisation.letter_head_customisations[:header_height].to_i * 10, :bottom =>  @organisation.letter_head_customisations[:footer_height].to_i * 10} }
#     end
#   end

#   def print_glass_prescription
#     @opdrecord = OpdRecord.find(params[:opdrecordid])
#     @appointment = Appointment.find(params[:appointmentid])
#     @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Print")
#     @patient = Patient.find(params[:patientid])
#     @speciality_folder_name = params[:specality]
#     @templatetype = params[:templatetype]
#     @organisation = current_user.organisation
#     @user = User.find(@opdrecord.userid)
#     filename = "OpdSummary_#{@patient.fullname}_#{Date.current.strftime("%d-%B-%Y")}"
#     respond_to do |format|
#       # format.html {render "templates/#{@speciality_folder_name}/print/opd_summary_print", :layout => "print"}
#       format.pdf {render :template => "templates/#{@speciality_folder_name}/download/glasses_opd_summary_download", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => {:spacing => 4,:html => {:template => 'layouts/pdf-header.html'}},:footer => {:html => { :template=>  'layouts/pdf-footer.html' },:spacing => 10, }, :margin => {left: @organisation.letter_head_customisations[:left_margin].to_i * 10,right: @organisation.letter_head_customisations[:right_margin].to_i * 10,:top=> @organisation.letter_head_customisations[:header_height].to_i * 10, :bottom =>  @organisation.letter_head_customisations[:footer_height].to_i * 10} }
#     end
#   end

#   def print_medication
#     @opdrecord = OpdRecord.find(params[:opdrecordid])
#     @appointment = Appointment.find(params[:appointmentid])
#     @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Print")
#     @patient = Patient.find(params[:patientid])
#     @speciality_folder_name = params[:specality]
#     @templatetype = params[:templatetype]
#     @organisation = current_user.organisation
#     @user = User.find(@opdrecord.userid)
#     filename = "OpdSummary_#{@patient.fullname}_#{Date.current.strftime("%d-%B-%Y")}"
#     respond_to do |format|
#       # format.html {render "templates/#{@speciality_folder_name}/print/opd_summary_print", :layout => "print"}
#       format.pdf {render :template => "templates/#{@speciality_folder_name}/download/medication_opd_summary_download", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => {:spacing => 4,:html => {:template => 'layouts/pdf-header.html'}},:footer => {:html => { :template=>  'layouts/pdf-footer.html' },:spacing => 10, }, :margin => {left: @organisation.letter_head_customisations[:left_margin].to_i * 10,right: @organisation.letter_head_customisations[:right_margin].to_i * 10,:top=> @organisation.letter_head_customisations[:header_height].to_i * 10, :bottom =>  @organisation.letter_head_customisations[:footer_height].to_i * 10} }
#     end
#   end

# =begin
#     format.pdf do
#       render :pdf => 'file_name',
#              :template => 'products/show.pdf.erb',
#              :layout => 'pdf.html.erb', viewport_size: '1280x1024',
#              :show_as_html => params[:debug].present?
#     end
# =end

#   def add_comment_opd_record
#     @opdrecord = OpdRecord.find(params[:opdrecordid])
#     @opdrecordcommentsave = @opdrecord.opd_record_comments.create(:comment => params[:opdrecordcomment][:comment], :user_id => session[:user_id], :doctorname => current_user.fullname, :commenttime => Time.current)
#     @opdcomments = @opdrecord.opd_record_comments
#     respond_to do |format|
#       format.js {render "templates/add_comment_opd_record", :layout => false}
#     end
#   end

#   def schedule_followup_from_opd_record
#     @patient = Patient.find_by(:_id => params[:patientid])
#     respond_to do |format|
#       format.js {render "templates/schedule_followup_from_opd_record", :layout => false }
#     end
#   end

#   def schedule_admission_from_opd_record
#     @patient = Patient.find(params[:patientid])
#     respond_to do |format|
#       format.js {render "templates/schedule_admisison_from_opd_record", :layout => false }
#     end
#   end

#   def fill_medication_data
#     @medication_set = MedicationKit.find(params[:ajax][:medicationkitid])
#     @department_id = @medication_set.department
#     @medication_kit_data = JSON.parse(@medication_set.data)
#   end

#   def fill_ipd_medication_data
#     @medication_set = MedicationKit.find(params[:ajax][:medicationkitid])
#     @department_id = @medication_set.department
#     @medication_kit_data = JSON.parse(@medication_set.data)
#   end

#   def registry
#     @patient = Patient.find(params[:patientid])
#     @registrytype = params[:registrytype]
#     respond_to do |format|
#       format.html{}
#       format.js {}
#     end
#   end
#   def functional_score
#     @patient = Patient.find(params[:patientid])
#     respond_to do |format|
#       format.js{}
#     end
#   end

#   def annontatetrauma
#     @traumaparams_limb = params[:traumaparams][:limb]
#     @traumaparams_side = params[:traumaparams][:side]
#     respond_to do |format|
#       format.html {render :layout => false}
#     end
#   end

#   def saveannontatetrauma
#     @annotatedfields = params[:traumaannotate]
#     respond_to do |format|
#       format.js { render "saveannontatetrauma", :layout => false }
#     end
#   end

#   def populate_proceduretype
#     @speciality_folder_name = params[:ajax][:specalityfoldername]
#     @regionname = params[:ajax][:templatetype]
#     @procedures = params[:ajax][:procedures]
#     @counter = params[:ajax][:counter]
#     @proceduretypes = Array[]
#     @proceduretypes = Global.send("#{@speciality_folder_name}#{@regionname}#{@procedures}").send("#{@procedures}").map do |proceduretype| proceduretype.map.with_index{|procedurehash, procedureindex| [2, 3].include?(procedureindex) ? Hash[procedurehash.each_slice(2).to_a] : procedurehash[1] } end
#     respond_to do |format|
#       format.js { render "populate_proceduretype", :layout => false }
#     end
#   end

#   def populate_side_approach_procedures
#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @templatetype = params[:ajax][:templatetype]
#     @regionid = params[:ajax][:regionid]
#     @proceduresides = Array[]
#     @procedureapproachs = Array[]
#     @procedures = Array[]
#     @proceduresubqualifiers = Array[]
#     @proceduresides = Global.send("#{@speciality_folder_name}#{@templatetype}procedures").send("side").map do |x| x.values end
#     @procedureapproachs = Global.send("#{@speciality_folder_name}#{@templatetype}procedures").send("approach").map do |x| x.values  end
#     @procedures = Global.send("#{@speciality_folder_name}#{@templatetype}procedures").send("procedures").map do |x| x.values end
#     @proceduresubqualifiers = Global.send("#{@speciality_folder_name}#{@templatetype}procedures").send("proceduresubqualifier").map do |x| x.values end
#     respond_to do |format|
#       format.json { render "templates/orthopedics/populate_side_approach_procedures", :layout => false }
#     end
#   end

#   def populate_procedurename
#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @templatetype = params[:ajax][:templatetype]
#     @proceduretype = params[:ajax][:proceduretype]
#     @regionfilename = params[:ajax][:regionfilename]
#     @procedurenames = Array[]
#     if Global.send("#{@speciality_folder_name}#{@regionfilename}procedures").try(@proceduretype.to_sym)
#       @procedurenames = Global.send("#{@speciality_folder_name}#{@regionfilename}procedures").send(@proceduretype.to_sym).map do |x| x.values end
#     end
#     respond_to do |format|
#       if @procedurenames.size > 0
#         format.json { render json: @procedurenames }
#       else
#         format.json { render json: @procedurenames }
#       end
#     end
#   end

#   def populate_procedurequalifier
#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @templatetype = params[:ajax][:templatetype]
#     @procedurename = params[:ajax][:procedurename]
#     @regionfilename = params[:ajax][:regionfilename]
#     @procedurequalifiers = Array[]
#     if Global.send("#{@speciality_folder_name}#{@templatetype}procedures").try(@procedurename.to_sym)
#       @procedurequalifiers = Global.send("#{@speciality_folder_name}#{@templatetype}procedures").send(@procedurename.to_sym).map do |x| x.values end
#     end
#     respond_to do |format|
#       if @procedurequalifiers.size > 0
#         format.json { render json: @procedurequalifiers }
#       else
#         format.json { render json: @procedurequalifiers }
#       end
#     end
#   end

#   def populate_radiology_investigations
#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @templateid = params[:ajax][:templatetype]
#     @xrayinvestigations = RadiologyInvestigationData.where(:specialty_id => @specalityid.to_i, :template_id => @templateid.to_i, :investigation_type_id.in => [Global.ehrcommon.xray.id ]).order_by(investigation_id: :asc)
#     @ctmriinvestigations = RadiologyInvestigationData.where(:specialty_id => @specalityid.to_i, :template_id => @templateid.to_i, :investigation_type_id.in => [Global.ehrcommon.mri.id, Global.ehrcommon.ct.id]).order_by(investigation_id: :asc)
#     respond_to do |format|
#       format.json { render "templates/orthopedics/populate_radiology_investigations", :layout => false }
#     end
#   end

#   def add_procedurelist
#     @counter = params[:ajax][:counter]
#     @speciality_folder_name = params[:ajax][:specalityfoldername]
#     @templatetype = params[:ajax][:templatetype]
#     @regionname = params[:ajax][:regionname]
#     @procedurename = params[:ajax][:proceduretype]
#     @proceduresides = Array[]
#     @proceduretypes = Array[]
#     @procedureapproachs = Array[]
#     @procedurenames = Array[]
#     @proceduresubqualifiers = Array[]
#     @proceduresides = Global.send("#{@speciality_folder_name}#{@regionname}procedures").send("side").map do |procedureside| procedureside.map.with_index{|proceduresidehash, proceduresideindex| proceduresideindex == 2 ? Hash[proceduresidehash.each_slice(2).to_a] : proceduresidehash[1] } end
#     @proceduretypes = Global.send("#{@speciality_folder_name}#{@regionname}procedures").send("type").map do |proceduretype| proceduretype.map.with_index{|proceduretypehash, proceduretypeindex| proceduretypeindex == 2 ? Hash[proceduretypehash.each_slice(2).to_a] : proceduretypehash[1] } end
#     @procedureapproachs = Global.send("#{@speciality_folder_name}#{@regionname}procedures").send("approach").map do |procedureapproach| procedureapproach.map.with_index{|procedureapproachhash, procedureapproachindex| procedureapproachindex == 2 ? Hash[procedureapproachhash.each_slice(2).to_a] : procedureapproachhash[1] } end
#     @procedurenames = Global.send("#{@speciality_folder_name}#{@regionname}procedures").send(@procedurename.to_sym).map do |procedurename| procedurename.map.with_index{|procedurenamehash, procedurenameindex| procedurenameindex == 2 ? Hash[procedurenamehash.each_slice(2).to_a] : procedurenamehash[1] } end
#     @proceduresubqualifiers = Global.send("#{@speciality_folder_name}#{@regionname}procedures").send("proceduresubqualifier").map do |proceduresubqualifier| proceduresubqualifier.map.with_index{|proceduresubqualifierhash, proceduresubqualifierindex| proceduresubqualifierindex == 2 ? Hash[proceduresubqualifierhash.each_slice(2).to_a] : proceduresubqualifierhash[1] } end
#     respond_to do |format|
#       format.js { render "add_procedurelist", :layout => false }
#     end
#   end

#   def populate_topicd_list
#     topicd_name = params[:ajax][:topicd_name]
#     topicd_list = Array[]
#     topicddiagnosis = TopIcdDiagnosis.find_by(name: topicd_name)
#     topicd_list = topicddiagnosis.try(:list)
#     respond_to do |format|
#       if topicd_list.size > 0
#         format.json { render json: topicd_list }
#       else
#         format.json { render json: topicd_list }
#       end
#     end

#   end

#   def populate_ophthalinvestigations
#     eyearea = params[:ajax][:eyearea]
#     #eyearea_region_snomedid = params[:ajax][:selected_eyearea_region_snomedid]
#     ophthalinvestigations = Array[]
#     if Global.send("ophthalmologyinvestigations").try(eyearea.to_sym)
#       ophthalinvestigations = Global.send("ophthalmologyinvestigations").try(eyearea.to_sym)
#     end
#     respond_to do |format|
#       if ophthalinvestigations.size > 0
#         format.json { render json: ophthalinvestigations }
#       else
#         format.json { render json: ophthalinvestigations }
#       end
#     end
#   end

#   def populate_ophthalprocedures
#     eyearea = params[:ajax][:eyearea]
#     #eyearea_region_snomedid = params[:ajax][:selected_eyearea_region_snomedid]
#     ophthalprocedures = Array[]
#     if Global.send("ophthalmologyprocedures").try(eyearea.to_sym)
#       ophthalprocedures = Global.send("ophthalmologyprocedures").try(eyearea.to_sym)
#     end
#     respond_to do |format|
#       if ophthalprocedures.size > 0
#         format.json { render json: ophthalprocedures }
#       else
#         format.json { render json: ophthalprocedures }
#       end
#     end
#   end

#   def testinlinesvg

#   end

#   def user_templates
#     respond_to do |format|
#       format.js { render :layout => "loggedin" }
#       format.html { render :layout => "loggedin" }
#     end
#   end

#   def fetch_custom
#     @total_custom_count = UsersOpdRecord.where(:user_id => current_user.id).count
#     @custom_count = UsersOpdRecord.where(:user_id => current_user.id,:name => %r[#{params[:sSearch]}]).count
#     @custom_templates = UsersOpdRecord.where(:user_id => current_user.id,:name => %r[#{params[:sSearch]}])
#                             .limit(params[:iDisplayLength])
#                             .offset(params[:iDisplayStart])
#                             .order("name "+params[:sSortDir_0])
#     @sEcho = params[:sEcho]
#     respond_to do |format|
#       format.json {}
#     end
#   end

#   def custom_new
#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @templatetype = params[:templatetype]
#     @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     @patient = nil
#     @formbuttons = 'prefill_actions'
#     @savepath = 'templates_custom_create_path'
#     @opdrecord = OpdRecord.new
#     @opdspeciality = TemplateOpdRecord.new(@patient, @opdrecord, @speciality_folder_name, @specalityid, @templatetype, @templateid, current_user.department_id).new_record
#     respond_to do |format|
#       format.js {}
#     end
#   end
#   def custom_create
#     @user_template = UsersOpdRecord.new
#     @user_template.user_id = current_user.id
#     @user_template.record_details = params[:opdrecord].to_json
#     @user_template.name = params[:label]
#     @user_template.base_template = params[:opdrecord][:templatetype]
#     @user_template.save
#     respond_to do |format|
#       format.js {}
#     end
#   end

#   def custom_edit
#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @custom_template = UsersOpdRecord.find(params[:custom_template_id])
#     custom_record_data = JSON.parse(@custom_template.record_details)
#     @templatetype = @custom_template.base_template
#     @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)

#     @opdrecord = OpdRecord.new(custom_record_data)
#     @patient = nil
#     @formbuttons = 'prefill_actions'
#     @savepath = 'templates_custom_update_path'
#     @opdspeciality = TemplateOpdRecord.new(@patient, @opdrecord, @speciality_folder_name, @specalityid, @templatetype, @templateid, current_user.department_id).new_record
#     respond_to do |format|
#       format.js {}
#     end
#   end

#   def custom_update
#     @user_template = UsersOpdRecord.find(params[:custom_template_id])
#     @user_template.record_details = params[:opdrecord].to_json
#     @user_template.name = params[:label]
#     @user_template.update
#     respond_to do |format|
#       format.js {}
#     end
#   end
#   def custom_destroy
#     user_template = UsersOpdRecord.find(params[:custom_template_id])
#     user_template.destroy
#     respond_to do |format|
#       format.js {}
#     end
#   end

#   # IPD
#   def new_ipd_record
#     @templates_save_ipd_record_path = "templates_save_ipd_record_path"
#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @find_diagnosis_path = "new"
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @templatetype = params[:templatetype]
#     if @templatetype == "operativenote"
#       @procedurenotes = ProcedureNote.where(:organisation_id => current_user.organisation_id.to_s, :user_id => current_user.id.to_s)
#     end
#     @templateid, @displayname = TemplatesHelper.get_ipd_templateid_displayname(params[:templatetype])
#     @patient = Patient.find(params[:patient_id])
#     # For pulling some data from opd
#     @opd = OpdRecord.where(:patientid => @patient.id.to_s)
#     @admission = Admission.find_by(:id => params[:admission_id])
#     @facilities = current_user.facilities
#     @departments = @facilities.first.departments
#     @users = User.where(:facility_ids.in => [@facilities.first.id], :department_id => current_user.department_id).with_all_roles(:doctor)
#     # todo have to add admission
#     @form_buttons = Global.ehrcommon.newepisode.formbuttons
#     @save_path = Global.ehrcommon.newepisode.savepath
#     @ipdrecord = IpdRecord.new

#     respond_to do |format|
#       format.js {}
#     end
#   end

#   # IPD
#   def save_ipd_record
#     @patient = Patient.find(params[:ipdrecord][:patientid])
#     @admission = Admission.find_by(:id => params[:ipdrecord][:admissionid])
#     @templatetype = params[:ipdrecord][:templatetype]
#     @opd = OpdRecord.where(:patientid => @patient.id.to_s)
#     @ipdrecord = IpdRecord.new(ipd_record_params)
#     if (@ipdrecord.save)
#       #TemplateDataWorker.perform_async(@opdrecord.id)
#       respond_to do |format|
#         format.js {render "save_ipd_record", :layout => false}
#       end
#       IpdRecordJob.perform_later(@ipdrecord.id.to_s)
#       OtInventoryInvoiceJob.perform_later(@ipdrecord.id.to_s)
#     end
#   end

#   # IPD
#   def edit_ipd_record
#     @templates_save_ipd_record_path = "templates_update_ipd_record_path"
#     # @templatetype = params[:templatetype]
#     # {"admissionid"=>"56aefff4f9c44c1cb9000001", "ipdrecordid"=>"56af4572f9c44c1cb9000077", "patientid"=>"56a8bc1df9c44c063800004f", "templatetype"=>"admissionnote", "controller"=>"templates", "action"=>"edit_ipd_record"}
#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @find_diagnosis_path = "edit"
#     @templatetype = params[:templatetype]
#     if @templatetype == "operativenote"
#       @procedurenotes = ProcedureNote.where(:organisation_id => current_user.organisation_id.to_s, :user_id => current_user.id.to_s)
#     end
#     @templateid, @displayname = TemplatesHelper.get_ipd_templateid_displayname(params[:templatetype])
#     @patient = Patient.find_by(:id => params[:patient_id])
#     @opd = OpdRecord.where(:patientid => @patient.id.to_s)
#     @admission = Admission.find_by(:id => params[:admission_id])
#     @facilities = current_user.facilities
#     @departments = @facilities.first.departments
#     @users = User.where(:facility_ids.in => [@facilities.first.id], :department_id => current_user.department_id).with_all_roles(:doctor)
#     @form_buttons = Global.ehrcommon.ongoingepisode.formbuttons
#     @save_path = Global.ehrcommon.ipdongoingepisode.savepath
#     @ipdrecord = IpdRecord.find_by(:id => params[:ipdrecord_id])
#     respond_to do |format|
#       format.js {}
#     end
#   end

#   # IPD
#   def update_ipd_record
#     @patient = Patient.find(params[:ipdrecord][:patientid])
#     @admission = Admission.find_by(:id => params[:ipdrecord][:admissionid])
#     @templatetype = params[:ipdrecord][:templatetype]
#     @opd = OpdRecord.where(:patientid => @patient.id.to_s)
#     @ipdrecord = IpdRecord.find(params[:ipdrecord][:ipdrecordid])
#     # IpdRecordJob.perform_later(@ipdrecord.id.to_s)
#     if @ipdrecord.update_attributes(ipd_record_params)
#       respond_to do |format|
#         format.js {render "save_ipd_record", :layout => false}
#       end
#     end
#   end

#   # IPD
#   def print_ipd_record
#     @ipdrecord = IpdRecord.find_by(:id => params[:ipdrecord_id])
#     @patient = Patient.find_by(:id => params[:patient_id])
#     @admission = Admission.find_by(:id => params[:admission_id])
#     @templatetype = params[:templatetype]
#     #@speciality_folder_name = params[:specality]
#     @organisation = current_user.organisation
#     filename = "IpdSummary_#{@patient.fullname}_#{Date.current.strftime("%d-%B-%Y")}"
#     @user = User.find_by(:id => @ipdrecord.userid)
#     respond_to do |format|
#       # format.html {render "templates/common/print/ipd_summary_print", :layout => "print"}
#       format.pdf {render :template => "templates/ophthalmology/download/ipd_summary_download", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => {:spacing => 4,:html => {:template => 'layouts/pdf-header.html'}},:footer => {:html => { :template=>  'layouts/pdf-footer.html' },:spacing => 10, }, :margin => {left: @organisation.letter_head_customisations[:left_margin].to_i * 10,right: @organisation.letter_head_customisations[:right_margin].to_i * 10,:top=> @organisation.letter_head_customisations[:header_height].to_i * 10, :bottom =>  @organisation.letter_head_customisations[:footer_height].to_i * 10}}
#     end
#   end

#   def record
#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @templatetype = params[:templatetype]
#     @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     @patient = Patient.find(params[:patientid])
#     #@pastopdrecord = OpdRecordAttribute.opdPatient(params[:patientid])
#     @pastopdrecord = OpdRecordAttribute.where(:patient_id => params[:patientid]).order_by(created_at: :desc).first # check the patient's past opd records history sorted by decending order and pick the 1st record.
#     if (!@pastopdrecord.nil?)          # Check if any past OPD records exist for the patient.
#       if (@pastopdrecord.templatetype.eql?(@templatetype))              # if past records do exist, get the last one and see if same template is being opened.
#         if (@pastopdrecord.recordcreatedate.eql?(Date.current))           # Check if opd record is being opened same day.
#           @formbuttons = Global.ehrcommon.ongoingepisode.formbuttons    # if same day then, opd buttons will show update opd record.
#           @savepath = Global.ehrcommon.ongoingepisode.savepath
#           @opdrecord = @pastopdrecord.opd_record
#           @opdrecord.initialize_nested_objects
#         else                                                            # if patients comes same day for checkup then, and different template is opened then new emtpy form will be openeed.
#           @formbuttons = Global.ehrcommon.newepisode.formbuttons
#           @savepath = Global.ehrcommon.newepisode.savepath
#           @opdrecord = @pastopdrecord.opd_record
#           @opdrecord.initialize_nested_objects
#         end
#       else                                                              # if patient has past opd records but if template is different then open new empty form.
#         @formbuttons = Global.ehrcommon.newepisode.formbuttons
#         @savepath = Global.ehrcommon.newepisode.savepath
#         @opdrecord = OpdRecord.new
#         @opdrecord.initialize_nested_objects
#       end
#     else                                                                # if patient has no past opd records then open new empty form
#       @formbuttons = Global.ehrcommon.newepisode.formbuttons
#       @savepath = Global.ehrcommon.newepisode.savepath
#       @opdrecord = OpdRecord.new
#       @opdrecord.initialize_nested_objects
#     end
#     #end
#     #get all the medication kits of the current doctor
#     @medication_kits = MedicationKit.where(:user_id => current_user.id)
#     respond_to do |format|
#       format.html{}
#       format.js {render "record", :layout => false}
#     end
#   end

#   def record_order
#     @templatetype = params[:templatetype]
#     @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
#     @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
#     @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
#     @patient = Patient.find(params[:patientid])
#     @medication_kits = MedicationKit.where(:user_id => current_user.id)
#     respond_to do |format|
#       format.html{}
#       format.js {render "patientorders", :layout => false}
#     end
#   end

#   def add_appendages_diagram
#     @eyeside = params[:ajax][:eyeside]
#     @patient_id = params[:ajax][:patient_id]
#     @diagramtype = params[:ajax][:diagram_type]
#     @a = Base64.strict_encode64(File.open(Rails.root.join("app", "assets", "images", "ophthal_annotations", "appendages_#{@eyeside}.png").to_path, "rb").read)
#     respond_to do |format|
#       format.js { render "templates/ophthalmology/js/add_appendages_diagram", :layout => false }
#     end
#   end

#   def save_appendages_diagram
#     @eyeside = params[:ajax][:eyeside]
#     params[:ajax] = convert_data_uri_to_upload(params[:ajax])
#     @tempasset = PatientSummaryAssetUpload.new(diagram_params)
#     @tempasset["parent_folder_id"] = "560cc6f72b2e26135d000007"
#     @tempasset["is_folder"] = "N"
#     @tempasset["name"] = params[:ajax][:diagram_type]
#     if @tempasset.save
#       respond_to do |format|
#         format.js { render "templates/ophthalmology/js/save_appendages_diagram", :layout => false }
#       end
#     end
#   end

#   def edit_appendages_diagram
#     @eyeside = params[:eyeside]
#     @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
#     @a = Base64.strict_encode64(read_file_remote("#{@tempasset.asset_path_url}"))
#     #@a = Base64.strict_encode64(File.open(@tempasset.asset_path_url, "rb").read)
#     respond_to do |format|
#       format.js { render "templates/ophthalmology/js/add_appendages_diagram", :layout => false }
#     end
#   end

#   def add_fundus_diagram
#     @eyeside = params[:ajax][:eyeside]
#     @diagramtype = params[:ajax][:diagram_type]
#     @patient_id = params[:ajax][:patient_id]
#     @a = Base64.strict_encode64(File.open(Rails.root.join("app", "assets", "images", "ophthal_annotations", "fundus_#{@eyeside}.png").to_path, "rb").read)
#     respond_to do |format|
#       format.js { render "templates/ophthalmology/js/add_fundus_diagram", :layout => false }
#     end
#   end

#   def save_fundus_diagram
#     puts "anc"
#     puts params
#     @eyeside = params[:ajax][:eyeside]
#     params[:ajax] = convert_data_uri_to_upload(params[:ajax])
#     @tempasset = PatientSummaryAssetUpload.new(diagram_params)
#     @tempasset["parent_folder_id"] = "560cc6f72b2e26135d000007"
#     @tempasset["is_folder"] = "N"
#     @tempasset["name"] = params[:ajax][:diagram_type]
#     if @tempasset.save
#       respond_to do |format|
#         format.js { render "templates/ophthalmology/js/save_fundus_diagram", :layout => false }
#       end
#     end
#   end

#   def edit_fundus_diagram
#     @eyeside = params[:eyeside]
#     @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
#     @a = Base64.strict_encode64(read_file_remote("#{@tempasset.asset_path_url}"))
#     respond_to do |format|
#       format.js { render "templates/ophthalmology/js/add_fundus_diagram", :layout => false }
#     end
#   end

#   def discard_fundus_diagram
#     @eyeside = params[:eyeside]
#     @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
#     if @tempasset
#       @patient_id = @tempasset.patient_id
#       @tempasset.remove_asset_path!
#       @tempasset.delete
#     end
#     respond_to do |format|
#       format.js { render "templates/ophthalmology/js/discard_fundus_diagram", :layout => false }
#     end
#   end

#   def add_cornea_diagram
#     @eyeside = params[:ajax][:eyeside]
#     @patient_id = params[:ajax][:patient_id]
#     @diagramtype = params[:ajax][:diagram_type]
#     @a = Base64.strict_encode64(File.open(Rails.root.join("app", "assets", "images", "ophthal_annotations", "cornea_#{@eyeside}.png").to_path, "rb").read)
#     respond_to do |format|
#       format.js { render "templates/ophthalmology/js/add_cornea_diagram", :layout => false }
#     end
#   end

#   def add_appendages_diagram
#     @eyeside = params[:ajax][:eyeside]
#     @patient_id = params[:ajax][:patient_id]
#     @diagramtype = params[:ajax][:diagram_type]
#     @a = Base64.strict_encode64(File.open(Rails.root.join("app", "assets", "images", "ophthal_annotations", "appendages_#{@eyeside}.png").to_path, "rb").read)
#     respond_to do |format|
#       format.js { render "templates/ophthalmology/js/add_appendages_diagram", :layout => false }
#     end
#   end

#   def discard_appendages_diagram
#     @eyeside = params[:eyeside]
#     @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
#     if @tempasset
#       @patient_id = @tempasset.patient_id
#       @tempasset.remove_asset_path!
#       @tempasset.delete
#     end
#     respond_to do |format|
#       format.js { render "templates/ophthalmology/js/discard_appendages_diagram", :layout => false }
#     end
#   end

#   def save_cornea_diagram
#     @eyeside = params[:ajax][:eyeside]
#     params[:ajax] = convert_data_uri_to_upload(params[:ajax])
#     @tempasset = PatientSummaryAssetUpload.new(diagram_params)
#     @tempasset["parent_folder_id"] = "560cc6f72b2e26135d000007"
#     @tempasset["is_folder"] = "N"
#     @tempasset["name"] = params[:ajax][:diagram_type]
#     if @tempasset.save
#       respond_to do |format|
#         format.js { render "templates/ophthalmology/js/save_cornea_diagram", :layout => false }
#       end
#     end
#   end

#   def edit_cornea_diagram
#     @eyeside = params[:eyeside]
#     @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
#     @a = Base64.strict_encode64(read_file_remote("#{@tempasset.asset_path_url}"))
#     #@a = Base64.strict_encode64(File.open(@tempasset.asset_path_url, "rb").read)
#     respond_to do |format|
#       format.js { render "templates/ophthalmology/js/add_cornea_diagram", :layout => false }
#     end
#   end

#   def discard_cornea_diagram
#     @eyeside = params[:eyeside]
#     @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
#     if @tempasset
#       @patient_id = @tempasset.patient_id
#       @tempasset.remove_asset_path!
#       @tempasset.delete
#     end
#     respond_to do |format|
#       format.js { render "templates/ophthalmology/js/discard_cornea_diagram", :layout => false }
#     end
#   end

#   def add_cornea_slit_diagram
#     @eyeside = params[:ajax][:eyeside]
#     @patient_id = params[:ajax][:patient_id]
#     @diagramtype = params[:ajax][:diagram_type]
#     @a = Base64.strict_encode64(File.open(Rails.root.join("app", "assets", "images", "ophthal_annotations", "corneaslit.png").to_path, "rb").read)
#     respond_to do |format|
#       format.js { render "templates/ophthalmology/js/add_cornea_slit_diagram", :layout => false }
#     end
#   end

#   def save_cornea_slit_diagram
#     @eyeside = params[:ajax][:eyeside]
#     params[:ajax] = convert_data_uri_to_upload(params[:ajax])
#     @tempasset = PatientSummaryAssetUpload.new(diagram_params)
#     @tempasset["parent_folder_id"] = "560cc6f72b2e26135d000007"
#     @tempasset["is_folder"] = "N"
#     @tempasset["name"] = params[:ajax][:diagram_type]
#     if @tempasset.save
#       respond_to do |format|
#         format.js { render "templates/ophthalmology/js/save_cornea_slit_diagram", :layout => false }
#       end
#     end
#   end

#   def edit_cornea_slit_diagram
#     @eyeside = params[:eyeside]
#     @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
#     @a = Base64.strict_encode64(read_file_remote("#{@tempasset.asset_path_url}"))
#     #@a = Base64.strict_encode64(File.open(@tempasset.asset_path_url, "rb").read)
#     respond_to do |format|
#       format.js { render "templates/ophthalmology/js/add_cornea_slit_diagram", :layout => false }
#     end
#   end

#   def discard_cornea_slit_diagram
#     @eyeside = params[:eyeside]
#     @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
#     if @tempasset
#       @patient_id = @tempasset.patient_id
#       @tempasset.remove_asset_path!
#       @tempasset.delete
#     end
#     respond_to do |format|
#       format.js { render "templates/ophthalmology/js/discard_cornea_slit_diagram", :layout => false }
#     end
#   end

#   def print_flag
#     opdrecord = OpdRecord.find_by(:id => params[:ajax][:opd_record_id])
#     opdrecord.update_attribute(:"#{params[:ajax][:flag_name]}", params[:ajax][:flag_value])
#     respond_to do |format|
#       format.js { render nothing: true }
#     end
#   end

#   def saved_procedure_note
#     @procedurenote = ProcedureNote.find_by(:id => params[:ajax][:procedure_note_id])
#     @proceduretextstring = @procedurenote.proceduretext.to_s.html_safe.to_s
#     puts @proceduretextstring
#     respond_to do |format|
#       format.js { render "templates/ipd/common/saved_procedure_note", :layout => false }
#     end
#   end

#   def new_note
#     @procedurenote = ProcedureNote.new(:proceduretext => params[:ajax][:proceduretext])
#     puts params[:ajax][:proceduretext]
#     respond_to do |format|
#       format.html{render "templates/ipd/common/new_note", layout: false}
#     end
#   end

#   def save_note
#     params[:procedurenote][:organisation_id] = current_user.organisation_id.to_s
#     params[:procedurenote][:user_id] = current_user.id.to_s
#     @procedurenote = ProcedureNote.new(save_procedurenote_params)
#     if @procedurenote.save
#       @procedurenotes = ProcedureNote.where(:organisation_id => current_user.organisation_id.to_s, :user_id => current_user.id.to_s)
#       respond_to do |format|
#         #format.js { render nothing: true }
#         format.js { render "templates/ipd/common/save_note", layout: false }
#       end
#     end
#   end

#   def reload_note
#     @procedurenotes = ProcedureNote.where(:organisation_id => current_user.organisation_id.to_s, :user_id => current_user.id.to_s)
#     respond_to do |format|
#       format.js { render "templates/ipd/common/save_note", layout: false }
#     end
#   end

#   # OPD
#   def add_medication
#     @counter = params[:ajax][:counter]
#     @taper = params[:ajax][:taper]
#     respond_to do |format|
#       format.js { render "add_medication", layout: false }
#     end
#   end

#   def add_ot_item
#     @counter = params[:ajax][:counter]
#     respond_to do |format|
#       format.js { render "add_ot_item", layout: false }
#     end
#   end

#   # IPD
#   def ipdaddmedication
#     @counter = params[:ajax][:counter]
#     respond_to do |format|
#       format.js { render "ipdaddmedication", layout: false }
#     end
#   end

#   def setup_view_only_flag
#     @flag = "view"
#   end

#   def setup_print_only_flag
#     @flag = "print"
#   end

#   def optoreading
#     @flag = "view"
#     @opdrecord = OpdRecord.find_by(:id => params[:optoreadingid])
#     respond_to do |format|
#       format.html{render "templates/ophthalmology/opd_partials/past_optometrist_reading", layout: false}
#     end
#   end

#   def delete_clone_record
#     @opdrecord = OpdRecord.find_by(id: params[:id])
#     @patienttimeline = PatientTimeline.find_by(record_id: @opdrecord.id)

#     if @patienttimeline.nil?
#       unless @opdrecord.nil?
#         @opdrecord.delete
#       end
#     end
#     respond_to do |format|
#       format.js {}
#     end
#   end

#   private

#   def save_procedurenote_params
#     params.require(:procedurenote).permit(:name, :proceduretext, :organisation_id, :user_id)
#   end

#   def record_params
#     params.require(:opdrecord).permit!
#   end

#   def ipd_record_params
#     params.require(:ipdrecord).permit!
#   end

#   def diagram_params
#     #params.require(:ajax).permit(:asset_path_data, :diagram_type, :eyeside)
#     params.require(:ajax).permit(:asset_path, :diagram_type, :eyeside, :patient_id)
#   end

#   # Split up a data uri
#   def split_base64(uri_str)
#     if uri_str.match(%r{^data:(.*?);(.*?),(.*)$})
#       uri = Hash.new
#       uri[:type] = $1 # "image/gif"
#       uri[:encoder] = $2 # "base64"
#       uri[:data] = $3 # data string
#       uri[:extension] = $1.split('/')[1] # "gif"
#       return uri
#     else
#       return nil
#     end
#   end

#   # Convert data uri to uploaded file. Expects object hash, eg: params[:post]
#   def convert_data_uri_to_upload(obj_hash)
#     if obj_hash[:asset_path_data].try(:match, %r{^data:(.*?);(.*?),(.*)$})
#       image_data = split_base64(obj_hash[:asset_path_data])
#       image_data_string = image_data[:data]
#       image_data_binary = Base64.decode64(image_data_string)

#       temp_img_file = Tempfile.new("data_uri-upload")
#       temp_img_file.binmode
#       temp_img_file << image_data_binary
#       temp_img_file.rewind

#       img_params = {:filename => "data-uri-img.#{image_data[:extension]}", :type => image_data[:type], :tempfile => temp_img_file}
#       uploaded_file = ActionDispatch::Http::UploadedFile.new(img_params)

#       obj_hash[:asset_path] = uploaded_file
#       obj_hash.delete(:asset_path_data)
#     end

#     return obj_hash
#   end

#   def read_file_remote(url)
#     uri = URI(url)
#     puts 'llllllll'
#     puts uri
#     data = Net::HTTP.get_response(uri)
#     data.body
#   end

#   def history_params
#     params.require(:patient).permit!
#   end

#   # def start_cinical_workflow
#   #   patient = Patient.find_by(id: @temp_appointment.patient_id)
#   #   if current_user.department.name == "Ophthalmology"
#   #     OpdClinicalWorkflow::Ophthalmology.create(:patient_id => @temp_appointment.patient_id,appointment_id: @temp_appointment.id.to_s,facility_id: record_params[:advice_attributes][:appointment_facility],organisation_id: current_user.organisation.id,user_id: current_user.id,appointmentdate: @temp_appointment.appointmentdate,patient_name: patient.fullname,doctor_ids: [@temp_appointment.doctor.to_s])
#   #   elsif current_user.department.name == "Orthopedics"
#   #     OpdClinicalWorkflow::Orthopedics.create(:patient_id =>  @temp_appointment.patient_id,appointment_id: @temp_appointment.id.to_s,facility_id: record_params[:advice_attributes][:appointment_facility],organisation_id: current_user.organisation.id,user_id: current_user.id,appointmentdate: @temp_appointment.appointmentdate,patient_name: patient.fullname,doctor_ids: [@temp_appointment.doctor.to_s])
#   #   end
#   # end

#   #  by anoop
#   # def history_params
#   #   params.require(:patient).permit(:specialstatus,patient_history_attributes: [ :patient_id, :templatetype, :templateid, patientpersonalhistory_attributes: [:flag,problems: []], patientallergyhistory_attributes: [:flag,:others, antimicrobialagents: [], nsaids: [], antifungalagents: [], antiviralagents: [], contact: [],eyedrops: [], food: []] ])
#   # end
#   # ***below is migration code for patient personal and allergy history**

#   # def create_history_params

#   # end

#   #
#   #
#   # def update_other_allergy
#   #   Patient.all.each do |pat|
#   #     if pat.patient_history.patientallergyhistory.others.nil?
#   #       @pat_history = PatientHistory.find_by(patient_id: pat.id)
#   #       @pat_history.update_attributes("patientallergyhistory_attributes"=>{others: '' })
#   #     end
#   #   end
#   # end

# end
