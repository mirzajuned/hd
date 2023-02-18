class External::Customer::DrAgarwals::ApiDrtIpdDischargeData < ActiveJob::Base

	def perform(mandatory, optional = {}, others = {})
		payload = {}
    Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdDischargeData :: perform method :: mandatory fields :: #{mandatory}")
		Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdDischargeData :: perform method :: optional fields  :: #{optional}")
		Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdDischargeData :: perform method :: others fields  :: #{others}")

		admission_id = "#{mandatory['admission_id'].to_s}"
		admission_info = IpdService::Read.get_admission_attributes(admission_id, [:display_id, :admissiondate, :admissiontime, :dischargedate, :dischargetime, :admissionreason, :doctor, :facility_id, :patient_id])
		ipd_record_info = IpdService::Read.get_ipd_record_attributes(admission_id, [:diagnosislist, :ophthal_investigations_list, :laboratory_investigations_list, :procedure, :discharge_note])
		#ipd_record_info = Inpatient::IpdRecord.find_by(admission_id: admission_id)

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
		payload["branch_id"] = CommonHelper::RubyStrings.if_nil_return_empty("#{facility_id}")
	  payload["branch_name"] = CommonHelper::RubyStrings.if_nil_return_empty("#{facility_info['name']}")
		payload["diagnosislist"] = get_diagnosis_array(ipd_record_info)
	  payload["ophthalinvestigationlist"] = get_ophthalinvestigationlist_array(ipd_record_info)
	  payload["laboratory_investigations_list"] = get_laboratory_investigations_list_array(ipd_record_info)
	  payload["procedure"] = get_procedure_array(ipd_record_info)
	  payload["treatmentmedication"] = get_medicine_array(ipd_record_info)

	  Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdDischargeData :: perform method :: payload data :: #{payload}")

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
	  rescue StandardError => e
	    # @user_integration_identifier = user.integration_identifier
	    @status = 'Failed'
	    @status_code = 500
	    @response_code = 500
	    @message = 'No Response Received'
	    @response = {}
	    @response_data = {}
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdDischargeData :: perform method :: StandardError error :: INSIDE EXECPTION ::")
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdDischargeData :: perform method :: StandardError error :: e.inspect :: #{e.inspect}")
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdDischargeData :: perform method :: StandardError error :: e.backtrace :: #{e.backtrace}")
	  end
		Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdDischargeData :: perform method :: @response data :: #{@response}")
	end

  private

		def get_diagnosis_array(data)
			diagnosis_array = []
			diagnoses = data['diagnosislist']
			diagnoses&.each do |diagnosis|
				diagnosis_hash = {}
				diagnosis_hash['icddiagnosiscode'] = CommonHelper::RubyStrings.if_nil_return_empty("#{diagnosis['icddiagnosiscode'].upcase.insert(3, '.')}")
				diagnosis_hash['diagnosisname'] = CommonHelper::RubyStrings.if_nil_return_empty("#{diagnosis['diagnosisoriginalname']}")
				diagnosis_hash['entered_by'] = CommonHelper::RubyStrings.if_nil_return_empty("#{diagnosis['entered_by']}")
				diagnosis_array << diagnosis_hash
			end
			diagnosis_array
		end

		def get_ophthalinvestigationlist_array(data)
			ophthalinvestigationlist_array = []
			ophthalinvestigations = data['ophthal_investigations_list']
			ophthalinvestigations&.each do |investigation|
				ophthalinvestigationlist_hash = {}
				if investigation['investigationside'] == '40638003'
					laterality = 'Bilateral'
				elsif investigation['investigationside'] == '18944008'
					laterality = 'Right'
				elsif investigation['investigationside'] == '8966001'
					laterality = 'Left'
				end
				ophthalinvestigationlist_hash['investigationname'] = CommonHelper::RubyStrings.if_nil_return_empty("#{investigation['investigationname']}").strip
				ophthalinvestigationlist_hash['entered_by'] = CommonHelper::RubyStrings.if_nil_return_empty("#{investigation['entered_by']}")
				ophthalinvestigationlist_hash['laterality'] = laterality
				ophthalinvestigationlist_hash['is_advised'] = CommonHelper::RubyStrings.if_nil_return_empty("#{investigation['is_advised']}")
				ophthalinvestigationlist_hash['is_performed'] = CommonHelper::RubyStrings.if_nil_return_empty("#{investigation['is_performed']}")
				ophthalinvestigationlist_array << ophthalinvestigationlist_hash
			end
			ophthalinvestigationlist_array
		end

		def get_laboratory_investigations_list_array(data)
			laboratory_investigations_list_array = []
			laboratoryinvestigations = data['laboratory_investigations_list']
			laboratoryinvestigations&.each do |investigation|
				laboratoryinvestigations_hash = {}
				laboratoryinvestigations_hash['investigationname'] = CommonHelper::RubyStrings.if_nil_return_empty("#{investigation['investigationname']}").strip
				laboratoryinvestigations_hash['entered_by'] = CommonHelper::RubyStrings.if_nil_return_empty("#{investigation['entered_by']}")
				laboratoryinvestigations_hash['is_advised'] = CommonHelper::RubyStrings.if_nil_return_empty("#{investigation['is_advised']}")
				laboratoryinvestigations_hash['is_performed'] = CommonHelper::RubyStrings.if_nil_return_empty("#{investigation['is_performed']}")
				laboratory_investigations_list_array << laboratoryinvestigations_hash
			end
			laboratory_investigations_list_array
		end

		def get_procedure_array(data)
			procedure_array = []
			procedures = data['procedure']
			procedures&.each do |procedure|
				procedure_hash = {}
				if procedure['procedureside'] == '40638003'
					laterality = 'Bilateral'
				elsif procedure['procedureside'] == '18944008'
					laterality = 'Right'
				elsif procedure['procedureside'] == '8966001'
					laterality = 'Left'
				end
				procedure_hash['procedurename'] = CommonHelper::RubyStrings.if_nil_return_empty("#{procedure['procedurename']}").strip
				procedure_hash['entered_by'] = CommonHelper::RubyStrings.if_nil_return_empty("#{procedure['entered_by']}")
				procedure_hash['laterality'] = laterality
				procedure_hash['is_advised'] = CommonHelper::RubyStrings.if_nil_return_empty("#{procedure['is_advised']}")
				procedure_hash['is_performed'] = CommonHelper::RubyStrings.if_nil_return_empty("#{procedure['is_performed']}")
				procedure_hash['performed_by'] = CommonHelper::RubyStrings.if_nil_return_empty("#{procedure['performed_by']}")
				procedure_array << procedure_hash
			end
			procedure_array
		end

		def get_medicine_array(data)
			medicines_array = []
			medicines = []
			unless data['discharge_note'].nil?
				medicines = data['discharge_note']['treatmentmedication']
			end
			medicines&.each do |medicine|
				treatmentmedication_hash = {}
				treatmentmedication_hash["medicinename"] = CommonHelper::RubyStrings.if_nil_return_empty("#{medicine['medicinename']}")
				treatmentmedication_hash["medicinetype"] = CommonHelper::RubyStrings.if_nil_return_empty("#{medicine['medicinetype']}")
				treatmentmedication_hash["medicinequantity"] = CommonHelper::RubyStrings.if_nil_return_empty("#{medicine['medicinequantity']}")
				treatmentmedication_hash["medicinefrequency"] = CommonHelper::RubyStrings.if_nil_return_empty("#{medicine['medicinefrequency']}")
				treatmentmedication_hash["medicineduration"] = CommonHelper::RubyStrings.if_nil_return_empty("#{medicine['medicineduration']}")
				treatmentmedication_hash["medicinedurationoption"] = CommonHelper::RubyStrings.if_nil_return_empty("#{medicine['medicinedurationoption']}")
				treatmentmedication_hash["eyeside"] = CommonHelper::RubyStrings.if_nil_return_empty("#{medicine['eyeside']}")
				treatmentmedication_hash["medicineinstructions"] = CommonHelper::RubyStrings.if_nil_return_empty("#{medicine['medicineinstructions']}")
				medicines_array << treatmentmedication_hash
			end
			medicines_array
		end

    def send_order_request(client, url, payload)
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdDischargeData :: send_order_request method :: client data :: #{client}")
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdDischargeData :: send_order_request method :: url data :: #{url}")
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdDischargeData :: send_order_request method :: payload data :: #{payload}")
      begin
        request = RestClient::Request.execute(method: :post, url: url, payload: payload.to_json, headers: { 'Content-Type' => 'application/json' })
        response = JSON.parse(request)
				Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdDischargeData :: send_order_request method :: RestClient::Request :: response data :: #{response}")
      rescue StandardError => e
				Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdDischargeData :: send_order_request method :: StandardError error :: INSIDE EXECPTION ::")
				Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdDischargeData :: send_order_request method :: StandardError error :: e.inspect :: #{e.inspect}")
				Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtIpdDischargeData :: send_order_request method :: StandardError error :: e.backtrace :: #{e.backtrace}")
      end
      response
    end

end # end of class
