module Api
  module V1
    class OtsController < ApiApplicationController
      before_action :authorize_token

      before_action :ot_schedule, only: [:edit, :update, :link_ot, :unlink_ot]
      before_action :print_params, only: [:print_all_list, :print_scheduled_list, :print_admitted_list, :print_engaged_list, :print_completed_list]
      before_action :find_patient, only: [:new, :edit]
      before_action :find_admission, only: [:new, :edit]
      before_action :get_ot_form_values, only: [:edit]

      def new
        @patient_type = PatientType.where(is_active: true, organisation_id: current_user.organisation_id).pluck(:label, :id)
        @occupation_list = Global.send('occupation_list').send('sets').pluck(:name, :snomedcode)
        @ot_schedules = OtSchedule.where(patient_id: @patient.id.to_s, is_deleted: false, is_engaged: false, operation_done: false).sort(ottime: :asc)
        @ot_schedule = OtSchedule.new
        get_ot_form_values
        set_procedure_diagnosis_data_for_ot_schedule
      end

      def create
        # Create/Update Patient
        unless params[:ot_schedule][:patient_id].present?
          @patient = Patients::CreateService.call(params, current_user, current_facility) # Call Patient CreateService
        else
          @patient = Patients::UpdateService.call(params[:ot_schedule][:patient_id], params, current_user) # Call Patient UpdateService
        end

        @calculate_age = @patient.calculate_age
        # Create New OT
        if @patient
          # Check Whether End Time is not Less than Start Time
          start_time, end_time = Time.zone.parse(params[:ot_schedule][:ottime]), Time.zone.parse(params[:ot_schedule][:otendtime])
          params[:ot_schedule][:otendtime] = start_time + 30.minutes if start_time > end_time

          params[:ot_schedule][:patient_id] = @patient.id.to_s
          params[:ot_schedule][:display_id] = CommonHelper::get_ipd_record_identifier(current_user)
          @ot_schedule = OtSchedule.new(ot_params)
          if @ot_schedule.save
            update_procedures
            @admission_list_view = AdmissionListView.find_by(admission_id: @ot_schedule.admission_id)
            @ot_schedules = OtSchedule.where(patient_id: @patient.id.to_s, is_deleted: false)
            respond_to do |format|
              format.js { render 'ots/close' }
            end
            # get_daily_reports
            # Reports::Ipd::Ots.new(@ot_schedule).call
            Patients::Summary::TimelineWorker.call({ event_name: "IPD_OT", sub_event_name: "SCHEDULED", ot_id: @ot_schedule.id, user_id: current_user.id, user_name: current_user.fullname })
          end
        end
      end

      def edit
        set_procedure_diagnosis_data_for_ot_schedule
      end

      def update
        start_time, end_time = Time.zone.parse(params[:ot_schedule][:ottime]), Time.zone.parse(params[:ot_schedule][:otendtime])
        params[:ot_schedule][:otendtime] = start_time + 30.minutes if start_time > end_time
        if @ot_schedule.update_attributes(ot_params)
          @patient = Patient.find_by(id: @ot_schedule.patient_id)
          @ot_schedules = OtSchedule.where(patient_id: @ot_schedule.patient.id.to_s, is_deleted: false)
          if @ot_schedule.admission_id
            if @ot_schedule.admission.patient_arrived
              @active_tab = "Admitted"
            else
              @active_tab = "Scheduled"
            end
          else
            @active_tab = "Scheduled"
          end

          respond_to do |format|
            format.js { render 'close' }
          end
          # get_daily_reports
          # Reports::Ipd::Ots.new(@ot_schedule).call
          Patients::Summary::TimelineWorker.call({ event_name: "IPD_OT", sub_event_name: "RESCHEDULED", ot_id: @ot_schedule.id, user_id: current_user.id, user_name: current_user.fullname })
        else
          redirect_to 'edit'
        end
      end

      def search_ot_list
        if params[:active_doctor]
          @active_doctor = params[:active_doctor]
        else
          if current_user.role_ids.include? 158965000
            @active_doctor = current_user.id.to_s
          end # else nil
        end
        @active_tab = params[:active_tab]
        @current_date = params[:current_date]
        unless @active_doctor == "all" || @active_doctor == nil
          @ot_list = OtListView.where(facility_id: current_facility.id.to_s, ot_date: @current_date, :patient_name => /#{Regexp.escape(params[:q])}/i).not.where(current_state: "Deleted")
        else
          @ot_list = OtListView.where(facility_id: current_facility.id.to_s, ot_date: @current_date, :patient_name => /#{Regexp.escape(params[:q])}/i, operating_doctor_id: @active_doctor).not.where(current_state: "Deleted")
        end
        if params[:q].present?
          if @active_tab == "All"
            @ot_list
          else
            @ot_list = @ot_list.where(current_state: @active_tab)
          end
        end
      end

      def get_users_from_facility
        @facility = Facility.find_by(id: params[:facility_id])
        @user = User.where(:facility_ids => params[:facility_id], :role_ids => 158965000, is_active: true).pluck("fullname", "id")
        render :json => @user.to_json
      end

      def link_ot
        @admission = Admission.find(params[:admission_id])
        @active_tab = ("Admitted" if @admission.patient_arrived) || "Scheduled"
        @ot_schedule.update_attributes(admission_id: @admission.id)
        Patients::Summary::TimelineWorker.call({ event_name: "IPD_OT", sub_event_name: "LINKED", ot_id: @ot_schedule.id, user_id: current_user.id, user_name: current_user.fullname })
        render :json => { success: true }
      end

      def unlink_ot
        @ot_schedule.update_attributes(admission_id: nil)
        Patients::Summary::TimelineWorker.call({ event_name: "IPD_OT", sub_event_name: "UNLINKED", ot_id: @ot_schedule.id, user_id: current_user.id, user_name: current_user.fullname })
        render :json => { success: true }
      end

      def print_all_list
        @ot_list = OtListView.where(facility_id: @facility.id, ot_date: @current_date).not.where(current_state: "Deleted").order(ot_time: :desc)
        if current_user.has_role?(:doctor)
          @ot_list = @ot_list.where(operating_doctor_id: current_user.id.to_s)
        end
        @opdrecord = OpdRecord.where(:patientid.in => @ot_list.pluck(:patient_id).map!(&:to_s)).not.where(templatetype: "optometrist")
        @type = "All"
        setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "all")
        @print_settings = setting_service.select_print_setting
        @logo = @print_settings[1]
        respond_to do |format|
          format.pdf { render :template => "ots/print_all_list", :pdf => "OtList", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, orientation: 'Landscape', :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
        end
      end

      def print_scheduled_list
        @ot_list = OtListView.where(facility_id: @facility.id, current_state: "Scheduled", ot_date: @current_date).order(ot_time: :desc)
        if current_user.has_role?(:doctor)
          @ot_list = @ot_list.where(operating_doctor_id: current_user.id.to_s)
        end
        @opdrecord = OpdRecord.where(:patientid.in => @ot_list.pluck(:patient_id).map!(&:to_s)).not.where(templatetype: "optometrist")
        @type = "Scheduled"
        setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "all")
        @print_settings = setting_service.select_print_setting
        @logo = @print_settings[1]
        respond_to do |format|
          format.pdf { render :template => "ots/print_scheduled_list", :pdf => "OtList", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, orientation: 'Landscape', :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
        end
      end

      def print_admitted_list
        @ot_list = OtListView.where(facility_id: @facility.id, current_state: "Admitted", ot_date: @current_date).order(ot_time: :desc)
        if current_user.has_role?(:doctor)
          @ot_list = @ot_list.where(operating_doctor_id: current_user.id.to_s)
        end
        @opdrecord = OpdRecord.where(:patientid.in => @ot_list.pluck(:patient_id).map!(&:to_s)).not.where(templatetype: "optometrist")
        @type = "Admitted"
        setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "all")
        @print_settings = setting_service.select_print_setting
        @logo = @print_settings[1]
        respond_to do |format|
          format.pdf { render :template => "ots/print_admitted_list", :pdf => "OtList", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, orientation: 'Landscape', :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
        end
      end

      def print_engaged_list
        @ot_list = OtListView.where(facility_id: @facility.id, current_state: "Engaged", ot_date: @current_date).order(ot_time: :desc)
        if current_user.has_role?(:doctor)
          @ot_list = @ot_list.where(operating_doctor_id: current_user.id.to_s)
        end
        @opdrecord = OpdRecord.where(:patientid.in => @ot_list.pluck(:patient_id).map!(&:to_s)).not.where(templatetype: "optometrist")
        @type = "Engaged"
        setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "all")
        @print_settings = setting_service.select_print_setting
        @logo = @print_settings[1]
        respond_to do |format|
          format.pdf { render :template => "ots/print_engaged_list", :pdf => "OtList", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, orientation: 'Landscape', :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
        end
      end

      def print_completed_list
        @ot_list = OtListView.where(facility_id: @facility.id, current_state: "Completed", ot_date: @current_date).order(ot_time: :desc)
        if current_user.has_role?(:doctor)
          @ot_list = @ot_list.where(operating_doctor_id: current_user.id.to_s)
        end
        @opdrecord = OpdRecord.where(:patientid.in => @ot_list.pluck(:patient_id).map!(&:to_s)).not.where(templatetype: "optometrist")
        @type = "Completed"
        setting_service = PrintSettingService.new(current_facility_id, current_user.id.to_s, "all")
        @print_settings = setting_service.select_print_setting
        @logo = @print_settings[1]
        respond_to do |format|
          format.pdf { render :template => "ots/print_completed_list", :pdf => "OtList", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, orientation: 'Landscape', :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
        end
      end

      private

      def ot_params
        params.require(:ot_schedule).permit(:admission_id, :patient_id, :user_id, :otdate, :ottime, :otendtime, :facility_id, :surgeonname, :theatreno)
      end

      def ot_schedule
        @ot_schedule = OtSchedule.find(params[:id])
      end

      def find_patient
        @patient = Patient.find_by(id: params[:patient_id]) || Patient.new
      end

      def find_admission
        @admission = Admission.find_by(patient_id: @patient.id, isdischarged: false, is_deleted: false)
      end

      def get_ot_form_values
        @current_date = @ot_schedule.otdate || Date.parse(params[:date]) || Date.current
        @current_time = @ot_schedule.ottime || Time.zone.parse(params[:time]) || Time.current
        @ot_end_time = @ot_schedule.otendtime || (@current_time + 30.minutes)
        @selected_facility = @ot_schedule.facility_id || params[:facility_id] || current_facility.id
        @selected_surgeonname = @ot_schedule.surgeonname || params[:doctor_id] || (current_user.id if current_user.role_ids.include?(158965000) && current_user.facility_ids.map(&:to_s).include?(@selected_facility.to_s)) || User.where(role_ids: 158965000, facility_ids: @selected_facility, is_active: true)[0].id
      end

      def set_procedure_diagnosis_data_for_ot_schedule
        if @admission.present?
          @ipdrecord = Inpatient::IpdRecord.find_by(admission_id: @admission.id.to_s)
          @clinical_note = @ipdrecord.try(:clinical_note)
        end
        @last_opdrecord = OpdRecord.where(patientid: @patient.id.to_s).order('created_at DESC')[0]
        if @clinical_note.blank? && @last_opdrecord.blank?
          @performed_remaining = []
          @procedures = []
          @diagnosis = []
        elsif current_user.specialty_ids.include?("309988001") && @clinical_note.present?
          @performed_remaining = @ipdrecord.procedure.where(procedurestage: "A")
          @procedures = @ipdrecord.procedure.where(procedurestage: "P")
          @diagnosis = @ipdrecord.diagnosislist
        elsif current_user.specialty_ids.include?("309988001") && @clinical_note.blank?
          @performed_remaining = @last_opdrecord.procedure.where(procedurestage: "A")
          @procedures = @last_opdrecord.procedure.where(procedurestage: "P")
          @diagnosis = @last_opdrecord.diagnosislist
        elsif current_user.specialty_ids.include?("309989009") && @clinical_note.present?
          @performed_remaining = @clinical_note.procedurelist
          @procedures = @clinical_note.try(:procedurelist) if @admission.present?
          @diagnosis = @clinical_note.try(:diagnosis) if @clinical_note.present?
        elsif current_user.specialty_ids.include?("309989009") && @admission.blank?
          @performed_remaining = (@last_opdrecord.free_procedure if @last_opdrecord.templatetype == "freeform") || @last_opdrecord.procedure.where(procedurestage: "A")
          @procedures = (@last_opdrecord.free_procedure if @last_opdrecord.templatetype == "freeform") || @last_opdrecord.procedure.where(procedurestage: "P")
          @diagnosis = (@last_opdrecord.diagnosis if @last_opdrecord.templatetype == "freeform") || @last_opdrecord.diagnosislist
        end
      end

      def update_procedures
        if params[:procedure] && params[:procedure].count > 0
          params[:procedure].values.each do |procedure|
            @procedure = @ipdrecord.procedure.find_by(id: procedure["id"])
            @procedure.update(iol: procedure["iol"], iol_updated_at: Time.current, ot_schedule_id: @ot_schedule.id, :procedurestatus => procedure["status"], procedureside: procedure["side"], :surgerydate => procedure["surgerydate"])
          end
        end
      end

      def print_params
        @organisation = current_facility.organisation
        @facility = current_facility
        @ward = Ward.where(facility_id: current_facility.id)
        if params[:current_date].present?
          @current_date = Date.parse(params[:current_date])
        end
      end
    end
  end
end
