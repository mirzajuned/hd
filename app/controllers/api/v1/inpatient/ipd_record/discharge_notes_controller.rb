module Api
  module V1
    class Inpatient::IpdRecord::DischargeNotesController < ApiApplicationController
      before_action :authorize_token
      before_action :find_ipd_record, only: [:new, :edit, :print, :show, :print, :print_flags]
      before_action :convert_to_json, :find_ipd_record_for_write, only: [:create, :update]
      before_action :discharge_note_form_params, only: [:new, :edit]
      before_action :discharge_note, only: [:show, :edit, :update, :print, :print_flags]

      def new
        @discharge_note = @ipdrecord.build_discharge_note
        @procedure = @ipdrecord.procedure.where(procedurestage: "P")
        @diagnosislist = @ipdrecord.diagnosislist
        @current_department = current_user.department.name.downcase
        @url = "/inpatient/ipd_record/discharge_note/#{@current_department}_notes"
        @method = "POST"
        @date = Date.current.midnight
        clinical_note_data
        # images_params
        @record_history = @discharge_note.record_histories.new
        # respond_to do |format|
        #   format.js { render "inpatient/ipd_record/discharge_note/form" }
        # end
      end

      def create
        @discharge_note = @ipdrecord.build_discharge_note
        if @ipdrecord.update(discharge_note_params)
          discharge_note_view_params
          # images_params
          create_followup_appointment
          clinical_note_data
          # operative_note
          # create_patient_assets
          operative_procedure_note
          # render json: {'success': true}

          Rails.logger.info("=======================================@discharge_note===#{@discharge_note.to_a}")
          Rails.logger.info("=======================================@@discharge_note.followup_appointment_id===#{@discharge_note.followup_appointment_id}")

          Patients::Summary::TimelineWorker.call({ event_name: "IPD_RECORD", sub_event_name: "CREATED", ipd_record_id: @ipdrecord.id, user_id: current_user.id, user_name: current_user.fullname, ipdtemplatetype: "Discharge Note" })
          if @new == true
            Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "SCHEDULED", appointment_id: @discharge_note.followup_appointment_id, user_id: current_user.id, user_name: current_user.fullname, workflow: current_facility.clinical_workflow })
          end
          IpdRecordJob.perform_later(@ipdrecord.id.to_s, @discharge_note.id.to_s, 'discharge_note')
        end
      end

      def show
        discharge_note_view_params
        clinical_note_data
        # operative_note
        respond_to do |format|
          format.js { render "inpatient/ipd_record/discharge_note/show" }
        end
      end

      def edit
        @date = Date.current.midnight
        clinical_note_data
        # images_params
        @procedure = @ipdrecord.procedure.where(procedurestage: "P")
        @diagnosislist = @ipdrecord.diagnosislist
        @current_department = current_user.department.name.downcase
        @url = "/inpatient/ipd_record/discharge_note/#{@current_department}_notes/#{@ipdrecord.id}"
        @method = "PATCH"
        @record_history = @discharge_note.record_histories.new
        # respond_to do |format|
        #   format.js { render "inpatient/ipd_record/discharge_note/form" }
        # end
      end

      def update
        @discharge_note = @ipdrecord.discharge_note
        if @ipdrecord.update_attributes(discharge_note_update_params)
          discharge_note_view_params
          # images_params
          create_followup_appointment
          clinical_note_data
          # operative_note
          # update_patient_assets
          operative_procedure_note
          # render json: {'success': true}

          Rails.logger.info("=============update==========================@discharge_note===#{@discharge_note.to_a}")
          Rails.logger.info("================update=======================@@discharge_note.followup_appointment_id===#{@discharge_note.followup_appointment_id}")

          Patients::Summary::TimelineWorker.call({ event_name: "IPD_RECORD", sub_event_name: "UPDATED", ipd_record_id: @ipdrecord.id, user_id: current_user.id, user_name: current_user.fullname, ipdtemplatetype: "Discharge Note" })
          if @new == true
            Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "SCHEDULED", appointment_id: @discharge_note.followup_appointment_id, user_id: current_user.id, user_name: current_user.fullname, workflow: current_facility.clinical_workflow })
          elsif @edit == true
            Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "RESCHEDULED", appointment_id: @discharge_note.followup_appointment_id, user_id: current_user.id, user_name: current_user.fullname, workflow: current_facility.clinical_workflow })
          end
          IpdRecordJob.perform_later(@ipdrecord.id.to_s, @discharge_note.id.to_s, 'discharge_note')
        end
      end

      def print_flags
        @flag = params[:flag]
        @discharge_note.update_attributes(print_procedure: @flag)
        render json: { flag: @flag, "success": true }
      end

      def print
        @view = params[:view]
        @patient = Patient.find_by(id: @discharge_note.patient_id)
        @admission = Admission.find_by(id: @discharge_note.admission_id)
        @tpa = ::Inpatient::Insurance::Tpa.find_by(admission_id: @discharge_note.admission_id)
        @department = current_user.department.name.downcase
        @organisation = current_user.organisation
        @followup_doctor = User.find_by(id: @discharge_note.followup_doctor_id)
        @followup_facility = Facility.find_by(id: @discharge_note.followup_facility)
        clinical_note_data
        # operative_note
        operative_procedure_note
        @procedure = @ipdrecord.procedure.where(procedurestage: "P")
        @diagnosislist = @ipdrecord.diagnosislist
        setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, "IPD")
        @print_settings = setting_service.select_print_setting
        @logo = @print_settings[1]
        respond_to do |format|
          format.pdf { render :template => "inpatient/ipd_record/discharge_note/print", :pdf => "", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 10, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { :top => @print_settings[0]['header_height'].to_f * 10, :bottom => 40 }, encoding: 'utf8' }
        end
        # Patients::Summary::TimelineWorker.call({event_name: "IPD_RECORD", sub_event_name: "PRINTED", ipd_record_id: @discharge_note.id, user_id: current_user.id, user_name: current_user.fullname })
      end

      private

      def discharge_note_form_params
        current_user = current_user
        @current_facility = current_facility
        @admission = Admission.find_by(id: params[:admission_id])
        @tpa = ::Inpatient::Insurance::Tpa.find_by(admission_id: @admission.id)
        @patient = @admission.patient
        @medication_instruction_set = Global.medication_instruction_option.sets.map { |p| ["#{p[:en]}", "#{p[:id]}"] } << 'Add a text Box'
        @patient_identifier_id = @patient.patient_identifier_id
        @patient_mrn = @patient.patient_mrn
        @age_gender = @patient.patient_age_gender
        @ots = OtSchedule.where(admission_id: @admission.id, operation_done: true, is_deleted: false).order(ottime: :desc)
        @user = User.where(:role_ids.in => [158965000], :facility_ids.in => [current_facility.id])[0]
        # Asset Upload
      end

      def images_params
        @image_before_surgery_1 = PatientSummaryAssetUpload.find_by(patient_id: @patient.id, source: "before_surgery_1", ipdrecord_id: @discharge_note.id)
        @image_before_surgery_2 = PatientSummaryAssetUpload.find_by(patient_id: @patient.id, source: "before_surgery_2", ipdrecord_id: @discharge_note.id)
        @image_after_surgery_1 = PatientSummaryAssetUpload.find_by(patient_id: @patient.id, source: "after_surgery_1", ipdrecord_id: @discharge_note.id)
        @image_after_surgery_2 = PatientSummaryAssetUpload.find_by(patient_id: @patient.id, source: "after_surgery_2", ipdrecord_id: @discharge_note.id)
      end

      def discharge_note_view_params
        @admission = Admission.find_by(id: @ipdrecord.admission_id)
        @patient = Patient.find_by(id: @ipdrecord.patient_id)
        @tpa = ::Inpatient::Insurance::Tpa.find_by(admission_id: @ipdrecord.admission_id)
        @procedure = @ipdrecord.procedure.where(procedurestage: "P")
        @diagnosislist = @ipdrecord.diagnosislist
      end

      def discharge_note_params
        params.require(:inpatient_ipd_record).permit(admission_attributes: [:id, :admissiondate, :dischargedate, :dischargetime], discharge_note_attributes: [:note_date, :print_procedure, :note_time, :note_created_at, :organisation_id, :admission_id, :patient_id, :user_id, :department, :specalityname, :specalityid, :ward_id, :room_id, :bed_id, :daycare, :patient_name, :patient_age, :patient_gender, :mr_no, :patient_identifier_id, :check_all, :discharge_intimation, :band_removed, :intracath_removed, :discharge_summary_given, :correct_dose_explained, :wound_dressing_needs, :process_of_followup_explained, :pending_reports_given, :emergency_contact_explained, :admission_date, :discharge_date, :discharge_time, :investigation_notes, :treatment_type, :treatment_notes, :precautions, :followup_date, :followup_time, :followup_doctor_id, :followup_facility, :appointment_category_id, :appointment_type_id, :advicemanagementplan, :bookappointment, :diagnosis, :procedure, :patient_condition, :procedure_code, :terms, :physiotherapy, medicationsets: [], treatmentmedication_attributes: [:medicinename, :medicinetype, :medicinequantity, :medicinefrequency, :medicineduration, :medicinedurationoption, :taper_id, :eyeside, :medicineinstructions, :instruction, :pharmacy_item_id, :_destroy], record_histories_attributes: [:user_id, :action, :actiontime, :template_type]])
      end

      def discharge_note_update_params
        params.require(:inpatient_ipd_record).permit(admission_attributes: [:id, :admissiondate, :dischargedate, :dischargetime], discharge_note_attributes: [:id, :print_procedure, :note_date, :note_time, :note_created_at, :organisation_id, :admission_id, :patient_id, :user_id, :department, :specalityname, :specalityid, :ward_id, :room_id, :bed_id, :daycare, :patient_name, :patient_age, :patient_gender, :mr_no, :patient_identifier_id, :check_all, :discharge_intimation, :band_removed, :intracath_removed, :discharge_summary_given, :correct_dose_explained, :wound_dressing_needs, :process_of_followup_explained, :pending_reports_given, :emergency_contact_explained, :admission_date, :discharge_date, :discharge_time, :investigation_notes, :treatment_type, :treatment_notes, :precautions, :followup_date, :followup_time, :followup_doctor_id, :followup_facility, :appointment_category_id, :appointment_type_id, :advicemanagementplan, :bookappointment, :diagnosis, :procedure, :patient_condition, :procedure_code, :terms, :physiotherapy, medicationsets: [], treatmentmedication_attributes: [:id, :medicinename, :medicinetype, :medicinequantity, :medicinefrequency, :medicineduration, :medicinedurationoption, :taper_id, :eyeside, :medicineinstructions, :instruction, :pharmacy_item_id, :_destroy], record_histories_attributes: [:user_id, :action, :actiontime, :template_type]])
      end

      def discharge_note
        @discharge_note = @ipdrecord.discharge_note
      end

      def clinical_note_data
        @clinical_note = @ipdrecord.clinical_note
        @clinical_note_investigation = @clinical_note.try(:investigations).to_s
      end

      def operative_note
      end

      def create_followup_appointment
        if @discharge_note.bookappointment == "true" && @discharge_note.followup_date != "" && @discharge_note.followup_date != nil
          if @discharge_note.followup_facility
            @appointment_facility = @discharge_note.followup_facility
          else
            @appointment_facility = current_facility.id.to_s
          end

          @followup_date = Time.zone.parse(@discharge_note.followup_date).strftime("%d/%m/%Y")
          @appointment_type_id = @discharge_note.appointment_type_id

          if @discharge_note.followup_time.split(" ")[1] == "AM"
            unless @discharge_note.followup_time.split(":")[0] == "12"
              @hours = @discharge_note.followup_time.split(":")[0]
            else
              @hours = 00
            end
          else
            unless @discharge_note.followup_time.split(":")[0] == "12"
              @hours = @discharge_note.followup_time.split(":")[0].to_i + 12
            else
              @hours = @discharge_note.followup_time.split(":")[0]
            end
          end
          @minutes = @discharge_note.followup_time.split(":")[1].to_i
          @date = @followup_date.split("/")[0]
          @month = @followup_date.split("/")[1]
          @year = @followup_date.split("/")[2]
          @followup_date_time = Time.new(@year, @month, @date, @hours, @minutes, 0)

          @appointment_type_id = params[:inpatient_ipd_record][:discharge_note_attributes][:appointment_type_id]
          @followup_doctor = User.find_by(id: @discharge_note.followup_doctor_id)
          @followup_facility = Facility.find_by(id: @discharge_note.followup_facility)

          Rails.logger.info("============sxscscdddddddddsc==================0=========@@followupappointment===#{@followupappointment.to_a}")

          if @discharge_note.followup_appointment_id == nil || @discharge_note.followup_appointment_id == ""
            @followupappointment = Appointment.new(patient_id: @discharge_note.patient_id.to_s, department_id: "485396012", departmenttype: "440655000", facility_id: @appointment_facility, appointmentdate: @followup_date_time, start_time: @followup_date_time, consultant_id: @followup_doctor.id, appointment_type_id: @appointment_type_id, appointmentstatus: 416774000, ref_doc_name: "", ref_doc_place: "", user_id: current_user.id, display_id: CommonHelper::get_opd_record_identifier(current_user), patient_name: @patient.fullname)
            Rails.logger.info("============sxscscsc==================0=========@@followupappointment===#{@followupappointment.to_a}")
            @followupappointment.organisation_id = current_facility.organisation_id
            puts "mannu--------------------------"
            if @followupappointment.save!

              Rails.logger.info("==============================0=========@@followupappointment===#{@followupappointment.to_a}")
              Rails.logger.info("==============================0=========@@@discharge_note===#{@discharge_note.to_a}")

              @discharge_note.update_attributes(followup_appointment_id: @followupappointment.id)
              @followupappointment.update(end_time: @followupappointment.start_time + 10.minutes)

              Rails.logger.info("==============================10=========@@@discharge_note===#{@discharge_note.to_a}")
              # # Code for Tracker
              # @patient_tracker = PatientTracker.find_by(patient_id: @followupappointment.patient_id, tracker_removed: false)
              # unless @patient_tracker.nil?
              #   if @patient_tracker.tracker_type == "Session"
              #     @new_array = @patient_tracker.session_dates << Date.current
              #     @patient_tracker.update(current_session: @patient_tracker.current_session.to_i + 1, session_dates: @new_array)
              #   end
              # end
            end

            @temp_appointment = @followupappointment
            patient = Patient.find_by(id: @temp_appointment.patient_id)
            # eval("OpdClinicalWorkflow::" + current_user.department.name.to_s).create(:patient_id => @temp_appointment.patient_id,appointment_id: @temp_appointment.id.to_s,facility_id: @discharge_note.facility_id.to_s,organisation_id: current_user.organisation.id,user_id: current_user.id,appointmentdate: @temp_appointment.appointmentdate,patient_name: @patient.fullname,doctor_ids: [@temp_appointment.doctor.to_s])
            @new = true
          else
            Appointment.find_by(id: @discharge_note.followup_appointment_id).update_attributes(appointmentdate: @followup_date_time, start_time: @followup_date_time, end_time: @followup_date_time + 10.minutes, consultant_id: @followup_doctor.id, appointment_type_id: @appointment_type_id, facility_id: @appointment_facility)

            @followup_workflow = OpdClinicalWorkflow.find_by(appointment_id: @discharge_note.followup_appointment_id.to_s)

            Rails.logger.info("========1111111=========@@@discharge_note===#{@discharge_note.to_a}")
            Rails.logger.info("========1111111=========@@@discharge_note===#{@followup_workflow.to_a}")

            unless @followup_workflow == nil
              doctors = @followup_workflow.consultant_ids << @followup_doctor.id.to_s
              @followup_workflow.update(appointmentdate: @followup_date_time, consultant_ids: doctors)
            end
            @edit = true
          end

          Rails.logger.info("==============================1=========@@followupappointment===#{@followupappointment.to_a}")

        end
      end

      # def create_patient_assets
      #   before_surgery_1=params[:before_surgery_1]
      #   before_surgery_2=params[:before_surgery_2]
      #   after_surgery_1=params[:after_surgery_1]
      #   after_surgery_2=params[:after_surgery_2]
      #   unless before_surgery_1[:asset_path].nil?
      #     PatientSummaryAssetUpload.create(asset_path: params[:before_surgery_1][:asset_path],name: params[:before_surgery_1][:name],patient_id: @discharge_note.patient_id,source: "before_surgery_1",ipdrecord_id: @discharge_note.id,:parent_folder_id => "560cc6f72b2e26135d000006",is_folder: "N")
      #   end
      #   unless before_surgery_2[:asset_path].nil?
      #     PatientSummaryAssetUpload.create(asset_path: params[:before_surgery_2][:asset_path],name: params[:before_surgery_2][:name],patient_id: @discharge_note.patient_id,source: "before_surgery_2",ipdrecord_id: @discharge_note.id,:parent_folder_id => "560cc6f72b2e26135d000006",is_folder: "N")
      #   end
      #   unless after_surgery_1[:asset_path].nil?
      #     PatientSummaryAssetUpload.create(asset_path: params[:after_surgery_1][:asset_path],name: params[:after_surgery_1][:name],patient_id: @discharge_note.patient_id,source: "after_surgery_1",ipdrecord_id: @discharge_note.id,:parent_folder_id => "560cc6f72b2e26135d000006",is_folder: "N")
      #   end
      #   unless after_surgery_2[:asset_path].nil?
      #     PatientSummaryAssetUpload.create(asset_path: params[:after_surgery_2][:asset_path],name: params[:after_surgery_2][:name],patient_id: @discharge_note.patient_id,source: "after_surgery_2",ipdrecord_id: @discharge_note.id,:parent_folder_id => "560cc6f72b2e26135d000006",is_folder: "N")
      #   end
      # end

      # def update_patient_assets
      #   before_surgery_1=params[:before_surgery_1]
      #   before_surgery_2=params[:before_surgery_2]
      #   after_surgery_1=params[:after_surgery_1]
      #   after_surgery_2=params[:after_surgery_2]
      #   unless before_surgery_1.nil?
      #     if params[:before_surgery_1][:id].blank? && params[:before_surgery_1][:asset_path]
      #       PatientSummaryAssetUpload.create(asset_path: params[:before_surgery_1][:asset_path],name: params[:before_surgery_1][:name],patient_id: @discharge_note.patient_id,source: "before_surgery_1",ipdrecord_id: @discharge_note.id,:parent_folder_id => "560cc6f72b2e26135d000006",is_folder: "N")
      #     elsif PatientSummaryAssetUpload.find_by(id: params[:before_surgery_1][:id])
      #       PatientSummaryAssetUpload.find_by(id: params[:before_surgery_1][:id]).update(asset_path: params[:before_surgery_1][:asset_path],name: params[:before_surgery_1][:name])
      #     end
      #   end
      #   unless before_surgery_2.nil?
      #     if params[:before_surgery_2][:id].blank? && params[:before_surgery_2][:asset_path]
      #       PatientSummaryAssetUpload.create(asset_path: params[:before_surgery_2][:asset_path],name: params[:before_surgery_2][:name],patient_id: @discharge_note.patient_id,source: "before_surgery_2",ipdrecord_id: @discharge_note.id,:parent_folder_id => "560cc6f72b2e26135d000006",is_folder: "N")
      #     elsif  PatientSummaryAssetUpload.find_by(id: params[:before_surgery_2][:id])
      #       PatientSummaryAssetUpload.find_by(id: params[:before_surgery_2][:id]).update(asset_path: params[:before_surgery_2][:asset_path],name: params[:before_surgery_2][:name])
      #     end
      #   end
      #   unless after_surgery_1.nil?
      #     if params[:after_surgery_1][:id].blank? && params[:after_surgery_1][:asset_path]
      #       PatientSummaryAssetUpload.create(asset_path: params[:after_surgery_1][:asset_path],name: params[:after_surgery_1][:name],patient_id: @discharge_note.patient_id,source: "after_surgery_1",ipdrecord_id: @discharge_note.id,:parent_folder_id => "560cc6f72b2e26135d000006",is_folder: "N")
      #     elsif PatientSummaryAssetUpload.find_by(id: params[:after_surgery_1][:id])
      #       PatientSummaryAssetUpload.find_by(id: params[:after_surgery_1][:id]).update(asset_path: params[:after_surgery_1][:asset_path],name: params[:after_surgery_1][:name])
      #     end
      #   end
      #   unless after_surgery_2.nil?
      #     if params[:after_surgery_2][:id].blank? && params[:after_surgery_2][:asset_path]
      #       PatientSummaryAssetUpload.create(asset_path: params[:after_surgery_2][:asset_path],name: params[:after_surgery_2][:name],patient_id: @discharge_note.patient_id,source: "after_surgery_2",ipdrecord_id: @discharge_note.id,:parent_folder_id => "560cc6f72b2e26135d000006",is_folder: "N")
      #     elsif PatientSummaryAssetUpload.find_by(id: params[:after_surgery_2][:id])
      #       PatientSummaryAssetUpload.find_by(id: params[:after_surgery_2][:id]).update(asset_path: params[:after_surgery_2][:asset_path],name: params[:after_surgery_2][:name])
      #     end
      #   end
      # end

      def operative_procedure_note
        if @operative_note.present?
          unless @operative_note.procedure_note.nil?
            unless @operative_note.procedure_note == "<br>"
              @procedure_notes = @operative_note.procedure_note.html_safe()
            end
          end
        end
      end

      def convert_to_json
        params[:inpatient_ipd_record] = eval(params[:inpatient_ipd_record])
        # params[:patient] = eval(params[:patient])
        # params[:inpatient_ipd_record] = JSON.parse(params[:inpatient_ipd_record].gsub(/:(\w+)/){"\"#{$1}\""}.gsub('=>', ':'))
        # params[:patient] = JSON.parse(params[:patient].gsub(/:(\w+)/){"\"#{$1}\""}.gsub('=>', ':'))
      end

      def find_ipd_record
        @ipdrecord = ::Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
      end

      def find_ipd_record_for_write
        @ipdrecord = ::Inpatient::IpdRecord.find_by(admission_id: params[:inpatient_ipd_record][:discharge_note_attributes][:admission_id])
      end
    end
  end
end
