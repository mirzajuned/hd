# rubocop:disable all
module Api
  module V1
    module Psr
      class PatientAppointmentsController < ApiApplicationController
        before_action :doorkeeper_authorize!
        before_action :get_user_through_qr_code_token

        def create
          params[:patient] = JSON.parse(params[:data].gsub('=>', ':'))
          unless params[:sub_referral_type].blank?
            params[:sub_referral_type] = JSON.parse(params[:sub_referral_type].gsub('=>', ':'))
          end
          unless params[:patient_referral_type].blank?
            params[:patient_referral_type] = JSON.parse(params[:patient_referral_type].gsub('=>', ':'))
          end
          current_user = User.find(@current_user_id)
          current_facility = Facility.find(params[:current_facility_id])

          if params[:patient][:patient_id].present?
            if params[:patient_profile_pic].present?
              params[:patient][:patientassets_attributes] = {}
              params[:patient][:patientassets_attributes]['0'] = { asset_path: params[:patient_profile_pic] }
            end

            @patient_other_identifier = PatientOtherIdentifier.find_by(patient_id: params[:patient][:patient_id])
            params[:patient_other_identifier] = { mr_no: @patient_other_identifier.try(:mr_no) }
            @patient = Patients::UpdateService.call(params[:patient][:patient_id], params, current_user)
          else
            params[:patient_other_identifier] = { mr_no: '' }

            params[:patient][:patientassets_attributes] = {}
            params[:patient][:patientassets_attributes]['0'] = { asset_path: params[:patient_profile_pic] }

            @patient = Patients::CreateService.call(params, current_user, current_facility) # Call Patient CreateService

            PatientHistory.create!('patient_id' => @patient.id.to_s,
                                   'patientpersonalhistory_attributes' => { 'opthal_history_comment' => '', 'glaucoma' => 'false', 'glaucoma_duration' => '', 'glaucoma_duration_unit' => ' ', 'retinal_detachment' => 'false', 'retinal_detachment_duration' => '', 'retinal_detachment_duration_unit' => ' ', 'glasses' => 'false', 'glasses_duration' => '', 'glasses_duration_unit' => ' ', 'eye_disease' => 'false', 'eye_disease_duration' => '', 'eye_disease_duration_unit' => ' ', 'eye_surgery' => 'false', 'eye_surgery_duration' => '', 'eye_surgery_duration_unit' => ' ', 'uveitis' => 'false', 'uveitis_duration' => '', 'uveitis_duration_unit' => ' ', 'retinal_laser' => 'false', 'retinal_laser_duration' => '', 'retinal_laser_duration_unit' => ' ', 'history_comment' => '', 'diabetes' => 'false', 'diabetes_duration' => '', 'diabetes_duration_unit' => ' ', 'hypertension' => 'false', 'hypertension_duration' => '', 'hypertension_duration_unit' => ' ', 'alcoholism' => 'false', 'alcoholism_duration' => '', 'alcoholism_duration_unit' => ' ', 'smoking_tobacco' => 'false', 'smoking_tobacco_duration' => '', 'smoking_tobacco_duration_unit' => ' ', 'steroid_intake' => 'false', 'steroid_intake_duration' => '', 'steroid_intake_duration_unit' => ' ', 'drug_abuse' => 'false', 'drug_abuse_duration' => '', 'drug_abuse_duration_unit' => ' ', 'hiv_aids' => 'false', 'hiv_aids_duration' => '', 'hiv_aids_duration_unit' => ' ', 'cancer_tumor' => 'false', 'cancer_tumor_duration' => '', 'cancer_tumor_duration_unit' => ' ', 'cardiac_disorder' => 'false', 'cardiac_disorder_duration' => '', 'cardiac_disorder_duration_unit' => ' ', 'tuberculosis' => 'false', 'tuberculosis_duration' => '', 'tuberculosis_duration_unit' => ' ', 'asthma' => 'false', 'asthma_duration' => '', 'asthma_duration_unit' => ' ', 'cns_disorder_stroke' => 'false', 'cns_disorder_stroke_duration' => '', 'cns_disorder_stroke_duration_unit' => ' ', 'thyroid_disorder' => 'false', 'thyroid_disorder_duration' => '', 'thyroid_disorder_duration_unit' => ' ', 'hypothyroidism' => 'false', 'hypothyroidism_duration' => '', 'hypothyroidism_duration_unit' => ' ', 'hyperthyroidism' => 'false', 'hyperthyroidism_duration' => '', 'hyperthyroidism_duration_unit' => ' ', 'hepatitis_cirrhosis' => 'false', 'hepatitis_cirrhosis_duration' => '', 'hepatitis_cirrhosis_duration_unit' => ' ', 'renal_disorder' => 'false', 'renal_disorder_duration' => '', 'renal_disorder_duration_unit' => ' ', 'acidity' => 'false', 'acidity_duration' => '', 'acidity_duration_unit' => ' ', 'on_insulin' => 'false', 'on_insulin_duration' => '', 'on_insulin_duration_unit' => ' ', 'on_aspirin_blood_thinners' => 'false', 'on_aspirin_blood_thinners_duration' => '', 'on_aspirin_blood_thinners_duration_unit' => ' ', 'medical_history_comment' => '', 'family_history_comment' => '' }, 'patientallergyhistory_attributes' => { 'others' => '' })

          end

          doctor_id = User.where(:role_ids.in => [158965000], :facility_ids.in => [current_facility],
                                 is_active: true)[0].id

          # Create Appointment
          if @patient.present?

            @appointment = Appointment.find_by(facility_id: current_facility.id, patient_id: @patient.id,
                                               appointmentdate: Date.current, appointmentstatus: 416774000)
            if @appointment.nil?

              params[:appointment] = { facility_id: current_facility.id, consultant_id: doctor_id,
                                       appointmentdate: Date.current, start_time: Time.current,
                                       patient_id: @patient.id, department_id: '485396012',
                                       specialty_id: '309988001', organisation_id: current_user.organisation_id.to_s,
                                       user_id: current_user.id }

              if params[:patient_signature].present?
                params[:appointment][:appointmentassets_attributes] = {}
                params[:appointment][:appointmentassets_attributes]['0'] = { asset_path: params[:patient_signature] }
              end

              @appointment = Appointment::CreateService.call(params[:appointment], current_user,
                                                             @patient, current_facility, true)
              # CaseSheet
              CaseSheet::CreateAppointmentService.call(@patient, @appointment, current_user, nil)
            else
              # raise error
            end
          end
          if params[:patient_referral_type].present? && params[:patient_referral_type][:referral_type_id].present?
            create_patient_referral

            analytics_params = {}
            analytics_params['appointment_id'] = @appointment.id.to_s
            analytics_params['patient_referral_id'] = @patient_referral_type.id.to_s
            ::Analytics::CreateService.call(analytics_params.to_json, nil, @appointment.facility_id.to_s, 'patient_referral_type')
          end

          if @patient.present?
            @patient_present = 'true'
            @message = 'Success'
          else
            @patient_present = 'false'
            @message = 'Failed'
          end

          respond_to do |format|
            format.json {}
          end
        end

        def create_history
          params[:patient_self_history] = eval(params[:patient_self_history])
          # params[:patient_self_history] = JSON.parse(params[:patient_self_history].gsub(/:(\w+)/){"\"#{$1}\""}.gsub('=>', ':'))

          current_user = User.find(@current_user_id)
          current_facility = Facility.find(params[:current_facility_id])

          @patient = Patient.find(params[:patient_id].to_s)

          if params[:patient_self_history].present?
            params[:patient_self_history][:patient_id] = @patient.id.to_s
            PatientSelfHistory.create!(patient_history_params(params))
          end

          doctor_id = User.where(:role_ids.in => [158965000], :facility_ids.in => [current_facility],
                                 is_active: true)[0].id
          if @patient.present?

            @appointment = Appointment.find_by(facility_id: current_facility.id, patient_id: @patient.id,
                                               appointmentdate: Date.current, appointmentstatus: 416774000)

            if @appointment.nil?

              params[:appointment] = { facility_id: current_facility.id, consultant_id: doctor_id,
                                       appointmentdate: Date.current, start_time: Time.current,
                                       patient_id: @patient.id, department_id: '309988001',
                                       organisation_id: current_user.organisation_id.to_s, user_id: current_user.id }

              if params[:patient_signature].present?
                params[:appointment][:appointmentassets_attributes] = {}
                params[:appointment][:appointmentassets_attributes]['0'] = { asset_path: params[:patient_signature] }
              end

              @appointment = Appointment::CreateService.call(params[:appointment], current_user, @patient,
                                                             current_facility, true)
            else
              # raise Errors::AppointmentAlreadyExists.new(@appointment.appointmentdate.strftime('%d/%m/%Y'),
            end
          end

          if @patient.present?
            @patient_present = 'true'
            @message = 'Success'
          else
            @patient_present = 'false'
            @message = 'Failed'
          end

          respond_to do |format|
            format.json {}
          end
        end

        def referral_source
          @referral_types = ReferralType.where(is_active: true, :id.nin => ['FS-RT-0009'])
          referral_source_ids = @referral_types.pluck(:id)
          referral_source_names = @referral_types.pluck(:name)
          render json: { referral_source_ids: referral_source_ids, referral_source_names: referral_source_names,
                         message: 'ok' }, status: :ok
        end

        def create_patient_referral
          # Create SubReferral, Case: Relative, Self
          if params[:sub_referral_type].present?
            params[:sub_referral_type][:referral_type_id] = params[:patient_referral_type][:referral_type_id]
            params[:sub_referral_type][:facility_ids] = Facility.where(organisation_id: @current_organisation_id).pluck(:id)
            if params[:sub_referral_type][:referral_type_id] == 'FS-RT-0001'
              @sub_referral_type = SubReferralType.find_by(referral_type_id: 'FS-RT-0001', organisation_id: @current_organisation_id) # Case Self
            end
            unless @sub_referral_type.present?
              @sub_referral_type = SubReferralType.new(sub_referral_type_params)
              @sub_referral_type.save!
            end
            params[:patient_referral_type][:sub_referral_type_id] = @sub_referral_type.try(:id).to_s
          end
          if params[:patient_referral_type][:sub_referral_type_id].present?
            # Create PatientReferral Params
            params[:patient_referral_type][:patient_id] = @patient.id.to_s
            params[:patient_referral_type][:appointment_id] = @appointment.id.to_s
            params[:patient_referral_type][:facility_id] = @appointment.facility_id.to_s
            params[:patient_referral_type][:organisation_id] = @appointment.organisation_id.to_s

            # Create PatientReferral
            @patient_referral_type = PatientReferralType.new(patient_referral_type_params)
            @patient_referral_type.save!
          end
        end

        def sub_referral_type
          @sub_referral_type = SubReferralType.where(referral_type_id: params[:referral_type_id],
                                                     facility_ids: params[:facility_id], is_deleted: false)
          sub_referral_type_ids = @sub_referral_type.pluck(:id)
          sub_referral_type_names = @sub_referral_type.pluck(:name)

          is_active, user_id, organisation_id, name = nil
          if params[:referral_type_id] == 'FS-RT-0001'
            is_active = false
            user_id = @current_user_id.to_s
            organisation_id = @current_organisation_id
            name = 'Self'
          end
          if params[:referral_type_id] == 'FS-RT-0004'
            is_active = false
            user_id = @current_user_id.to_s
            organisation_id = @current_organisation_id
          end
          if ['FS-RT-0001','FS-RT-0004'].include? params[:referral_type_id]
            sub_referral_type = { is_active: is_active, user_id: user_id, organisation_id: organisation_id, name: name }
          end

          render json: { sub_referral_type_ids: sub_referral_type_ids, sub_referral_type_names: sub_referral_type_names,
                         sub_referral_type: sub_referral_type, message: 'ok' }, status: :ok
        end

        private

        def get_user_through_qr_code_token
          @link_device = LinkFacilityDevice.find_by(qr_auth_token: params[:qr_auth_token])
          @link_device.update(last_activity_date: DateTime.current)
          @current_user_id = @link_device.user_id
          @current_organisation_id = @link_device.organisation_id || params[:organisation_id]
        end

        def appointment_params
          params.require(:appointment).permit(:facility_id, :consultant_id, :appointment_type_id, :appointmentdate,
                                              :start_time, :patient_id, :department_id, :organisation_id, :user_id,
                                              :display_id, :created_from, :opd_referral_id, :referral,
                                              :referral_created_on, :referring_doctor, :referee_doctor,
                                              :to_facility_name, :from_facility_name, :referral_note,
                                              :integration_identifier, :specialty_id)
        end

        def patient_history_params(params)
          params.require(:patient_self_history).permit! # (:patient_id, :patientpersonalhistory, :patientallergyhistory)
        end

        def sub_referral_type_params
          params.require(:sub_referral_type).permit(:is_active, :existing_patient, :name, :mobile_number, :email, :relation, :comment, :facility_ids, :user_id, :referral_type_id, :organisation_id)
        end

        def patient_referral_type_params
          params.require(:patient_referral_type).permit(:referral_type_id, :sub_referral_type_id, :patient_id, :appointment_id, :facility_id, :organisation_id)
        end
      end
    end
  end
end
