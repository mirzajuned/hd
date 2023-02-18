module Api
  module V1
    module Psr
      class PatientsController < ApiApplicationController
        before_action :doorkeeper_authorize!

        def search_patient
          mobilenumber = params[:mobilenumber]
          @link_device = LinkFacilityDevice.find_by(qr_auth_token: params[:qr_auth_token])
          @user_id = @link_device.user_id
          organisation_id = User.find(@user_id).organisation_id

          @patient = Patient.where(mobilenumber: mobilenumber.to_s, reg_hosp_ids: [organisation_id.to_s]).limit(8)

          if @patient.present?
            @patient_present = "true"
            @message = "Success"
          else
            @patient_present = "false"
            @message = "No patient found"
          end
          @link_device.update(last_activity_date: DateTime.current)
          respond_to do |format|
            format.json {}
          end
        end
      end
    end
  end
end
