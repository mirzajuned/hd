module Api
  module V1
    class AdmissionsController < ApiApplicationController
      before_action :authorize_token
      before_action :set_current_user_current_facility
      before_action :find_patient, only: [:new]
      before_action :find_admission, only: [:edit, :update, :delete_admission, :patient_arrived, :cancel_discharge, :mark_not_arrived, :discharge]
      before_action :get_admission_form_values, only: [:edit]

      def new
        @patient_id = params[:patient_id]
        @patient_type = PatientType.where(is_active: true, organisation_id: @current_user.organisation_id).pluck(:label, :id)
        @selected_facility = params[:current_facility_id] || @current_facility.id
        @selected_doctor = params[:doctor_id] || (@current_user.id if @current_user.role_ids.include?(158965000) && @current_user.facility_ids.map(&:to_s).include?(@selected_facility.to_s)) || User.where(role_ids: 158965000, facility_ids: @selected_facility, is_active: true)[0].id

        @current_doctors = User.where(:facility_ids.in => [@current_facility.id], role_ids: 158965000, is_active: true).sort(fullname: :asc)

        @facilities = @current_user.facilities

        @occupation_list = Global.send('occupation_list').send('sets').pluck(:name, :snomedcode)

        @scheduled_ots = OtSchedule.where(patient_id: @patient.id.to_s, is_deleted: false, admission_id: nil)
        @admission = Admission.new
        get_admission_form_values
      end

      def edit
        # Get Min Discharge Date
        @selected_facility = params[:current_facility_id] || @current_facility.id
        @current_doctors = User.where(:facility_ids.in => [@current_facility.id], role_ids: 158965000, is_active: true).sort(fullname: :asc)
        @facilities = @current_user.facilities
        @admission_list_view = AdmissionListView.find_by(admission_id: @admission.id)
        @ots = OtSchedule.where(admission_id: @admission.id, operation_done: true, is_deleted: false).order(ottime: :desc)
        @min_date = (@ots[0].otdate.strftime("%d/%m/%Y") if @ots.count > 0) || @admission.admissiondate.strftime("%d/%m/%Y")
      end

      def create
        # Create/Update Patient
        unless params[:admission][:patient_id].present?
          @patient = Patients::CreateService.call(params, @current_user, @current_facility) # Call Patient CreateService
        else
          @patient = Patients::UpdateService.call(params[:admission][:patient_id], params, @current_user) # Call Patient UpdateService
        end

        # Create New Admission
        if @patient
          # Check Whether Discharge DateTime is Not Less Than Admission DateTime
          admissiontime, dischargetime = Time.zone.parse(params[:admission][:admissiontime]), Time.zone.parse(params[:admission][:dischargetime])
          params[:admission][:dischargedate] = params[:admission][:admissiondate] if admissiontime > dischargetime
          params[:admission][:dischargetime] = params[:admission][:admissiontime] if admissiontime > dischargetime

          params[:admission][:patient_id] = @patient.id.to_s
          params[:admission][:display_id] = CommonHelper::get_ipd_record_identifier(@current_user)

          if params[:admission][:is_insured] == "No"
            params[:admission][:insurance_status] = "Not Insured"
          else
            params[:admission][:insurance_status] = "Waiting"
          end

          # setting insurance_fields if selected from patient_existing_insurances
          if params[:admission][:patient_insurance_id].present?
            params[:admission][:insurance_contact_id] = params[:admission][:hidden_insurance_contact_id]
            params[:admission][:insurance_name] = params[:admission][:hidden_insurance_name]
            params[:admission][:insurance_contact_no] = params[:admission][:hidden_insurance_contact_no]
            params[:admission][:insurance_contact_person] = params[:admission][:hidden_insurance_contact_person]
            params[:admission][:insurance_address] = params[:admission][:hidden_insurance_address]
            params[:admission][:insurance_policy_no] = params[:admission][:hidden_insurance_policy_no]
            params[:admission][:insurance_policy_expiry_date] = params[:admission][:hidden_insurance_policy_expiry_date]
          end

          @admission = Admission.new(admission_params)
          if @admission.save
            @wards = Ward.where(facility_id: @admission.facility_id.to_s)
            # Link Ots Created w/o AdmissionID
            link_ots if params[:otschedule]

            @status_flag = true
            respond_to do |format|
              format.json { render "create", :layout => false }
            end
            # get_daily_reports
            # Reports::Ipd::Admissions.new(@admission).call
            Patients::Summary::TimelineWorker.call({ event_name: "IPD_ADMISSION", sub_event_name: "SCHEDULED", admission_id: @admission.id, user_id: @current_user.id, user_name: @current_user.fullname })

          end
        end
      end

      def update
        # Check Whether Discharge DateTime is Not Less Than Admission DateTime
        admissiontime, dischargetime = Time.zone.parse(params[:admission][:admissiontime]), Time.zone.parse(params[:admission][:dischargetime])
        params[:admission][:dischargedate] = params[:admission][:admissiondate] if admissiontime > dischargetime
        params[:admission][:dischargetime] = params[:admission][:admissiontime] if admissiontime > dischargetime

        params[:admission][:patient_id] = @admission.patient_id.to_s

        if @admission.update_attributes(admission_params)
          @status_flag = true
          respond_to do |format|
            format.json { render 'update', :layout => false }
          end
          # get_daily_reports
          # Reports::Ipd::Admissions.new(@admission).call
          Patients::Summary::TimelineWorker.call({ event_name: "IPD_ADMISSION", sub_event_name: "EDITED", admission_id: @admission.id, user_id: @current_user.id, user_name: @current_user.fullname })
        else
          redirect_to 'edit'
        end
      end

      def delete_admission
        if @admission.room_id
          @bed = Room.find_by(id: @admission.room_id).beds.find_by(id: @admission.bed_id)
          @bed.update_attributes(status: 78848005)
        end

        ipd_record = Inpatient::IpdRecord.unscoped.find_by(admission_id: @admission.id)
        ipd_record_procedures = ipd_record.try(:procedure)
        case_sheet = CaseSheet.find_by(id: @admission.case_sheet_id)
        case_sheet_procedures = case_sheet.procedures

        ipd_record_procedures.try(:delete_all)
        if ipd_record.present?
          if case_sheet_procedures.present?
            case_sheet_procedures.where(ipd_record_id: ipd_record.id ).each do |procedure|
              # Update IPD fields in Procedure
              procedure[:ipd_procedure_ids] = procedure.ipd_procedure_ids.except(ipd_record.id.to_s)
              procedure[:ipd_record_id] = nil
              procedure[:is_performed] = false
              procedure[:flow_in_ipd] = false
              procedure.save
            end
            case_sheet.save
          end
        end

        if @admission.update_attributes(is_deleted: true, bed_id: nil, room_id: nil, ward_id: nil)
          # Delete all OT Linked to the admission
          OtSchedule.where(admission_id: @admission.id).try(:each) do |ot|
            ot.update(is_deleted: true)
          end
          @patient = @admission.patient
          @status_flag = true
          respond_to do |format|
            format.json { render 'delete_admission', layout: false }
          end

          Patients::Summary::TimelineWorker.call({ event_name: "IPD_ADMISSION", sub_event_name: "CANCELLED", admission_id: @admission.id, user_id: @current_user.id, user_name: @current_user.fullname })
        end
      end

      def get_admission_form_values
        @current_date = @admission.admissiondate || Date.parse(params[:date]) || Date.current
        @current_time = @admission.admissiontime || Time.zone.parse(params[:time]) || Time.current
        @discharge_date = @admission.dischargedate || Date.parse(params[:date]) || Date.current
        @discharge_time = @admission.dischargetime || Time.zone.parse(params[:time]) || Time.current
        @selected_facility = @admission.facility_id || params[:facility_id] || @current_facility.id
        @selected_doctor = @admission.doctor || params[:doctor_id] || (@current_user.id if @current_user.role_ids.include?(158965000) && @current_user.facility_ids.map(&:to_s).include?(@selected_facility.to_s)) || User.where(role_ids: 158965000, facility_ids: @selected_facility)[0].id
      end

      def find_patient
        @patient = Patient.find_by(id: params[:patient_id]) || Patient.new
        if @patient.present?
          @patient_asset = @patient.patientassets
          if @patient_asset.size > 0
            @user_profile_pic_url = @patient_asset[0].asset_path_url
          else
            @user_profile_pic_url = "https://hg-user-assets.s3.amazonaws.com/profile-pics/592fe79f666d67271794c8e1_photo_20170601_153831.png"
          end
        end
      end

      def mark_not_arrived
        if @admission.update_attributes(patient_arrived: false)
          render json: { "success": true }
        end
        pst = PatientSummaryTimeline.where(event_name: "IPD ADMISSION", sub_event_name: "ADMITTED", query: { _id: @admission.id.to_s })
        pst.delete_all if pst.count > 0
        PatientSummaryTimeline.where(query: { _id: @admission.id.to_s }).order(created_at: :desc)[0].update(is_active: true)
      end

      def discharge
        @admission = Admission.find_by(:id => params[:admission_id])
        @patient = Patient.find_by(:id => params[:patient_id])
        if @admission
          @admission.update_attributes({ :isdischarged => true })
          @facilities = Common.new.fetch_facilities(:user => current_user)
          @departments = Common.new.fetch_departments(:facilities => @facilities)
          @admissionlist = Admission.where(:isdischarged => false, :facility_id => current_facility.id, :department_id => @departments.first.id)
          discharge_count = Admission.where(:isdischarged => true, :dischargedate => Date.current, user_id: current_user.id).count
          @discharge_report = DailyReport.find_by(date: Date.current, facility_id: @admission.facility_id.to_s, specialty_id: @admission.specialty_id)

          if @discharge_report.nil?
            @new_discharge_report = DailyReport.new
            @new_discharge_report.user_id = @admission.user_id
            @new_discharge_report.date = @admission.dischargedate
            @new_discharge_report.discharge_count = discharge_count
            @new_discharge_report.month = @admission.dischargedate.month
            @new_discharge_report.year = @admission.dischargedate.year
            @new_discharge_report.organisation_id = @admission.organisation_id.to_s
            @new_discharge_report.facility_id = @admission.facility_id.to_s
            @new_discharge_report.specialty_id = @admission.specialty_id
            @new_discharge_report.save!
          else
            @discharge_report.update_attributes(discharge_count: discharge_count)
          end
          unless @admission.bed_id.nil?
            Room.find(@admission.room_id).beds.find(@admission.bed_id).update_attributes(status: 78848005)
          end
          # DischargeSmsJob.perform_later(@admission.id.to_s)
          # SmsJob.perform_later('discharge_sms',@admission.id.to_s,@admission.class.to_s,request.host_with_port)
          # respond_to do |format|
          render json: { "success": true }
          # end
          Patients::Summary::TimelineWorker.call({ event_name: "IPD_ADMISSION", sub_event_name: "DISCHARGED", admission_id: @admission.id, user_id: current_user.id, user_name: current_user.fullname })
          # DischargeSmsJob.perform_later(@admission.id.to_s)
        end
      end

      def cancel_discharge
        if @admission.update_attributes(isdischarged: false)
          render json: { "success": true }
        end
        pst = PatientSummaryTimeline.where(event_name: "IPD ADMISSION", sub_event_name: "DISCHARGED", query: { _id: @admission.id.to_s })
        pst.delete_all if pst.count > 0
        PatientSummaryTimeline.where(query: { _id: @admission.id.to_s }).order(created_at: :desc)[0].update(is_active: true)
      end

      private

      def link_ots
        params[:otschedule].each do |ot, i|
          if i[:decider] == "Link"
            OtSchedule.find_by(id: i[:id]).update_attributes(admission_id: @admission.id)
          elsif i[:decider] == "Delete"
            OtSchedule.find_by(id: i[:id]).update_attributes(is_deleted: true, admission_id: @admission.id)
          end
        end
      end

      def find_admission
        @admission = Admission.find(params[:id])
        @admission_list_view = AdmissionListView.find_by(admission_id: @admission.id)
      end

      def admission_params
        params.require(:admission).permit(:admissionreason, :managementplan, :admissiondate, :admissiontime, :dischargedate, :patient_arrived, :insurance_status, :facility_id, :doctor, :ward_id, :room_id, :bed_id, :daycare, :patient_id, :user_id, :organisation_id, :department_id, :dischargetime, :display_id, :case_sheet_id, :insurance_selected_id, :admission_hospitalisation_type, :is_insured, :admission_hospitalization_type, :patient_insurance_id, :insurance_name, :insurance_id, :insurance_address, :insurance_email, :insurance_contact_no, :insurance_contact_person, :tpa_name, :tpa_contact_id, :tpa_contact_no, :tpa_contact_person, :tpa_address, :tpa_email, :patient_contact_person, :insurance_policy_no, :insurance_policy_expiry_date, :insurance_type, :company_name, :employee_id, :comment, :patient_id, :insurance_status, :bracket_amount, :document_passport, :document_aadharcard, :document_electioncard, :document_insurancecard, :document_employeecard, :document_drivinglicense, :document_others, :document_tpa_form, :sum_insured, :insurance_comments, :insurance_contact_id, :document_passport, :document_aadharcard, :document_electioncard, :document_insurancecard, :document_employeecard, :document_drivinglicense, :document_others, :document_tpa_form, :document_patient_cancelled_cheque)
      end

      def get_admission_form_values
        @current_date = @admission.admissiondate || Date.parse(params[:date]) || Date.current
        @current_time = @admission.admissiontime || Time.zone.parse(params[:time]) || Time.current
        @discharge_date = @admission.dischargedate || Date.parse(params[:date]) || Date.current
        @discharge_time = @admission.dischargetime || Time.zone.parse(params[:time]) || Time.current
        @selected_facility = @admission.facility_id || params[:facility_id] || @current_facility.id
        @selected_doctor = @admission.doctor || params[:doctor_id] || (@current_user.id if @current_user.role_ids.include?(158965000) && @current_user.facility_ids.map(&:to_s).include?(@selected_facility.to_s)) || User.where(role_ids: 158965000, facility_ids: @selected_facility)[0].id
      end

      def set_current_user_current_facility
        @current_user = User.find_by(id: params[:current_user_id])
        @current_facility = Facility.find_by(id: params[:current_facility_id])
      end
    end
  end
end
