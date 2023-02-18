module Api
  module V1
    module Psr
      class DevicesController < ApiApplicationController
        before_action :doorkeeper_authorize!
        before_action :bsonify_variable, except: :validate_psr_user
        before_action :check_for_facility_organisation, only: [:create]

        def create
          @user = User.find_by(username: params[:username])
          @user.present? ? update_user : create_user
          # save data coming from psr though doorkeeper
          @facility_device = LinkFacilityDevice.new(
            device_id: params[:scan_facility][:device_id],
            device_name: params[:scan_facility][:device_name],
            registered_by: params[:scan_facility][:registered_by],
            facility_id: @facility_id,
            organisation_id: @organisation_id,
            last_activity_date: params[:scan_facility][:last_activity_date],
            registered_since: params[:scan_facility][:registered_since],
            qr_auth_token: params[:scan_facility][:qr_auth_token],
            user_id: @user.id,
            organisation_name: params[:scan_facility][:organisation_name],
            organisation_logo: params[:scan_facility][:organisation_logo],
            country_name: params[:scan_facility][:country_name]
          )
          if @facility_device.save
            render json: { msg: 'success!!', status: '200' }
          else
            render json: { msg: "failed!!#{@facility_device.errors.full_messages}", status: '500' }
          end
        end

        def validate_psr_user
          @user_name = User.find_by(username: params[:username])
          @user_email = User.find_by(email: params[:email])
          if @user_name.present? || @user_email.present?
            render json: { msg: "Username/email already used in FOSS", status: '403' }
          else
            render json: { msg: 'success!!', status: '200' }
          end
        end

        private

        def update_user
          @user.update(organisation_id: @organisation_id, facility_ids: [@facility_id])
        end

        def create_user
          @user = User.new(username: params[:username],
                           email: params[:email],
                           fullname: params[:username],
                           password: 'Healthgraph@12',
                           integration_identifier: @integration_identifier,
                           facility_ids: [@facility_id],
                           employee_id: @emp_id,
                           organisation_id: @organisation_id)
          @user.save!
        end

        def check_for_facility_organisation
          org = Organisation.find_by(_id: @organisation_id)
          fac = Facility.find_by(_id: @facility_id)
          if org.present?
            if org.facilities.include? fac
              true
            else
              render :json => { :msg => "Facility not available", status: 500 } and return
            end
          else
            render :json => { :msg => "Facility not available", status: 500 } and return
          end
        end

        def bsonify_variable
          @facility_id = BSON::ObjectId(params[:scan_facility][:facility_id])
          @organisation_id = BSON::ObjectId(params[:scan_facility][:organisation_id])
          @integration_identifier = BSON::ObjectId.new
          @emp_id = SecureRandom.hex(5)
        end
      end
    end
  end
end
