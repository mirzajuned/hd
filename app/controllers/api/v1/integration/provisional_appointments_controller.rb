module Api
  module V1
    module Integration
      class ProvisionalAppointmentsController < ApiApplicationController
        before_action :doorkeeper_authorize!
        after_action :create_data_request, :create_data_response
        respond_to :json
        # before_action :params_received

        def create
          @original_params = params.dup
          params_received
          find_organisation
          find_facility
          find_appointment_data
          find_users
          find_appointment
          additional_params
          begin
            exceptions
            if @provisional_appointment.nil?
              @provisional_appointment = ProvisionalAppointments::CreateService.call(
                provisional_params, @user, @facility, true
              )
            else
              raise Errors::AppointmentAlreadyExists.new(@provisional_appointment.appointmentdate.strftime('%d/%m/%Y'), @mr_no, 'Failed')
            end
            @status_message = 'Appointment Created Succesfully'
            @status = 'Success'
            @status_code = 200
            @method_type = 'Create'

            update_data_received
            update_response_sent

            @message = { message: @status_message, status: @status, status_code: @status_code, data: { facility_integration_identifier: @facility_integration_identifier, organisation_integration_identifier: @organisation_integration_identifier } }
          rescue StandardError => e
            @status_message = e.try(:message) || 'Invalid Request'
            @status = e.try(:status) || 'Failed'
            @status_code = 400
            @method_type = 'Create'

            update_data_received
            update_response_sent

            @message = { message: @status_message, status: @status, status_code: @status_code, data: { facility_integration_identifier: @facility_integration_identifier, organisation_integration_identifier: @organisation_integration_identifier } }
          end
        end

        def update
          @original_params = params.dup
          params_received
          find_organisation
          find_facility
          find_appointment_data
          find_users
          find_appointment
          additional_params
          begin
            exceptions
            @provisional_appointment.skip_validation = true
            @provisional_appointment.update(provisional_params)

            @status_message = 'Appointment Updated Succesfully'
            @status = 'Success'
            @status_code = 200
            @method_type = 'Update'

            update_data_received
            update_response_sent
            @message = { message: @status_message, status: @status, status_code: @status_code, data: { facility_integration_identifier: @facility_integration_identifier, organisation_integration_identifier: @organisation_integration_identifier } }
          rescue StandardError => e
            @status_message = e.try(:message) || 'Invalid Request'
            @status = e.try(:status) || 'Failed'
            @status_code = 400
            @method_type = 'Update'

            update_data_received
            update_response_sent
            @message = { message: @status_message, status: @status, status_code: @status_code, data: { facility_integration_identifier: @facility_integration_identifier, organisation_integration_identifier: @organisation_integration_identifier } }
          end
        end

        private

        def params_received
          @patient_params = params[:patient]

          if @patient_params
            @mr_no = @patient_params[:mr_no].to_s.upcase.strip
            unless ['Mr.', 'Mrs.', 'Ms.', 'Mx.', 'Dr.', 'Mst.', 'Baby', 'Sr.'].include?(@patient_params[:salutation].to_s)
              @patient_params[:salutation] = ''
            end
            @salutation = @patient_params[:salutation].to_s
            @first_name = @patient_params[:firstname] = @patient_params[:first_name].to_s
            @middle_name = @patient_params[:middlename] = @patient_params[:middle_name].to_s
            @last_name = @patient_params[:lastname] = @patient_params[:last_name].to_s
            @mobile_number = @patient_params[:mobilenumber] = @patient_params[:mobile_number].to_s
            @email = @patient_params[:email] = @patient_params[:email_id].to_s
            @dob = @patient_params[:dob].to_s
            @age = @patient_params[:age].to_s
            @age_month = @patient_params[:age_month].to_s
            @gender = @patient_params[:gender].to_s
            @address1 = @patient_params[:address_1].to_s
            @address2 = @patient_params[:address_2].to_s
            @address1 = @address1.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '!')
            @address2 = @address2.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '!')
            @city = @patient_params[:city].to_s
            @state = @patient_params[:state].to_s
            @pincode = @patient_params[:pincode].to_s
            @facility_code = @patient_params[:facility_code].to_s
            @referral_type = @patient_params[:referral_type].to_s
          end

          @appointment_params = params[:appointment]
          if @appointment_params
            @appointment_integration_identifier = @appointment_params[:appointment_integration_identifier] || @appointment_params[:appointment_id]
            @facility_integration_identifier = @appointment_params[:facility_integration_identifier] || @appointment_params[:facility_code]
            @organisation_integration_identifier = @appointment_params[:organisation_integration_identifier]
            @appointment_date = Time.parse(@appointment_params[:appointment_date]) || Time.current
            @doctor_integration_identifier = @appointment_params[:doctor_integration_identifier].to_s
            @token_number = @appointment_params[:token_no].to_i
            @doctor_employee_id = @appointment_params[:doctor_employee_id].to_s
            @registered_appointment = false
            @created_from = @appointment_params[:created_from] || 'Integration'
          end

          @employee_integration_identifier = @doctor_integration_identifier
          @employee_id = params[:created_by].to_s
        end

        def find_organisation
          @organisation = Organisation.find_by(integration_identifier: @organisation_integration_identifier)
        end

        def find_facility
          if @facility_integration_identifier.present?
            @facility = Facility.find_by(integration_identifier: @facility_integration_identifier, organisation_id: @organisation.id)
          end
          if @facility.blank?
            @facility = Facility.find_by(abbreviation: @facility_code, organisation_id: @organisation.id)
          end
        end

        def find_appointment_data
          @appointment_data = ApiIntegration::Appointment::Data.find_by(appointment_integration_identifier: @appointment_integration_identifier, registered_appointment: @registered_appointment, status_code: 200, method_type: 'Create')
        end

        def find_users
          Rails.logger.info("==========================@@doctor_integration_identifier========================#{@doctor_integration_identifier}")
          if @doctor_integration_identifier.present?
            @doctor = User.find_by(integration_identifier: @doctor_integration_identifier, facility_ids: @facility&.id, role_ids: 158965000, is_active: true)
          end
          if @doctor.blank?
            @doctor = User.find_by(employee_id: @doctor_employee_id, facility_ids: @facility&.id, role_ids: 158965000, is_active: true)
          end
          if @employee_integration_identifier.present?
            @user = User.find_by(integration_identifier: @employee_integration_identifier, is_active: true)
          end
          @user = User.find_by(employee_id: @employee_id, is_active: true) if @user.blank?
          Rails.logger.info("==========================@doctor========================#{@doctor}")
        end

        def find_appointment
          if @appointment_data.present?
            @provisional_appointment = ProvisionalAppointment.find_by(integration_identifier: @appointment_data.appointment_integration_identifier_bson)
          end
        end

        def additional_params
          # Addition Params for Appointment
          params[:appointment] = {
            organisation_id: @facility&.organisation_id.to_s,
            facility_id: @facility&.id.to_s,
            user_id: @user.try(:id).to_s,
            consultant_id: @doctor.try(:id).to_s,
            specialty_id: '309988001',
            start_time: @appointment_date,
            appointmentdate: @appointment_date,
            department_id: @doctor.try(:department_id).to_s,
            created_from: @created_from || 'Integration',
            registered_appointment: false
          }
        end

        def data_received_params
          { first_name: @first_name,
            last_name: @last_name,
            mobile_number: @mobile_number,
            email: @email,
            age: @age,
            age_month: @age_month,
            gender: @gender,
            mr_no: @mr_no,
            appointment_date: @appointment_date,
            referral_type: @referral_type,
            employee_integration_identifier: @employee_integration_identifier,
            doctor_integration_identifier: @doctor_integration_identifier,
            facility_integration_identifier: @facility_integration_identifier,
            organisation_integration_identifier: @organisation_integration_identifier,
            organisation_id: @organisation.try(:id),
            facility_id: @facility.try(:id),
            appointment_integration_identifier: @appointment_integration_identifier,
            appointment_integration_identifier_bson: @provisional_appointment.try(:integration_identifier),
            received_date: Date.current,
            received_time: Time.current,
            request_type: 'Received',
            method_type: @method_type,
            status: @status,
            status_code: @status_code,
            message: @status_message }
        end

        def provisional_params
          appointment_params.merge(patient_params)
        end

        def appointment_params
          params.require(:appointment).permit(
            :facility_id, :consultant_id, :appointment_type_id, :appointmentdate, :start_time, :patient_id, :department_id, :consultant_id,
            :organisation_id, :user_id, :display_id, :created_from, :opd_referral_id, :referral, :referral_created_on,
            :referring_doctor, :referee_doctor, :to_facility_name, :from_facility_name, :referral_text, :referral_note,
            :integration_identifier, :specialty_id, :token_number, :registered_appointment
          )
        end

        def patient_params
          params.require(:patient).permit(
            :firstname, :lastname, :middlename, :mobilenumber, :salutation, :gender, :age, :age_month, :dob, :email,
            :address_1, :address_2, :commune, :city, :state, :pincode
          )
        end

        def update_data_received
          # Save ReceivedData
          @appointment_data = ApiIntegration::Appointment::Data.new(data_received_params)
          @appointment_data.save!
        end

        def update_response_sent
          @response_sent = ApiIntegration::Appointment::ResponseSent.new(status: @status, status_code: @status_code, message: @status_message, appointment_integration_identifier: @appointment_integration_identifier)
          @response_sent.save!
        end

        def exceptions
          # No Params
          if @patient_params.nil? && @appointment_params.nil? && @employee_integration_identifier.nil?
            raise Errors::NoParams
          end

          # Field Missing
          # raise Errors::FieldMissing.new('MR No.') if @mr_no.blank?
          raise Errors::FieldMissing, 'First Name' if @first_name.blank?
          raise Errors::FieldMissing, 'Mobile Number' if @mobile_number.blank?
          if @facility_integration_identifier.blank? && @facility_code.blank?
            raise Errors::FieldMissing, 'Facility Identifier'
          end
          raise Errors::FieldMissing, 'Appointment ID' if @appointment_integration_identifier.blank?
          raise Errors::FieldMissing, 'Appointment Date' if @appointment_date.blank?
          if @doctor_integration_identifier.blank? && @doctor_employee_id.blank?
            raise Errors::FieldMissing, 'Doctor Integration Identifier'
          end
          raise Errors::FieldMissing, 'Employee ID' if @employee_integration_identifier.blank? && @employee_id.blank?

          # find_by Nil
          raise Errors::FindByNil.new('Facility', 'FacilityCode') if @facility.nil?
          raise Errors::FindByNil.new('Doctor', 'DoctorId') if @doctor.nil?
          raise Errors::FindByNil.new('User', 'UserId') if @user.nil?
          if @provisional_appointment.nil? && params[:action] == 'update'
            raise Errors::FindByNil.new('Appointment', 'AppointmentId')
          end

          # Length Incorrect
          country = @facility&.country
          mobile_number = @mobile_number.gsub(/[^0-9]/, '').to_s.length
          if country.present?
            min = country.minimum_phone_no_length
            max = country.maximum_phone_no_length
            raise Errors::InvalidLength.new('Mobile Number', min, max) unless (min..max).cover?(mobile_number)
          end

          # has_role Incorrect
          raise Errors::HasRole, 'Doctor' unless @doctor.has_role?(:doctor)

          # Appointment Existance by  AppointmentID
          if @appointment_data.present? && params[:action] == 'create'
            raise Errors::AppointmentIdAlreadyExists, @appointment_data.appointment_integration_identifier
          end
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
