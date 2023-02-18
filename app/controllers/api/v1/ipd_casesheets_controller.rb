module Api
  module V1
    class IpdCasesheetsController < ApiApplicationController
      before_action :authorize_token

      before_action :convert_to_json, :find_ipdrecord_for_write, :find_admission, :find_patient, only: [:update]
      before_action :find_ipdrecord, :find_admission, :find_patient, :find_patient_details, :find_templatetype, :find_tpa, :admission_note_form_params, only: [:edit]

      def edit
        @current_user = current_user
        @organisation = @current_user.organisation
        @speciality_folder_name = TemplatesHelper.get_speciality_folder_name(@ipdrecord.specialty_id)

        case @template_type
        when "admissionnote"
          get_admission_note_params
          render 'edit'
        when "clinicalnotenew"
          redirect_to eval("new_inpatient_ipd_record_clinical_note_#{@speciality_folder_name}_note_path(admission_id: '#{@ipdrecord.admission_id}',:action => 'new')")
          # redirect_to controller: "inpatient/ipd_record/clinical_note/#{@speciality_folder_name}_notes", action: 'new', admission_id: @ipdrecord.admission_id
        when "clinicalnoteedit"
          redirect_to eval("edit_inpatient_ipd_record_clinical_note_#{@speciality_folder_name}_note_path(id: @ipdrecord.id,admission_id: '#{@ipdrecord.admission_id}',:action => 'edit')")
          # redirect_to controller: "inpatient/ipd_record/clinical_note/#{@speciality_folder_name}_notes", action: 'edit', id: @ipdrecord.id, admission_id: @ipdrecord.admission_id
        when "operativenotenew"
          redirect_to eval("new_inpatient_ipd_record_operative_note_#{@speciality_folder_name}_note_path(id: @ipdrecord.id,admission_id: '#{@ipdrecord.admission_id.to_s}',:action => 'new')")
          # redirect_to controller: "inpatient/ipd_record/operative_note/#{@speciality_folder_name}_notes", action: 'new', id: @ipdrecord.id, admission_id: @ipdrecord.admission_id.to_s
        when "operativenoteedit"
          redirect_to eval("edit_inpatient_ipd_record_operative_note_#{@speciality_folder_name}_note_path(id: '#{params[:id]}',admission_id: '#{@ipdrecord.admission_id.to_s}',:action => 'new')")
          # redirect_to controller: "inpatient/ipd_record/operative_note/#{@speciality_folder_name}_notes", action: 'new', id: params[:id], admission_id: @ipdrecord.admission_id.to_s
        when "dischargenotenew"
          redirect_to eval("new_inpatient_ipd_record_discharge_note_#{@speciality_folder_name}_note_path(id: @ipdrecord.id,admission_id: '#{@ipdrecord.admission_id.to_s}',:action => 'new')")
          # redirect_to controller: "inpatient/ipd_record/discharge_note/#{@speciality_folder_name}_notes", action: 'new', id: @ipdrecord.id, admission_id: @ipdrecord.admission_id.to_s
        when "dischargenoteedit"
          redirect_to eval("edit_inpatient_ipd_record_discharge_note_#{@speciality_folder_name}_note_path(id: @ipdrecord.id,admission_id: '#{@ipdrecord.admission_id.to_s}',:action => 'edit')")
          # redirect_to controller: "inpatient/ipd_record/discharge_note/#{@speciality_folder_name}_notes", action: 'edit', id: @ipdrecord.id, admission_id: @ipdrecord.admission_id.to_s
        else
          respond_to do |format|
          end
        end
      end

      # def new_clinical_note
      #
      # end
      #
      def create_clinial_note
      end

      def update
        @current_user = User.find(params[:current_user_id])
        if params[:inpatient_ipd_record][:admission_attributes][:doctor].blank? || params[:inpatient_ipd_record][:admission_attributes][:facility_id].blank?
          render json: { 'success': false }
        else
          @ipdrecord.update!(ipd_record_params)
          render json: { 'success': true }
          update_patient_timeline
          update_record_history(@ipdrecord.template_type) if @ipdrecord.template_type.present?
        end
      end

      private

      def convert_to_json
        params[:inpatient_ipd_record] = eval(params[:inpatient_ipd_record])
        # params[:inpatient_ipd_record] = JSON.parse(params[:inpatient_ipd_record].gsub(/:(\w+)/){"\"#{$1}\""}.gsub('=>', ':'))
      end

      def update_patient_timeline
        Patients::Summary::TimelineWorker.call({ event_name: "IPD_ADMISSION", sub_event_name: "ADMITTED", admission_id: @ipdrecord.admission_id, user_id: @current_user.id, user_name: @current_user.fullname })
      end

      def ipd_record_params
        params.require(:inpatient_ipd_record).permit(:id, :organisation_id, :admission_id, :patient_id, :user_id, :department, :specalityname, :specalityid, :ward_id, :room_id, :bed_id, :daycare, :patient_name, :patient_age, :patient_gender, :mr_no, :patient_identifier_id, :expected_management, :expected_stay, :hospitalization_reason, :complaint_date, :medico_legal_case, :medico_legal_details, :payment_type, :facility_id, :doctor_id, patient_attributes: [:id, :occupation, :employee_id, :address_1, :address_2, :city, :state, :pincode, :emergencycontactname, :emergencymobilenumber, :blood_group, :maritalstatus], admission_attributes: [:id, :admissiondate, :admissiontime, :admissionreason, :managementplan, :facility_id, :doctor, :patient_arrived, :dischargedate])
      end

      def patient_params
        params.require(:patient).permit(:id, :occupation, :employee_id, :address_1, :address_2, :city, :state, :pincode, :emergencycontactname, :emergencymobilenumber, :blood_group, :maritalstatus)
      end

      def admission_params
        params.require(:admission).permit(:id, :admissiondate, :admissiontime, :admissionreason, :managementplan, :facility_id, :doctor)
      end

      def find_ipdrecord
        @ipdrecord = ::Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
      end

      def find_ipdrecord_for_write
        @ipdrecord = ::Inpatient::IpdRecord.find_by(admission_id: params[:inpatient_ipd_record][:admission_id])
      end

      def find_patient
        @patient = @ipdrecord.patient
      end

      def find_tpa
        @tpa = @admission
      end

      def find_admission
        @admission = @ipdrecord.admission
      end

      def find_templatetype
        @template_type = params[:templatetype]
      end

      def admission_note_form_params
        @ward_count = Ward.where(facility_id: params[:current_facility_id]).count
        if @ward_count < 0 || @admission.daycare
          @bed_details = "Daycare"
        else
          ward, room, bed = @admission.set_bed_details
          @bed_details = "#{bed&.code}(#{ward&.name}/#{room&.name})"
        end

        # For Case Open All Notes Before Admitting
        # @clinical_note = Inpatient::IpdRecord::ClinicalNote.find_by(admission_id: @admission.id)
      end

      def find_patient_details
        @patient_identifier_id = @patient.patient_identifier_id
        @patient_mrn = @patient.patient_mrn
        @age_gender = @patient.patient_age_gender
      end

      def create_record_history
      end

      def update_record_history(tempaltetype)
        @ipdrecord.record_histories.create(:user_id => @current_user.id, :action => "U", :actiontime => Time.current, :template_type => tempaltetype)
      end
    end
  end
end
