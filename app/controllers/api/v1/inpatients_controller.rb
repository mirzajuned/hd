module Api
  module V1
    class InpatientsController < ApiApplicationController
      before_action :authorize_token

      before_action :initial_params, only: [:ot_management, :ot_scheduler, :ot_list]
      before_action :ot_list_params, only: [:ot_list]
      before_action :details_view_params, only: [:ot_details]

      def admission_list
        @current_user_id = params[:current_user_id]
        @current_facility_id = params[:current_facility_id]
        @user = User.find_by(id: @current_user_id)
        @facility = Facility.find_by(id: @current_facility_id)
        if params[:current_date].present?
          @current_date = Date.parse(params[:current_date])
        else
          @current_date = Date.current
        end

        @users = User.where(facility_ids: @facility.id.to_s, is_active: true, role_ids: 158965000)

        if params[:active_doctor]
          @active_doctor = params[:active_doctor]
        else
          if @user.role_ids.include? 158965000
            @active_doctor = @user.id.to_s
          end # else nil
        end
        @admission_id = params[:admission_id]

        @scheduled_count = @facility.admission_schedule_list_length
        unless @active_doctor == "all" || @active_doctor == nil
          if @current_date == Date.current
            @admission_list = AdmissionListView.where(facility_id: @facility.id.to_s, admitting_doctor_id: @active_doctor, "$or" => [{ current_state: "Admitted" }, { current_state: "Scheduled", admission_date: @scheduled_count.days.ago.to_date..Date.current }, { current_state: "Discharged", discharge_date: @current_date }])
          else
            @admission_list = AdmissionListView.where(facility_id: @facility.id.to_s, admitting_doctor_id: @active_doctor, "$or" => [{ current_state: "Admitted" }, { current_state: "Scheduled", admission_date: @current_date }, { current_state: "Discharged", discharge_date: @current_date }])
          end
        else
          if @current_date == Date.current
            @admission_list = AdmissionListView.where(facility_id: @facility.id.to_s, "$or" => [{ current_state: "Admitted" }, { current_state: "Scheduled", admission_date: @scheduled_count.days.ago.to_date..Date.current }, { current_state: "Discharged", discharge_date: @current_date }])
          else
            @admission_list = AdmissionListView.where(facility_id: @facility.id.to_s, "$or" => [{ current_state: "Admitted" }, { current_state: "Scheduled", admission_date: @current_date }, { current_state: "Discharged", discharge_date: @current_date }])
          end
        end

        # Bifercate List per tab
        @scheduled_list = @admission_list.where(current_state: "Scheduled").order(admission_date: :desc)
        @admitted_list = @admission_list.where(current_state: "Admitted").order(admission_date: :desc)
        @current_admitted_list = @admission_list.where(current_state: "Admitted", admission_date: @current_date).order(admission_date: :desc)
        @discharged_list = @admission_list.where(current_state: "Discharged").order(discharge_date: :desc)

        # Get active admission & tab
        unless @admission_list.find_by(admission_id: params[:admission_id]).nil?
          @admission_id = params[:admission_id].to_s
        else
          if @scheduled_list.count > 0
            @admission_id = @scheduled_list[0].admission_id.to_s
          end
        end
        if params[:active_tab].present?
          @active_tab = params[:active_tab]
        else
          @active_tab = "Admitted"
        end
      end

      def admission_details
        @current_user = User.find(params[:current_user_id])
        @current_facility = Facility.find(params[:current_facility_id])

        @current_date = params[:current_date]
        if params[:admission_id]
          admission_id = params[:admission_id]
        else
          @ot = OtSchedule.find_by(id: params[:ot_id])
          admission_id = @ot.admission_id
        end
        @showpatientnote = PatientNote.where(organisation_id: @current_user.organisation_id).order(:created_at => :desc)

        if admission_id
          @admission = Admission.find(admission_id)
          @patient = Patient.find_by(id: @admission.patient_id)
          @case_sheet = CaseSheet.find_by(id: @admission.case_sheet_id.to_s)
          @initial_referral_type = PatientReferralType.includes(:referral_type, :sub_referral_type).where(patient_id: @patient.try(:id), is_deleted: false).order(created_at: :asc)[0]

          @patient_language = "#{@patient.try(:primary_language)}" +
                              if (@patient.primary_language.present? && @patient.secondary_language.present?)
                                ", " + "#{@patient.try(:secondary_language)}"
                              else
                                "#{@patient.try(:secondary_language)}"
                              end

          # @past_appointment = AppointmentListView.where(patient_id: @patient.try(:id), :appointment_date.lt => Date.current).order(appointment_date: :desc)
          @patient_note = PatientNote.where(patient_id: @patient.id).order(:created_at => :desc)
          @counsellor_note = CounsellorNote.where(patient_id: @patient.id).order(:created_at => :desc)
          patient_asset = @patient.patientassets
          @patient_asset = (patient_asset.last.asset_path_url if patient_asset.count > 0) || "https://hg-user-assets.s3.amazonaws.com/profile-pics/5882e6e6666d670647000087_photo_20170121_101318.png"

          @admission_list_view = AdmissionListView.find_by(admission_id: @admission.id)
          @ot_list_view = OtListView.find_by(admission_id: @admission.id)
          if params[:action] == "admission_details"
            @ot_schedules = OtSchedule.where(patient_id: @admission.patient.id.to_s, is_deleted: false, admission_id: @admission.id)
          else
            @ot_schedules = OtSchedule.where(patient_id: @admission.patient.id.to_s, is_deleted: false)
          end
          @advance = AdvancePayment.where(patient_id: @admission.patient_id, type: "IPD", advance_state: "None")
          @invoice_templates = InvoiceTemplate.where(facility_id: @current_facility.id, version: "v21.0")
          @cash_register_templates = CashRegisterTemplate.where(:user_id => @current_user.id)
          @inv_ins_id = Invoice::Insurance.find_by(admission_id: @admission.id)
          @inv_est_id = Invoice::InsuranceEstimate.find_by(admission_id: @admission.id)
          @copayment = Copayment.find_by(admission_id: @admission.id)
          @tpa = @admission
          # @pre_admission_note = Inpatient::IpdRecord::AdmissionNote.find_by(admission_id: @admission.id)
          @ipdrecord = ::Inpatient::IpdRecord.find_by(admission_id: @admission.id)
          @clinical_note = @ipdrecord.clinical_note
          @operative_note = @ipdrecord.operative_notes
          @discharge_note = @ipdrecord.discharge_note
          @ward_notes = @ipdrecord.ward_notes
          @procedure = @ipdrecord.procedure
          @pre_admission_note = ::Inpatient::IpdRecord.find_by(admission_id: @admission.id)
          # @clinical_note = Inpatient::IpdRecord::ClinicalNote.find_by(admission_id: @admission.id)
          # @operative_note = Inpatient::IpdRecord::OperativeNote.find_by(admission_id: @admission.id)
          # @discharge_note = Inpatient::IpdRecord::DischargeNote.find_by(admission_id: @admission.id)
          # @ward_notes = Inpatient::IpdRecord::WardNote.where(admission_id: @admission.id)
          @doctor = User.find_by(id: @admission.doctor.to_s)
          # @reminder_note = DocReminderNote.find_by(patient_id: @admission.patient.id.to_s).try(:reminder_text)
          @engaged_time = []
          @engage_ots = @admission.ot_schedules.where(is_engaged: true)
          @engage_ots.each do |engaged|
            @engaged_time << engaged.ottime.strftime("%I:%M %p on %b %d,%Y")
          end
          @completed_ots = @admission.ot_schedules.where(operation_done: true)

          unless @admission.isdischarged?

            if @admission.patient_arrived?
              if @admission.ot_schedules.where(is_deleted: false).count == @completed_ots.count
                @discharge_patient = "discharge"
                @not_arrived = "na"
              else
                @discharge_patient = "restrict_discharge"
                @not_arrived = "na"
              end
              @admitpatient = ""
            else
              @not_arrived = ""
              if @pre_admission_note.nil?
                @admitpatient = "new"
              else
                @admitpatient = "edit"
              end
            end
            @readmit = ""
          else
            @not_arrived = ""
            @discharge_patient = ""
            @admitpatient = ""

            if AdmissionListView.find_by(patient_id: @admission.patient_id, :current_state.nin => ["Deleted", "Discharged"]).nil?
              if @current_user.has_role?(:owner) || @current_user.has_role?(:doctor) || @current_user.has_role?(:admin)
                @readmit = "true"
              else
                @readmit = ""
              end
            end
          end

        else
          @admission = Admission.find_by(patient_id: @ot.patient.id, isdischarged: false, is_deleted: false)
          @ot_schedules = OtSchedule.where(patient_id: @ot.patient.id.to_s, is_deleted: false)
          @ot_list_view = OtListView.find_by(ot_id: @ot.try(:id))
          @patient = Patient.find_by(id: @ot.patient_id)
          @case_sheet = CaseSheet.find_by(id: @admission.case_sheet_id.to_s)
          @initial_referral_type = PatientReferralType.includes(:referral_type, :sub_referral_type).where(patient_id: @ot.patient.try(:id), is_deleted: false).order(created_at: :asc)[0]
        end
      end

      # Get OT List LHS
      def ot_list
        # @current_user_id = params[:current_user_id]
        # @current_facility_id = params[:current_facility_id]
        #
        # @current_user = User.find_by(id: @current_user_id)
        # @current_facility = Facility.find_by(id: @current_facility_id)
      end

      # Get OT Details RHS - Common for List & Calender Views
      def ot_details
        @case_sheet = CaseSheet.find_by(id: @ot.case_sheet_id.to_s)
        if @ot.admission_id
          unless @admission.patient_arrived == false
            if @ot.admission.patient_arrived && !(@ot.is_engaged) && !(@ot.operation_done)
              @unlink_ot = "true"
              @engage_ot = "true"
            elsif !(@ot.operation_done) && @ot.is_engaged
              @cancel = "true"
              @mark_as_done = "true"
            elsif @ot.operation_done && !(@ot.is_engaged)
              @ot_completed = "true"
            end
          else
            @pre_admission_note = ::Inpatient::IpdRecord.find_by(admission_id: @admission_list_view.try(:admission_id)).try(:admission_note)
            if @pre_admission_note.nil?
              @admit_patient = "new"
            else
              @admit_patient = "edit"
            end
            @unlink_ot = "true"
          end
        else
          if @admission
            @link_to_admission = "true"
          else
            @add_admission = "true"
          end
        end
      end

      def save_admission_consent
        params[:data] = eval(params[:data])
        # params[:data] = JSON.parse(params[:data].gsub(/:(\w+)/){"\"#{$1}\""}.gsub('=>', ':'))
        params[:data][:facility_id] = params[:data][:current_facility_id]
        params[:data][:user_id] = params[:data][:current_user_id]
        params[:data][:consent_date] = params[:data][:current_date]
        params[:data][:consent_path] = params[:consent]

        @admission_consent = AdmissionConsent.new(admission_consent_params(params[:data]))

        if @admission_consent.save!
          render json: { 'success': true }
        else
          render json: { 'success': false }
        end
      end

      # Get Data for Calendar
      def admission_calendar_data
        @current_facility_id = params[:current_facility_id]

        options = { facility_id: @current_facility_id }
        unless params[:doctor_id] == "all" || params[:doctor_id] == "" || params[:doctor_id] == nil
          options = options.merge({ admitting_doctor_id: params[:doctor_id] })
        end

        if Date.parse(params[:start]) < Date.current
          options = options.merge({ current_state: "Discharged" })
        elsif Date.parse(params[:start]) > Date.current
          options = options.merge({ current_state: "Scheduled" })
        else
          options = options.merge({ :current_state.nin => ["Deleted"] })
        end

        @admission_list = AdmissionListView.where(options).between(:admission_date => Date.parse(params[:start])..(Date.parse(params[:end]) - 1))
        @admission_list = (@admission_list + AdmissionListView.where(options).between(:discharge_date => Date.parse(params[:start])..(Date.parse(params[:end]) - 1))).uniq
      end

      def deleteot
        @ot = OtSchedule.find_by(id: params[:id])
        @active_ot = OtSchedule.find_by(id: params[:active_id])
        @admission_list_view = AdmissionListView.find_by(admission_id: @ot.admission_id)
        @ot.update(is_deleted: true)

        # For RHS VIEW (Appt)
        @patient = Patient.find_by(id: @ot.patient_id)
        @ot_schedules = OtSchedule.where(patient_id: @patient.id.to_s, is_deleted: false, is_engaged: false, operation_done: false).sort(ottime: :asc)
        render json: { 'success': true }
        Patients::Summary::TimelineWorker.call({ event_name: "IPD_OT", sub_event_name: "CANCELLED", ot_id: @ot.id, user_id: current_user.id, user_name: current_user.fullname })
      end

      def engageot
        @ot = OtSchedule.find_by(id: params[:ot_id])
        @ot_status = @ot.is_engaged
        if @ot_status
          @ot.update_attributes(is_engaged: false)
          pst = PatientSummaryTimeline.find_by(event_name: "IPD OT", sub_event_name: "ENGAGED", query: { _id: @ot.id.to_s })
          pst.delete if pst
        else
          @ot.update_attributes(is_engaged: true)
          Patients::Summary::TimelineWorker.call({ event_name: "IPD_OT", sub_event_name: "ENGAGED", ot_id: @ot.id, user_id: current_user.id, user_name: current_user.fullname })
        end
        render json: { "status": @ot.is_engaged }
      end

      def completeot
        @ot = OtSchedule.find_by(id: params[:ot_id])
        @admission = Admission.find(@ot.admission_id)
        if @admission && @admission.isdischarged
          render json: { "status": "Discharged" }
        else
          if @ot.operation_done
            @ot.update_attributes(operation_done: false, is_engaged: true)
            pst = PatientSummaryTimeline.find_by(event_name: "IPD OT", sub_event_name: "COMPLETED", query: { _id: @ot.id.to_s })
            pst.delete if pst
          else
            @ot.update_attributes(operation_done: true, is_engaged: false)
            if @admission.dischargedate
              if @ot.otdate > @admission.dischargedate
                @admission.update_attributes(dischargedate: Date.current, dischargetime: Time.current)
              end
            end
            Patients::Summary::TimelineWorker.call({ event_name: "IPD_OT", sub_event_name: "COMPLETED", ot_id: @ot.id, user_id: current_user.id, user_name: current_user.fullname })
          end

          render json: { "status": @ot.operation_done }
        end
      end

      def calendar_ot_details
        @ot = OtSchedule.find_by(id: params[:ot_id])

        @invoice_templates = InvoiceTemplate.where(facility_id: current_facility.id, version: "v21.0")
        @cash_register_templates = CashRegisterTemplate.where(:user_id => current_user.id)

        respond_to do |format|
          # format.html { render partial: "opd_appointments/calendar/calendar_appointment_details.html", layout: false }
          format.html { render partial: "inpatient/home/ot_management/calendar_ot_details.html", layout: false }
        end
      end

      def ot_calendar_data
        @current_facility_id = params[:current_facility_id]
        options = { facility_id: @current_facility_id }
        unless params[:doctor_id] == "all" || params[:doctor_id] == "" || params[:doctor_id] == nil
          options = options.merge({ operating_doctor_id: params[:doctor_id] })
        end

        if Date.parse(params[:start]) < Date.current
          options = options.merge({ current_state: "Completed" })
        elsif Date.parse(params[:start]) > Date.current
          options = options.merge({ :current_state.in => ["Scheduled", "Admitted"] })
        else
          options = options.merge({ :current_state.nin => ["Deleted"] })
        end

        @ot_list = OtListView.where(options).between(:ot_date => Date.parse(params[:start])..(Date.parse(params[:end]) - 1)).sort(ottime: :desc)
      end

      ####################  Private Methods ####################
      private

      def admission_consent_params(para)
        para.permit(:admission_id, :assigned_doctor, :assigned_doctor_id, :user_id, :facility_id, :organisation_id, :patient_id, :consent_date, :consent_path)
      end

      # Get Current Date & Active Doctor
      def initial_params
        @current_user_id = params[:current_user_id]
        @current_facility_id = params[:current_facility_id]

        @current_user = User.find_by(id: @current_user_id)
        @current_facility = Facility.find_by(id: @current_facility_id)

        if params[:current_date].present?
          @current_date = Date.parse(params[:current_date])
        else
          @current_date = Date.current
        end

        @users = User.where(facility_ids: @current_facility_id.to_s, is_active: true, role_ids: 158965000)

        if params[:active_doctor]
          @active_doctor = params[:active_doctor]
        else
          if @current_user.role_ids.include? 158965000
            @active_doctor = @current_user_id.to_s
          end # else nil
        end
        if params[:action] == "ot_management"
          @active_tab = params[:active_tab] || "All"
        else
          @active_tab = params[:active_tab] || "Admitted"
        end
        @admission_id = params[:admission_id]
        @ot_id = params[:ot_id]
        @users_list = params[:doctors_list] || "in"
      end

      # Get List Of OT
      def ot_list_params
        # Load all concerned Ots
        unless @active_doctor == "all" || @active_doctor == nil
          @ot_list = OtListView.where(facility_id: @current_facility_id.to_s, operating_doctor_id: @active_doctor, ot_date: @current_date).not.where(current_state: "Deleted")
        else
          @ot_list = OtListView.where(facility_id: @current_facility_id.to_s, ot_date: @current_date).not.where(current_state: "Deleted")
        end

        # Bifercate List per tab
        @all_list = @ot_list.order(ot_time: :asc)
        @scheduled_list = @ot_list.where(current_state: "Scheduled").order(ot_time: :asc)
        @admitted_list = @ot_list.where(current_state: "Admitted").order(ot_time: :asc)
        @engaged_list = @ot_list.where(current_state: "Engaged").order(ot_time: :asc)
        @completed_list = @ot_list.where(current_state: "Completed").order(ot_time: :asc)

        # Get active ot & tab
        unless @ot_list.find_by(ot_id: params[:ot_id]).nil?
          @ot_id = params[:ot_id].to_s
        else
          if @admitted_list.count > 0
            @ot_id = @admitted_list[0].ot_id.to_s
          end
        end
        if params[:active_tab]
          @active_tab = params[:active_tab]
        else
          @active_tab = "All"
        end

        @users_list = params[:doctors_list]
      end

      def details_view_params
        @current_user_id = params[:current_user_id]
        @current_facility_id = params[:current_facility_id]

        @current_user = User.find_by(id: @current_user_id)
        @current_facility = Facility.find_by(id: @current_facility_id)

        @current_date = params[:current_date]
        if params[:admission_id]
          admission_id = params[:admission_id]
        else
          @ot = OtSchedule.find_by(id: params[:ot_id])
          admission_id = @ot.admission_id
        end

        @patient_card_enabled = OrganisationsSetting.find_by(organisation_id: @current_facility.organisation_id).try(:patient_card_enabled)
        if admission_id
          @admission = Admission.find(admission_id)
          @patient = Patient.find_by(id: @admission.patient_id)
          @initial_referral_type = PatientReferralType.includes(:referral_type, :sub_referral_type).where(patient_id: @patient.try(:id), is_deleted: false).order(created_at: :asc)[0]

          @admission_list_view = AdmissionListView.find_by(admission_id: @admission.id)
          @ot_list_view = OtListView.find_by(admission_id: @admission.id)
          if params[:action] == "admission_details"
            @ot_schedules = OtSchedule.where(patient_id: @admission.patient.id.to_s, is_deleted: false, admission_id: @admission.id)
          else
            @ot_schedules = OtSchedule.where(patient_id: @admission.patient.id.to_s, is_deleted: false)
          end
          @advance = AdvancePayment.where(patient_id: @admission.patient_id, advance_state: "None")
          @invoice_templates = InvoiceTemplate.where(:facility_id => @current_facility_id)
          @cash_register_templates = CashRegisterTemplate.where(:user_id => @current_user_id)
          @past_cash_registers = CashRegister.where(:patient_id => @patient.id)
          @inv_ins_id = Invoice::Insurance.find_by(admission_id: @admission.id)
          @inv_est_id = Invoice::InsuranceEstimate.find_by(admission_id: @admission.id)
          @copayment = Copayment.find_by(admission_id: @admission.id)
          @tpa = @admission
          # @pre_admission_note = Inpatient::IpdRecord::AdmissionNote.find_by(admission_id: @admission.id)
          # @pre_admission_note = Inpatient::IpdRecord.find_by(admission_id: @admission.id).admission_note
          @ipdrecord = ::Inpatient::IpdRecord.find_by(admission_id: @admission.id)
          @clinical_note = @ipdrecord.clinical_note
          @operative_note = @ipdrecord.operative_notes
          @discharge_note = @ipdrecord.discharge_note
          @ward_notes = @ipdrecord.ward_notes
          @procedure = @ipdrecord.procedure
          @doctor = User.find_by(id: @admission.doctor.to_s)
          # @reminder_note = DocReminderNote.find_by(patient_id: @admission.patient.id.to_s).try(:reminder_text)
          @engaged_time = []
          @engage_ots = @admission.ot_schedules.where(is_engaged: true)
          @engage_ots.each do |engaged|
            @engaged_time << engaged.ottime.strftime("%I:%M %p on %b %d,%Y")
          end
          @completed_ots = @admission.ot_schedules.where(operation_done: true)
        else
          @admission = Admission.find_by(patient_id: @ot.patient.id, isdischarged: false, is_deleted: false)
          @ot_schedules = OtSchedule.where(patient_id: @ot.patient.id.to_s, is_deleted: false)
          @ot_list_view = OtListView.find_by(ot_id: @ot.try(:id))
          @patient = Patient.find_by(id: @ot.patient_id)
          @initial_referral_type = PatientReferralType.includes(:referral_type, :sub_referral_type).where(patient_id: @patient.try(:id), is_deleted: false).order(created_at: :asc)[0]
        end
        @patient_note = PatientNote.where(patient_id: @patient.id).order(:created_at => :desc).limit(5)

        patient_asset = @patient.patientassets
        @patient_asset = (patient_asset.last.asset_path_url if patient_asset.count > 0) || "https://hg-user-assets.s3.amazonaws.com/profile-pics/5882e6e6666d670647000087_photo_20170121_101318.png"
      end
    end
  end
end
