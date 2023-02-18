module Api
  module V1
    module Integration
      class AdmissionStatusController < ApiApplicationController
        before_action :doorkeeper_authorize!
        after_action :create_data_request, :create_data_response
        respond_to :json

        def update
          @original_params = params.dup
          params_received
          find_organisation
          find_facility
          find_admission_data
          find_admission
          find_users

          LoggerService.new.integration(params, 'integration', 'admission order status update')

          begin
            exceptions

            if @admission_status == 'cleared_for_discharge'
              @admission.update(cleared_for_discharge: true)

              LoggerService.new.integration(@admission.to_json, 'integration', 'admission order status update')

            end

            if @admission_status == 'admitted'
              user_id = @user.id
              facility_id = @facility.id
              # @dropdown_users = UsersDropdownHelper.create(@admission, user_id, facility_id)

              # @milestones = @admission.admission_milestones
              position = 3
              # if params[:value] == 'true'
              AdmissionsHelper.update_milestone(@admission, params[:state], position, user_id, params[:ot_id])
              # else
              #   milestone = @milestones.find_by(position: position, :ot_id.in => [params[:ot_id], nil])
              #   milestone&.delete
              # end
              @admission.update("ready_for_admission": 'true')
              # PatientIdentifier and reg_ fields updation
              patient = Patient.find_by(id: @admission.patient_id)
              if patient.try(:reg_status) == false
                patient.update(reg_status: true, reg_date: Date.current, reg_time: Time.current, reg_facility_id: @admission.facility_id.to_s)
                create_patient_identifier(patient, current_user)
                create_patient_search(patient)
              end
              # EOF PatientIdentifier and reg_ fields updation
            end

            @status_message = "Admission Status Updated to #{@admission_status} Succesfully"
            @status = 'Success'
            @status_code = 200

            update_data_received
            update_response_sent

            @message = { message: @status_message, status: @status, status_code: @status_code, data: { facility_integration_identifier: @facility_integration_identifier, organisation_integration_identifier: @organisation_integration_identifier, mr_no: @mr_no } }
          rescue StandardError => e
            @status_message = 'Invalid Request'
            @status = e.try(:status) || 'Failed'
            @status_code = 400

            update_data_received
            update_response_sent

            @message = { message: @status_message, status: @status, status_code: @status_code, data: {} }
          end
        end

        private

        def params_received
          @facility_integration_identifier = params[:facility_integration_identifier]
          @admission_integration_identifier = params[:admission_integration_identifier]
          @organisation_integration_identifier = params[:organisation_integration_identifier]
          @doctor_integration_identifier = params[:doctor_integration_identifier]
          @mr_no = params[:mr_no].to_s.upcase.strip
          @admission_status = params[:status].downcase
        end

        def find_organisation
          @organisation = Organisation.find_by(integration_identifier: @organisation_integration_identifier)
        end

        def find_facility
          @facility = Facility.find_by(integration_identifier: @facility_integration_identifier, organisation_id: @organisation.id)
        end

        def find_admission_data
          @admission_data = ApiIntegration::Admission::Data.find_by(admission_integration_identifier: @admission_integration_identifier, status_code: 200, method_type: 'Create')
        end

        def find_admission
          if @admission_data.present?
            @admission = Admission.find_by(integration_identifier: @admission_data.admission_integration_identifier_bson)
          end
        end

        def find_users
          if @doctor_integration_identifier.present?
            @user = User.find_by(integration_identifier: @doctor_integration_identifier, facility_ids: @facility&.id, role_ids: 158965000, is_active: true)
          end
        end

        def update_data_received
          # Save ReceivedData
          if @admission_data.present?
            @admission_data.admission_status = @admission_status
            @admission_data.save!
          end
        end

        def update_response_sent
          @response_sent = ApiIntegration::Admission::ResponseSent.new(status: @status, status_code: @status_code, message: @status_message, admission_integration_identifier: @admission_integration_identifier, mr_no: @mr_no)
          @response_sent.save!
        end

        def exceptions
          # No Params
          # Field Missing
          raise Errors::FieldMissing, 'Admission Status' if @admission_status.blank?
          raise Errors::FieldMissing, 'MR No.' if @mr_no.blank?
          if @facility_integration_identifier.blank? && @facility_code.blank?
            raise Errors::FieldMissing, 'Facility Identifier'
          end
          raise Errors::FieldMissing, 'Admission ID' if @admission_integration_identifier.blank?
          if @doctor_integration_identifier.blank? && @doctor_employee_id.blank?
            raise Errors::FieldMissing, 'Doctor Integration Identifier'
          end

          # find_by Nil
          raise Errors::FindByNil.new('Facility', 'FacilityCode') if @facility.nil?
          raise Errors::FindByNil.new('Doctor', 'DoctorId') if @user.nil?
          raise Errors::FindByNil.new('Admission', 'AdmissionId') if @admission.nil?
        end

        def create_data_request
          organisation_id = @organisation&.id
          facility_id = @facility&.id
          url = "#{params[:controller]}/#{params[:action]}"
          data_hash = @original_params.permit!.to_hash
          ApiIntegration::DataRequests::CreateService.call(data_hash, url, 'received', organisation_id, facility_id, {})
        rescue StandardError
        end

        def create_data_response
          organisation_id = @organisation&.id
          facility_id = @facility&.id
          url = "#{params[:controller]}/#{params[:action]}"
          data_hash = @message
          ApiIntegration::DataResponses::CreateService.call(data_hash, url, 'sent', organisation_id, facility_id, {})
        rescue StandardError
        end
      end
    end
  end
end
