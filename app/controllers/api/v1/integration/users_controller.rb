module Api
  module V1
    module Integration
      class UsersController < ApiApplicationController
        before_action :doorkeeper_authorize!
        after_action :create_data_request, :create_data_response
        respond_to :json

        def deactivate
          @original_params = params.dup
          @status_message = "Input parameters are empty or Invalid attempt"
          @status = "Failed"
          @status_code = 400
          employee_info_hash = {}
          if (params[:integration_identifier].present? || params[:employee_id].present? || params[:organisation_integration_identifier].present?) && (params[:deactivate].present? && params[:deactivate] == true)
            @organisation = find_organisation(params[:organisation_integration_identifier].to_s)
            if params[:integration_identifier].present?
              user = User.find_by(integration_identifier: params[:integration_identifier].to_s)
              if user.nil? || @organisation.nil?
                @status_message = "Employee Id not exists."
                @status = "Failed"
                @status_code = 401
              elsif !user.is_active?
                @status_message = "The User is already deactivated."
                @status = "Success"
                @status_code = 200
              else
                user.update_attributes(is_active: false, last_edited_by: "API")
                @status_message = "The User has been deactivated."
                @status = "Success"
                @status_code = 200
              end
            elsif params[:employee_id].present? # if employee_id is present, then employee_info_hash is sent back in certain conditions (refer code below elseif and else), this is added per Dr. Agarwal's request. Added by Mohit on 11th Oct 2022.
              user = User.find_by(employee_id: params[:employee_id].to_s)
              if user.nil? || @organisation.nil?
                @status_message = "Employee Id not exists."
                @status = "Failed"
                @status_code = 400
              elsif !user.is_active?
                @status_message = "The User is already deactivated."
                @status = "Success"
                @status_code = 200
                employee_info_hash = {employee: {employee_id: "#{params[:employee_id]}", deactivated_on: "#{user&.updated_at.strftime("%d/%m/%Y %I.%M %p")}", deactivated_by: "#{user&.fullname}"}}
              else
                user.update_attributes(is_active: false, last_edited_by: "API")
                @status_message = "The User has been deactivated."
                @status = "Success"
                @status_code = 200
                employee_info_hash = {employee: {employee_id: "#{params[:employee_id]}", deactivated_on: "#{user&.updated_at.strftime("%d/%m/%Y %I.%M %p")}", deactivated_by: "API"}}
              end
            end
            if employee_info_hash.key?(:employee)
              @message = { message: @status_message, status: @status, status_code: @status_code }
              @message = @message.merge!(employee_info_hash)
            else
              @message = { message: @status_message, status: @status, status_code: @status_code }
            end
          else
            @message = { message: @status_message, status: @status, status_code: @status_code }
          end
        end

        private

        def find_organisation(organisation_integration_identifier)
          organisation = Organisation.find_by(integration_identifier: organisation_integration_identifier.to_s)
        end

        def find_first_facility(organisation_id)
          facility = Facility.where(organisation_id: organisation_id.to_s)&.first
        end

        def create_data_request
          organisation_id = @organisation.nil? ? "" : @organisation&.id.to_s
          @facility = find_first_facility(organisation_id)
          facility_id = @facility.nil? ? "" : @facility&.id.to_s
          url = "#{params[:controller]}/#{params[:action]}"
          data_hash = @original_params.permit!.to_hash
          ApiIntegration::DataRequests::CreateService.call(data_hash, url, 'received', organisation_id, facility_id, {})
        rescue StandardError
        end

        def create_data_response
          organisation_id = @organisation.nil? ? "" : @organisation&.id.to_s
          @facility = find_first_facility(organisation_id)
          facility_id = @facility.nil? ? "" : @facility&.id.to_s
          url = "#{params[:controller]}/#{params[:action]}"
          data_hash = @message
          ApiIntegration::DataResponses::CreateService.call(data_hash, url, 'sent', organisation_id, facility_id, {})
        rescue StandardError
        end

      end
    end
  end
end
