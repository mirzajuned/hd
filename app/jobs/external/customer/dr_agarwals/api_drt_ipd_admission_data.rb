class External::Customer::DrAgarwals::ApiDrtIpdAdmissionData < ActiveJob::Base

	def perform(mandatory, optional = {}, others = {})
		payload = {}
		Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdAdmissionData :: perform method :: mandatory fields :: #{mandatory}")
		Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdAdmissionData :: perform method :: optional fields  :: #{optional}")
		Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdAdmissionData :: perform method :: others fields  :: #{others}")

		admission_id = "#{mandatory['admission_id'].to_s}"
		admission_info = IpdService::Read.get_admission_attributes(admission_id, [:display_id, :admissiondate, :admissiontime, :dischargedate, :dischargetime, :admissionreason, :doctor, :facility_id, :patient_id, :insurance_name, :insurance_address, :insurance_email, :insurance_contact_no, :insurance_contact_person, :tpa_name, :tpa_contact_id, :tpa_contact_no, :tpa_address, :tpa_email, :tpa_contact_person, :patient_contact_person, :insurance_policy_no, :insurance_policy_expiry_date, :insurance_type, :company_name, :employee_id, :document_passport, :document_aadharcard, :document_electioncard, :document_insurancecard, :document_employeecard, :document_others, :document_tpa_form, :sum_insured, :insurance_comments])

		patient_id = "#{admission_info['patient_id'].to_s}"
		facility_id = "#{admission_info['facility_id'].to_s}"
		user_id = "#{admission_info['doctor'].to_s}" # consultant id or doctor
		facility_info = Facilitydata::Read.get_facility_attributes(facility_id, [:name])
		user_info = Userdata::Read.get_user_attributes(user_id, [:fullname])
		patient_info = Patientdata::Read.get_patient_attributes(patient_id, [:_id, :fullname])
		patient_other_info = Patientdata::Read.get_patient_other_attributes(patient_id, [:mr_no])

		payload["patient_name"] = CommonHelper::RubyStrings.if_nil_return_empty("#{patient_info['fullname']}")
		payload["patient_mrn"] = CommonHelper::RubyStrings.if_nil_return_empty("#{patient_other_info['mr_no']}")
		payload["admissionid"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['display_id']}")
		payload["admissiondate"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['admissiondate']}")
		payload["admissiontime"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['admissiontime']}")
		payload["dischargedate"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['dischargedate']}")
		payload["dischargetime"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['dischargetime']}")
		payload["admissionreason"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['admissionreason']}")
		payload["consultant_name"] = CommonHelper::RubyStrings.if_nil_return_empty("#{user_info['fullname']}")
		payload["branch_id"] = "#{facility_id}"
	  payload["branch_name"] = CommonHelper::RubyStrings.if_nil_return_empty("#{facility_info['name']}")
		payload["insurance_name"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['insurance_name']}")
		payload["insurance_address"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['insurance_address']}")
		payload["insurance_email"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['insurance_email']}")
		payload["insurance_contact_no"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['insurance_contact_no']}")
		payload["insurance_contact_person"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['insurance_contact_person']}")
		payload["tpa_name"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['tpa_name']}")
		payload["tpa_contact_id"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['tpa_contact_id']}")
		payload["tpa_contact_no"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['tpa_contact_no']}")
		payload["tpa_address"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['tpa_address']}")
		payload["tpa_email"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['tpa_email']}")
		payload["tpa_contact_person"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['tpa_contact_person']}")
		payload["patient_contact_person"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['patient_contact_person']}")
		payload["insurance_policy_no"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['insurance_policy_no']}")
		payload["insurance_policy_expiry_date"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['insurance_policy_expiry_date']}")
		payload["insurance_type"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['insurance_type']}")
		payload["company_name"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['company_name']}")
		payload["employee_id"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['employee_id']}")
		payload["document_passport"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['document_passport']}")
		payload["document_aadharcard"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['document_aadharcard']}")
		payload["document_electioncard"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['document_electioncard']}")
		payload["document_insurancecard"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['document_insurancecard']}")
		payload["document_employeecard"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['document_employeecard']}")
		payload["document_others"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['document_others']}")
		payload["document_tpa_form"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['document_tpa_form']}")
		payload["sum_insured"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['sum_insured']}")
		payload["insurance_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{admission_info['insurance_comments']}")

		Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdAdmissionData :: perform method :: payload data :: #{payload}")

	  client = mandatory["job_customer"]
	  url = mandatory["external_api"]
	  begin
	    response = send_order_request(client, url, payload)
	    @status = response.try(:[], 'status')
	    @status_code = 200
	    @response_code = response.try(:[], 'responseCode')
	    @message = response.try(:[], 'errorMessage') || 'Success'
	    @response = response
	    @response_data = response.try(:[], 'response').try(:[], 'data')
	  rescue StandardError
	    # @user_integration_identifier = user.integration_identifier
	    @status = 'Failed'
	    @status_code = 500
	    @response_code = 500
	    @message = 'No Response Received'
	    @response = {}
	    @response_data = {}
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdAdmissionData :: perform method :: StandardError error :: INSIDE EXECPTION ::")
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdAdmissionData :: perform method :: StandardError error :: e.inspect :: #{e.inspect}")
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdAdmissionData :: perform method :: StandardError error :: e.backtrace :: #{e.backtrace}")
	  end
		Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdAdmissionData :: perform method :: @response data :: #{@response}")
	end

  private

		def send_order_request(client, url, payload)
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdAdmissionData :: send_order_request method :: client data :: #{client}")
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdAdmissionData :: send_order_request method :: url data :: #{url}")
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdAdmissionData :: send_order_request method :: payload data :: #{payload}")
			begin
				request = RestClient::Request.execute(method: :post, url: url, payload: payload.to_json, headers: { 'Content-Type' => 'application/json' })
				response = JSON.parse(request)
				Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdAdmissionData :: send_order_request method :: RestClient::Request :: response data :: #{response}")
			rescue StandardError => e
				Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdAdmissionData :: send_order_request method :: StandardError error :: INSIDE EXECPTION ::")
				Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdAdmissionData :: send_order_request method :: StandardError error :: e.inspect :: #{e.inspect}")
				Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdAdmissionData :: send_order_request method :: StandardError error :: e.backtrace :: #{e.backtrace}")
			end
			response
		end

end # end of class
