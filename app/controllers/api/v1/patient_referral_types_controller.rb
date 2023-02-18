module Api
  module V1
    class PatientReferralTypesController < ApiApplicationController
      before_action :find_referral_types, only: [:new, :edit]
      before_action :find_patient_referral_type, only: [:edit, :update]
      before_action :find_patient, only: [:update]
      before_action :find_appointment, only: [:update]
      before_action :find_current_user, only: [:create, :update]

      def new
        @appointment = Appointment.find_by(id: params[:appointment_id])
      end

      def create
        create_sub_referral if params[:sub_referral_type].present?

        # Create PatientReferral
        params[:patient_referral_type][:facility_id] = params[:current_facility_id]
        params[:patient_referral_type][:facility_id] = @current_user.try(:organisation_id)
        @patient_referral_type = PatientReferralType.new(patient_referral_type_params)
        if @patient_referral_type.save
          @status = 'referral created'
          find_patient
          find_appointment
          patient_referral_types
        end
      end

      def edit
        @sub_referral_types = SubReferralType.where(referral_type_id: @patient_referral_type.referral_type_id, facility_ids: params[:facility_id], is_deleted: false).pluck(:name, :id)
      end

      def update
        params[:patient_referral_type][:facility_id] = @appointment.facility_id
        params[:patient_referral_type][:facility_id] = @appointment.organisation_id
        if params[:patient_referral_type][:referral_type_id].present?
          create_sub_referral if params[:sub_referral_type].present?

          @message = ("Success" if @patient_referral_type.update_attributes(patient_referral_type_params)) || "Failure"
        else
          @appointment = @patient_referral_type.appointment

          @message = ("Success" if @patient_referral_type.update_attributes(is_deleted: true)) || "Failure"
          @patient_referral_type = nil
        end

        if @message == "Success"
          patient_referral_types
        end
      end

      private

      def find_current_user
        @current_user = User.find_by(id: params[:current_user_id])
      end

      def find_referral_types
        @referral_types = ReferralType.where(is_active: true, :id.nin => ['FS-RT-0009'])
      end

      def find_patient_referral_type
        @patient_referral_type = PatientReferralType.find_by(id: params[:id])
      end

      def create_sub_referral
        # Create SubReferral, Case: Relative
        params[:sub_referral_type][:referral_type_id] = params[:patient_referral_type][:referral_type_id]
        params[:sub_referral_type][:facility_ids] = @current_user.facility_ids
        if params[:sub_referral_type][:referral_type_id] == "FS-RT-0001"
          @sub_referral_type = SubReferralType.find_by(referral_type_id: 'FS-RT-0001', organisation_id: @current_user.organisation_id) # Case Self
        end
        unless @sub_referral_type.present?
          @sub_referral_type = SubReferralType.new(sub_referral_type_params)
          @sub_referral_type.save!
        end
        params[:patient_referral_type][:sub_referral_type_id] = @sub_referral_type.try(:id).to_s
      end

      def sub_referral_type_params
        params.require(:sub_referral_type).permit(:is_active, :existing_patient, :name, :mobile_number, :email, :relation, :comment, :facility_ids, :user_id, :referral_type_id, :organisation_id)
      end

      def patient_referral_type_params
        params.require(:patient_referral_type).permit(:referral_type_id, :sub_referral_type_id, :patient_id, :appointment_id, :is_deleted, :facility_id, :organisation_id)
      end

      def find_patient
        @patient = Patient.find_by(id: @patient_referral_type.patient_id)
      end

      def find_appointment
        @appointment = Appointment.find_by(id: @patient_referral_type.appointment_id)
      end

      def patient_referral_types
        @initial_referral_type = PatientReferralType.where(patient_id: @patient.id, is_deleted: false).order(created_at: :asc)[0]
        @deleted_patient_referral_type = PatientReferralType.find_by(appointment_id: @appointment.id, is_deleted: true)
      end
    end
  end
end
