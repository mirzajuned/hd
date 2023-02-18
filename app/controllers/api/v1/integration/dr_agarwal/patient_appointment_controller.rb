module Api
  module V1
    module Integration
      module DrAgarwal
        class PatientAppointmentController < ApiApplicationController
          before_action :doorkeeper_authorize!
          respond_to :json

          before_action :params_received, :find_appointment_data, :find_organisation, :find_facility, :find_users, :find_patient, :find_appointment, :additional_params

          def create
            begin
              exceptions # Exception For All Scenarios

              # Create/Update Patient
              unless @patient.present?
                @patient = Patients::CreateService.call(params, @doctor, @facility)
                patient_message = "Created"
              else
                @patient = Patients::UpdateService.call(@patient.try(:id), params, @doctor)
                patient_message = "Updated"
              end

              # Create Appointment
              if @patient.present?
                if @appointment.nil?
                  @appointment = Appointment::CreateService.call(params[:appointment], @user, @patient, @facility, true)

                  # CaseSheet
                  CaseSheet::CreateAppointmentService.call(@patient, @appointment, @user, nil)

                  # Create Referral
                  create_referral

                else
                  raise Errors::AppointmentAlreadyExists.new(@appointment.appointmentdate.strftime('%d/%m/%Y'), @mr_no, "Failed")
                end
              end

              if @provisional_appointment_integration_identifier.present?
                update_provisional_appointment(@provisional_appointment_integration_identifier, @appointment.id)
              end

              @status_message = "Patient " + patient_message + " & Appointment Created Succesfully"
              @status = "Success"
              @status_code = 200
              @method_type = "Create"

              update_data_received
              update_response_sent

              @message = { message: @status_message, status: @status, status_code: @status_code, data: { facility_integration_identifier: @facility_integration_identifier, organisation_integration_identifier: @organisation_integration_identifier, mr_no: @mr_no } }
            rescue => e
              @status_message = e.try(:message) || "Invalid Request"
              @status = e.try(:status) || "Failed"
              @status_code = 400
              @method_type = "Create"

              update_data_received
              update_response_sent

              return @message = { message: @status_message, status: @status, status_code: @status_code, data: {} }
            end
          end

          def update
            begin
              exceptions # Exception For All Scenarios

              # Update Patient
              @patient = Patients::UpdateService.call(@patient.try(:id), params, @doctor)

              # Update Appointment
              @appointment.skip_validation = true
              @appointment.update(appointment_params)

              # Create Referral
              create_referral

              @status_message = "Appointment Updated Succesfully"
              @status = "Success"
              @status_code = 200
              @method_type = "Update"

              update_data_received
              update_response_sent
              @message = { message: @status_message, status: @status, status_code: @status_code, data: { facility_integration_identifier: @facility_integration_identifier, organisation_integration_identifier: @organisation_integration_identifier, mr_no: @mr_no, appointment_integration_identifier: @appointment_integration_identifier } }

              Patients::Summary::TimelineWorker.call({ event_name: "OPD_APPOINTMENT", sub_event_name: "EDITED", appointment_id: @appointment.id, user_id: @user.id, user_name: @user.fullname, workflow: @facility&.clinical_workflow })
            rescue => e
              @status_message = e.try(:message) || "Invalid Request"
              @status = e.try(:status) || "Failed"
              @status_code = 400
              @method_type = "Update"

              update_data_received
              update_response_sent
              return @message = { message: @status_message, status: @status, status_code: @status_code, data: {} }
            end
          end

          private

          def params_received
            @patient_params = params[:patient]
            if @patient_params
              @mr_no = @patient_params[:mr_no].to_s.upcase.strip
              unless ["Mr.", "Mrs.", "Ms.", "Mx.", "Dr.", "Mst.", "Baby", "Sr."].include?(@patient_params[:salutation].to_s)
                @patient_params[:salutation] = ""
              end
              @salutation = @patient_params[:salutation].to_s
              @first_name = @patient_params[:firstname] = @patient_params[:first_name].to_s
              @middle_name = @patient_params[:middlename] = @patient_params[:middle_name].to_s
              @last_name = @patient_params[:lastname] = @patient_params[:last_name].to_s
              @mobile_number = @patient_params[:mobilenumber] = @patient_params[:mobile_number].to_s
              @email = @patient_params[:email] = @patient_params[:email_id].to_s
              @dob = @patient_params[:dob].to_s
              @age = @patient_params[:age].to_s
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
              @appointment_integration_identifier = @appointment_params[:appointment_id].to_s
              @appointment_date = @appointment_params[:appointment_date].to_s
              @doctor_employee_id = @appointment_params[:doctor_employee_id].to_s
              @organisation_integration_identifier = @appointment_params[:organisation_integration_identifier].to_s
            end

            @provisional_appointment = params[:provisional_appointment]
            if @provisional_appointment
              @provisional_appointment_integration_identifier = @provisional_appointment[:appointment_integration_identifier].to_s
            end

            @employee_id = params[:created_by].to_s
          end

          def find_appointment_data
            @appointment_data = ApiIntegration::DrAgarwal::Appointment::Data.find_by(appointment_integration_identifier: @appointment_integration_identifier, status_code: 200, method_type: 'Create')
          end

          def find_facility
            @facility = Facility.find_by(abbreviation: @facility_code, organisation_id: @organisation.try(:id))
          end

          def find_users
            @doctor = User.find_by(employee_id: @doctor_employee_id, facility_ids: @facility&.id, role_ids: 158965000, is_active: true)
            @user = User.find_by(employee_id: @employee_id, is_active: true)
          end

          def find_patient
            @patient_other_identifier = PatientOtherIdentifier.find_by(mr_no: @mr_no)
            @patient = Patient.find_by(id: @patient_other_identifier.try(:patient_id), reg_hosp_ids: @facility&.organisation_id.to_s)
          end

          def find_organisation
            @organisation = Organisation.find_by(integration_identifier: @organisation_integration_identifier)
          end

          def find_appointment
            if @patient.present? && @facility.present? && @appointment_data.nil? && params[:action] == "create"
              appointment_date = (Date.parse(@appointment_date) if @appointment_date.present?) || Date.current
              @appointment = Appointment.find_by(facility_id: @facility&.id.to_s, patient_id: @patient.try(:id).to_s, appointmentdate: appointment_date, appointmentstatus: 416774000)
            elsif @appointment_data.present? && params[:action] == "update"
              @appointment = Appointment.find_by(integration_identifier: @appointment_data.appointment_integration_identifier_bson)
            end
          end

          def additional_params
            # Additional Params for Patient
            params[:patient][:patientassets_attributes] = { "0" => { "asset_path_data_uri" => "" } }
            params[:patient_other_identifier] = { mr_no: @mr_no }
            params[:patient_registration_source] = {}
            params[:patient_history] = {
                patient_id: @patient.try(:id).to_s,
                patientallergyhistory_attributes: { others: '' },
                patientpersonalhistory_attributes: { opthal_history_comment: "", history_comment: "", medical_history_comment: "", family_history_comment: "" }
            }

            # Addition Params for Appointment
            display_id = (CommonHelper.get_opd_record_identifier(@doctor) if @doctor.present?) || nil
            params[:appointment] = {
                patient_id: @patient.try(:id).to_s,
                display_id: display_id,
                organisation_id: @facility&.organisation_id.to_s,
                facility_id: @facility&.id.to_s,
                user_id: @user.try(:id).to_s,
                consultant_id: @doctor.try(:id).to_s,
                specialty_id: "309988001",
                start_time: @appointment_date,
                appointmentdate: @appointment_date,
                department_id: @doctor.try(:department_id).to_s,
                created_from: "Integration"
            }
          end

          def update_provisional_appointment(provisional_appointment_integration_identifier, appointment_id)
            @provisional_appointment_data = ApiIntegration::DrAgarwal::Appointment::Data.find_by(appointment_integration_identifier: provisional_appointment_integration_identifier, status_code: 200, method_type: 'Create')
            @provisional_appointment = ProvisionalAppointment.find_by(integration_identifier: @provisional_appointment_data.appointment_integration_identifier_bson)
            @provisional_appointment.update(appointment_id: appointment_id.to_s, converted: true)
          end

          def data_received_params
            { first_name: @first_name,
              last_name: @last_name,
              mobile_number: @mobile_number,
              email: @email,
              age: @age,
              gender: @gender,
              mr_no: @mr_no,
              appointment_date: @appointment_date,
              referral_type: @referral_type,
              employee_id: @employee_id,
              doctor_employee_id: @doctor_employee_id,
              abbreviation: @facility_code,
              appointment_integration_identifier: @appointment_integration_identifier,
              appointment_integration_identifier_bson: @appointment.try(:integration_identifier),
              received_date: Date.current,
              received_time: Time.current,
              request_type: "Received",
              method_type: @method_type,
              status: @status,
              status_code: @status_code,
              message: @status_message }
          end

          def appointment_params
            params.require(:appointment).permit(:facility_id, :doctor, :appointment_type_id, :appointmentdate, :start_time, :patient_id, :department_id, :organisation_id, :user_id, :display_id, :created_from, :opd_referral_id, :referral, :referral_created_on, :referring_doctor, :referee_doctor, :to_facility_name, :from_facility_name, :referral_note, :integration_identifier, :specialty_id, :consultant_id)
          end

          def update_data_received
            # Save ReceivedData
            @appointment_data = ApiIntegration::DrAgarwal::Appointment::Data.new(data_received_params)
            @appointment_data.save!
          end

          def update_response_sent
            @response_sent = ApiIntegration::DrAgarwal::Appointment::ResponseSent.new(status: @status, status_code: @status_code, message: @status_message, appointment_integration_identifier: @appointment_integration_identifier, mr_no: @mr_no)
            @response_sent.save!
          end

          def create_referral
            if @referral_type.present?
              @sub_referral_type = SubReferralType.find_by(referral_type_id: 'FS-RT-0010', organisation_id: @user.organisation_id, name: @referral_type)
              unless @sub_referral_type.present?
                @sub_referral_type = SubReferralType.new(name: @referral_type, user_id: @user.id, referral_type_id: "FS-RT-0010", organisation_id: @user.organisation_id, facility_ids: [@facility&.id], is_active: false)
                @sub_referral_type.save!
              end
              if @sub_referral_type.present?
                @patient_referral_type = PatientReferralType.find_by(patient_id: @patient.id)
                unless @patient_referral_type.present?
                  @patient_referral_type = PatientReferralType.new(referral_type_id: @sub_referral_type.referral_type_id, sub_referral_type_id: @sub_referral_type.id, patient_id: @patient.id, appointment_id: @appointment.id)
                  @patient_referral_type.save!
                else
                  @patient_referral_type.update(referral_type_id: @sub_referral_type.referral_type_id, sub_referral_type_id: @sub_referral_type.id, patient_id: @patient.id, appointment_id: @appointment.id)
                end
              end
            end
          end

          def exceptions
            # No Params
            raise Errors::NoParams if @patient_params.nil? && @appointment_params.nil? && @employee_id.nil?

            # Field Missing
            raise Errors::FieldMissing.new('MR No.') if @mr_no.blank?
            raise Errors::FieldMissing.new('First Name') if @first_name.blank?
            raise Errors::FieldMissing.new('Mobile Number') if @mobile_number.blank?
            raise Errors::FieldMissing.new('Facility Code') if @facility_code.blank?
            raise Errors::FieldMissing.new('Appointment ID') if @appointment_integration_identifier.blank?
            raise Errors::FieldMissing.new('Appointment Date') if @appointment_date.blank?
            raise Errors::FieldMissing.new('Doctor Employee ID') if @doctor_employee_id.blank?
            raise Errors::FieldMissing.new('Employee ID') if @employee_id.blank?

            # find_by Nil
            raise Errors::FindByNil.new("Facility", "FacilityCode") if @facility.nil?
            raise Errors::FindByNil.new("Doctor", "DoctorId") if @doctor.nil?
            raise Errors::FindByNil.new("User", "UserId") if @user.nil?
            raise Errors::FindByNil.new("Appointment", "AppointmentId") if @appointment.nil? && params[:action] == "update"

            # Length Incorrect
            country = @facility&.country
            mobile_number = @mobile_number.gsub(/[^0-9]/, '').to_s.length
            if country.present?
              min = country.minimum_phone_no_length
              max = country.maximum_phone_no_length
              raise Errors::InvalidLength.new('Mobile Number', min, max) unless (min..max).cover?(mobile_number)
            end

            # has_role Incorrect
            raise Errors::HasRole.new("Doctor") unless @doctor.has_role?(:doctor)

            # Appointment Existance by IDEAMED AppointmentID
            raise Errors::AppointmentIdAlreadyExists.new(@appointment_data.appointment_integration_identifier) if @appointment_data.present? && params[:action] == "create"
          end

          def doorkeeper_unauthorized_render_options(error: nil)
            { json: { status: "Failed", message: "Authentication Failed" } }
          end

          # Private Methods End
        end
      end
    end
  end
end
