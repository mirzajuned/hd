# 89   Metrics/LineLength
# 19   Metrics/AbcSize
# 14   Metrics/MethodLength
# 10   Style/GuardClause
# 8    Metrics/BlockNesting
# 8    Naming/VariableNumber
# 5    Metrics/CyclomaticComplexity
# 5    Metrics/PerceivedComplexity
# 4    Style/IfInsideElse
# 3    Layout/EndAlignment
# 3    Naming/AccessorMethodName
# 2    Style/ClassAndModuleChildren
# 1    Metrics/ClassLength
# --
# 171 Total Offenses Pending
module Api
  module V1
    class Inpatient::IpdRecordsController < ApiApplicationController
      before_action :authorize

      # Api needs change wrt to web view - or move everything to web view
      # Api not in use
      def show_all_notes
        @department = current_user.department.name.downcase
        @department_notes = current_user.department.name.downcase + '_notes'
        @organisation = current_user.organisation
        @patient = Patient.find(params[:patient_id])
        @admission = Admission.find(params[:admission_id])
        @tpa = @admission
        @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
        @clinical_note = @ipdrecord.clinical_note
        # @operative_note_ids = @ipdrecord.procedure.where(:operative_note_id.nin => ["",nil]).pluck(:operative_note_id)
        # @operative_notes = @ipdrecord.operative_notes.find(@operative_note_ids)
        @all_operative_notes = @ipdrecord.operative_notes
        # @operative_note = @ipdrecord.operative_notes[-1]
        @discharge_note = @ipdrecord.discharge_note
        @procedure = @ipdrecord.procedure.where(procedurestage: 'P')
        @diagnosislist = @ipdrecord.diagnosislist
      end

      def print_all_notes
        @department = current_user.department.name.downcase
        @department_notes = current_user.department.name.downcase + '_notes'
        @organisation = current_user.organisation
        @patient = Patient.find(params[:patient_id])
        @admission = Admission.find(params[:admission_id])
        @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: @admission.id)
        @tpa = @admission
        @clinical_note = @ipdrecord.clinical_note
        # @operative_note_ids = @ipdrecord.procedure.where(:operative_note_id.nin => ["",nil]).pluck(:operative_note_id)
        # @operative_notes = @ipdrecord.operative_notes.find(@operative_note_ids)
        @all_operative_notes = @ipdrecord.operative_notes
        @discharge_note = @ipdrecord.discharge_note
        @procedure = @ipdrecord.procedure.where(procedurestage: 'P')
        @diagnosislist = @ipdrecord.diagnosislist
        @view = params[:view]
        setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, 'IPD')
        @print_settings = setting_service.select_print_setting
        @logo = @print_settings[1]
        respond_to do |format|
          format.pdf { render template: 'inpatient/ipd_records/print_all_notes', pdf: '', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 }, encoding: 'utf8' }
        end
      end

      def new
        @department = current_user.department.name.downcase
        @organisation = current_user.organisation
        @admission = Admission.find(params[:admission_id])
        @patient = @admission.patient
        @template_type = params[:templatetype]
        @tpa = @admission
        @action = 'New'
        @date = Time.current
        @user = User.where(:role_ids.in => [158965000], :facility_ids.in => [current_facility.id])[0]
        @facility_id = current_facility.id
        @opd_records = PatientTimeline.where(patient_id: @patient.id, :templatetype.nin => ['optometrist', 'operativenote', 'dischargenote', 'admissionnote', 'wardnote', 'knee', 'shoulder', 'elbow', 'wristhand', 'spine', 'hip', 'footankle', 'trauma']).order('encounterdate DESC')
        if params[:flag] == 'Clone Wardnote'
          ipdrecord = Inpatient::IpdRecord.find_by(id: params[:ipdrecord_id])
          @ipdrecord = ipdrecord.clone
        else
          @ipdrecord = Inpatient::IpdRecord.new
        end

        respond_to do |format|
          format.js { render 'inpatient/ipd_records/common/newedit_ipd_record', layout: false }
        end
      end

      def create
        @ipdrecord = Inpatient::IpdRecord.new(ipd_record_params)
        @load_path = 'Create'
        if @ipdrecord.save
          @ipdrecord.record_histories.create(user_id: current_user.id, action: 'C', actiontime: Time.current, template_type: @ipdrecord.template_type)
          @patient = Patient.find_by(id: @ipdrecord.patient_id)
          @patient.update_attributes(history_params) if @ipdrecord.template_type == 'admissionnote'
          @admission = Admission.find_by(id: @ipdrecord.admission_id)
          @admission.update_attributes(dischargedate: @ipdrecord.discharge_date, dischargetime: @ipdrecord.discharge_time)
          @template_type = @ipdrecord.template_type
          @department = current_user.department.name.downcase
          @organisation = current_user.organisation
          @admission_selected = Admission.find(@ipdrecord.admission_id)
          @tpa = @admission

          if @ipdrecord.bookappointment == 'true' && @ipdrecord.followup_date != '' && !@ipdrecord.followup_date.nil?
            # @hours = @ipdrecord.followup_time.split(":")[0]
            # @minutes = @ipdrecord.followup_time.split(":")[1].to_i
            # @date = @ipdrecord.followup_date.split("/")[0]
            # @month = @ipdrecord.followup_date.split("/")[1]
            # @year = @ipdrecord.followup_date.split("/")[2]
            @appointment_facility = @ipdrecord.followup_facility || current_facility.id.to_s

            @followup_date = Time.zone.parse(@ipdrecord.followup_date).strftime('%d/%m/%Y')
            @appointment_type_id = @ipdrecord.appointment_type_id

            @hours = if @ipdrecord.followup_time.split(' ')[1] == 'AM'
                       if @ipdrecord.followup_time.split(':')[0] == '12'
                         0
                       else
                         @ipdrecord.followup_time.split(':')[0]
                       end
                     else
                       if @ipdrecord.followup_time.split(':')[0] == '12'
                         @ipdrecord.followup_time.split(':')[0]
                       else
                         @ipdrecord.followup_time.split(':')[0].to_i + 12
                       end
                     end
            @minutes = @ipdrecord.followup_time.split(':')[1].to_i
            @date = @followup_date.split('/')[0]
            @month = @followup_date.split('/')[1]
            @year = @followup_date.split('/')[2]
            @followup_date_time = Time.new(@year, @month, @date, @hours, @minutes, 0)

            @appointment_type_id = params[:inpatient_ipd_record][:appointment_type_id]
            @followup_doctor = User.find(@ipdrecord.followup_doctor_id)
            if @ipdrecord.followup_appointment_id.nil? || @ipdrecord.followup_appointment_id == ''
              @followupappointment = Appointment.new(patient_id: @ipdrecord.patient_id.to_s, department_id: '485396012', specialty_id: @admission.specialty_id, departmenttype: '440655000', facility_id: @appointment_facility, appointmentdate: @followup_date_time, start_time: @followup_date_time, consultant_id: @followup_doctor.id, appointment_type_id: @appointment_type_id, appointmentstatus: 416774000, ref_doc_name: '', ref_doc_place: '', user_id: current_user.id, display_id: CommonHelper.get_opd_record_identifier(current_user), patient_name: @patient.fullname)
              if @followupappointment.save
                @ipdrecord.update_attributes(followup_appointment_id: @followupappointment.id)
                @followupappointment.update(end_time: @followupappointment.start_time + 10.minutes)
              end

              @temp_appointment = @followupappointment
              # start_cinical_workflow

            else
              Appointment.find(@ipdrecord.followup_appointment_id).update_attributes(appointmentdate: @followup_date_time, start_time: @followup_date_time, end_time: @followup_date_time + 10.minutes, consultant_id: @followup_doctor.id, appointment_type_id: @appointment_type_id, facility_id: @appointment_facility)

              @followup_workflow = OpdClinicalWorkflow.find_by(appointment_id: @ipdrecord.followup_appointment_id.to_s)
              unless @followup_workflow.nil?
                doctors = @followup_workflow.consultant_ids << @followup_doctor.id.to_s
                @followup_workflow.update(appointmentdate: @followup_date_time, consultant_ids: doctors)
              end
            end
          end

          # private method
          time_calculation
          update_admission_fields
          update_insurance_fields
          # private method Ends
          recomended_procedure = params[:procedure]
          recomended_procedure&.each do |proc|
            @procedure = Inpatient::Procedure.find_by(id: proc[1]['id'])
            if @procedure.procedurestatus != 'Performed'
              if proc[1]['status'] == 'Pre-Operative'
                @procedure.update_attributes(procedurestatus: 'Pre-Operative', surgerydate: proc[1]['surgerydate'])
              elsif proc[1]['status'] == 'Performed'
                @procedure.update_attributes(procedurestatus: 'Performed', surgerydate: proc[1]['surgerydate'])
              elsif proc[1]['status'].nil?
                @procedure.update_attributes(procedurestatus: 'Advised')
              end
            end
          end
          if @template_type == 'admissionnote'
            added_procedure = params[:procedure_added]
            if added_procedure
              Inpatient::Procedure.where(ipdrecord_id: @ipdrecord.id, :procedurestatus.nin => ['Performed']).destroy
              added_procedure.each do |proc|
                Inpatient::Procedure.create(procedurename: proc[1]['name'], procedurestatus: 'Pre-Operative', procedureid: proc[1]['id'], procedureside: proc[1]['side'], facility_id: @ipdrecord.facility_id, ipdrecord_id: @ipdrecord.id, ipdtemplatetype: @ipdrecord.template_type, patient_id: @ipdrecord.patient_id)
              end
            end
          end
          create_patient_assets if @template_type == 'dischargenote'
          # private method to add diagnosis in admission note
          if @ipdrecord.template_type == 'admissionnote'
            Inpatient::Diagnosis.where(ipdrecord_id: @ipdrecord.id).try(:destroy)
            add_diagnosis(@ipdrecord)
          end
          # private method to add new personnel
          add_personnel

          procedure_operative
          # IpdRecordJob.perform_later(@ipdrecord.id.to_s,"")
          respond_to do |format|
            if @template_type == 'wardnote'
              format.js { render 'inpatient/ipd_records/common/show_allward_record', layout: false }
            else
              format.js { render 'inpatient/ipd_records/common/show_ipd_record', layout: false }
            end
          end
        end
      end

      def show
        @ipdrecord = Inpatient::IpdRecord.find_by(id: params[:id])
        @patient = Patient.find(@ipdrecord.patient_id)
        @admission = Admission.find(@ipdrecord.admission_id)
        @followup_doctor = User.find_by(id: @ipdrecord.followup_doctor_id)
        @tpa = @admission
        @template_type = @ipdrecord.template_type
        @department = @ipdrecord.department.downcase
        @organisation = current_user.organisation
        procedure_operative
        @load_path = 'Show'
        respond_to do |format|
          format.js { render 'inpatient/ipd_records/common/show_ipd_record', layout: false }
        end
      end

      def edit
        @ipdrecord = Inpatient::IpdRecord.find_by(id: params[:id])
        # if @ipdrecord.followup_date.present?
        #   # @date = Date.parse(@ipdrecord.followup_date)
        #   # @hours = @ipdrecord.followup_time.split(":")[0]
        #   # @minutes = @ipdrecord.followup_time.split(":")[1].to_i
        #   @date = @ipdrecord.followup_date.split("/")[0]
        #   @month = @ipdrecord.followup_date.split("/")[1]
        #   @year = @ipdrecord.followup_date.split("/")[2]
        #   @date = Time.new(@year, @month, @date, 0, 0, 0)
        # else
        #   @date = Date.current
        # end
        @date = if @ipdrecord.followup_date.present?
                  Date.parse(@ipdrecord.followup_date)
                else
                  Date.current
                end
        @user = if @ipdrecord.followup_doctor_id.present?
                  User.find(@ipdrecord.followup_doctor_id)
                else
                  User.find_by(:role_ids.in => [158965000], :organisation_id => current_user.organisation)
                end
        @facility_id = if @ipdrecord.followup_facility.present?
                         @ipdrecord.followup_facility
                       else
                         current_facility.id
                       end
        # t1 = Time.zone.parse('16:00:00')
        # t2 = t1 + 3599
        # Appointment.where(start_time: t1..t2, appointmentdate: @date, doctor: @user.id, facility_id: @facility_id).map { |e| ap e }

        @department = current_user.department.name.downcase
        @organisation = current_user.organisation
        @admission = Admission.find(params[:admission_id])
        @patient = @admission.patient
        @template_type = params[:templatetype]
        @tpa = Inpatient::Insurance::Tpa.find_by(admission_id: params[:admission_id])
        @procedure = Inpatient::Procedure.where(patient_id: @patient.id.to_s)
        @ot_procedure = Inpatient::Procedure.where(patient_id: @patient.id.to_s, :procedurestatus.in => ['Performed', 'Pre-Operative'])
        @action = 'Edit'

        respond_to do |format|
          format.js { render 'inpatient/ipd_records/common/newedit_ipd_record', layout: false }
        end
      end

      def update
        @ipdrecord = Inpatient::IpdRecord.find_by(id: params[:id])
        @patient = Patient.find(@ipdrecord.patient_id)
        @patient.update_attributes(history_params) if @ipdrecord.template_type == 'admissionnote'
        @admission = Admission.find(@ipdrecord.admission_id)
        @tpa = @admission
        @template_type = @ipdrecord.template_type
        @department = current_user.department.name.downcase
        @organisation = current_user.organisation
        @load_path = 'Update'
        @appointment_facility = @ipdrecord.followup_facility || current_facility.id.to_s
        # Hack For Embeded Form

        delete_all_b4_update if @ipdrecord.template_type == 'operativenote' && @ipdrecord.department == 'orthopedics'
        if @ipdrecord.update_attributes(ipd_record_params)
          @ipdrecord.record_histories.create(user_id: current_user.id, action: 'U', actiontime: Time.current, template_type: @template_type)

          @admission.update_attributes(dischargedate: @ipdrecord.discharge_date, dischargetime: @ipdrecord.discharge_time)
          if @ipdrecord.bookappointment == 'true' && @ipdrecord.followup_date != '' && !@ipdrecord.followup_date.nil?
            # @hours = @ipdrecord.followup_time.split(":")[0]
            # @minutes = @ipdrecord.followup_time.split(":")[1].to_i
            # @date = @ipdrecord.followup_date.split("/")[0]
            # @month = @ipdrecord.followup_date.split("/")[1]
            # @year = @ipdrecord.followup_date.split("/")[2]
            @followup_date = Time.zone.parse(@ipdrecord.followup_date).strftime('%d/%m/%Y')
            @hours = if @ipdrecord.followup_time.split(' ')[1] == 'AM'
                       if @ipdrecord.followup_time.split(':')[0] == '12'
                         0
                       else
                         @ipdrecord.followup_time.split(':')[0]
                       end
                     else
                       if @ipdrecord.followup_time.split(':')[0] == '12'
                         @ipdrecord.followup_time.split(':')[0]
                       else
                         @ipdrecord.followup_time.split(':')[0].to_i + 12
                       end
                     end
            @minutes = @ipdrecord.followup_time.split(':')[1].to_i
            @date = @followup_date.split('/')[0]
            @month = @followup_date.split('/')[1]
            @year = @followup_date.split('/')[2]
            @followup_date_time = Time.new(@year, @month, @date, @hours, @minutes, 0)
            @appointment_type_id = @ipdrecord.appointment_type_id

            @followup_doctor = User.find_by(id: @ipdrecord.followup_doctor_id)
            if @ipdrecord.followup_appointment_id.nil? || @ipdrecord.followup_appointment_id == ''
              @followupappointment = Appointment.new(patient_id: @ipdrecord.patient_id.to_s, department_id: '485396012', specialty_id: @admission.specialty_id, departmenttype: '440655000', facility_id: @appointment_facility, appointmentdate: @followup_date_time, start_time: @followup_date_time, consultant_id: @followup_doctor.id, appointment_type_id: @appointment_type_id, appointmentstatus: 416774000, ref_doc_name: '', ref_doc_place: '', user_id: current_user.id, display_id: CommonHelper.get_opd_record_identifier(current_user), patient_name: @patient.fullname)
              if @followupappointment.save
                @ipdrecord.update_attributes(followup_appointment_id: @followupappointment.id)
                @followupappointment.update(end_time: @followupappointment.start_time + 10.minutes)

                # Code for Tracker
                @patient_tracker = PatientTracker.find_by(patient_id: @followupappointment.patient_id, tracker_removed: false)
                unless @patient_tracker.nil?
                  if @patient_tracker.tracker_type == 'Session'
                    @new_array = @patient_tracker.session_dates << Date.current
                    @patient_tracker.update(current_session: @patient_tracker.current_session.to_i + 1, session_dates: @new_array)
                  end
                end

                @temp_appointment = @followupappointment
                # start_cinical_workflow
              end
            else
              @followupappointment = Appointment.find(@ipdrecord.followup_appointment_id)
              @followupappointment.update_attributes(appointmentdate: @followup_date, start_time: @ipdrecord.followup_time, end_time: @followupappointment.start_time + 10.minutes, consultant_id: @followup_doctor.id, appointment_type_id: @appointment_type_id, facility_id: @appointment_facility)

              @followup_workflow = OpdClinicalWorkflow.find_by(appointment_id: @ipdrecord.followup_appointment_id.to_s)
              unless @followup_workflow.nil?
                doctors = @followup_workflow.consultant_ids << @followup_doctor.id.to_s
                @followup_workflow.update(appointmentdate: @followup_date, consultant_ids: doctors)
              end
            end
          end

          # private method
          time_calculation
          update_admission_fields
          update_insurance_fields
          if @ipdrecord.template_type == 'admissionnote'
            Inpatient::Diagnosis.where(ipdrecord_id: @ipdrecord.id).try(:destroy)
            add_diagnosis(@ipdrecord)
          end
          # private method to add new personnel
          add_personnel
          # private method Ends
          recomended_procedure = params[:procedure]
          recomended_procedure&.each do |proc|
            @procedure = Inpatient::Procedure.find_by(id: proc[1]['id'])
            if proc[1]['status'] == 'Pre-Operative'
              @procedure.update_attributes(procedurestatus: 'Pre-Operative', surgerydate: proc[1]['surgerydate'])
            elsif proc[1]['status'] == 'Performed'
              @procedure.update_attributes(procedurestatus: 'Performed', surgerydate: proc[1]['surgerydate'])
            elsif proc[1]['status'].nil?
              @procedure.update_attributes(procedurestatus: 'Advised')
            end
          end
          added_procedure = params[:procedure_added]
          if added_procedure
            Inpatient::Procedure.where(patient_id: @patient.id.to_s, :procedurestatus.nin => ['Performed']).destroy
            added_procedure.each do |proc|
              Inpatient::Procedure.create(procedurename: proc[1]['name'], procedurestatus: 'Pre-Operative', procedureid: proc[1]['id'], procedureside: proc[1]['side'], patient_id: @patient.id.to_s, facility_id: @ipdrecord.facility_id, ipdrecord_id: @ipdrecord.id, ipdtemplatetype: @ipdrecord.template_type)
            end
          end
          @admission_selected = Admission.find(@ipdrecord.admission_id)
          update_patient_assets if @template_type == 'dischargenote'

          procedure_operative

          respond_to do |format|
            if @template_type == 'wardnote'
              format.js { render 'inpatient/ipd_records/common/show_allward_record', layout: false }
            else
              format.js { render 'inpatient/ipd_records/common/show_ipd_record', layout: false }
            end
          end
        end
      end

      def print_summary
        @ipdrecord = Inpatient::IpdRecord.find_by(id: params[:id])
        @patient = Patient.find(@ipdrecord.patient_id)
        @admission = Admission.find(@ipdrecord.admission_id)
        @tpa = @admission
        @template_type = @ipdrecord.template_type
        @department = current_user.department.name.downcase
        @organisation = current_user.organisation
        @print = 'Summary'
        @procedure_notes = nil
        procedure_operative
        # puts @procedure_notes
        setting_service = PrintSettingService.new(current_facility_id, @admission.consultant_id.to_s, 'IPD')
        @print_settings = setting_service.select_print_setting
        @logo = @print_settings[1]
        respond_to do |format|
          format.pdf { render template: 'inpatient/ipd_records/views/ipd_common_view', pdf: '', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, top: @print_settings[0]['header_height'].to_f * 10, bottom: @print_settings[0]['footer_height'].to_f * 10 } }
        end
      end

      def print
        @ipdrecord = Inpatient::IpdRecord.find_by(id: params[:id])
        @diagnosislist = @ipdrecord.diagnosislist
        @procedure = @ipdrecord.procedure
        @patient = Patient.find(@ipdrecord.patient_id)
        @admission = Admission.find(@ipdrecord.admission_id)
        @tpa = @admission
        @template_type = @ipdrecord.template_type
        @department = current_user.department.name.downcase
        @organisation = current_user.organisation
        @print = 'Note'
        setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, 'IPD')
        @print_settings = setting_service.select_print_setting
        @logo = @print_settings[1]
        respond_to do |format|
          format.pdf { render template: 'inpatient/ipd_records/views/ipd_common_view', pdf: '', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 10, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { top: @print_settings[0]['header_height'].to_f * 10, bottom: 40 } }
        end
      end

      def current_time
        @current_time = Time.current
        render json: @current_time
      end

      def selected_time
        @meridian = params[:time].split(' ')[1]
        @hours = params[:time].split(':')[0].to_i
        @minutes = params[:time].split(':')[1].to_i
        if @meridian == 'PM'
          @hours = (@hours + 12 if @hours != 12) || 12
        else
          @hours = 0 if @hours == 12
        end

        @selected_time = Time.new(Time.current.strftime('%Y'), Time.current.strftime('%m'), Time.current.strftime('%d'), @hours, @minutes, 0)
        render json: @selected_time
      end

      def consent_note
        @patient = Patient.find_by(id: params[:patient_id])
        # Age Calculation
        @calculate_age = @patient.calculate_age
        @admission = Admission.find_by(id: params[:admission_id])
        respond_to do |format|
          format.js { render 'inpatient/ipd_consents/operative/common/consent_note' }
        end
      end

      def load_consent
        service_id = params[:surgery_id]
        @patient = Patient.find_by(id: params[:patient_id])
        @admission = Admission.find_by(id: params[:admission_id])
        if current_user.department.name == 'Ophthalmology'
          @erb = Global.send('ipd').send('ophthalconsent')[service_id.to_s]['erb']
        elsif current_user.department.name == 'Orthopedics'
          @erb = Global.send('ipd').send('orthoconsent')[service_id.to_s]['erb']
        end
        respond_to do |format|
          format.js { render 'inpatient/ipd_consents/operative/common/load_consent' }
        end
      end

      def print_consent
        @patient = Patient.find_by(id: params[:patient_id])
        @admission = Admission.find_by(id: params[:admission_id])
        @organisation = current_user.organisation
        if current_user.department.name == 'Ophthalmology'
          @erb = Global.send('ipd').send('ophthalconsent')[params[:surgery_id]]['erb'] + '.html.erb'
        elsif current_user.department.name == 'Orthopedics'
          @erb = Global.send('ipd').send('orthoconsent')[params[:surgery_id]]['erb'] + '.html.erb'
        end
        setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, 'IPD')
        @print_settings = setting_service.select_print_setting
        @logo = @print_settings[1]
        respond_to do |format|
          format.pdf { render template: 'inpatient/ipd_consents/operative/common/print_consent', pdf: '', layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 4, html: { template: 'layouts/pdf-header.html' } }, footer: { html: { template: 'layouts/pdf-footer.html' }, spacing: 10 }, margin: { top: @print_settings[0]['header_height'].to_i * 10, bottom: 40 } }
        end
      end

      def followup_appointment
        @admission = Admission.find_by(id: params[:admission_id])

        @hours = if params[:appointment_time].split(' ')[1] == 'AM'
                   if params[:appointment_time].split(':')[0] == '12'
                     0
                   else
                     params[:appointment_time].split(':')[0]
                   end
                 else
                   if params[:appointment_time].split(':')[0] == '12'
                     params[:appointment_time].split(':')[0]
                   else
                     params[:appointment_time].split(':')[0].to_i + 12
                   end
                 end
        @minutes = params[:appointment_time].split(':')[1].to_i
        @date = params[:appointment_date].split('/')[0]
        @month = params[:appointment_date].split('/')[1]
        @year = params[:appointment_date].split('/')[2]
        @followup_date_time = Time.new(@year, @month, @date, @hours, @minutes, 0)
        @appointment_type_id = params[:appointment_type]

        @followup_doctor = User.find_by(fullname: params[:followup_doctor_id])
        if params[:click] == 'Add'
          Appointment.create(patient_id: @admission.patient_id.to_s, department_id: '485396012', specialty_id: @admission.specialty_id, departmenttype: '440655000', facility_id: @admission.facility_id.to_s, appointmentdate: @followup_date_time, start_time: @followup_date_time, consultant_id: @followup_doctor.id, appointment_type_id: @appointment_type_id, appointmentstatus: 416774000, end_time: @followup_date_time + 15.minutes, ref_doc_name: '', ref_doc_place: '', user_id: current_user.id, display_id: CommonHelper.get_opd_record_identifier(current_user))
        else
          Appointment.where(patient_id: @admission.patient_id).update_attributes(appointmentdate: @followup_date_time, start_time: @followup_date_time, end_time: @followup_date_time + 15.minutes, consultant_id: @followup_doctor.id)
        end

        render json: { loc: @loc }
      end

      def searchprocedure
        @procedure = Inpatient::OphthalmologyProcedure.where(procedure_name: /#{Regexp.escape(params[:q])}/i)
      end

      def all_ward_note
        @template_type = 'wardnote'
        @admission = Admission.find_by(id: params[:admission_id])
        @patient = Patient.find_by(id: @admission.patient_id)
        @load_path = 'Show'
        respond_to do |format|
          format.js { render 'inpatient/ipd_records/common/show_allward_record.js.erb' }
        end
      end

      def search_sugery_personnel
        @results_name = Inpatient::SurgeryPersonnel.where(name: /#{Regexp.escape(params[:q])}/i, :specialty_id.in => current_user.specialty_id, :organisation_id.in => [nil, current_user.organisation_id.to_s])
        respond_to do |format|
          format.json {}
        end
      end

      def data_from_opd
        @clincal_note = Inpatient::IpdRecord::ClinicalNote.find_by(admission_id: params[:admission_id], patient_id: params[:patient_id])
        @operative_note = Inpatient::IpdRecord::OperativeNote.find_by(admission_id: params[:admission_id], patient_id: params[:patient_id])
        # @patient = Patient.find_by(id: params[:patient_id])
        if @clinical_note.nil?
          @diagnosis = []
          @procedures = []
          @performed_remaining = []
        else
          @diagnosis = if current_user.department.name == 'Orthopedics'
                         @clinical_note.diagnosis
                       else
                         Inpatient::Diagnosis.where(ipdrecord_id: @clinical_note.id).order('created_at DESC')
                       end

          @procedures = Inpatient::Procedure.where(ipdrecord_id: @clinical_note.id, :procedurestatus.in => ['Performed']).order('created_at DESC')
          @performed_remaining = Inpatient::Procedure.where(ipdrecord_id: @clinical_note.id).order('created_at DESC')
        end
      end

      def get_diagnosis_output
        if params[:ipdrecord_id].blank?
          @diagnosis_array = []
        else
          current_diagnosis = Inpatient::Diagnosis.where(ipdrecord_id: BSON::ObjectId(params[:ipdrecord_id])).order('created_at DESC')
          diagnosis_output(current_diagnosis)
        end
      end

      def get_diagnosis_output_for_counsellor
        if params[:patient_id].blank?
          @diagnosis_array = []
        else
          current_diagnosis = OpdRecord.where(patientid: params[:patient_id]).order('created_at DESC')[0].try(:diagnosislist)
          if current_diagnosis.present?
            diagnosis_output(current_diagnosis)
          else
            @diagnosis_array = []
          end
        end
      end

      def print_flags
        @ipdrecord = Inpatient::IpdRecord.find(params[:ipdrecord_id])
        @flag = params[:flag]
        @ipdrecord.update_attributes(print_procedure: @flag)
        render json: { "success": true }
      end

      def get_opd_data
        patientopd = PatientOpd.find_by(id: params[:patientid])
        if patientopd.records.count > 0
          @opdrecord = patientopd.records.find_by(id: params[:opdrecord_id])
          @department = current_user.department.name.downcase
          @organisation = current_user.organisation
          @admission = Admission.find(params[:admission_id])
          @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: @admission.id)
          # @ipdrecord.procedure.destroy
          # @ipdrecord.diagnosislist.destroy
          @patient = @admission.patient
          @action = 'New'
          @procedures = patientopd.procedures.where(record_id: BSON::ObjectId(params[:opdrecord_id]))
          @diagnosis_from_opd = patientopd.diagnosis.where(record_id: BSON::ObjectId(params[:opdrecord_id]))
          respond_to do |format|
            format.js {}
            format.json {}
          end
        end
      end

      # moved from opd_record to IpdRecord - Anoop
      def ipdaddmedication
        @counter = params[:ajax][:counter]
        respond_to do |format|
          format.js { render '/inpatient/ipd_record/ipdaddmedication', layout: false }
        end
      end

      private

      def add_diagnosis(ipdrecord)
        if params[:opdrecord]
          diagnosis_attributes = params[:opdrecord][:diagnosislist_attributes]
          diagnosis_attributes&.values&.each do |dia_attr|
            dia_attr[:ipdrecord_id] = ipdrecord.id
            dia_attr[:ipdtemplatetype] = ipdrecord.template_type
            puts '++++++++++++++++++++++++++++', dia_attr

            unlocked_params = ActiveSupport::HashWithIndifferentAccess.new(dia_attr)
            diagnosis = Inpatient::Diagnosis.create(unlocked_params)
            diagnosis.update(patient_id: @patient.id.to_s)
          end
        end
        diagnosis_attributes_two = params[:diagnosislist_attributes]
        diagnosis_attributes_two&.values&.each do |dia|
          dia[:ipdrecord_id] = ipdrecord.id
          dia[:ipdtemplatetype] = ipdrecord.template_type
          puts '-----------------------', dia
          punlocked_params = ActiveSupport::HashWithIndifferentAccess.new(dia)
          diagnosis2 = Inpatient::Diagnosis.create(punlocked_params)
          diagnosis2.update(patient_id: @patient.id.to_s)
        end
      end

      def diagnosis_output(diagnosis_from_opd)
        @diagnosis_array = []

        diagnosis_from_opd.each do |diagnosis|
          diagnosis_output = if diagnosis.created_from == 'migration'
                               diagnosis.diagnosisname.capitalize
                             else
                               diagnosis.diagnosisoriginalname.capitalize
                             end
          @diagnosis_array << diagnosis_output
        end
      end

      def create_patient_assets
        befor_surgery_1 = params[:before_surgery_1]
        befor_surgery_2 = params[:before_surgery_2]
        after_surgery_1 = params[:after_surgery_1]
        after_surgery_2 = params[:after_surgery_2]
        unless befor_surgery_1[:asset_path].nil?
          PatientSummaryAssetUpload.create(asset_path: params[:before_surgery_1][:asset_path], name: params[:before_surgery_1][:name], patient_id: @ipdrecord.patient_id, source: 'before_surgery_1', ipdrecord_id: @ipdrecord.id, parent_folder_id: '560cc6f72b2e26135d000006', is_folder: 'N')
        end
        unless befor_surgery_2[:asset_path].nil?
          PatientSummaryAssetUpload.create(asset_path: params[:before_surgery_2][:asset_path], name: params[:before_surgery_2][:name], patient_id: @ipdrecord.patient_id, source: 'before_surgery_2', ipdrecord_id: @ipdrecord.id, parent_folder_id: '560cc6f72b2e26135d000006', is_folder: 'N')
        end
        unless after_surgery_1[:asset_path].nil?
          PatientSummaryAssetUpload.create(asset_path: params[:after_surgery_1][:asset_path], name: params[:after_surgery_1][:name], patient_id: @ipdrecord.patient_id, source: 'after_surgery_1', ipdrecord_id: @ipdrecord.id, parent_folder_id: '560cc6f72b2e26135d000006', is_folder: 'N')
        end
        unless after_surgery_2[:asset_path].nil?
          PatientSummaryAssetUpload.create(asset_path: params[:after_surgery_2][:asset_path], name: params[:after_surgery_2][:name], patient_id: @ipdrecord.patient_id, source: 'after_surgery_2', ipdrecord_id: @ipdrecord.id, parent_folder_id: '560cc6f72b2e26135d000006', is_folder: 'N')
        end
      end

      def update_patient_assets
        befor_surgery_1 = params[:before_surgery_1]
        befor_surgery_2 = params[:before_surgery_2]
        after_surgery_1 = params[:after_surgery_1]
        after_surgery_2 = params[:after_surgery_2]
        unless befor_surgery_1.nil?
          if params[:before_surgery_1][:id].blank? && params[:before_surgery_1][:asset_path]
            PatientSummaryAssetUpload.create(asset_path: params[:before_surgery_1][:asset_path], name: params[:before_surgery_1][:name], patient_id: @ipdrecord.patient_id, source: 'before_surgery_1', ipdrecord_id: @ipdrecord.id, parent_folder_id: '560cc6f72b2e26135d000006', is_folder: 'N')
          elsif PatientSummaryAssetUpload.find_by(id: params[:before_surgery_1][:id])
            PatientSummaryAssetUpload.find_by(id: params[:before_surgery_1][:id]).update(asset_path: params[:before_surgery_1][:asset_path], name: params[:before_surgery_1][:name])
          end
        end
        unless befor_surgery_2.nil?
          if params[:before_surgery_2][:id].blank? && params[:before_surgery_2][:asset_path]
            PatientSummaryAssetUpload.create(asset_path: params[:before_surgery_2][:asset_path], name: params[:before_surgery_2][:name], patient_id: @ipdrecord.patient_id, source: 'before_surgery_2', ipdrecord_id: @ipdrecord.id, parent_folder_id: '560cc6f72b2e26135d000006', is_folder: 'N')
          elsif PatientSummaryAssetUpload.find_by(id: params[:before_surgery_2][:id])
            PatientSummaryAssetUpload.find_by(id: params[:before_surgery_2][:id]).update(asset_path: params[:before_surgery_2][:asset_path], name: params[:before_surgery_2][:name])
          end
        end
        unless after_surgery_1.nil?
          if params[:after_surgery_1][:id].blank? && params[:after_surgery_1][:asset_path]
            PatientSummaryAssetUpload.create(asset_path: params[:after_surgery_1][:asset_path], name: params[:after_surgery_1][:name], patient_id: @ipdrecord.patient_id, source: 'after_surgery_1', ipdrecord_id: @ipdrecord.id, parent_folder_id: '560cc6f72b2e26135d000006', is_folder: 'N')
          elsif PatientSummaryAssetUpload.find_by(id: params[:after_surgery_1][:id])
            PatientSummaryAssetUpload.find_by(id: params[:after_surgery_1][:id]).update(asset_path: params[:after_surgery_1][:asset_path], name: params[:after_surgery_1][:name])
          end
        end
        unless after_surgery_2.nil?
          if params[:after_surgery_2][:id].blank? && params[:after_surgery_2][:asset_path]
            PatientSummaryAssetUpload.create(asset_path: params[:after_surgery_2][:asset_path], name: params[:after_surgery_2][:name], patient_id: @ipdrecord.patient_id, source: 'after_surgery_2', ipdrecord_id: @ipdrecord.id, parent_folder_id: '560cc6f72b2e26135d000006', is_folder: 'N')
          elsif PatientSummaryAssetUpload.find_by(id: params[:after_surgery_2][:id])
            PatientSummaryAssetUpload.find_by(id: params[:after_surgery_2][:id]).update(asset_path: params[:after_surgery_2][:asset_path], name: params[:after_surgery_2][:name])
          end
        end
      end

      def ipd_record_params
        params.require(:inpatient_ipd_record).permit!
      end

      def delete_all_b4_update
        @ipdrecord.inventorymedication.delete_all
        @ipdrecord.inventoryconsumables.delete_all
        @ipdrecord.inventorypack.delete_all
        @ipdrecord.inventoryprep.delete_all
        @ipdrecord.inventorydressings.delete_all
        @ipdrecord.inventoryinstrument.delete_all
        @ipdrecord.inventoryimplants.delete_all
        @ipdrecord.inventoryswabs.delete_all
      end

      def time_calculation
        if @ipdrecord.patient_entry_time.present? && @ipdrecord.patient_exit_time.present?
          time_total_sec = @ipdrecord.patient_exit_time - @ipdrecord.patient_entry_time
          time_in_hours = ((time_total_sec / 60) / 60).to_i
          time_in_minutes = (time_total_sec / 60).to_i - (time_in_hours * 60)
          time_in_seconds = time_total_sec - ((time_total_sec / 60).to_i * 60)
          time_to_save = time_in_hours.abs.to_s + 'h ' + time_in_minutes.abs.to_s + 'm ' + time_in_seconds.round.abs.to_s + 's'
          @ipdrecord.update_attributes(patient_entry_exit_time: time_to_save)
        end

        if @ipdrecord.anesthesia_start_time.present? && @ipdrecord.anesthesia_end_time.present?
          time_total_sec = @ipdrecord.anesthesia_end_time - @ipdrecord.anesthesia_start_time
          time_in_hours = ((time_total_sec / 60) / 60).to_i
          time_in_minutes = (time_total_sec / 60).to_i - (time_in_hours * 60)
          time_in_seconds = time_total_sec - ((time_total_sec / 60).to_i * 60)
          time_to_save = time_in_hours.abs.to_s + 'h ' + time_in_minutes.abs.to_s + 'm ' + time_in_seconds.round.abs.to_s + 's'
          @ipdrecord.update_attributes(anesthesia_start_end_time: time_to_save)
        end

        if @ipdrecord.surgery_start_time.present? && @ipdrecord.surgery_end_time.present?
          time_total_sec = @ipdrecord.surgery_end_time - @ipdrecord.surgery_start_time
          time_in_hours = ((time_total_sec / 60) / 60).to_i
          time_in_minutes = (time_total_sec / 60).to_i - (time_in_hours * 60)
          time_in_seconds = time_total_sec - ((time_total_sec / 60).to_i * 60)
          time_to_save = time_in_hours.abs.to_s + 'h ' + time_in_minutes.abs.to_s + 'm ' + time_in_seconds.round.abs.to_s + 's'
          @ipdrecord.update_attributes(surgery_start_end_time: time_to_save)
        end
      end

      def update_admission_fields
        if @template_type == 'admissionnote'
          @admission.update_attributes(admissionreason: @ipdrecord.admissionreason, dischargedate: @ipdrecord.expected_discharge_date)
        end
      end

      def update_insurance_fields
        if @template_type == 'admissionnote'
          @tpa.update_attributes(insurance_name: @ipdrecord.insurance_name, tpa_name: @ipdrecord.tpa_name)
        end
      end

      def add_personnel
        unless params[:inpatient_ipd_record][:surgeon1] == ''
          surgeon1 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:surgeon1], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless surgeon1
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:surgeon1], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:surgeon2] == ''
          surgeon2 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:surgeon2], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless surgeon2
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:surgeon2], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:surgeon3] == ''
          surgeon3 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:surgeon3], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless surgeon3
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:surgeon3], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:surgeon_assistant1] == ''
          surgeon_assistant1 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:surgeon_assistant1], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless surgeon_assistant1
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:surgeon_assistant1], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:surgeon_assistant2] == ''
          surgeon_assistant2 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:surgeon_assistant2], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless surgeon_assistant2
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:surgeon_assistant2], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:surgeon_assistant3] == ''
          surgeon_assistant3 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:surgeon_assistant3], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless surgeon_assistant3
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:surgeon_assistant3], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:anaesthetist1] == ''
          anaesthetist1 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:anaesthetist1], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless anaesthetist1
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:anaesthetist1], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:anaesthetist2] == ''
          anaesthetist2 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:anaesthetist2], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless anaesthetist2
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:anaesthetist2], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:anaesthetist3] == ''
          anaesthetist3 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:anaesthetist3], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless anaesthetist3
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:anaesthetist3], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:anesthetic_assistant1] == ''
          anesthetic_assistant1 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:anesthetic_assistant1], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless anesthetic_assistant1
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:anesthetic_assistant1], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:anesthetic_assistant2] == ''
          anesthetic_assistant2 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:anesthetic_assistant2], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless anesthetic_assistant2
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:anesthetic_assistant2], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:anesthetic_assistant3] == ''
          anesthetic_assistant3 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:anesthetic_assistant3], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless anesthetic_assistant3
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:anesthetic_assistant3], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end

        unless params[:inpatient_ipd_record][:circulating_nurse1] == ''
          circulating_nurse1 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:circulating_nurse1], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless circulating_nurse1
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:circulating_nurse1], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:circulating_nurse2] == ''
          circulating_nurse2 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:circulating_nurse2], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless circulating_nurse2
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:circulating_nurse2], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:circulating_nurse3] == ''
          circulating_nurse3 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:circulating_nurse3], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless circulating_nurse3
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:circulating_nurse3], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end

        unless params[:inpatient_ipd_record][:scrub_nurse1] == ''
          scrub_nurse1 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:scrub_nurse1], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless scrub_nurse1
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:scrub_nurse1], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:scrub_nurse2] == ''
          scrub_nurse2 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:scrub_nurse2], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless scrub_nurse2
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:scrub_nurse2], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:scrub_nurse3] == ''
          scrub_nurse3 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:scrub_nurse3], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless scrub_nurse3
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:scrub_nurse3], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end

        unless params[:inpatient_ipd_record][:other_staff1] == ''
          other_staff1 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:other_staff1], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless other_staff1
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:other_staff1], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:other_staff2] == ''
          other_staff2 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:other_staff2], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless other_staff2
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:other_staff2], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
        unless params[:inpatient_ipd_record][:other_staff3] == ''
          other_staff3 = Inpatient::SurgeryPersonnel.find_by(name: params[:inpatient_ipd_record][:other_staff3], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s)
          unless other_staff3
            Inpatient::SurgeryPersonnel.create(name: params[:inpatient_ipd_record][:other_staff3], specialty_id: @ipdrecord.specialty_id, organisation_id: current_user.organisation_id.to_s, facility_id: current_facility.id)
          end
        end
      end

      # def start_cinical_workflow
      #   patient = Patient.find_by(id: @temp_appointment.patient_id)
      #   if current_user.department.name == "Ophthalmology"
      #     OpdClinicalWorkflow::Ophthalmology.create(:patient_id => @temp_appointment.patient_id,appointment_id: @temp_appointment.id.to_s,facility_id: @ipdrecord.facility_id.to_s,organisation_id: current_user.organisation.id,user_id: current_user.id,appointmentdate: @temp_appointment.appointmentdate,patient_name: patient.fullname,doctor_ids: [@temp_appointment.doctor.to_s])
      #   elsif current_user.department.name == "Orthopedics"
      #     OpdClinicalWorkflow::Orthopedics.create(:patient_id =>  @temp_appointment.patient_id,appointment_id: @temp_appointment.id.to_s,facility_id: @ipdrecord.facility_id.to_s,organisation_id: current_user.organisation.id,user_id: current_user.id,appointmentdate: @temp_appointment.appointmentdate,patient_name: patient.fullname,doctor_ids: [@temp_appointment.doctor.to_s])
      #   end
      # end

      def procedure_operative
        @ipdrecord_operative = Inpatient::IpdRecord.find_by(admission_id: @admission.id.to_s, template_type: 'operativenote')
        if @ipdrecord_operative.present?
          unless @ipdrecord_operative.procedure_note.nil?
            unless @ipdrecord_operative.procedure_note == '<br>'
              @procedure_notes = @ipdrecord_operative.procedure_note.html_safe
            end
          end
        end
      end

      def history_params
        params.require(:patient).permit!
      end
    end
  end
end
