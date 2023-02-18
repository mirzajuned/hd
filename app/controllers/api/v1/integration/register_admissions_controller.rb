module Api
  module V1
    module Integration
      class RegisterAdmissionsController < ApiApplicationController
        before_action :doorkeeper_authorize!
        after_action :create_data_request, :create_data_response

        respond_to :json

        def create
          @original_params = params.dup
          params_received
          find_organisation
          find_facility
          find_case_appointment_data
          find_admission_data
          find_users
          find_patient
          find_admission
          find_case_appointment
          find_case_sheet
          additional_params

          begin
            exceptions

            @patient = if @patient.present?
                         Patients::UpdateService.call(@patient.id, params, @doctor) # Call Patient UpdateService
                       else
                         Patients::CreateService.call(params, @doctor, @facility) # Call Patient CreateService
                       end

            # Create Admission

            if @patient.present?
              if @admission.nil?
                create_admission

              else
                raise ::Errors::AdmissionAlreadyExists.new(
                  @admission.admissiondate.strftime('%d/%m/%Y'), @mr_no, 'Failed'
                )
              end
            end

            @status_message = 'Admission Created Succesfully'
            @status = 'Success'
            @status_code = 200
            @method_type = 'Create'

            update_data_received
            update_response_sent

            @message = { message: @status_message, status: @status, status_code: @status_code, data: {
              facility_integration_identifier: @facility_integration_identifier,
              organisation_integration_identifier: @organisation_integration_identifier, mr_no: @mr_no
            } }
          rescue StandardError => e
            @status_message = e.try(:message) || 'Invalid Request'
            @status = e.try(:status) || 'Failed'
            @status_code = 400
            @method_type = 'Create'

            update_data_received
            update_response_sent

            @message = { message: @status_message, status: @status, status_code: @status_code, data: {
              facility_integration_identifier: @facility_integration_identifier,
              organisation_integration_identifier: @organisation_integration_identifier, mr_no: @mr_no
            } }
          end
        end

        def update
          @original_params = params.dup
          params_received
          find_organisation
          find_facility
          find_case_appointment_data
          find_admission_data
          find_users
          find_patient
          find_admission
          find_case_appointment
          find_case_sheet
          additional_params

          begin
            exceptions
            @patient = Patients::UpdateService.call(@patient.id, params, @doctor) # Call Patient UpdateService

            # Update Admission

            update_admission if @admission.present?
            @status_message = 'Admission Updated Succesfully'
            @status = 'Success'
            @status_code = 200
            @method_type = 'Update'

            update_data_received
            update_response_sent

            @message = { message: @status_message, status: @status, status_code: @status_code, data: {
              facility_integration_identifier: @facility_integration_identifier,
              organisation_integration_identifier: @organisation_integration_identifier,
              mr_no: @mr_no, admission_integration_identifier: @admission_integration_identifier
            } }
          rescue StandardError => e
            @status_message = e.try(:message) || 'Invalid Request'
            @status = e.try(:status) || 'Failed'
            @status_code = 400
            @method_type = 'Update'

            update_data_received
            update_response_sent
            @message = { message: @status_message, status: @status, status_code: @status_code, data: {
              facility_integration_identifier: @facility_integration_identifier,
              organisation_integration_identifier: @organisation_integration_identifier,
              mr_no: @mr_no, admission_integration_identifier: @admission_integration_identifier
            } }
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
            @patient_type_info = @patient_params[:patient_type].to_s
            @patient_visit_category = @patient_params[:patient_visit_category].to_s
            @patient_category = @patient_params[:patient_category].to_s
          end

          @admission_params = params[:admission]

          if @admission_params
            @admission_integration_identifier = @admission_params[:admission_integration_identifier] || @admission_params[:admission_id]
            @facility_integration_identifier = @admission_params[:facility_integration_identifier] || @admission_params[:facility_code]
            @organisation_integration_identifier = @admission_params[:organisation_integration_identifier].to_s
            @admission_date = Time.parse(@admission_params[:admission_date]) || Time.current
            @doctor_integration_identifier = @admission_params[:doctor_integration_identifier].to_s
            # @referral_text = @appointment_params[:referral_text].to_s
            # @appointment_type = @appointment_params[:appointment_type].to_s
            # @token_number = @appointment_params[:token_no].to_i
            # @doctor_employee_id = @appointment_params[:doctor_employee_id].to_s
            @registered_admission = true
          end

          @case_appointment = params[:case_appointment]
          if @case_appointment
            @appointment_integration_identifier = @case_appointment[:appointment_integration_identifier].to_s
          end

          @procedures_received = params[:procedures]

          # @employee_integration_identifier = params[:created_by].to_s
          @employee_integration_identifier = @doctor_integration_identifier
          @employee_id = params[:created_by].to_s
        end

        def find_organisation
          @organisation = Organisation.find_by(integration_identifier: @organisation_integration_identifier)
        end

        def find_facility
          @facility = Facility.find_by(
            integration_identifier: @facility_integration_identifier, organisation_id: @organisation.id
          )
          if @facility.blank?
            @facility = Facility.find_by(abbreviation: @facility_code, organisation_id: @organisation.id)
          end
        end

        def find_case_appointment_data
          if @appointment_integration_identifier.present?
            @appointment_data = ApiIntegration::Appointment::Data.find_by(
              appointment_integration_identifier: @appointment_integration_identifier, status_code: 200,
              method_type: 'Create'
            )
          end
        end

        def find_admission_data
          @admission_data = ApiIntegration::Admission::Data.find_by(
            admission_integration_identifier: @admission_integration_identifier, status_code: 200,
            method_type: 'Create'
          )
        end

        def find_users
          if @doctor_integration_identifier.present?
            @doctor = User.find_by(integration_identifier: @doctor_integration_identifier,
                                   facility_ids: @facility&.id, role_ids: 158965000, is_active: true)
          end
          if @doctor.blank?
            @doctor = User.find_by(employee_id: @doctor_employee_id, facility_ids: @facility&.id, role_ids: 158965000, is_active: true)
          end
          if @employee_integration_identifier.present?
            @user = User.find_by(integration_identifier: @employee_integration_identifier, is_active: true)
          end
          @user = User.find_by(employee_id: @employee_id, is_active: true) if @user.blank?
        end

        def find_patient
          @patient_other_identifier = PatientOtherIdentifier.find_by(mr_no: @mr_no)
          @patient = Patient.find_by(
            id: @patient_other_identifier.try(:patient_id), reg_hosp_ids: @facility&.organisation_id.to_s
          )
        end

        def find_case_appointment
          if @appointment_data.present?
            @appointment = Appointment.find_by(
              integration_identifier: @appointment_data.appointment_integration_identifier_bson
            )
          end
        end

        def find_case_sheet
          if @appointment.present?
            @case_sheet_id = @appointment.try(:case_sheet_id)
            @case_sheet = CaseSheet.find_by(id: @case_sheet_id)
          else
            @case_sheets = CaseSheet.where(patient_id: @patient.try(:id).to_s, is_active: true)
            @case_sheet = @case_sheets.find_by(specialty_id: '309988001')
            @case_sheet_id = @case_sheet.try(:id).to_s
          end
        end

        def find_admission
          if @patient.present? && @facility.present? && @admission_data.nil? && params[:action] == 'create'
            @admission = Admission.find_by(patient_id: @patient.id, isdischarged: false, is_deleted: false)
          elsif @admission_data.present? && params[:action] == 'update'
            @admission = Admission.find_by(
              integration_identifier: @admission_data.admission_integration_identifier_bson
            )
          end
        end

        def additional_params
          # Additional Params for Patient
          params[:patient][:patientassets_attributes] = { '0' => { 'asset_path_data_uri' => '' } }
          params[:patient][:patient_type_info] = @patient_type_info
          params[:patient_other_identifier] = { mr_no: @mr_no }
          params[:patient_registration_source] = {}
          params[:patient_history] = {
            patient_id: @patient.try(:id).to_s,
            patientallergyhistory_attributes: { others: '' },
            patientpersonalhistory_attributes: {
              opthal_history_comment: '', history_comment: '', medical_history_comment: '', family_history_comment: ''
            }
          }

          # Addition Params for Appointment
          display_id = (CommonHelper.get_ipd_record_identifier(@doctor) if @doctor.present?) || nil
          params[:admission] = {
            patient_id: @patient.try(:id).to_s,
            display_id: display_id,
            organisation_id: @facility&.organisation_id.to_s,
            facility_id: @facility&.id.to_s,
            user_id: @user.try(:id).to_s,
            doctor: @doctor.try(:id).to_s,
            specialty_id: '309988001',
            start_time: @admission_date,
            admissiondate: @admission_date,
            patient_visit_category: @patient_visit_category,
            patient_category: @patient_category,
            department_id: '486546481',
            created_from: 'Integration',
            insurance_status: 'Waiting',
            case_sheet_id: @case_sheet_id.to_s,
            is_insured: 'No',
            admission_milestones_attributes: {
              '0' => { user_id: @user.try(:id).to_s, label: 'admission_scheduled', position: 1 }
            }
          }

          return if @case_sheet.blank?

          params['case_sheet'] = {}

          params['case_sheet']['case_id'] = @case_sheet.case_id
          params['case_sheet']['case_name'] = @case_sheet.case_name.to_s
          params['case_sheet']['start_date'] = @case_sheet.start_date

          case_sheet_diagnosis = {}
          @case_sheet.diagnoses.each_with_index { |a, i| case_sheet_diagnosis[i.to_s] = a.try(:attributes).merge('id': a['_id'].to_s) }
          params['case_sheet']['diagnoses'] = case_sheet_diagnosis

          case_sheet_procedures = {}

          @case_sheet.procedures.each_with_index do |a, i|
            case_sheet_procedures[i.to_s] = a.try(:attributes).slice(
              '_id', 'procedurestage', 'procedurename', 'procedure_id', 'procedure_performed', 'procedureoriginalside',
              'procedureside', 'procedurefullcode', 'procedure_type', 'entered_from', 'entered_by', 'entered_by_id',
              'entered_datetime', 'entered_at_facility', 'entered_at_facility_id', 'procedure_comment', 'users_comment',
              'advised_by', 'advised_by_id', 'advised_datetime', 'advised_from', 'advised_at_facility',
              'advised_at_facility_id', 'flow_in_ipd'
            ).merge('id': a['_id'].to_s)
          end

          @procedures_received.each_with_index do |procedure_received, _i|
            LoggerService.new.integration(
              procedure_received['code'], 'integration', 'procedure_received_code'
            )

            laterality_received = if procedure_received['lateral'].try(:downcase) == 'right'
                                    '18944008'
                                  elsif procedure_received['lateral'].try(:downcase) == 'left'
                                    '8966001'
                                  else
                                    ''
                                  end

            converted_procedure = get_converted_procedure(
              case_sheet_procedures, procedure_received, laterality_received
            )

            if converted_procedure.present?
              converted_procedure['flow_in_ipd'] = 'true'
              converted_procedure['id'] = converted_procedure['_id'].to_s
              converted_procedure['entered_by_id'] = converted_procedure['entered_by_id'].to_s
              converted_procedure['entered_at_facility_id'] = converted_procedure['entered_at_facility_id'].to_s
              converted_procedure['advised_by_id'] = converted_procedure['advised_by_id'].to_s
              converted_procedure['advised_at_facility_id'] = converted_procedure['advised_at_facility_id'].to_s
            else

              custom_procedure = CustomCommonProcedure.find_by(
                code: procedure_received['code'], organisation_id: @organisation.id
              )

              if custom_procedure.present?
                converted_procedure = {}
                converted_procedure['procedurestage'] = 'Advised'
                converted_procedure['procedurename'] = custom_procedure.name
                converted_procedure['procedure_id'] = custom_procedure.code
                converted_procedure['procedure_performed'] = ''
                converted_procedure['procedureoriginalside'] = laterality_received
                converted_procedure['procedureside'] = laterality_received
                converted_procedure['procedurefullcode'] = custom_procedure.code
                converted_procedure['procedure_type'] = custom_procedure.procedure_type
                converted_procedure['entered_by'] = @doctor.try(:fullname)
                converted_procedure['entered_by_id'] = @doctor.id.to_s
                converted_procedure['entered_datetime'] = Date.current
                converted_procedure['entered_at_facility'] = @facility.name
                converted_procedure['entered_at_facility_id'] = @facility.id.to_s
                converted_procedure['procedure_comment'] = ''
                converted_procedure['users_comment'] = ''
                converted_procedure['flow_in_ipd'] = 'true'
              end

              if converted_procedure.present?
                case_sheet_procedures = case_sheet_procedures.merge(
                  case_sheet_procedures.size.to_s => converted_procedure
                )
              end
            end
          end

          LoggerService.new.integration(case_sheet_procedures, 'integration', 'case_sheet_procedures')

          params['case_sheet']['procedures'] = case_sheet_procedures
        end

        def get_converted_procedure(case_sheet_procedures, procedure_received, laterality_received)
          case_sheet_procedures.each do |_k, cs_procedure|
            if (cs_procedure['procedurefullcode'] == procedure_received['code']) && (cs_procedure['procedureside'] == laterality_received) && procedure_received['status'].try(:downcase) == 'converted'
              return cs_procedure
            end
          end
          {}
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
            admission_date: @admission_date,
            procedures_received: @procedures_received.as_json,
            case_appointment_identifier: @appointment_integration_identifier,
            patient_visit_category: @patient_visit_category,
            patient_category: @patient_category,
            token_number: @token_number,
            employee_integration_identifier: @employee_integration_identifier,
            doctor_integration_identifier: @doctor_integration_identifier,
            facility_integration_identifier: @facility_integration_identifier,
            organisation_integration_identifier: @organisation_integration_identifier,
            admission_integration_identifier: @admission_integration_identifier,
            organisation_id: @organisation.try(:id),
            facility_id: @facility.try(:id),
            admission_integration_identifier_bson: @admission.try(:integration_identifier),
            received_date: Date.current,
            received_time: Time.current,
            request_type: 'Received',
            method_type: @method_type,
            status: @status,
            status_code: @status_code,
            registered_admission: true,
            message: @status_message }
        end

        def update_data_received
          # Save ReceivedData
          @admission_data = ApiIntegration::Admission::Data.new(data_received_params)
          @admission_data.save!
        end

        def update_response_sent
          @response_sent = ApiIntegration::Admission::ResponseSent.new(
            status: @status, status_code: @status_code, message: @status_message,
            admission_integration_identifier: @admission_integration_identifier, mr_no: @mr_no
          )
          @response_sent.save!
        end

        def create_admission
          @admission = Admission::CreateService.call(params[:admission], @user, @patient, true)

          current_user = @doctor

          if @admission.present?

            @admission_list_view = AdmissionListView.find_by(admission_id: @admission.id)

            # StateMachine Logic
            user_role = current_user.primary_role
            if ['receptionist', 'nurse', 'doctor', 'counsellor', 'tpa'].include?(user_role)
              admitting_user_id = current_user.id
              @admission_list_view.send("assign_to_#{user_role}", current_user.id, 'user', '')
            else
              admitting_user_id = @admission.doctor
              @admission_list_view.send('assign_to_doctor', @admission.doctor, 'user', '')
            end

            facility_id = @admission.facility_id
            specialty_id = @admission.specialty_id
            AdmissionListViewsHelper.update_redis_counter(facility_id, specialty_id, admitting_user_id, 'inc')

            # CaseSheet
            CaseSheet::CreateAdmissionService.call(@patient, @admission, params[:case_sheet], current_user.id.to_s, facility_id.to_s)

            # Reports::Ipd::Admissions.call(@admission)
            Patients::Summary::TimelineWorker.call(
              event_name: 'IPD_ADMISSION', sub_event_name: 'SCHEDULED', admission_id: @admission.id,
              user_id: current_user.id, user_name: current_user.fullname
            )
            # IpdRecord
            IpdRecords::CreateService.call(@admission, params[:case_sheet], 'Admission')

          end
        end

        def update_admission
          @admission = Admission::UpdateService.call(params[:admission], @user, @admission, true)
        end

        def exceptions
          # No Params
          if @patient_params.nil? && @admission_params.nil? && @employee_integration_identifier.nil?
            raise Errors::NoParams
          end

          # Field Missing
          raise Errors::FieldMissing, 'MR No.' if @mr_no.blank?
          raise Errors::FieldMissing, 'First Name' if @first_name.blank?
          raise Errors::FieldMissing, 'Mobile Number' if @mobile_number.blank?
          if @facility_integration_identifier.blank? && @facility_code.blank?
            raise Errors::FieldMissing, 'Facility Identifier'
          end
          raise Errors::FieldMissing, 'Admission ID' if @admission_integration_identifier.blank?
          raise Errors::FieldMissing, 'Admission Date' if @admission_date.blank?
          if @doctor_integration_identifier.blank? && @doctor_employee_id.blank?
            raise Errors::FieldMissing, 'Doctor Integration Identifier'
          end
          raise Errors::FieldMissing, 'Employee ID' if @employee_integration_identifier.blank? && @employee_id.blank?

          # find_by Nil
          raise Errors::FindByNil.new('Facility', 'FacilityCode') if @facility.nil?
          raise Errors::FindByNil.new('CaseSheet', 'patient') if @case_sheet.nil?
          # raise Errors::FindByNil.new('Appointment', 'AppointmentId') if @appointment.nil?
          raise Errors::FindByNil.new('Doctor', 'DoctorId') if @doctor.nil?
          raise Errors::FindByNil.new('User', 'UserId') if @user.nil?
          raise Errors::FindByNil.new('Admission', 'AsmissionId') if @admission.nil? && params[:action] == 'update'

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

          # Admission Existance by AdmissionID
          if @admission_data.present? && params[:action] == 'create'
            raise ::Errors::AdmissionIdAlreadyExists, @admission_data.admission_integration_identifier
          end
        end

        def doorkeeper_unauthorized_render_options(error: nil)
          { json: { status: 'Failed', message: 'Authentication Failed' } }
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
