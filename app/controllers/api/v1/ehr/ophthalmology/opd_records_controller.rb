module Api
  module V1
    module Ehr
      module Ophthalmology
        class OpdRecordsController < ApiApplicationController
          include TemplatesHelper

          before_action :authorize_token
          before_action :convert_to_json, only: [:create, :update]
          before_action :setup_view_only_flag, only: [:new, :create, :edit, :update, :view_opd_summary]
          before_action :setup_print_only_flag, only: [:print_opd_record]

          respond_to :js, :json, :html

          def new
            @current_user = current_user
            @current_facility = current_facility
            @procedures = CommonProcedure::Ophthalmology.all
            @templatetype = params[:templatetype]
            @patient = Patient.find(params[:patientid])
            @appointment = Appointment.find(params[:appointmentid])
            @clone_record = params[:flag]

            @advice_set = AdviceSet.where(organisation_id: @current_user.organisation_id, is_deleted: false, '$or' => [
                                            { level: "organisation" },
                                            { facility_id: @current_facility.id, level: "facility" },
                                            { user_id: @current_user.id, level: "user" }
                                          ]).order(counter: "desc").map { |p| ["#{p[:name]} by: #{p[:level].to_s.capitalize}", "#{p[:content]}", { 'data-id' => "#{p[:id]}" }] } + Global.ophthal_advice_option.sets.map { |p| ["#{p[:name]}", "#{p[:content]}"] }

            if @current_facility.clinical_workflow
              workflow = OpdClinicalWorkflow.find_by(appointment_id: params[:appointmentid].to_s)
              @consultant_id = workflow.try(:consultant_ids).try(:last)
            else
              @consultant_id = @appointment.consultant_id
            end

            if @clone_record == "clone"
              @clone_record_id = params[:opd_record_id]
            else
              if ['eye', 'quickeye', 'paediatrics', 'postop'].include? @templatetype

                @patient_self_history = PatientSelfHistory.where(patient_id: @patient.id.to_s).order_by('created_at DESC')[0]

                find_ipd_record_for_postop
                @opdrecord = OpdRecord.new
                @record = OpdRecord.where(:templatetype => "optometrist", :patientid => @patient.id.to_s, :appointmentid => @appointment.id.to_s).order_by(created_at: "asc")
                if @record.size > 0
                  if @record.last
                    record_keys_values_r
                    record_keys_values_l
                    record_keys_values_chiefcomplaint
                    record_keys_values_other
                    @opdrecord.attributes = @record_keys_values_r.merge(@record_keys_values_l).merge(@record_keys_values_chiefcomplaint).merge(@record_keys_values_other)
                    @new_opt_view = "optometrist"
                  end
                end
              elsif (@templatetype == "pmt")
                @opdrecord = OpdRecord.new
                @record = OpdRecord.where(:templatetype.in => ["eye", "quickeye", "paediatrics"], :specalityid.in => current_user.specialty_ids, :patientid => @patient.id.to_s, :created_at.lt => Date.current).order_by(created_at: "asc")
                if @record.size > 0
                  if @record.last
                    record_keys_values_r
                    record_keys_values_l
                    record_keys_values_other
                    @opdrecord.attributes = @record_keys_values_l.merge(@record_keys_values_r).merge(@record_keys_values_other)
                    # @new_opt_view = "optometrist"
                  end
                end
              else
                # @optometrist_record = OpdRecord.where(:templatetype => "optometrist", :specalityid => current_user.department_id.to_s, :patientid => @patient.id.to_s, :created_at => {'$lt' => Date.current })
                @optometrist_record = OpdRecord.where(:templatetype => "optometrist", :specalityid.in => current_user.specialty_ids, :patientid => @patient.id.to_s)
                @opdrecord = OpdRecord.new
              end
            end

            @user_set_type = UsersLaboratoryList.where(user_id: @current_user.id, set_type: 440655000, is_deleted: false).pluck(:name, :id)
            @facility_set_type = FacilityLaboratoryList.where(facility_id: @current_facility.id, set_type: 440655000, is_deleted: false).pluck(:name, :id)
            @set_type = @user_set_type + @facility_set_type
            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@appointment.specialty_id)
            @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
            @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
            @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
            @facility_id = current_facility.id
            @date = Date.current
            @user = User.find_by(id: @consultant_id)
            @facilities = Common.new.fetch_facilities(:user => @user)
            @referral_facilities = Common.new.fetch_referred_facilities(:current_user => @current_user, :facility_id => @current_facility)

            @referred_from_facility = [@current_facility]

            # referral doc for intra facility start
            @referral_doctor = User.where(organisation_id: @current_user.organisation_id, role_ids: 158965000, is_active: true)

            # referral doc for intra facility end

            if @current_user.has_role?(:doctor)
              @appointment_types = AppointmentType.where(:user_id => @current_user.id, :is_active => true)
            else
              @appointment_types = AppointmentType.where(:user_id => @user.id, :is_active => true)
            end

            if @current_user.has_role?(:doctor)
              @ophthal_laboratory_set = OphthalLaboratorySet.where(doctor_id: @current_user.id.to_s, is_active: true)
              @radiology_laboratory_set = RadiologyLaboratorySet.where(doctor_id: @current_user.id.to_s, is_active: true)
            else
              @ophthal_laboratory_set = OphthalLaboratorySet.where(facility_id: @current_facility.id.to_s, doctor_id: nil, is_active: true)
              @radiology_laboratory_set = RadiologyLaboratorySet.where(facility_id: @current_facility.id.to_s, doctor_id: nil, is_active: true)
            end

            @formbuttons = Global.ehrcommon.newepisode.formbuttons
            @savepath = Global.ehrcommon.newepisode.savepath

            if @clone_record == "clone"
              opd_record = OpdRecord.find_by(:id => @clone_record_id)
              @opdrecord = opd_record.clone
              @opdrecord.created_at = Time.current.utc
              @opdrecord.updated_at = Time.current.utc
              @opdrecord.record_type = "clone"
              @opdrecord.record_histories.delete_all
              @opdrecord.appointmentid = @appointment.id
              unless @opdrecord.templatetype == 'optometrist'
                @opdrecord.advice.followupappointment_id = nil
                @opdrecord.advice.opdfollowupdate = nil
              end
              @opdrecord.save
            end

            @opdspeciality = TemplateOpdRecord.new(@patient, @opdrecord, @speciality_folder_name, @specalityid, @templatetype, @templateid, @appointment.specialty_id).new_record
            # end

            @post_operation = OtSchedule.where(patient_id: @patient.id, operation_done: true, is_deleted: false)
            if @post_operation.size > 0
              @post_operative_day = @post_operation.order_by(otdate: "asc").last.otdate.strftime("%d/%m/%Y")
            end

            if @clone_record == "clone"
              render json: { 'msg': "clone" }
              # @edit_opd_link = "edit_opd_records_"+@speciality_folder_name+"_note_path(@opdrecord.id,:opdrecordid=> @opdrecord.id, :patientid=> @opdrecord.patientid, :appointmentid=> @opdrecord.appointmentid, :templatetype=> @opdrecord.templatetype)"
              # redirect_to eval(@edit_opd_link),:flash => { :notice => "Message" }
              #
              # redirect_to templates_edit_opd_record_path(:opdrecordid=> @opdrecord.id, :patientid=> @opdrecord.patientid, :appointmentid=> @opdrecord.appointmentid, :templatetype=> @opdrecord.templatetype),:flash => { :notice => "Message" }
            else

            end

            set_record_owners
          end

          def create
            @current_user = current_user
            @current_facility = current_facility

            @patient = Patient.find(params[:opdrecord][:patientid])
            @appointment = Appointment.find(params[:opdrecord][:appointmentid])
            @templatetype = params[:opdrecord][:templatetype]

            if (@templatetype == "express")
              params[:opdrecord][:chiefcomplaintselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:chiefcomplaintselectedtags], params[:opdrecord][:chiefcomplaintselectedtagnames], @appointment.specialty_id, @current_user.organisation.id.to_s, @current_user.id.to_s, 33962009)
            elsif (@templatetype == "freeform")
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

            appointmentdate = @appointment.appointmentdate
            appointmenttime = @appointment.start_time
            @consultant_id = @appointment.consultant_id
            @user = User.find_by(id: @consultant_id)

            # Code for Follow Up from Advice Starts Here
            if record_params[:bookappointment] == 'true'
              if record_params[:advice_attributes][:opdfollowupdate] != "" && record_params[:advice_attributes][:opdfollowupdate].present?
                opdfollowupdate = Date.parse(record_params[:advice_attributes][:opdfollowupdate]).strftime("%d/%m/%Y")
                opdfollowuptime = record_params[:advice_attributes][:opdfollowuptime]
                @followup_date_time = Time.zone.parse(opdfollowuptime)

                @appointment_type_id = params[:appointment_type]
                @new_appointment = Appointment.new(:appointmentdate => opdfollowupdate, :start_time => @followup_date_time, :end_time => @followup_date_time + 10.minutes, :patient_id => @patient.id, :appointment_type_id => record_params[:advice_attributes][:appointment_type_id], :consultant_id => record_params[:advice_attributes][:appointment_doctor], :user_id => @current_user.id, :facility_id => record_params[:advice_attributes][:appointment_facility], :department_id => @user.department_id.to_s, :departmenttype => params[:opdrecord][:encountertypeid], :appointmentstatus => 416774000, :display_id => CommonHelper::get_opd_record_identifier(@user), patient_name: @patient.fullname, organisation_id: @current_user.organisation_id, created_from: "OpdRecord")
                if @new_appointment.save
                  @followupappointment_id = @new_appointment.id
                  @temp_appointment = @new_appointment
                  # get_daily_reports
                  # Reports::Opd::Appointments.new(@new_appointment).call
                  @new = true
                else
                  @followupappointment_id = ""
                end
              end
              record_params[:advice_attributes][:followupappointment_id] = @followupappointment_id
            end
            # Code for Follow Up from Advice Ends Here

            # Code for management plan advice.
            @patient_notes = record_params[:advicemanagementplan]
            @patient_notes_to_rec = record_params[:advicemanagementplantoreceptionist]

            if @patient_notes_to_rec == "true"
              @newnote = PatientNote.new()
              @newnote.organisation_id = @current_user.organisation_id.to_s
              @newnote.user_id = @current_user.id.to_s
              @newnote.patient_id = @patient.id.to_s
              @newnote.comment = @patient_notes
              @newnote.created_by = record_params[:consultant_name]
              @newnote.save
            end
            # Code for management plan advice ends.

            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@appointment.specialty_id)
            @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
            @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
            @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
            unless (@templatetype == "freeform" || @templatetype == "express" || @templatetype == "trauma" || @templatetype == "pmt" || @templatetype == "postop")
              @patient.update_attributes(history_params)
            end
            @opdrecord = OpdRecord.new(record_params)
            @opdcomments = @opdrecord.opd_record_comments

            if (@opdrecord.save)
              @opdrecord.record_histories.create(:user_id => current_user.id, :action => "C", :actiontime => Time.current, :template_type => @templatetype)
              OpdRecordIdentifier.create(:patient_id => @patient.id, :organisation_id => current_user.organisation_id, :opd_record_org_id => CommonHelper::get_opd_record_identifier(current_user))
              @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Save")
              @opdrecordattribute = @opdrecord.create_opd_record_attribute(:recordcreateduser => session[:user_id], :recordstatus => Global.opd.unapproved_opdrecord.status)
              @users = User.where(:specialty_ids => @appointment.specialty_id, :facility_ids => @appointment.facility_id)
              if @opdrecord.advice.present?
                @followupappointment = Appointment.find(@opdrecord.advice.followupappointment_id.to_s)
              end

              # For AppointmentPanel Soft Refresh
              @opd_templates = Global.send("#{@speciality_folder_name}").send("opdtemplates")
              @appointment_opd_records = OpdRecord.where(appointmentid: @opdrecord.appointmentid.to_s)
              @old_records = PatientTimeline.where(patient_id: @patient.id.to_s, encountertype: "OPD").not.where(appointment_id: @appointment.id.to_s).limit(3).order(encounterdate: :desc)

              unless @opdrecord.diagnosislist == [] || @opdrecord.diagnosislist == nil || @opdrecord.diagnosislist == ""
                @opdrecord.diagnosislist.each do |diagnosislist|
                  icd_diagnosis = eval(diagnosislist.icd_type).find_by(code: diagnosislist.icddiagnosiscode)

                  if icd_diagnosis.present? && icd_diagnosis.has_laterality
                    code = diagnosislist.icddiagnosiscode.first(-1)
                    icd_name, code = get_parent_icd_name(diagnosislist, code)
                  else
                    code = diagnosislist.icddiagnosiscode
                    icd_name = diagnosislist.diagnosisoriginalname
                  end
                  save_recent_icd(code, icd_name, @doctor, diagnosislist.icd_type, diagnosislist.specialty_id, diagnosislist.template_id)
                end
              end
              set_record_owners
              Patients::Summary::TimelineWorker.call({ event_name: "OPD_RECORD", sub_event_name: "CREATED", opd_record_id: @opdrecord.id, user_id: @current_user.id, user_name: @current_user.fullname })
              if @new == true
                Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "SCHEDULED", appointment_id: @new_appointment.id, user_id: @current_user.id, user_name: @current_user.fullname, workflow: @current_facility.clinical_workflow })
              end

              OpdRecordJob.perform_later(@opdrecord.id.to_s, @analytics_params.to_json)
              DataForIpdJob.perform_later(@opdrecord.id.to_s)
            end
          end

          def edit
            @current_user = User.find(params[:current_user_id])
            @current_facility = Facility.find(params[:current_facility_id])
            @procedures = CommonProcedure::Ophthalmology.all
            @patient = Patient.find(params[:patientid])
            @opdrecord = OpdRecord.find(params[:opdrecordid])
            @advice_set = AdviceSet.where(:user_id => @current_user.id).order(counter: "desc").map { |p| ["#{p[:name]}", "#{p[:content]}", { 'data-id' => "#{p[:id]}" }] } + Global.ophthal_advice_option.sets.map { |p| ["#{p[:name]}", "#{p[:content]}"] }
            @optometrist_record = OpdRecord.where(:templatetype => "optometrist", :specalityid => @opdrecord.specalityid, :patientid => @patient.id.to_s)
            @patient_self_history = PatientSelfHistory.where(patient_id: @patient.id.to_s).order_by('created_at DESC')[0]

            unless @opdrecord.templatetype == "optometrist"
              @new_opt_view = "optometrist"
            end
            if @opdrecord.templatetype == 'postop'
              find_ipd_record_for_postop
            end
            @url_path = "opd_records_ophthalmology_note_path"
            @url_method = "patch"

            @user_set_type = UsersLaboratoryList.where(user_id: @current_user.id, set_type: 440655000, is_deleted: false).pluck(:name, :id)
            @facility_set_type = FacilityLaboratoryList.where(facility_id: @current_facility.id, set_type: 440655000, is_deleted: false).pluck(:name, :id)
            @set_type = @user_set_type + @facility_set_type
            @appointment = Appointment.find(@opdrecord.appointmentid)
            @consultant_id = @appointment.try(:consultant_id)
            @user = User.find_by(id: @consultant_id)
            @date = @appointment.appointmentdate
            @facility_id = @appointment.facility_id
            @facilities = Common.new.fetch_facilities(:user => @user)

            if @opdrecord.referred_to_facility.present?
              @referral_facilities = (Common.new.fetch_referred_facilities(:current_user => @current_user, :facility_id => @current_facility) + [Facility.find(@opdrecord.referred_to_facility)]).uniq # uniq :we are adding "referred to facility" if user from that facility see this but it get doubled in user from "referred from facility  (anoop)"
            else
              @referral_facilities = Common.new.fetch_referred_facilities(:current_user => @current_user, :facility_id => @current_facility)
            end

            # referral doc for intra facility start
            @referral_doctor = User.where(organisation_id: @current_user.organisation_id, role_ids: 158965000, is_active: true)

            @appointment_types = AppointmentType.where(:user_id => @consultant_id.to_s, :is_active => true)
            @formbuttons = Global.ehrcommon.ongoingepisode.formbuttons
            @savepath = Global.ehrcommon.ongoingepisode.savepath
            @templatetype = params[:templatetype]
            appointmentdate = @appointment.appointmentdate
            appointmenttime = @appointment.start_time
            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@opdrecord.specalityid)
            @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
            @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
            @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
            @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Edit")
            @post_operation = OtSchedule.where(patient_id: @patient.id, operation_done: true, is_deleted: false)
            if @post_operation.size > 0
              @post_operative_day = @post_operation.order_by(otdate: "asc").last.otdate.strftime("%d/%m/%Y")
            end

            # Laboratory Sets
            if @current_user.has_role?(:doctor)
              @ophthal_laboratory_set = OphthalLaboratorySet.where(doctor_id: @current_user.id.to_s, is_active: true)
              @radiology_laboratory_set = RadiologyLaboratorySet.where(doctor_id: @current_user.id.to_s, is_active: true)
            else
              @ophthal_laboratory_set = OphthalLaboratorySet.where(facility_id: @current_facility.id.to_s, doctor_id: nil, is_active: true)
              @radiology_laboratory_set = RadiologyLaboratorySet.where(facility_id: @current_facility.id.to_s, doctor_id: nil, is_active: true)
            end
            set_record_owners
            # respond_to do |format|
            #   format.js {render "edit", :layout => false}
            # end
          end

          def update
            @current_user = current_user
            @current_facility = current_facility

            @patient = Patient.find(params[:opdrecord][:patientid])
            @opdrecord = OpdRecord.find(params[:opdrecord][:opdrecordid])

            @appointment = Appointment.find(params[:opdrecord][:appointmentid])

            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@opdrecord.specalityid)
            @templatetype = params[:opdrecord][:templatetype]
            @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
            @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
            @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
            if (@templatetype == "express")
              params[:opdrecord][:chiefcomplaintselectedtags] = OpdRecord.compute_mongoid_for_tags(params[:opdrecord][:chiefcomplaintselectedtags], params[:opdrecord][:chiefcomplaintselectedtagnames], @opdrecord.specalityid.to_i, @current_user.organisation.id.to_s, @current_user.id.to_s, 33962009)
            elsif (@templatetype == "freeform")
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

            if params[:opdrecord][:distalneurovasculardeficit].to_s == "Absent"
              params[:opdrecord][:sensorydeficit] = ""
              params[:opdrecord][:motordeficit] = ""
              params[:opdrecord][:vascualardeficit] = ""
            end
            appointmentdate = @appointment.appointmentdate
            appointmenttime = @appointment.start_time

            @consultant_id = @appointment.consultant_id
            @user = User.find_by(id: @consultant_id)

            # Code for Follow Up from Advice Starts Here
            if record_params[:bookappointment] == 'true'
              if record_params[:advice_attributes][:opdfollowupdate] != "" && record_params[:advice_attributes][:opdfollowupdate].present?
                opdfollowupdate = Date.parse(record_params[:advice_attributes][:opdfollowupdate]).strftime("%d/%m/%Y")
                opdfollowuptime = record_params[:advice_attributes][:opdfollowuptime]
                @followup_date_time = Time.zone.parse(opdfollowuptime)

                if @opdrecord.advice.followupappointment_id == nil || @opdrecord.advice.followupappointment_id == ""
                  # For worst case below code will handle error -anoop
                  if record_params[:advice_attributes][:appointment_type_id].blank?
                    record_params[:advice_attributes][:appointment_type_id] = @opdrecord.advice.appointment_type_id
                  end
                  @new_appointment = Appointment.new(:appointmentdate => opdfollowupdate, :start_time => @followup_date_time, :end_time => @followup_date_time + 10.minutes, :patient_id => @patient.id, :appointment_type_id => record_params[:advice_attributes][:appointment_type_id], :consultant_id => @consultant_id, :user_id => @current_user.id, :facility_id => record_params[:advice_attributes][:appointment_facility], :department_id => @user.department_id.to_s, :departmenttype => params[:opdrecord][:encountertypeid], :appointmentstatus => 416774000, :display_id => CommonHelper::get_opd_record_identifier(@user), patient_name: @patient.fullname, organisation_id: @current_user.organisation_id, created_from: "OpdRecord")
                  if @new_appointment.save
                    @followupappointment_id = @new_appointment.id
                    @temp_appointment = @new_appointment
                    # start_cinical_workflow
                    # get_daily_reports
                    # Reports::Opd::Appointments.new(@new_appointment).call
                  else
                    @followupappointment_id = ""
                  end
                  @new = true
                else
                  @followupappointment_id = @opdrecord.advice.followupappointment_id
                  @followupappointment = Appointment.find(@followupappointment_id)

                  unless @followupappointment == nil
                    if record_params[:advice_attributes][:appointment_type_id].blank?
                      record_params[:advice_attributes][:appointment_type_id] = @opdrecord.advice.appointment_type_id
                    end

                    @new_appointment = @followupappointment.update(:appointmentdate => opdfollowupdate, :start_time => @followup_date_time, end_time: @followup_date_time + 10.minutes, :facility_id => record_params[:advice_attributes][:appointment_facility], :appointment_type_id => record_params[:advice_attributes][:appointment_type_id], :consultant_id => record_params[:advice_attributes][:appointment_doctor])
                  end
                  @followup_workflow = OpdClinicalWorkflow.find_by(appointment_id: @followupappointment_id.to_s)
                  unless @followup_workflow == nil
                    @followup_workflow.update(:appointmentdate => opdfollowupdate, :facility_id => record_params[:advice_attributes][:appointment_facility])
                  end
                  @edit = true
                end
              end
              record_params[:advice_attributes][:followupappointment_id] = @followupappointment_id
            end
            # Code for Follow Up from Advice Ends Here

            # Code for management plan advice.
            @patient_notes = record_params[:advicemanagementplan]
            @patient_notes_to_rec = record_params[:advicemanagementplantoreceptionist]

            if @patient_notes_to_rec == "true"
              @newnote = PatientNote.new()
              @newnote.organisation_id = @current_user.organisation_id.to_s
              @newnote.user_id = @current_user.id.to_s
              @newnote.patient_id = @patient.id.to_s
              @newnote.comment = @patient_notes
              @newnote.created_by = @opdrecord.consultant_name
              @newnote.save
            end
            # Code for management plan advice ends.

            unless (@templatetype == "freeform" || @templatetype == "express" || @templatetype == "trauma" || @templatetype == "pmt" || @templatetype == "postop")
              @patient.update_attributes(history_params)
            end
            @opdcomments = @opdrecord.opd_record_comments

            # This needs to be done before updating(anoop)
            unless @opdrecord.diagnosislist == [] || @opdrecord.diagnosislist == nil || @opdrecord.diagnosislist == ""
              @opdrecord.diagnosislist.each do |diagnosislist|
                icd_diagnosis = eval(diagnosislist.icd_type).find_by(code: diagnosislist.icddiagnosiscode)

                if icd_diagnosis.present? && icd_diagnosis.has_laterality
                  code = diagnosislist.icddiagnosiscode.first(-1)
                  get_diagnosis_code(diagnosislist, code)
                else
                  code = diagnosislist.icddiagnosiscode
                end
                recent_icd = RecentIcd.find_by(code: code)
                recent_icd.update(counter: recent_icd.counter.to_i - 1) if recent_icd.present?
              end
            end

            # To cancel the appointment whose intra referral is removed.
            if record_params[:intra_facility_referral_removed_id] != ""
              deleted_referral_ids = (record_params[:intra_facility_referral_removed_id].to_s).split(",")
              deleted_referral_ids.each do |ref_id|
                app = Appointment.find_by(:intra_referral_id => ref_id)
                if app.present?
                  app.update(appointmentstatus: 89925002)
                  Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "CANCELLED", appointment_id: app.id, user_id: @current_user.id, user_name: @current_user.fullname, workflow: @current_facility.clinical_workflow })
                end
              end
            end

            # To remove from referral list if inter referral is deleted
            if record_params[:inter_facility_referral_removed_id] != ""
              deleted_referral_ids = (record_params[:inter_facility_referral_removed_id].to_s).split(",")
              deleted_referral_ids.each do |ref_id|
                @opd_referral = OpdReferral.find_by(:inter_facility_referral_id => ref_id)
                unless @opd_referral == nil
                  @opd_referral.update(is_deleted: true)
                end
              end
            end

            if (@opdrecord.update(record_params))
              @opdrecord.record_histories.create(:user_id => current_user.id, :action => "U", :actiontime => Time.current, :template_type => @templatetype)
              @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Update")
              @users = User.where(specialty_ids: @appointment.specialty_id, :facility_ids.in => [@appointment.facility_id])

              # For AppointmentPanel Soft Refresh
              @opd_templates = Global.send("#{@speciality_folder_name}").send("opdtemplates")
              @appointment_opd_records = OpdRecord.where(appointmentid: @opdrecord.appointmentid.to_s)
              @old_records = PatientTimeline.where(patient_id: @patient.id.to_s, encountertype: "OPD").not.where(appointment_id: @appointment.id.to_s).limit(3).order(encounterdate: :desc)

              unless @opdrecord.diagnosislist == [] || @opdrecord.diagnosislist == nil || @opdrecord.diagnosislist == ""
                @opdrecord.diagnosislist.each do |diagnosislist|
                  icd_diagnosis = eval(diagnosislist.icd_type).find_by(code: diagnosislist.icddiagnosiscode)

                  if icd_diagnosis.present? && icd_diagnosis.has_laterality
                    code = diagnosislist.icddiagnosiscode.first(-1)
                    icd_name, code = get_parent_icd_name(diagnosislist, code)
                  else
                    code = diagnosislist.icddiagnosiscode
                    icd_name = diagnosislist.diagnosisoriginalname
                  end
                  save_recent_icd(code, icd_name, @consultant_id, diagnosislist.icd_type, diagnosislist.specialty_id, diagnosislist.template_id)
                end
              end
              set_record_owners
              Patients::Summary::TimelineWorker.call({ event_name: "OPD_RECORD", sub_event_name: "UPDATED", opd_record_id: @opdrecord.id, user_id: @current_user.id, user_name: @current_user.fullname })
              if @new == true
                Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "SCHEDULED", appointment_id: @new_appointment.id, user_id: @current_user.id, user_name: @current_user.fullname, workflow: @current_facility.clinical_workflow })
              elsif @edit == true
                Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "RESCHEDULED", appointment_id: @followupappointment_id, user_id: @current_user.id, user_name: @current_user.fullname, workflow: @current_facility.clinical_workflow })
              end

              OpdRecordJob.perform_later(@opdrecord.id.to_s, @analytics_params.to_json)
              DataForIpdJob.perform_later(@opdrecord.id.to_s)
            end
          end

          def view_opd_summary
            @current_user = current_user
            @current_facility = current_facility
            @opdrecord = OpdRecord.find(params[:opdrecordid])
            @opdrecord.created_at.strftime('%d%m%Y')
            @patient = Patient.find(params[:patientid])
            @opdcomments = @opdrecord.opd_record_comments
            @appointment = Appointment.find(@opdrecord.appointmentid)
            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@opdrecord.specalityid)
            @templatetype = params[:templatetype]
            if @appointment.try(:facility_id).present?
              @facility_id = @appointment.facility_id
              @nabh_setting = NabhSetting.find_by(facility_id: @facility_id)
            else
              @facility_id = @current_facility.id
              @nabh_setting = NabhSetting.find_by(facility_id: @facility_id)
            end
            @users = User.where(:department_id => @opdrecord.specalityid, :facility_ids.in => [@facility_id])
          end

          def download_pdf_opd_record
            @opdrecord = OpdRecord.find(params[:opdrecordid])
            @appointment = Appointment.find(params[:appointmentid])
            @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Download")
            @patient = Patient.find(params[:patientid])
            @speciality_folder_name = params[:specality]
            @templatetype = params[:templatetype]
            filename = "OpdSummary_#{@patient.fullname}_#{Date.current.strftime("%d-%B-%Y")}"
            respond_to do |format|
              format.pdf { render :template => "opd_records/#{@speciality_folder_name}_notes/download/opd_summary_download", :pdf => "#{filename}", :layout => 'pdfgen', :disposition => 'inline', :margin => { :bottom => 30 } }
            end
          end

          def print_blank_opd_record
            @appointment = Appointment.find(params[:appointmentid])
            @patient = Patient.find(params[:patientid])
            @speciality_folder_name = params[:specality]
            @templatetype = params[:templatetype]
            @organisation = current_user.organisation
            @height = @organisation.letter_head_customisations[:header_height]

            setting_service = PrintSettingService.new(current_facility_id, @appointment.consultant_id.to_s, "OPD")
            @print_settings = setting_service.select_print_setting
            @logo = @print_settings[1]
            filename = "#{@patient.fullname}_#{Date.current.strftime("%d-%B-%Y")}"
            respond_to do |format|
              format.pdf { render :template => "opd_records/#{@speciality_folder_name}_notes/download/blank_opd_summary_download", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 0, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
            end
          end

          def print_opd_record
            @opdrecord = OpdRecord.find(params[:opdrecordid])
            @appointment = Appointment.find(params[:appointmentid])
            @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Print")
            @patient = Patient.find(params[:patientid])
            @speciality_folder_name = params[:specality]
            @templatetype = params[:templatetype]
            @organisation = current_user.organisation
            @user = User.find(@opdrecord.userid)
            @opdrecord.record_histories.create(:user_id => current_user.id, :action => "P", :actiontime => Time.current, :template_type => @templatetype)
            @height = @organisation.letter_head_customisations[:header_height]

            setting_service = PrintSettingService.new(current_facility_id, @appointment.consultant_id.to_s, "OPD")
            @print_settings = setting_service.select_print_setting
            @logo = @print_settings[1]

            if @templatetype == "ophthalmic_report"
              filename = "OphthalmicReport_#{@patient.fullname}_#{Date.current.strftime("%d-%B-%Y")}"
            else
              filename = "OpdSummary_#{@patient.fullname}_#{Date.current.strftime("%d-%B-%Y")}"
            end

            respond_to do |format|
              # format.html {render "templates/#{@speciality_folder_name}/print/opd_summary_print", :layout => "print"}
              format.pdf { render :template => "opd_records/#{@speciality_folder_name}_notes/download/opd_summary_download", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 0, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
            end

            # Patients::Summary::TimelineWorker.call({event_name: "OPD_RECORD", sub_event_name: "PRINTED", opd_record_id: @opdrecord.id, user_id: current_user.id, user_name: current_user.fullname })
          end

          def print_contactlens_prescription
            @opdrecord = OpdRecord.find(params[:opdrecordid])
            @appointment = Appointment.find(params[:appointmentid])
            @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Print")
            @patient = Patient.find(params[:patientid])
            @speciality_folder_name = params[:specality]
            @templatetype = params[:templatetype]
            @organisation = current_user.organisation
            @user = User.find(@opdrecord.userid)
            @flag = 'print'
            filename = "OpdSummary_#{@patient.fullname}_#{Date.current.strftime("%d-%B-%Y")}"
            setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "Optical")
            @print_settings = setting_service.select_print_setting
            @logo = @print_settings[1]
            respond_to do |format|
              # format.html {render "templates/#{@speciality_folder_name}/print/opd_summary_print", :layout => "print"}
              format.pdf { render :template => "opd_records/#{@speciality_folder_name}_notes/download/contactlens_opd_summary_download", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
            end
          end

          def print_glass_prescription
            @opdrecord = OpdRecord.find(params[:opdrecordid])
            @appointment = Appointment.find(params[:appointmentid])
            @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Print")
            @patient = Patient.find(params[:patientid])
            @speciality_folder_name = params[:specality]
            @templatetype = params[:templatetype]
            @organisation = current_user.organisation
            @user = User.find(@opdrecord.userid)
            @flag = 'print'
            filename = "OpdSummary_#{@patient.fullname}_#{Date.current.strftime("%d-%B-%Y")}"
            setting_service = PrintSettingService.new(current_facility_id, @appointment.consultant_id.to_s, "Optical")
            @print_settings = setting_service.select_print_setting
            @logo = @print_settings[1]
            respond_to do |format|
              # format.html {render "templates/#{@speciality_folder_name}/print/opd_summary_print", :layout => "print"}
              format.pdf { render :template => "opd_records/#{@speciality_folder_name}_notes/download/glasses_opd_summary_download", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom =>  @print_settings[0]['footer_height'].to_f * 10 } }
            end
          end

          def print_medication
            @opdrecord = OpdRecord.find(params[:opdrecordid])
            @appointment = Appointment.find(params[:appointmentid])
            @opdrecordaudit = @opdrecord.opd_record_audits.create(:user_id => session[:user_id], :action => "Print")
            @patient = Patient.find(params[:patientid])
            @speciality_folder_name = params[:specality]
            @templatetype = params[:templatetype]
            @organisation = current_user.organisation
            @user = User.find(@opdrecord.userid)
            filename = "OpdSummary_#{@patient.fullname}_#{Date.current.strftime("%d-%B-%Y")}"
            setting_service = PrintSettingService.new(current_facility_id, @appointment.consultant_id.to_s, "Pharmacy")
            @print_settings = setting_service.select_print_setting
            @logo = @print_settings[1]
            respond_to do |format|
              # format.html {render "templates/#{@speciality_folder_name}/print/opd_summary_print", :layout => "print"}
              format.pdf { render :template => "opd_records/#{@speciality_folder_name}_notes/download/medication_opd_summary_download", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
            end
          end

          def add_comment_opd_record
            @opdrecord = OpdRecord.find(params[:opdrecordid])
            @comment = params[:opdrecordcomment][:comment]
            if @comment.present?
              @opdrecordcommentsave = @opdrecord.opd_record_comments.create(:comment => params[:opdrecordcomment][:comment], :user_id => session[:user_id], :doctorname => current_user.fullname, :commenttime => Time.current)
            end
            @opdcomments = @opdrecord.opd_record_comments
            respond_to do |format|
              format.js { render "opd_records/add_comment_opd_record", :layout => false }
            end
          end

          def delete_comment_opd_record
            @opdrecord = OpdRecord.find(params[:opdrecordid])
            @opdcomments = @opdrecord.opd_record_comments.find(params[:id]).try(:delete)
            @opdcomments = @opdrecord.opd_record_comments
            respond_to do |format|
              format.js { render "opd_records/add_comment_opd_record", :layout => false }
            end
          end

          def fill_medication_data
            @medication_set = MedicationKit.find(params[:ajax][:medicationkitid])
            @department_id = @medication_set.department
            if @medication_set.try(:data) != "null"
              # p @medication_set.try(:data)
              @medication_kit_data = JSON.parse(@medication_set.data)
            else
              head :ok
            end
          end

          def fill_ipd_medication_data
            @medication_set = MedicationKit.find(params[:ajax][:medicationkitid])
            @department_id = @medication_set.department
            if @medication_set.try(:data) != "null"
              @medication_kit_data = JSON.parse(@medication_set.data)
            else
              head :ok
            end
          end

          def registry
            @patient = Patient.find(params[:patientid])
            @registrytype = params[:registrytype]
            respond_to do |format|
              format.html {}
              format.js {}
            end
          end

          def functional_score
            @patient = Patient.find(params[:patientid])
            respond_to do |format|
              format.js {}
            end
          end

          def annontatetrauma
            @traumaparams_limb = params[:traumaparams][:limb]
            @traumaparams_side = params[:traumaparams][:side]
            respond_to do |format|
              format.html { render :layout => false }
            end
          end

          def saveannontatetrauma
            @annotatedfields = params[:traumaannotate]
            respond_to do |format|
              format.js { render "saveannontatetrauma", :layout => false }
            end
          end

          # Brakeman :: cannot find anywhere in the product, so commenting
          def populate_proceduretype
            @speciality_folder_name = params[:ajax][:specalityfoldername]
            @regionname = params[:ajax][:templatetype]
            @procedures = params[:ajax][:procedures]
            @counter = params[:ajax][:counter]
            @proceduretypes = Array[]
            @proceduretypes = Global.send("#{@speciality_folder_name}#{@regionname}#{@procedures}").send("#{@procedures}").map do |proceduretype| proceduretype.map.with_index { |procedurehash, procedureindex| [2, 3].include?(procedureindex) ? Hash[procedurehash.each_slice(2).to_a] : procedurehash[1] } end
            respond_to do |format|
              format.js { render "populate_proceduretype", :layout => false }
            end
          end

          # Brakeman :: cannot find anywhere in the product, so commenting
          def populate_side_approach_procedures
            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
            @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
            @templatetype = params[:ajax][:templatetype]
            @regionid = params[:ajax][:regionid]
            @proceduresides = Array[]
            @procedureapproachs = Array[]
            @procedures = Array[]
            @proceduresubqualifiers = Array[]
            @proceduresides = Global.send("#{@speciality_folder_name}#{@templatetype}procedures").send("side").map do |x| x.values end
            @procedureapproachs = Global.send("#{@speciality_folder_name}#{@templatetype}procedures").send("approach").map do |x| x.values end
            @procedures = Global.send("#{@speciality_folder_name}#{@templatetype}procedures").send("procedures").map do |x| x.values end
            @proceduresubqualifiers = Global.send("#{@speciality_folder_name}#{@templatetype}procedures").send("proceduresubqualifier").map do |x| x.values end
            respond_to do |format|
              format.json { render "templates/orthopedics/populate_side_approach_procedures", :layout => false }
            end
          end

          # Brakeman :: cannot find anywhere in the product, so commenting
          def populate_procedurename
            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
            @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
            @templatetype = params[:ajax][:templatetype]
            @proceduretype = params[:ajax][:proceduretype]
            @regionfilename = params[:ajax][:regionfilename]
            @procedurenames = Array[]
            if Global.send("#{@speciality_folder_name}#{@regionfilename}procedures").try(@proceduretype.to_sym)
              @procedurenames = Global.send("#{@speciality_folder_name}#{@regionfilename}procedures").send(@proceduretype.to_sym).map do |x| x.values end
            end
            respond_to do |format|
              if @procedurenames.size > 0
                format.json { render json: @procedurenames }
              else
                format.json { render json: @procedurenames }
              end
            end
          end

          # Brakeman :: cannot find anywhere in the product, so commenting
          def populate_procedurequalifier
            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
            @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
            @templatetype = params[:ajax][:templatetype]
            @procedurename = params[:ajax][:procedurename]
            @regionfilename = params[:ajax][:regionfilename]
            @procedurequalifiers = Array[]
            if Global.send("#{@speciality_folder_name}#{@templatetype}procedures").try(@procedurename.to_sym)
              @procedurequalifiers = Global.send("#{@speciality_folder_name}#{@templatetype}procedures").send(@procedurename.to_sym).map do |x| x.values end
            end
            respond_to do |format|
              if @procedurequalifiers.size > 0
                format.json { render json: @procedurequalifiers }
              else
                format.json { render json: @procedurequalifiers }
              end
            end
          end

          def populate_radiology_investigations
            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
            @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
            @templateid = params[:ajax][:templatetype]
            @xrayinvestigations = RadiologyInvestigationData.where(:specialty_id => @specalityid.to_i, :template_id => @templateid.to_i, :investigation_type_id.in => [Global.ehrcommon.xray.id]).order_by(investigation_id: :asc)
            @ctmriinvestigations = RadiologyInvestigationData.where(:specialty_id => @specalityid.to_i, :template_id => @templateid.to_i, :investigation_type_id.in => [Global.ehrcommon.mri.id, Global.ehrcommon.ct.id]).order_by(investigation_id: :asc)
            respond_to do |format|
              format.json { render "opd_records/orthopedics_notes/populate_radiology_investigations", :layout => false }
            end
          end

          def populate_topicd_list
            topicd_name = params[:ajax][:topicd_name]
            topicd_list = Array[]
            topicddiagnosis = TopIcdDiagnosis.find_by(name: topicd_name)
            topicd_list = topicddiagnosis.try(:list)
            respond_to do |format|
              if topicd_list.size > 0
                format.json { render json: topicd_list }
              else
                format.json { render json: topicd_list }
              end
            end
          end

          def populate_ophthalinvestigations
            # eyearea = if params[:ajax][:eyearea] == 'cornea'
            #             'cornea'
            #           elsif params[:ajax][:eyearea] == 'retina'
            #             'retina'
            #           elsif params[:ajax][:eyearea] == 'glaucoma'
            #             'glaucoma'
            #           elsif params[:ajax][:eyearea] == 'cataract'
            #             'cataract'
            #           elsif params[:ajax][:eyearea] == 'squint'
            #             'squint'
            #           elsif params[:ajax][:eyearea] == 'eyeside'
            #             'eyeside'
            #           end
            eyearea = params[:ajax][:eyearea]
            # eyearea_region_snomedid = params[:ajax][:selected_eyearea_region_snomedid]
            ophthalinvestigations = Array[]
            if Global.send("ophthalmologyinvestigations").try(eyearea.to_sym)
              ophthalinvestigations = Global.send("ophthalmologyinvestigations").try(eyearea.to_sym)
            end
            respond_to do |format|
              if ophthalinvestigations.size > 0
                format.json { render json: ophthalinvestigations }
              else
                format.json { render json: ophthalinvestigations }
              end
            end
          end

          def populate_ophthalprocedures
            if params[:procedure_type] == 'common_procedures'
              procedures = CommonProcedure.where(region: params[:region], speciality_id: params[:speciality_id]).pluck(:code, :name)
            else
              procedures = CustomCommonProcedure.where(region: params[:region], speciality_id: params[:speciality_id], "$or": [{organisation_id: current_user.organisation_id, level: "organisation"}, {facility_id: current_facility.id.to_s, level: "facility"}], is_deleted: false).pluck(:code, :name, :procedure_type) + SynonymCommonProcedure.where(region: params[:region], is_deleted: false).pluck(:code, :name, :procedure_type)
            end

            respond_to do |format|
              if procedures.size > 0
                format.json { render json: procedures }
              else
                format.json { render json: procedures }
              end
            end
          end

          def testinlinesvg
          end

          def user_templates
            respond_to do |format|
              format.js { render :layout => "loggedin" }
              format.html { render :layout => "loggedin" }
            end
          end

          def fetch_custom
            @current_user = current_user
            @total_custom_count = UsersOpdRecord.where(:user_id => @current_user.id).count
            @custom_count = UsersOpdRecord.where(:user_id => @current_user.id, :name => %r[#{params[:sSearch]}]).count
            @custom_templates = UsersOpdRecord.where(:user_id => @current_user.id, :name => %r[#{params[:sSearch]}])
                                              .limit(params[:iDisplayLength])
                                              .offset(params[:iDisplayStart])
                                              .order("name " + params[:sSortDir_0])
            @sEcho = params[:sEcho]
            respond_to do |format|
              format.json {}
            end
          end

          def custom_new
            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
            @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
            @templatetype = params[:templatetype]
            @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
            @patient = nil
            @formbuttons = 'prefill_actions'
            @savepath = 'templates_custom_create_path'
            @opdrecord = OpdRecord.new
            @opdspeciality = TemplateOpdRecord.new(@patient, @opdrecord, @speciality_folder_name, @specalityid, @templatetype, @templateid, current_user.department_id).new_record
            respond_to do |format|
              format.js {}
            end
          end

          def custom_create
            @user_template = UsersOpdRecord.new
            @user_template.user_id = current_user.id
            @user_template.record_details = params[:opdrecord].to_json
            @user_template.name = params[:label]
            @user_template.base_template = params[:opdrecord][:templatetype]
            @user_template.save
            respond_to do |format|
              format.js {}
            end
          end

          def custom_edit
            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
            @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
            @custom_template = UsersOpdRecord.find(params[:custom_template_id])
            custom_record_data = JSON.parse(@custom_template.record_details)
            @templatetype = @custom_template.base_template
            @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
            @displayname = TemplatesHelper.get_template_display_name_for_speciality_and_templatename(@speciality_folder_name, @templatetype)

            @opdrecord = OpdRecord.new(custom_record_data)
            @patient = nil
            @formbuttons = 'prefill_actions'
            @savepath = 'templates_custom_update_path'
            @opdspeciality = TemplateOpdRecord.new(@patient, @opdrecord, @speciality_folder_name, @specalityid, @templatetype, @templateid, current_user.department_id).new_record
            respond_to do |format|
              format.js {}
            end
          end

          def custom_update
            @user_template = UsersOpdRecord.find(params[:custom_template_id])
            @user_template.record_details = params[:opdrecord].to_json
            @user_template.name = params[:label]
            @user_template.update
            respond_to do |format|
              format.js {}
            end
          end

          def custom_destroy
            user_template = UsersOpdRecord.find(params[:custom_template_id])
            user_template.destroy
            respond_to do |format|
              format.js {}
            end
          end

          # IPD
          def new_ipd_record
            @templates_save_ipd_record_path = "templates_save_ipd_record_path"
            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
            @find_diagnosis_path = "new"
            @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
            @templatetype = params[:templatetype]
            if @templatetype == "operativenote"
              @procedurenotes = ProcedureNote.where(:organisation_id => current_user.organisation_id, is_active: true, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id, level: 'facility' }, { user_id: current_user.id, level: 'user' }])
            end
            @templateid, @displayname = TemplatesHelper.get_ipd_templateid_displayname(params[:templatetype])
            @patient = Patient.find(params[:patient_id])
            # For pulling some data from opd
            @opd = OpdRecord.where(:patientid => @patient.id.to_s)
            @admission = Admission.find_by(:id => params[:admission_id])
            @facilities = current_user.facilities
            @departments = @facilities.first.departments
            @users = User.where(:facility_ids.in => [@facilities.first.id], :department_id => current_user.department_id).with_all_roles(:doctor)
            # have to add admission
            @form_buttons = Global.ehrcommon.newepisode.formbuttons
            @save_path = Global.ehrcommon.newepisode.savepath
            @ipdrecord = IpdRecord.new

            respond_to do |format|
              format.js {}
            end
          end

          # IPD
          def save_ipd_record
            @patient = Patient.find(params[:ipdrecord][:patientid])
            @admission = Admission.find_by(:id => params[:ipdrecord][:admissionid])
            @templatetype = params[:ipdrecord][:templatetype]
            @opd = OpdRecord.where(:patientid => @patient.id.to_s)
            @ipdrecord = IpdRecord.new(ipd_record_params)
            if (@ipdrecord.save)
              # TemplateDataWorker.perform_async(@opdrecord.id)
              respond_to do |format|
                format.js { render "save_ipd_record", :layout => false }
              end
              # IpdRecordJob.perform_later(@ipdrecord.id.to_s)
              OtInventoryInvoiceJob.perform_later(@ipdrecord.id.to_s)
            end
          end

          # IPD
          def edit_ipd_record
            @templates_save_ipd_record_path = "templates_update_ipd_record_path"
            # @templatetype = params[:templatetype]
            # {"admissionid"=>"56aefff4f9c44c1cb9000001", "ipdrecordid"=>"56af4572f9c44c1cb9000077", "patientid"=>"56a8bc1df9c44c063800004f", "templatetype"=>"admissionnote", "controller"=>"templates", "action"=>"edit_ipd_record"}
            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
            @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
            @find_diagnosis_path = "edit"
            @templatetype = params[:templatetype]
            if @templatetype == "operativenote"
              @procedurenotes = ProcedureNote.where(:organisation_id => current_user.organisation_id.to_s, :user_id => current_user.id.to_s)
            end
            @templateid, @displayname = TemplatesHelper.get_ipd_templateid_displayname(params[:templatetype])
            @patient = Patient.find_by(:id => params[:patient_id])
            @opd = OpdRecord.where(:patientid => @patient.id.to_s)
            @admission = Admission.find_by(:id => params[:admission_id])
            @facilities = current_user.facilities
            @departments = @facilities.first.departments
            @users = User.where(:facility_ids.in => [@facilities.first.id], :department_id => current_user.department_id).with_all_roles(:doctor)
            @form_buttons = Global.ehrcommon.ongoingepisode.formbuttons
            @save_path = Global.ehrcommon.ipdongoingepisode.savepath
            @ipdrecord = IpdRecord.find_by(:id => params[:ipdrecord_id])
            respond_to do |format|
              format.js {}
            end
          end

          # IPD
          def update_ipd_record
            @patient = Patient.find(params[:ipdrecord][:patientid])
            @admission = Admission.find_by(:id => params[:ipdrecord][:admissionid])
            @templatetype = params[:ipdrecord][:templatetype]
            @opd = OpdRecord.where(:patientid => @patient.id.to_s)
            @ipdrecord = IpdRecord.find(params[:ipdrecord][:ipdrecordid])
            # IpdRecordJob.perform_later(@ipdrecord.id.to_s)
            if @ipdrecord.update_attributes(ipd_record_params)
              respond_to do |format|
                format.js { render "save_ipd_record", :layout => false }
              end
            end
          end

          # IPD
          def print_ipd_record
            @ipdrecord = IpdRecord.find_by(:id => params[:ipdrecord_id])
            @patient = Patient.find_by(:id => params[:patient_id])
            @admission = Admission.find_by(:id => params[:admission_id])
            @templatetype = params[:templatetype]
            # @speciality_folder_name = params[:specality]
            @organisation = current_user.organisation
            filename = "IpdSummary_#{@patient.fullname}_#{Date.current.strftime("%d-%B-%Y")}"
            @user = User.find_by(:id => @ipdrecord.userid)
            setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "IPD")
            @print_settings = setting_service.select_print_setting
            @logo = @print_settings[1]
            respond_to do |format|
              # format.html {render "templates/common/print/ipd_summary_print", :layout => "print"}
              format.pdf { render :template => "templates/ophthalmology/download/ipd_summary_download", :pdf => "#{filename}", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
            end
          end

          def record
            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
            @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
            @templatetype = params[:templatetype]
            @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
            @patient = Patient.find(params[:patientid])
            # @pastopdrecord = OpdRecordAttribute.opdPatient(params[:patientid])
            @pastopdrecord = OpdRecordAttribute.where(:patient_id => params[:patientid]).order_by(created_at: :desc).first # check the patient's past opd records history sorted by decending order and pick the 1st record.
            if (!@pastopdrecord.nil?) # Check if any past OPD records exist for the patient.
              if (@pastopdrecord.templatetype.eql?(@templatetype)) # if past records do exist, get the last one and see if same template is being opened.
                if (@pastopdrecord.recordcreatedate.eql?(Date.current)) # Check if opd record is being opened same day.
                  @formbuttons = Global.ehrcommon.ongoingepisode.formbuttons    # if same day then, opd buttons will show update opd record.
                  @savepath = Global.ehrcommon.ongoingepisode.savepath
                  @opdrecord = @pastopdrecord.opd_record
                  @opdrecord.initialize_nested_objects
                else                                                            # if patients comes same day for checkup then, and different template is opened then new emtpy form will be openeed.
                  @formbuttons = Global.ehrcommon.newepisode.formbuttons
                  @savepath = Global.ehrcommon.newepisode.savepath
                  @opdrecord = @pastopdrecord.opd_record
                  @opdrecord.initialize_nested_objects
                end
              else                                                              # if patient has past opd records but if template is different then open new empty form.
                @formbuttons = Global.ehrcommon.newepisode.formbuttons
                @savepath = Global.ehrcommon.newepisode.savepath
                @opdrecord = OpdRecord.new
                @opdrecord.initialize_nested_objects
              end
            else                                                                # if patient has no past opd records then open new empty form
              @formbuttons = Global.ehrcommon.newepisode.formbuttons
              @savepath = Global.ehrcommon.newepisode.savepath
              @opdrecord = OpdRecord.new
              @opdrecord.initialize_nested_objects
            end
            # end
            # get all the medication kits of the current doctor
            @medication_kits = MedicationKit.where(:user_id => current_user.id)
            respond_to do |format|
              format.html {}
              format.js { render "record", :layout => false }
            end
          end

          def record_order
            @templatetype = params[:templatetype]
            @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(current_user.department_id)
            @specalityid = TemplatesHelper.get_speciality_name(@speciality_folder_name)
            @templateid = TemplatesHelper.get_template_id_for_speciality_and_templatename(@speciality_folder_name, @templatetype)
            @patient = Patient.find(params[:patientid])
            @medication_kits = MedicationKit.where(:user_id => current_user.id)
            respond_to do |format|
              format.html {}
              format.js { render "templates/patientorders", :layout => false }
            end
          end

          def add_appendages_diagram
            @eyeside = params[:ajax][:eyeside]
            @patient_id = params[:ajax][:patient_id]
            @diagramtype = params[:ajax][:diagram_type]
            @a = Base64.strict_encode64(File.open(Rails.root.join("app", "assets", "images", "ophthal_annotations", "appendages_#{@eyeside}.png").to_path, "rb").read)
            respond_to do |format|
              format.js { render "opd_records/ophthalmology_notes/js/add_appendages_diagram", :layout => false }
            end
          end

          def save_appendages_diagram
            @eyeside = params[:ajax][:eyeside]
            params[:ajax] = convert_data_uri_to_upload(params[:ajax])
            @tempasset = PatientSummaryAssetUpload.new(diagram_params)
            @tempasset["parent_folder_id"] = "560cc6f72b2e26135d000007"
            @tempasset["is_folder"] = "N"
            @tempasset["name"] = params[:ajax][:diagram_type]
            @tempasset["reported_date"] = Date.current
            @tempasset["reported_time"] = Time.current
            @tempasset["user_id"] = current_user.id.to_s
            if @tempasset.save
              respond_to do |format|
                format.js { render "opd_records/ophthalmology_notes/js/save_appendages_diagram", :layout => false }
              end
            end
          end

          def edit_appendages_diagram
            @eyeside = params[:eyeside]
            @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
            @a = Base64.strict_encode64(read_file_remote("#{@tempasset.asset_path_url}"))
            # @a = Base64.strict_encode64(File.open(@tempasset.asset_path_url, "rb").read)
            respond_to do |format|
              format.js { render "opd_records/ophthalmology_notes/js/add_appendages_diagram", :layout => false }
            end
          end

          def discard_appendages_diagram
            @eyeside = params[:eyeside]
            @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
            if @tempasset
              @patient_id = @tempasset.patient_id
              @tempasset.remove_asset_path!
              @tempasset.delete
            end
            respond_to do |format|
              format.js { render "templates/ophthalmology/js/discard_appendages_diagram", :layout => false }
            end
          end

          def add_fundus_diagram
            @eyeside = params[:ajax][:eyeside]
            @diagramtype = params[:ajax][:diagram_type]
            @patient_id = params[:ajax][:patient_id]
            @a = Base64.strict_encode64(File.open(Rails.root.join("app", "assets", "images", "ophthal_annotations", "fundus_#{@eyeside}.png").to_path, "rb").read)
            respond_to do |format|
              format.js { render "opd_records/ophthalmology_notes/js/add_fundus_diagram", :layout => false }
            end
          end

          def save_fundus_diagram
            @eyeside = params[:ajax][:eyeside]
            params[:ajax] = convert_data_uri_to_upload(params[:ajax])
            @tempasset = PatientSummaryAssetUpload.new(diagram_params)
            @tempasset["parent_folder_id"] = "560cc6f72b2e26135d000007"
            @tempasset["is_folder"] = "N"
            @tempasset["name"] = params[:ajax][:diagram_type]
            @tempasset["reported_date"] = Date.current
            @tempasset["reported_time"] = Time.current
            @tempasset["user_id"] = current_user.id.to_s
            if @tempasset.save
              respond_to do |format|
                format.js { render "opd_records/ophthalmology_notes/js/save_fundus_diagram", :layout => false }
              end
            end
          end

          def edit_fundus_diagram
            @eyeside = params[:eyeside]
            @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
            @a = Base64.strict_encode64(read_file_remote("#{@tempasset.asset_path_url}"))
            respond_to do |format|
              format.js { render "opd_records/ophthalmology_notes/js/add_fundus_diagram", :layout => false }
            end
          end

          def discard_fundus_diagram
            @eyeside = params[:eyeside]
            @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
            if @tempasset
              @patient_id = @tempasset.patient_id
              @tempasset.remove_asset_path!
              @tempasset.delete
            end
            respond_to do |format|
              format.js { render "opd_records/ophthalmology_notes/js/discard_fundus_diagram", :layout => false }
            end
          end

          def add_cornea_diagram
            @eyeside = params[:ajax][:eyeside]
            @patient_id = params[:ajax][:patient_id]
            @diagramtype = params[:ajax][:diagram_type]
            @a = Base64.strict_encode64(File.open(Rails.root.join("app", "assets", "images", "ophthal_annotations", "cornea_#{@eyeside}.png").to_path, "rb").read)
            respond_to do |format|
              format.js { render "opd_records/ophthalmology_notes/js/add_cornea_diagram", :layout => false }
            end
          end

          def discard_appendages_diagram
            @eyeside = params[:eyeside]
            @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
            if @tempasset
              @patient_id = @tempasset.patient_id
              @tempasset.remove_asset_path!
              @tempasset.delete
            end
            respond_to do |format|
              format.js { render "opd_records/ophthalmology_notes/js/discard_appendages_diagram", :layout => false }
            end
          end

          def save_cornea_diagram
            @eyeside = params[:ajax][:eyeside]
            params[:ajax] = convert_data_uri_to_upload(params[:ajax])
            @tempasset = PatientSummaryAssetUpload.new(diagram_params)
            @tempasset["parent_folder_id"] = "560cc6f72b2e26135d000007"
            @tempasset["is_folder"] = "N"
            @tempasset["name"] = params[:ajax][:diagram_type]
            @tempasset["reported_date"] = Date.current
            @tempasset["reported_time"] = Time.current
            @tempasset["user_id"] = current_user.id.to_s
            if @tempasset.save
              respond_to do |format|
                format.js { render "opd_records/ophthalmology_notes/js/save_cornea_diagram", :layout => false }
              end
            end
          end

          def edit_cornea_diagram
            @eyeside = params[:eyeside]
            @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
            @a = Base64.strict_encode64(read_file_remote("#{@tempasset.asset_path_url}"))
            # @a = Base64.strict_encode64(File.open(@tempasset.asset_path_url, "rb").read)
            respond_to do |format|
              format.js { render "opd_records/ophthalmology_notes/js/add_cornea_diagram", :layout => false }
            end
          end

          def discard_cornea_diagram
            @eyeside = params[:eyeside]
            @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
            if @tempasset
              @patient_id = @tempasset.patient_id
              @tempasset.remove_asset_path!
              @tempasset.delete
            end
            respond_to do |format|
              format.js { render "opd_records/ophthalmology_notes/js/discard_cornea_diagram", :layout => false }
            end
          end

          def view_opd_diagram
            @eyeside = params[:eyeside]
            @diagram_type = params[:diagram_type]
            @tempasset = OpdRecord.find_by(:id => params[:temp_asset_id])
            @image_url_full = @eyeside + '_' + @diagram_type + '_diagram_full'
            @image = eval("@tempasset.send(@image_url_full)")
            respond_to do |format|
              format.js { render "opd_records/ophthalmology_notes/view_opd_diagram", :layout => false }
            end
          end

          def add_cornea_slit_diagram
            @eyeside = params[:ajax][:eyeside]
            @patient_id = params[:ajax][:patient_id]
            @diagramtype = params[:ajax][:diagram_type]
            @a = Base64.strict_encode64(File.open(Rails.root.join("app", "assets", "images", "ophthal_annotations", "corneaslit.png").to_path, "rb").read)
            respond_to do |format|
              format.js { render "opd_records/ophthalmology_notes/js/add_cornea_slit_diagram", :layout => false }
            end
          end

          def save_cornea_slit_diagram
            @eyeside = params[:ajax][:eyeside]
            params[:ajax] = convert_data_uri_to_upload(params[:ajax])
            @tempasset = PatientSummaryAssetUpload.new(diagram_params)
            @tempasset["parent_folder_id"] = "560cc6f72b2e26135d000007"
            @tempasset["is_folder"] = "N"
            @tempasset["name"] = params[:ajax][:diagram_type]
            @tempasset["reported_date"] = Date.current
            @tempasset["reported_time"] = Time.current
            @tempasset["user_id"] = current_user.id.to_s
            if @tempasset.save
              respond_to do |format|
                format.js { render "opd_records/ophthalmology_notes/js/save_cornea_slit_diagram", :layout => false }
              end
            end
          end

          def edit_cornea_slit_diagram
            @eyeside = params[:eyeside]
            @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
            @a = Base64.strict_encode64(read_file_remote("#{@tempasset.asset_path_url}"))
            # @a = Base64.strict_encode64(File.open(@tempasset.asset_path_url, "rb").read)
            respond_to do |format|
              format.js { render "opd_records/ophthalmology_notes/js/add_cornea_slit_diagram", :layout => false }
            end
          end

          def discard_cornea_slit_diagram
            @eyeside = params[:eyeside]
            @tempasset = PatientSummaryAssetUpload.find_by(:id => params[:temp_asset_id])
            if @tempasset
              @patient_id = @tempasset.patient_id
              @tempasset.remove_asset_path!
              @tempasset.delete
            end
            respond_to do |format|
              format.js { render "opd_records/ophthalmology_notes/js/discard_cornea_slit_diagram", :layout => false }
            end
          end

          def print_flag
            opdrecord = OpdRecord.find_by(:id => params[:ajax][:opd_record_id])
            opdrecord.update_attribute(:"#{params[:ajax][:flag_name]}", params[:ajax][:flag_value])
            respond_to do |format|
              format.js { render nothing: true }
            end
          end

          def sign_off
            @current_user = current_user
            @opdrecord = OpdRecord.find_by(:id => params[:opd_record_id])
            @opdrecord.update(sign_off: params[:status])
            @templatetype = @opdrecord.templatetype

            if params[:status] == "true"
              Patients::Summary::TimelineWorker.call({ event_name: "OPD_RECORD", sub_event_name: "SIGNEDOFF", opd_record_id: @opdrecord.id, user_id: current_user.id, user_name: current_user.fullname })
              @opdrecord.record_histories.create(:user_id => current_user.id, :action => "S", :actiontime => Time.current, :template_type => @templatetype)
            else
              Patients::Summary::TimelineWorker.call({ event_name: "OPD_RECORD", sub_event_name: "UNDOSIGNEDOFF", opd_record_id: @opdrecord.id, user_id: current_user.id, user_name: current_user.fullname })
              @opdrecord.record_histories.create(:user_id => current_user.id, :action => "US", :actiontime => Time.current, :template_type => @templatetype)
            end
            respond_to do |format|
              format.js {}
            end
          end

          def saved_procedure_note
            @procedurenote = ProcedureNote.find_by(:id => params[:ajax][:procedure_note_id])
            @proceduretextstring = @procedurenote.proceduretext.to_s.html_safe.to_s
            puts @proceduretextstring
            respond_to do |format|
              format.js { render "templates/ipd/common/saved_procedure_note", :layout => false }
            end
          end

          def new_note
            @procedurenote = ProcedureNote.new(:proceduretext => params[:ajax][:proceduretext])
            puts params[:ajax][:proceduretext]
            respond_to do |format|
              format.html { render "templates/ipd/common/new_note", layout: false }
            end
          end

          def save_note
            @current_user = current_user
            params[:procedurenote][:organisation_id] = @current_user.organisation_id.to_s
            params[:procedurenote][:user_id] = @current_user.id.to_s
            @procedurenote = ProcedureNote.new(save_procedurenote_params)
            if @procedurenote.save
              @procedurenotes = ProcedureNote.where(:organisation_id => @current_user.organisation_id.to_s, :user_id => @current_user.id.to_s)
              respond_to do |format|
                # format.js { render nothing: true }
                format.js { render "templates/ipd/common/save_note", layout: false }
              end
            else
              respond_to do |format|
                format.js { "notice = new PNotify({ title: 'Warning', text: 'Procedure Note can not be saved without Procedure Name, Please try pesisting the form with valid data', type: 'warning' }); notice.get().click(function(){ notice.remove() });" }
              end
            end
          end

          def reload_note
            @procedurenotes = ProcedureNote.where(:organisation_id => current_user.organisation_id.to_s, :user_id => current_user.id.to_s)
            respond_to do |format|
              format.js { render "templates/ipd/common/save_note", layout: false }
            end
          end

          # OPD
          def add_medication
            @counter = params[:ajax][:counter]
            @taper = params[:ajax][:taper]
            respond_to do |format|
              format.js { render "add_medication", layout: false }
            end
          end

          def add_post_op_record
            @counter = params[:ajax][:counter]
            respond_to do |format|
              format.js { render "add_post_op_record", layout: false }
            end
          end

          def setup_view_only_flag
            @flag = "view"
          end

          def setup_print_only_flag
            @flag = "print"
          end

          def optoreading
            @flag = "view"
            @opdrecord = OpdRecord.find_by(:id => params[:optoreadingid])
            respond_to do |format|
              format.html { render "opd_records/ophthalmology_notes/opd_partials/past_optometrist_reading", layout: false }
            end
          end

          def delete_clone_record
            @opdrecord = OpdRecord.find_by(id: params[:id])
            @patienttimeline = PatientTimeline.find_by(record_id: @opdrecord.try(:id))

            if @patienttimeline.nil?
              unless @opdrecord.nil?
                @opdrecord.delete
              end
            end
            respond_to do |format|
              format.js { render "opd_records/delete_clone_record", layout: false }
            end
          end

          def append_ophthal_set
            @ophthal_laboratory_set = OphthalLaboratorySet.find_by(id: params[:id])
            @data = (JSON.parse(@ophthal_laboratory_set.try(:data)) if @ophthal_laboratory_set.present?) || {}
          end

          def append_radiology_set
            @radiology_laboratory_set = RadiologyLaboratorySet.find_by(id: params[:id])
            @data = (JSON.parse(@radiology_laboratory_set.try(:data)) if @radiology_laboratory_set.present?) || {}
          end

          def fill_patient_self_history
            @patient_self_history = PatientSelfHistory.where(patient_id: params[:patient_id]).order_by('created_at DESC')[0]
          end

          def fill_refraction_data
            @flag = params[:flag]
            respond_to do |format|
              format.js { "fill_refraction_data" }
            end
          end

          def get_ipd_data
            if params[:ipd_record_id].present?
              @ipd_record = Inpatient::IpdRecord.find_by(id: params[:ipd_record_id])
              if @ipd_record.present?
                @procedures = @ipd_record.procedure
              else
                @procedures = []
              end
            end
            respond_to do |format|
              format.js { render '/opd_records/ophthalmology_notes/get_ipd_data' }
            end
          end

          private

          def convert_to_json
            params[:opdrecord] = eval(params[:opdrecord])
            params[:patient] = eval(params[:patient])
            # params[:opdrecord] = JSON.parse(params[:opdrecord].gsub(/:(\w+)/){"\"#{$1}\""}.gsub('=>', ':'))
            # params[:patient] = JSON.parse(params[:patient].gsub(/:(\w+)/){"\"#{$1}\""}.gsub('=>', ':'))
          end

          def find_ipd_record_for_postop
            @ipd_records = Inpatient::IpdRecord.where(patient_id: @patient.id)
            @useful_ipd_records = []
            @ipd_records.where(is_deleted: false).each do |record|
              if record.procedure.count > 0
                if record.procedure.where(procedurestage: 'P').count > 0
                  @useful_ipd_records << record
                end
              end
            end
          end

          def record_keys_values_r
            @record_keys_values_r = @record.last.attributes.slice(:r_autorefraction_dry_sph, :r_autorefraction_dry_cyl, :r_autorefraction_dry_axis, :r_autorefraction_dilated1_sph, :r_autorefraction_dilated1_cyl, :r_autorefraction_dilated1_axis, :r_autorefraction_dilated2_sph, :r_autorefraction_dilated2_cyl, :r_autorefraction_dilated2_axis, :r_autorefraction_dilated3_sph, :r_autorefraction_dilated3_cyl, :r_autorefraction_dilated3_axis,  :r_visualacuity_unaided, :r_visualacuity_ua_s, :r_visualacuity_ua_i, :r_visualacuity_ua_n, :r_visualacuity_ua_t, :r_visualacuity_unaided_p, :r_visualacuity_ua_near, :r_visualacuity_ua_near_p, :r_visualacuity_pinhole, :r_visualacuity_pinhole_p, :r_visualacuity_pinhole_ni, :r_visualacuity_glasses, :r_visualacuity_glasses_p, :r_visualacuity_lens, :r_visualacuity_lens_p, :r_visualacuity_near, :r_visualacuity_near_p, :r_refraction_distant_sph, :r_refraction_distant_cyl, :r_refraction_distant_axis, :r_refraction_distant_vision, :r_refraction_add_sph, :r_refraction_add_cyl, :r_refraction_add_axis, :r_refraction_add_vision, :r_refraction_near_sph, :r_refraction_near_cyl, :r_refraction_near_axis, :r_refraction_near_vision, :r_refraction_comments, :r_dilatedrefraction_distant_sph, :r_dilatedrefraction_distant_cyl, :r_dilatedrefraction_distant_axis, :r_dilatedrefraction_distant_vision, :r_dilatedrefraction_add_sph, :r_dilatedrefraction_add_cyl, :r_dilatedrefraction_add_axis, :r_dilatedrefraction_add_vision, :r_dilatedrefraction_near_sph, :r_dilatedrefraction_near_cyl, :r_dilatedrefraction_near_axis, :r_dilatedrefraction_near_vision, :r_dilatedrefraction_drug_used, :r_dilatedrefraction_comments, :r_keratometry_distant_kh, :r_keratometry_distant_axis, :r_keratometry_near_kv, :r_keratometry_near_axis, :r_pgp_distant_sph, :r_pgp_distant_cyl, :r_pgp_distant_axis, :r_pgp_distant_vision, :r_pgp_near_sph, :r_pgp_near_cyl, :r_pgp_near_axis, :r_pgp_near_vision, :r_pgp_add_sph, :r_pgp_add_cyl, :r_pgp_add_axis, :r_pgp_add_vision, :r_pgp_typeoflens, :r_intraocularpressure, :r_intraocularpressure_time, :r_intraocularpressure_comments, :r_glassesprescriptions_distant_vision, :r_glassesprescriptions_distant_sph, :r_glassesprescriptions_distant_cyl, :r_glassesprescriptions_distant_axis, :r_glassesprescriptions_near_vision, :r_glassesprescriptions_near_sph, :r_glassesprescriptions_near_cyl, :r_glassesprescriptions_near_axis, :r_acceptance_framematerial, :r_acceptance_ipd, :r_acceptance_lensmaterial, :r_acceptance_lenstint, :r_acceptance_typeoflens, :r_acceptance_comments, :r_contactlens_bc, :r_contactlens_dia, :r_contactlens_sph, :r_contactlens_cyl, :r_contactlens_axis, :r_contactlens_add, :r_contactlens_color, :r_contactlens_types, :r_contactlens_comments, :r_contrastsensitivity, :checkuptype, :checkuptypecomments, :r_chiefcomplaint, :r_blurringdiminution_vision, :r_blurringdiminution_pain, :r_blurringdiminution_usingglasses, :r_deviationsquint_diplopia, :r_deviationsquint_trauma, :r_deviationsquint_pastsurgery, :r_othervisualsymptoms_glare, :r_othervisualsymptoms_floaters, :r_othervisualsymptoms_photophobia, :r_othervisualsymptoms_coloredhalos, :r_othervisualsymptoms_metamorphosia, :r_othervisualsymptoms_chromatopsia, :r_othervisualsymptoms_diminishednightvision, :r_othervisualsymptoms_diminisheddayvision, :r_subjective_duration_no, :r_subjective_duration_unit, :r_subjectivecomments, :r_dilated_retinoscopy_top_va1, :r_dilated_retinoscopy_bottom_va2, :r_dilated_retinoscopy_left_ha1, :r_dilated_retinoscopy_right_ha2, :r_dilated_retinoscopy_va, :r_dilated_retinoscopy_ha, :r_dilated_retinoscopy_distance, :r_retinoscopy_drug_used, :r_retinoscopy_comments, :r_dilatedretinoscopy_pmt_axis, :r_dilatedretinoscopy_pmt_sph, :r_dilatedretinoscopy_pmt_cyl, :r_dilatedretinoscopy_pmt_vision, :r_dilatedretinoscopy_pmt_axis_row2, :r_dilatedretinoscopy_pmt_sph_row2, :r_dilatedretinoscopy_pmt_cyl_row2, :r_dilatedretinoscopy_pmt_vision_row2, :r_dilatedretinoscopy_pmt_axis_row3, :r_dilatedretinoscopy_pmt_sph_row3, :r_dilatedretinoscopy_pmt_cyl_row3, :r_dilatedretinoscopy_pmt_vision_row3, :r_orthoptics, :r_color_vision)
          end

          def record_keys_values_l
            @record_keys_values_l = @record.last.attributes.slice(:l_autorefraction_dry_sph, :l_autorefraction_dry_cyl, :l_autorefraction_dry_axis, :l_autorefraction_dilated1_sph, :l_autorefraction_dilated1_cyl, :l_autorefraction_dilated1_axis, :l_autorefraction_dilated2_sph, :l_autorefraction_dilated2_cyl, :l_autorefraction_dilated2_axis, :l_autorefraction_dilated3_sph, :l_autorefraction_dilated3_cyl, :l_autorefraction_dilated3_axis,  :l_visualacuity_unaided, :l_visualacuity_ua_s, :l_visualacuity_ua_i, :l_visualacuity_ua_n, :l_visualacuity_ua_t, :l_visualacuity_unaided_p, :l_visualacuity_pinhole, :l_visualacuity_pinhole_p, :l_visualacuity_pinhole_ni, :l_visualacuity_glasses, :l_visualacuity_glasses_p, :l_visualacuity_near, :l_visualacuity_near_p, :l_visualacuity_lens_p, :l_visualacuity_lens, :l_visualacuity_ua_near, :l_visualacuity_ua_near_p, :l_refraction_distant_sph, :l_refraction_distant_cyl, :l_refraction_distant_axis, :l_refraction_distant_vision, :l_refraction_add_sph, :l_refraction_add_cyl, :l_refraction_add_axis, :l_refraction_add_vision, :l_refraction_near_sph, :l_refraction_near_cyl, :l_refraction_near_axis, :l_refraction_near_vision, :l_refraction_comments, :l_dilatedrefraction_distant_sph, :l_dilatedrefraction_distant_cyl, :l_dilatedrefraction_distant_axis, :l_contrastsensitivity, :l_dilatedrefraction_distant_vision, :l_dilatedrefraction_add_sph, :l_dilatedrefraction_add_cyl, :l_dilatedrefraction_add_axis, :l_dilatedrefraction_add_vision, :l_dilatedrefraction_near_sph, :l_dilatedrefraction_near_cyl, :l_dilatedrefraction_near_axis, :l_dilatedrefraction_near_vision, :l_dilatedrefraction_drug_used, :l_dilatedrefraction_comments, :l_keratometry_distant_kh, :l_keratometry_distant_axis, :l_keratometry_near_kv, :l_keratometry_near_axis, :l_pgp_distant_sph, :l_pgp_distant_cyl, :l_pgp_distant_axis, :l_pgp_distant_vision, :l_pgp_near_sph, :l_pgp_near_cyl, :l_pgp_near_axis, :l_pgp_near_vision, :l_pgp_add_sph, :l_pgp_add_cyl, :l_pgp_add_axis, :l_pgp_add_vision, :l_pgp_typeoflens, :l_intraocularpressure, :l_intraocularpressure_time, :l_intraocularpressure_comments, :l_glassesprescriptions_distant_vision, :l_glassesprescriptions_distant_sph, :l_glassesprescriptions_distant_cyl, :l_glassesprescriptions_distant_axis, :l_glassesprescriptions_near_vision, :l_glassesprescriptions_near_sph, :l_glassesprescriptions_near_cyl, :l_glassesprescriptions_near_axis, :l_acceptance_framematerial, :l_acceptance_ipd, :l_acceptance_lensmaterial, :l_acceptance_lenstint, :l_acceptance_typeoflens, :l_acceptance_comments, :l_contactlens_bc, :l_contactlens_dia, :l_contactlens_sph, :l_contactlens_cyl, :l_contactlens_axis, :l_contactlens_add, :l_contactlens_color, :l_contactlens_types, :l_contactlens_comments, :l_chiefcomplaint, :l_blurringdiminution_vision, :l_blurringdiminution_pain, :l_blurringdiminution_usingglasses, :l_deviationsquint_diplopia, :l_deviationsquint_trauma, :l_deviationsquint_pastsurgery, :l_othervisualsymptoms_glare, :l_othervisualsymptoms_floaters, :l_othervisualsymptoms_photophobia, :l_othervisualsymptoms_coloredhalos, :l_othervisualsymptoms_metamorphosia, :l_othervisualsymptoms_chromatopsia, :l_othervisualsymptoms_diminishednightvision, :l_othervisualsymptoms_diminisheddayvision, :l_subjective_duration_no, :l_subjective_duration_unit, :l_subjectivecomments, :l_dilated_retinoscopy_top_va1, :l_dilated_retinoscopy_bottom_va2, :l_dilated_retinoscopy_left_ha1, :l_dilated_retinoscopy_right_ha2, :l_dilated_retinoscopy_va, :l_dilated_retinoscopy_ha, :l_dilated_retinoscopy_distance, :l_retinoscopy_drug_used, :l_retinoscopy_comments, :l_dilatedretinoscopy_pmt_axis, :l_dilatedretinoscopy_pmt_sph, :l_dilatedretinoscopy_pmt_cyl, :l_dilatedretinoscopy_pmt_vision, :l_dilatedretinoscopy_pmt_axis_row2, :l_dilatedretinoscopy_pmt_sph_row2, :l_dilatedretinoscopy_pmt_cyl_row2, :l_dilatedretinoscopy_pmt_vision_row2, :l_dilatedretinoscopy_pmt_axis_row3, :l_dilatedretinoscopy_pmt_sph_row3, :l_dilatedretinoscopy_pmt_cyl_row3, :l_dilatedretinoscopy_pmt_vision_row3, :l_color_vision, :l_orthoptics)
          end

          def record_keys_values_chiefcomplaint
            @record_keys_values_chiefcomplaint = @record.last.attributes.slice(:chiefcomplaint_blurringdiminution, :chiefcomplaint_blurringdiminution_side, :chiefcomplaint_blurringdiminution_duration, :chiefcomplaint_blurringdiminution_duration_unit, :chiefcomplaint_blurringdiminution_comment, :chiefcomplaint_blurringdiminution_options, :chiefcomplaint_redness, :chiefcomplaint_redness_side, :chiefcomplaint_redness_duration, :chiefcomplaint_redness_duration_unit, :chiefcomplaint_redness_comment, :chiefcomplaint_pain, :chiefcomplaint_pain_side, :chiefcomplaint_pain_duration, :chiefcomplaint_pain_duration_unit, :chiefcomplaint_pain_comment, :chiefcomplaint_injury, :chiefcomplaint_injury_side, :chiefcomplaint_injury_duration, :chiefcomplaint_injury_duration_unit, :chiefcomplaint_injury_comment, :chiefcomplaint_watering, :chiefcomplaint_watering_side, :chiefcomplaint_watering_duration, :chiefcomplaint_watering_duration_unit, :chiefcomplaint_watering_comment, :chiefcomplaint_discharge, :chiefcomplaint_discharge_side, :chiefcomplaint_discharge_duration, :chiefcomplaint_discharge_duration_unit, :chiefcomplaint_discharge_comment, :chiefcomplaint_dryness, :chiefcomplaint_dryness_side, :chiefcomplaint_dryness_duration, :chiefcomplaint_dryness_duration_unit, :chiefcomplaint_dryness_comment, :chiefcomplaint_itichingfbsensation, :chiefcomplaint_itichingfbsensation_side, :chiefcomplaint_itichingfbsensation_duration, :chiefcomplaint_itichingfbsensation_duration_unit, :chiefcomplaint_itichingfbsensation_comment, :chiefcomplaint_deviationsquint, :chiefcomplaint_deviationsquint_side, :chiefcomplaint_deviationsquint_duration, :chiefcomplaint_deviationsquint_duration_unit, :chiefcomplaint_deviationsquint_comment, :chiefcomplaint_deviationsquint_options, :chiefcomplaint_headachestrain, :chiefcomplaint_headachestrain_side, :chiefcomplaint_headachestrain_duration, :chiefcomplaint_headachestrain_duration_unit, :chiefcomplaint_headachestrain_comment, :chiefcomplaint_changeinsizeshape, :chiefcomplaint_changeinsizeshape_side, :chiefcomplaint_changeinsizeshape_duration, :chiefcomplaint_changeinsizeshape_duration_unit, :chiefcomplaint_changeinsizeshape_comment, :chiefcomplaint_othervisualsymptoms, :chiefcomplaint_othervisualsymptoms_side, :chiefcomplaint_othervisualsymptoms_duration, :chiefcomplaint_othervisualsymptoms_duration_unit, :chiefcomplaint_othervisualsymptoms_comment, :chiefcomplaint_othervisualsymptoms_options, :chiefcomplaint_shadowdefect, :chiefcomplaint_shadowdefect_side, :chiefcomplaint_shadowdefect_duration, :chiefcomplaint_shadowdefect_duration_unit, :chiefcomplaint_shadowdefect_comment, :chiefcomplaint_discolorationeye, :chiefcomplaint_discolorationeye_side, :chiefcomplaint_discolorationeye_duration, :chiefcomplaint_discolorationeye_duration_unit, :chiefcomplaint_discolorationeye_comment, :chiefcomplaint_comments)
          end

          def record_keys_values_other
            @record_keys_values_other = @record.last.attributes.slice(:advise_glasses, :be_subjectivecomments)
          end

          def save_recent_icd(code, icd_name, doctor_id, icd_type, specialty_id, template_id)
            @presencerecenticd = RecentIcd.find_by(code: code)

            if @presencerecenticd.nil?
              @recent_icd = RecentIcd.new(code: code, icd_type: icd_type, originalname: icd_name, doctor: doctor_id, counter: 1, specialty_id: specialty_id, template_id: template_id)
              @recent_icd.save!
            else
              counter = @presencerecenticd.counter + 1
              @presencerecenticd.update(:counter => counter)
              @presencerecenticd.save
            end
          end

          def save_procedurenote_params
            params.require(:procedurenote).permit(:name, :proceduretext, :organisation_id, :user_id)
          end

          def record_params
            params.require(:opdrecord).permit!
          end

          def ipd_record_params
            params.require(:ipdrecord).permit!
          end

          def diagram_params
            # params.require(:ajax).permit(:asset_path_data, :diagram_type, :eyeside)
            params.require(:ajax).permit(:asset_path, :diagram_type, :eyeside, :patient_id)
          end

          # Split up a data uri
          def split_base64(uri_str)
            if uri_str.match(%r{^data:(.*?);(.*?),(.*)$})
              uri = Hash.new
              uri[:type] = $1 # "image/gif"
              uri[:encoder] = $2 # "base64"
              uri[:data] = $3 # data string
              uri[:extension] = $1.split('/')[1] # "gif"
              return uri
            else
              return nil
            end
          end

          # Convert data uri to uploaded file. Expects object hash, eg: params[:post]
          def convert_data_uri_to_upload(obj_hash)
            if obj_hash[:asset_path_data].try(:match, %r{^data:(.*?);(.*?),(.*)$})
              image_data = split_base64(obj_hash[:asset_path_data])
              image_data_string = image_data[:data]
              image_data_binary = Base64.decode64(image_data_string)

              temp_img_file = Tempfile.new("data_uri-upload")
              temp_img_file.binmode
              temp_img_file << image_data_binary
              temp_img_file.rewind

              img_params = { :filename => "data-uri-img.#{image_data[:extension]}", :type => image_data[:type], :tempfile => temp_img_file }
              uploaded_file = ActionDispatch::Http::UploadedFile.new(img_params)

              obj_hash[:asset_path] = uploaded_file
              obj_hash.delete(:asset_path_data)
            end

            return obj_hash
          end

          def read_file_remote(url)
            uri = URI(url)
            puts 'llllllll'
            puts uri
            data = Net::HTTP.get_response(uri)
            data.body
          end

          def history_params
            params.require(:patient).permit!
          end

          def create_referral_notification
            if record_params[:referraldate] != "" && record_params[:referraldate] != nil
              opdreferraldate = Time.zone.parse(record_params[:referraldate]).strftime("%d/%m/%Y")
              @date = opdreferraldate.split("/")[0]
              @month = opdreferraldate.split("/")[1]
              @year = opdreferraldate.split("/")[2]
              @referral_date_time = Time.new(@year, @month, @date, @hours, @minutes, 0)

              @referred_to_facility_id = record_params[:referred_to_facility]
              @referred_to_facility_name = Facility.find(record_params[:referred_to_facility]).name

              @referred_from_facility_id = record_params[:referred_from_facility]
              @referred_from_facility_name = Facility.find(record_params[:referred_from_facility]).name

              @referred_to_doctor = record_params[:referred_to_doctor]
              @referred_to_doctor_name = User.find(record_params[:referred_to_doctor]).fullname

              @referred_from_doctor = record_params[:referred_from_doctor]
              @referred_from_doctor_name = User.find(record_params[:referred_from_doctor]).fullname

              new_opd_referral = OpdReferral.new(:referral_date => @referral_date_time, :created_on => Time.current, :patient_id => @patient.id, patient_name: @patient.fullname, :to_facility => @referred_to_facility_id, :to_facility_name => @referred_to_facility_name, :from_facility => @referred_from_facility_id, :from_facility_name => @referred_from_facility_name, :to_doctor => @referred_to_doctor, :to_doctor_name => @referred_to_doctor_name, :from_doctor => @referred_from_doctor, :from_doctor_name => @referred_from_doctor_name, :referring_note => record_params[:referralnote])

              if new_opd_referral.save
                @opd_referral_id = new_opd_referral.id
              else
                @opd_referral_id = ""
              end
            end
            record_params[:opd_referral_id] = @opd_referral_id
          end

          def update_referral_notification
            if record_params[:referraldate] != "" && record_params[:referraldate] != nil
              opdreferraldate = Time.zone.parse(record_params[:referraldate]).strftime("%d/%m/%Y")
              @date = opdreferraldate.split("/")[0]
              @month = opdreferraldate.split("/")[1]
              @year = opdreferraldate.split("/")[2]
              @referral_date_time = Time.new(@year, @month, @date, @hours, @minutes, 0)

              @referred_to_facility_id = record_params[:referred_to_facility]
              @referred_to_facility_name = Facility.find(record_params[:referred_to_facility]).name

              @referred_from_facility_id = record_params[:referred_from_facility]
              @referred_from_facility_name = Facility.find(record_params[:referred_from_facility]).name

              @referred_to_doctor = record_params[:referred_to_doctor]
              @referred_to_doctor_name = User.find(record_params[:referred_to_doctor]).fullname

              @referred_from_doctor = record_params[:referred_from_doctor]
              @referred_from_doctor_name = User.find(record_params[:referred_from_doctor]).fullname

              if @opdrecord.opd_referral_id == nil || @opdrecord.opd_referral_id == ""
                new_opd_referral = OpdReferral.new(:referral_date => @referral_date_time, :created_on => Time.current, :patient_id => @patient.id, patient_name: @patient.fullname, :to_facility => @referred_to_facility_id, :to_facility_name => @referred_to_facility_name, :from_facility => @referred_from_facility_id, :from_facility_name => @referred_from_facility_name, :to_doctor => @referred_to_doctor, :to_doctor_name => @referred_to_doctor_name, :from_doctor => @referred_from_doctor, :from_doctor_name => @referred_from_doctor_name, :referring_note => record_params[:referralnote])

                if new_opd_referral.save
                  @opd_referral_id = new_opd_referral.id
                else
                  @opd_referral_id = ""
                end
              else
                @opd_referral_id = @opdrecord.opd_referral_id
                @opd_referral = OpdReferral.find(@opd_referral_id)

                unless @opd_referral == nil
                  @opd_referral.update(:referral_date => @referral_date_time, :created_on => @referral_date_time, :to_facility => @referred_to_facility_id, :to_facility_name => @referred_to_facility_name, :from_facility => @referred_from_facility_id, :from_facility_name => @referred_from_facility_name, :to_doctor => @referred_to_doctor, :to_doctor_name => @referred_to_doctor_name, :from_doctor => @referred_from_doctor, :from_doctor_name => @referred_from_doctor_name, :referring_note => record_params[:referralnote], is_deleted: false)
                end

              end
            end
            record_params[:opd_referral_id] = @opd_referral_id
          end

          def delete_referral_notification
            @opd_referral_id = @opdrecord.opd_referral_id
            @opd_referral = OpdReferral.find(@opd_referral_id)
            unless @opd_referral == nil
              @opd_referral.update(is_deleted: true)
            end
          end

          def create_referral_appointment
            if record_params[:referraldate] != "" && record_params[:referraldate] != nil
              @referral_appointment_time =  record_params[:referraltime]
              opdreferraldate = Time.zone.parse(record_params[:referraldate]).strftime("%d/%m/%Y")
              opdreferraltime = @referral_appointment_time
              if opdreferraltime.split(" ")[1] == "AM"
                unless opdreferraltime.split(":")[0] == "12"
                  @hours = opdreferraltime.split(":")[0]
                else
                  @hours = 00
                end
              else
                unless opdreferraltime.split(":")[0] == "12"
                  @hours = opdreferraltime.split(":")[0].to_i + 12
                else
                  @hours = opdreferraltime.split(":")[0]
                end
              end
              @minutes = opdreferraltime.split(":")[1].to_i
              @date = opdreferraldate.split("/")[0]
              @month = opdreferraldate.split("/")[1]
              @year = opdreferraldate.split("/")[2]
              @referral_date_time = Time.new(@year, @month, @date, @hours, @minutes, 0)
              new_appointment = Appointment.new(:appointmentdate => @referral_date_time, :start_time => @referral_date_time, :patient_id => @patient.id, :appointment_type_id => record_params[:referral_appointment_type_id], :consultant_id => record_params[:referred_to_doctor], :user_id => current_user.id, :facility_id => current_facility_id, :department_id => @user.department_id.to_s, :departmenttype => params[:opdrecord][:encountertypeid], :appointmentstatus => 416774000, :display_id => CommonHelper::get_opd_record_identifier(@user), patient_name: @patient.fullname, organisation_id: current_user.organisation_id)
              if new_appointment.save
                new_appointment.update(end_time: new_appointment.start_time + 10.minutes)
                @referralappointment_id = new_appointment.id
                @temp_appointment = new_appointment
                # start_cinical_workflow
                # get_daily_reports
                # Reports::Opd::Appointments.new(new_appointment).call
              else
                @referralappointment_id = ""
              end
            end
            record_params[:referralappointment_id] = @referralappointment_id
          end

          def update_referral_appointment
            if record_params[:referraldate] != "" && record_params[:referraldate] != nil
              @referral_appointment_time =  record_params[:referraltime]
              opdreferraldate = Time.zone.parse(record_params[:referraldate]).strftime("%d/%m/%Y")
              opdreferraltime = @referral_appointment_time

              if opdreferraltime.split(" ")[1] == "AM"
                unless opdreferraltime.split(":")[0] == "12"
                  @hours = opdreferraltime.split(":")[0]
                else
                  @hours = 00
                end
              else
                unless opdreferraltime.split(":")[0] == "12"
                  @hours = opdreferraltime.split(":")[0].to_i + 12
                else
                  @hours = opdreferraltime.split(":")[0]
                end
              end
              @minutes = opdreferraltime.split(":")[1].to_i
              @date = opdreferraldate.split("/")[0]
              @month = opdreferraldate.split("/")[1]
              @year = opdreferraldate.split("/")[2]
              @referral_date_time = Time.new(@year, @month, @date, @hours, @minutes, 0)

              if @opdrecord.referralappointment_id == nil || @opdrecord.referralappointment_id == ""
                new_appointment = Appointment.new(:appointmentdate => @referral_date_time, :start_time => @referral_date_time, :patient_id => @patient.id, :appointment_type_id => record_params[:referral_appointment_type_id], :consultant_id => record_params[:referred_to_doctor], :user_id => current_user.id, :facility_id => current_facility_id, :department_id => @user.department_id.to_s, :departmenttype => params[:opdrecord][:encountertypeid], :appointmentstatus => 416774000, :display_id => CommonHelper::get_opd_record_identifier(@user), patient_name: @patient.fullname, organisation_id: current_user.organisation_id)
                if new_appointment.save
                  new_appointment.update(end_time: new_appointment.start_time + 10.minutes)
                  @referralappointment_id = new_appointment.id
                  @temp_appointment = new_appointment
                  # start_cinical_workflow
                  # get_daily_reports
                  # Reports::Opd::Appointments.new(new_appointment).call
                else
                  @referralappointment_id = ""
                end
              else
                @referralappointment_id = @opdrecord.referralappointment_id
                @referralappointment = Appointment.find(@referralappointment_id)
                unless @referralappointment == nil
                  new_appointment = @referralappointment.update(:appointmentdate => @referral_date_time, :start_time => @referral_date_time, end_time: Time.zone.parse(opdreferraltime) + 10.minutes, :facility_id => current_facility_id, :appointment_type_id => record_params[:referral_appointment_type_id], :consultant_id => record_params[:referred_to_doctor])
                end
                @followup_workflow = OpdClinicalWorkflow.find_by(appointment_id: @referralappointment_id.to_s)
                unless @followup_workflow == nil
                  @followup_workflow.update(:appointmentdate => @referral_date_time, :facility_id => current_facility_id)
                end
              end
            end
            record_params[:referralappointment_id] = @referralappointment_id
          end

          def get_parent_icd_name(diagnosislist, code)
            parent_icd = eval(diagnosislist.icd_type).find_by(code: code)
            if parent_icd.present?
              icd_name = parent_icd.originalname
            else
              code = code.first(-1)
              get_parent_icd_name(diagnosislist, code)
            end

            return icd_name, code
          end

          def get_diagnosis_code(diagnosislist, code)
            icd_diagnosis = eval(diagnosislist.icd_type).find_by(code: code)
            if icd_diagnosis.present?
              code = code
            else
              code = code.first(-1)
              get_diagnosis_code(diagnosislist, code)
            end

            return code
          end

          def set_record_owners
            if params[:templatetype] == "optometrist"

              @optometrist = User.where(facility_ids: @appointment.facility_id, role_ids: 28229004, is_active: true)
              @optometrist_fullname_array = @optometrist.pluck(:fullname)
              @optometrist_ids_array = @optometrist.pluck(:id)

            else
              # doctors_array = User.where(facility_ids: @appointment.facility_id, role_ids: 158965000, is_active: true).pluck(:fullname, :id)
              # current_doctor_array =  [[@opdrecord.consultant_name , @opdrecord.consultant_id]]
              # appointment_opd_records = OpdRecord.where(appointmentid: @appointment.id.to_s, templatetype: @templatetype)
              # extra_doctors_array = appointment_opd_records.pluck(:consultant_name, :consultant_id)
              # doctors_array.delete_if {|el| ([el[1].to_s] & extra_doctors_array.map {|el| el[1]}).length > 0}
              # @doctors_array  = doctors_array | current_doctor_array
            end
          end
        end
      end
    end
  end
end
