class External::Customer::DrAgarwals::ApiDrtOpdData < ActiveJob::Base

	def perform(mandatory, optional = {}, others = {})
		payload = {}
		Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtOpdData :: perform method :: mandatory fields :: #{mandatory}")
		Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtOpdData :: perform method :: optional fields  :: #{optional}")
		Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtOpdData :: perform method :: others fields  :: #{others}")

		appointment_id = "#{mandatory['appointment_id'].to_s}"
    all_opd_records_for_appointment = OpdRecord.where(appointmentid: appointment_id)
		appointment_info = Appointment::Read.get_appointment_attributes(appointment_id, [:_id, :appointmentdate])

    all_opd_records_for_appointment.each do |opd_record_data|
			patient_id = "#{opd_record_data['patientid'].to_s}"
			facility_id = "#{opd_record_data['facility_id'].to_s}"
			user_id = "#{opd_record_data['userid'].to_s}" # consultant id or doctor
			facility_info = Facilitydata::Read.get_facility_attributes(facility_id, [:name])
			user_info = Userdata::Read.get_user_attributes(user_id, [:fullname])
			patient_info = Patientdata::Read.get_patient_attributes(patient_id, [:_id, :fullname])
			patient_other_info = Patientdata::Read.get_patient_other_attributes(patient_id, [:mr_no])

			payload["patient_name"] = CommonHelper::RubyStrings.if_nil_return_empty("#{patient_info['fullname']}")
			payload["patient_mrn"] = CommonHelper::RubyStrings.if_nil_return_empty("#{patient_other_info['mr_no']}")
			payload["template_id"] = CommonHelper::RubyStrings.if_nil_return_empty("#{opd_record_data['_id'].to_s}")
			payload["templatetype"] = CommonHelper::RubyStrings.if_nil_return_empty("#{opd_record_data['templatetype'].to_s}")
      payload["templatedate"] = CommonHelper::RubyStrings.if_nil_return_empty("#{opd_record_data['created_at']}")
      payload["appointmentid"] = CommonHelper::RubyStrings.if_nil_return_empty("#{appointment_info['_id']}")
      payload["appointmentdate"] = CommonHelper::RubyStrings.if_nil_return_empty("#{appointment_info['appointmentdate']}")
      payload["consultant_name"] = CommonHelper::RubyStrings.if_nil_return_empty("#{user_info['fullname']}")
      payload["branch_id"] = CommonHelper::RubyStrings.if_nil_return_empty("#{facility_id}")
      payload["branch_name"] = CommonHelper::RubyStrings.if_nil_return_empty("#{facility_info['name']}")
			payload["chief_complaints"] = get_chief_complaints_array(opd_record_data)
			payload["allergy_histories"] = get_allergy_histories_array(opd_record_data)
			payload["personal_history_records"] = get_personal_history_records_array(opd_record_data)
			payload["speciality_history_records"] = get_speciality_history_records_array(opd_record_data)
      payload["visualacuity"] = get_visual_acuity_hash(opd_record_data)
      payload["iop"] = get_iop_hash(opd_record_data)
      payload["glassesprescription"] = get_glassesprescription_hash(opd_record_data)
      payload["intermediate_glassesprescription"] = get_intermediate_glassesprescription_hash(opd_record_data)
      payload["contactlens"] = get_contactlens_hash(opd_record_data)
      payload["diagnosislist"] = get_diagnosis_array(opd_record_data)
      payload["provisional_diagnosis"] = get_provisional_diagnosis(opd_record_data)
      payload["ophthalinvestigationlist"] = get_ophthalinvestigationlist_array(opd_record_data)
			payload["radiologyinvestigationlist"] = get_radiology_investigations_list_array(opd_record_data)
      payload["laboratory_investigations_list"] = get_laboratory_investigations_list_array(opd_record_data)
      payload["procedure"] = get_procedure_array(opd_record_data)
      payload["treatmentmedication"] = get_medicine_array(opd_record_data)

			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtOpdData :: perform method :: payload data :: #{payload}")

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
				Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtOpdData :: perform method :: StandardError error :: INSIDE EXECPTION ::")
				Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtOpdData :: perform method :: StandardError error :: e.inspect :: #{e.inspect}")
				Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtOpdData :: perform method :: StandardError error :: e.backtrace :: #{e.backtrace}")
      end
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtOpdData :: perform method :: @response data :: #{@response}")
    end # for each ends here.
	end

  private

		def get_chief_complaints_array(data)
			chief_complaints_array = []
			chief_complaints = data['chief_complaints']
			chief_complaints&.each do |chief_complaint|
				chief_complaint_hash = {}
				chief_complaint_hash['name'] = CommonHelper::RubyStrings.if_nil_return_empty("#{chief_complaint['name']}")
				chief_complaint_hash['side'] = CommonHelper::RubyStrings.if_nil_return_empty("#{chief_complaint['side']}")
				chief_complaint_hash['duration'] = CommonHelper::RubyStrings.if_nil_return_empty("#{chief_complaint['duration']}")
				chief_complaint_hash['duration_unit'] = CommonHelper::RubyStrings.if_nil_return_empty("#{chief_complaint['duration_unit']}")
				chief_complaint_hash['comment'] = CommonHelper::RubyStrings.if_nil_return_empty("#{chief_complaint['comment']}")
				chief_complaint_hash['history_started'] = CommonHelper::RubyStrings.if_nil_return_empty("#{chief_complaint['history_started']}")
				chief_complaint_hash['updated_at'] = CommonHelper::RubyStrings.if_nil_return_empty("#{chief_complaint['updated_at']}")
				chief_complaints_array << chief_complaint_hash
			end
			chief_complaints_array
		end

		def get_allergy_histories_array(data)
			allergy_histories_array = []
			allergy_histories = data['allergy_histories']
			allergy_histories&.each do |allergy_history|
				allergy_history_hash = {}
				allergy_history_hash['name'] = CommonHelper::RubyStrings.if_nil_return_empty("#{allergy_history['name']}")
				allergy_history_hash['hidden_duration'] = CommonHelper::RubyStrings.if_nil_return_empty("#{allergy_history['hidden_duration']}")
				allergy_history_hash['duration'] = CommonHelper::RubyStrings.if_nil_return_empty("#{allergy_history['duration']}")
				allergy_history_hash['duration_unit'] = CommonHelper::RubyStrings.if_nil_return_empty("#{allergy_history['duration_unit']}")
				allergy_history_hash['comment'] = CommonHelper::RubyStrings.if_nil_return_empty("#{allergy_history['comment']}")
				allergy_history_hash['allergy_type'] = CommonHelper::RubyStrings.if_nil_return_empty("#{allergy_history['allergy_type']}")
				allergy_history_hash['allergy_subtype'] = CommonHelper::RubyStrings.if_nil_return_empty("#{allergy_history['allergy_subtype']}")
				allergy_history_hash['updated_at'] = CommonHelper::RubyStrings.if_nil_return_empty("#{allergy_history['updated_at']}")
				allergy_histories_array << allergy_history_hash
			end
			allergy_histories_array
		end

		def get_personal_history_records_array(data)
			personal_history_records_array = []
			personal_history_records = data['personal_history_records']
			personal_history_records&.each do |personal_history_record|
				personal_history_record_hash = {}
				personal_history_record_hash['name'] = CommonHelper::RubyStrings.if_nil_return_empty("#{personal_history_record['name']}")
				personal_history_record_hash['hidden_duration'] = CommonHelper::RubyStrings.if_nil_return_empty("#{personal_history_record['hidden_duration']}")
				personal_history_record_hash['duration'] = CommonHelper::RubyStrings.if_nil_return_empty("#{personal_history_record['duration']}")
				personal_history_record_hash['duration_unit'] = CommonHelper::RubyStrings.if_nil_return_empty(personal_history_record['duration_unit'])
				personal_history_record_hash['comment'] = CommonHelper::RubyStrings.if_nil_return_empty("#{personal_history_record['comment']}")
				personal_history_record_hash['updated_at'] = CommonHelper::RubyStrings.if_nil_return_empty("#{personal_history_record['updated_at']}")
				personal_history_records_array << personal_history_record_hash
			end
			personal_history_records_array
		end

		def get_speciality_history_records_array(data)
			speciality_history_records_array = []
			speciality_history_records = data['speciality_history_records']
			speciality_history_records&.each do |speciality_history_record|
				speciality_history_record_hash = {}
				speciality_history_record_hash['name'] = CommonHelper::RubyStrings.if_nil_return_empty("#{speciality_history_record['name']}")
				speciality_history_record_hash['l_hidden_duration'] = CommonHelper::RubyStrings.if_nil_return_empty("#{speciality_history_record['l_hidden_duration']}")
				speciality_history_record_hash['r_hidden_duration'] = CommonHelper::RubyStrings.if_nil_return_empty("#{speciality_history_record['r_hidden_duration']}")
				speciality_history_record_hash['l_duration'] = CommonHelper::RubyStrings.if_nil_return_empty("#{speciality_history_record['l_duration']}")
				speciality_history_record_hash['l_duration_unit'] = CommonHelper::RubyStrings.if_nil_return_empty("#{speciality_history_record['l_duration_unit']}")
				speciality_history_record_hash['r_duration'] = CommonHelper::RubyStrings.if_nil_return_empty("#{speciality_history_record['r_duration']}")
				speciality_history_record_hash['r_duration_unit'] = CommonHelper::RubyStrings.if_nil_return_empty("#{speciality_history_record['r_duration_unit']}")
				speciality_history_record_hash['comment'] = CommonHelper::RubyStrings.if_nil_return_empty("#{speciality_history_record['comment']}")
				speciality_history_record_hash['updated_at'] = CommonHelper::RubyStrings.if_nil_return_empty("#{speciality_history_record['updated_at']}")
				speciality_history_record_hash['created_at'] = CommonHelper::RubyStrings.if_nil_return_empty("#{speciality_history_record['created_at']}")
				speciality_history_records_array << speciality_history_record_hash
			end
			speciality_history_records_array
		end

		def get_visual_acuity_hash(data)
			visualacuity = {}
			visualacuity["r_visualacuity_unaided_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_unaided_comments']}")
			visualacuity["r_visualacuity_unaided"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_unaided']}")
			visualacuity["r_visualacuity_unaided_p"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_unaided_p']}")
			visualacuity["r_visualacuity_ua_near_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_ua_near_comments']}")
			visualacuity["r_visualacuity_ua_near"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_ua_near']}")
			visualacuity["r_visualacuity_ua_near_p"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_ua_near_p']}")
			visualacuity["r_visualacuity_ua_s"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_ua_s']}")
			visualacuity["r_visualacuity_ua_i"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_ua_i']}")
			visualacuity["r_visualacuity_ua_n"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_ua_n']}")
			visualacuity["r_visualacuity_ua_t"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_ua_t']}")
			visualacuity["r_visualacuity_pinhole_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_pinhole_comments']}")
			visualacuity["r_visualacuity_pinhole"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_pinhole']}")
			visualacuity["r_visualacuity_pinhole_p"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_pinhole_p']}")
			visualacuity["r_visualacuity_pinhole_ni"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_pinhole_ni']}")
			visualacuity["r_visualacuity_glasses_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_glasses_comments']}")
			visualacuity["r_visualacuity_glasses"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_glasses']}")
			visualacuity["r_visualacuity_glasses_p"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_glasses_p']}")
			visualacuity["r_visualacuity_near_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_near_comments']}")
			visualacuity["r_visualacuity_near"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_near']}")
			visualacuity["r_visualacuity_near_p"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_near_p']}")
			visualacuity["r_visualacuity_lens_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_lens_comments']}")
			visualacuity["r_visualacuity_lens"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_lens']}")
			visualacuity["r_visualacuity_lens_p"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_lens_p']}")
			visualacuity["r_visualacuity_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_visualacuity_comments']}")
			visualacuity["l_visualacuity_unaided_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_unaided_comments']}")
			visualacuity["l_visualacuity_unaided"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_unaided']}")
			visualacuity["l_visualacuity_unaided_p"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_unaided_p']}")
			visualacuity["l_visualacuity_ua_near_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_ua_near_comments']}")
			visualacuity["l_visualacuity_ua_near"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_ua_near']}")
			visualacuity["l_visualacuity_ua_near_p"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_ua_near_p']}")
			visualacuity["l_visualacuity_ua_s"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_ua_s']}")
			visualacuity["l_visualacuity_ua_i"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_ua_i']}")
			visualacuity["l_visualacuity_ua_n"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_ua_n']}")
			visualacuity["l_visualacuity_ua_t"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_ua_t']}")
			visualacuity["l_visualacuity_pinhole_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_pinhole_comments']}")
			visualacuity["l_visualacuity_pinhole"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_pinhole']}")
			visualacuity["l_visualacuity_pinhole_p"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_pinhole_p']}")
			visualacuity["l_visualacuity_pinhole_ni"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_pinhole_ni']}")
			visualacuity["l_visualacuity_glasses_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_glasses_comments']}")
			visualacuity["l_visualacuity_glasses"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_glasses']}")
			visualacuity["l_visualacuity_glasses_p"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_glasses_p']}")
			visualacuity["l_visualacuity_near_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_near_comments']}")
			visualacuity["l_visualacuity_near"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_near']}")
			visualacuity["l_visualacuity_near_p"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_near_p']}")
			visualacuity["l_visualacuity_lens_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_lens_comments']}")
			visualacuity["l_visualacuity_lens"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_lens']}")
			visualacuity["l_visualacuity_lens_p"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_lens_p']}")
			visualacuity["l_visualacuity_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_visualacuity_comments']}")
			visualacuity
		end

		def get_iop_hash(data)
			iop = {}
			iop["r_intraocularpressure"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_intraocularpressure']}")
			iop["r_intraocularpressure_time"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_intraocularpressure_time']}")
			iop["r_intraocularpressure_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_intraocularpressure_comments']}")
			iop["l_intraocularpressure"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_intraocularpressure']}")
			iop["l_intraocularpressure_time"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_intraocularpressure_time']}")
			iop["l_intraocularpressure_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_intraocularpressure_comments']}")
			iop
		end

		def get_glassesprescription_hash(data)
			glassesprescription = {}
			glassesprescription["advise_glasses"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['advise_glasses']}")
			glassesprescription["glassesprescriptions_show_add"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['advise_glasses']}")
			glassesprescription["r_glassesprescriptions_distant_sph"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_glassesprescriptions_distant_sph']}")
			glassesprescription["r_glassesprescriptions_distant_cyl"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_glassesprescriptions_distant_cyl']}")
			glassesprescription["r_glassesprescriptions_distant_axis"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_glassesprescriptions_distant_axis']}")
			glassesprescription["r_glassesprescriptions_distant_vision"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_glassesprescriptions_distant_vision']}")
			glassesprescription["r_glassesprescriptions_add_sph"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_glassesprescriptions_add_sph']}")
			glassesprescription["r_glassesprescriptions_add_cyl"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_glassesprescriptions_add_cyl']}")
			glassesprescription["r_glassesprescriptions_add_axis"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_glassesprescriptions_add_axis']}")
			glassesprescription["r_glassesprescriptions_add_vision"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_glassesprescriptions_add_vision']}")
			glassesprescription["r_glassesprescriptions_near_sph"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_glassesprescriptions_near_sph']}")
			glassesprescription["r_glassesprescriptions_near_cyl"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_glassesprescriptions_near_cyl']}")
			glassesprescription["r_glassesprescriptions_near_axis"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_glassesprescriptions_near_axis']}")
			glassesprescription["r_glassesprescriptions_near_vision"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_glassesprescriptions_near_vision']}")
			glassesprescription["r_acceptance_typeoflens"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_acceptance_typeoflens']}")
			glassesprescription["r_acceptance_ipd"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_acceptance_ipd']}")
			glassesprescription["r_acceptance_lensmaterial"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_acceptance_lensmaterial']}")
			glassesprescription["r_acceptance_lenstint"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_acceptance_lenstint']}")
			glassesprescription["r_acceptance_framematerial"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_acceptance_framematerial']}")
			glassesprescription["r_acceptance_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_acceptance_comments']}")
			glassesprescription["l_glassesprescriptions_distant_sph"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_glassesprescriptions_distant_sph']}")
			glassesprescription["l_glassesprescriptions_distant_cyl"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_glassesprescriptions_distant_cyl']}")
			glassesprescription["l_glassesprescriptions_distant_axis"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_glassesprescriptions_distant_axis']}")
			glassesprescription["l_glassesprescriptions_distant_vision"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_glassesprescriptions_distant_vision']}")
			glassesprescription["l_glassesprescriptions_add_sph"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_glassesprescriptions_add_sph']}")
			glassesprescription["l_glassesprescriptions_add_cyl"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_glassesprescriptions_add_cyl']}")
			glassesprescription["l_glassesprescriptions_add_axis"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_glassesprescriptions_add_axis']}")
			glassesprescription["l_glassesprescriptions_add_vision"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_glassesprescriptions_add_vision']}")
			glassesprescription["l_glassesprescriptions_near_sph"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_glassesprescriptions_near_sph']}")
			glassesprescription["l_glassesprescriptions_near_cyl"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_glassesprescriptions_near_cyl']}")
			glassesprescription["l_glassesprescriptions_near_axis"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_glassesprescriptions_near_axis']}")
			glassesprescription["l_glassesprescriptions_near_vision"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_glassesprescriptions_near_vision']}")
			glassesprescription["l_acceptance_typeoflens"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_acceptance_typeoflens']}")
			glassesprescription["l_acceptance_ipd"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_acceptance_ipd']}")
			glassesprescription["l_acceptance_lensmaterial"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_acceptance_lensmaterial']}")
			glassesprescription["l_acceptance_lenstint"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_acceptance_lenstint']}")
			glassesprescription["l_acceptance_framematerial"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_acceptance_framematerial']}")
			glassesprescription["l_acceptance_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_acceptance_comments']}")
			glassesprescription
		end

		def get_intermediate_glassesprescription_hash(data)
			intermediate_glassesprescription = {}
			intermediate_glassesprescription["intermediate_advise_glasses"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['intermediate_advise_glasses']}")
			intermediate_glassesprescription["intermediate_glasses_prescriptions_show_add"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['intermediate_glasses_prescriptions_show_add']}")
			intermediate_glassesprescription["r_intermediate_glasses_prescriptions_distant_sph"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_intermediate_glasses_prescriptions_distant_sph']}")
			intermediate_glassesprescription["r_intermediate_glasses_prescriptions_distant_cyl"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_intermediate_glasses_prescriptions_distant_cyl']}")
			intermediate_glassesprescription["r_intermediate_glasses_prescriptions_distant_axis"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_intermediate_glasses_prescriptions_distant_axis']}")
			intermediate_glassesprescription["r_intermediate_glasses_prescriptions_distant_vision"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_intermediate_glasses_prescriptions_distant_vision']}")
			intermediate_glassesprescription["r_intermediate_glasses_prescriptions_add_sph"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_intermediate_glasses_prescriptions_add_sph']}")
			intermediate_glassesprescription["r_intermediate_glasses_prescriptions_add_cyl"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_intermediate_glasses_prescriptions_add_cyl']}")
			intermediate_glassesprescription["r_intermediate_glasses_prescriptions_add_axis"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_intermediate_glasses_prescriptions_add_axis']}")
			intermediate_glassesprescription["r_intermediate_glasses_prescriptions_add_vision"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_intermediate_glasses_prescriptions_add_vision']}")
			intermediate_glassesprescription["r_intermediate_glasses_prescriptions_near_sph"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_intermediate_glasses_prescriptions_near_sph']}")
			intermediate_glassesprescription["r_intermediate_glasses_prescriptions_near_cyl"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_intermediate_glasses_prescriptions_near_cyl']}")
			intermediate_glassesprescription["r_intermediate_glasses_prescriptions_near_axis"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_intermediate_glasses_prescriptions_near_axis']}")
			intermediate_glassesprescription["r_intermediate_glasses_prescriptions_near_vision"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_intermediate_glasses_prescriptions_near_vision']}")
			intermediate_glassesprescription["r_acceptance_typeoflens"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_acceptance_typeoflens']}")
			intermediate_glassesprescription["r_acceptance_ipd"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_acceptance_ipd']}")
			intermediate_glassesprescription["r_acceptance_lensmaterial"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_acceptance_lensmaterial']}")
			intermediate_glassesprescription["r_acceptance_lenstint"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_acceptance_lenstint']}")
			intermediate_glassesprescription["r_acceptance_framematerial"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_acceptance_framematerial']}")
			intermediate_glassesprescription["r_acceptance_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_acceptance_comments']}")
			intermediate_glassesprescription["l_intermediate_glasses_prescriptions_distant_sph"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_intermediate_glasses_prescriptions_distant_sph']}")
			intermediate_glassesprescription["l_intermediate_glasses_prescriptions_distant_cyl"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_intermediate_glasses_prescriptions_distant_cyl']}")
			intermediate_glassesprescription["l_intermediate_glasses_prescriptions_distant_axis"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_intermediate_glasses_prescriptions_distant_axis']}")
			intermediate_glassesprescription["l_intermediate_glasses_prescriptions_distant_vision"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_intermediate_glasses_prescriptions_distant_vision']}")
			intermediate_glassesprescription["l_intermediate_glasses_prescriptions_add_sph"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_intermediate_glasses_prescriptions_add_sph']}")
			intermediate_glassesprescription["l_intermediate_glasses_prescriptions_add_cyl"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_intermediate_glasses_prescriptions_add_cyl']}")
			intermediate_glassesprescription["l_intermediate_glasses_prescriptions_add_axis"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_intermediate_glasses_prescriptions_add_axis']}")
			intermediate_glassesprescription["l_intermediate_glasses_prescriptions_add_vision"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_intermediate_glasses_prescriptions_add_vision']}")
			intermediate_glassesprescription["l_intermediate_glasses_prescriptions_near_sph"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_intermediate_glasses_prescriptions_near_sph']}")
			intermediate_glassesprescription["l_intermediate_glasses_prescriptions_near_cyl"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_intermediate_glasses_prescriptions_near_cyl']}")
			intermediate_glassesprescription["l_intermediate_glasses_prescriptions_near_axis"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_intermediate_glasses_prescriptions_near_axis']}")
			intermediate_glassesprescription["l_intermediate_glasses_prescriptions_near_vision"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_intermediate_glasses_prescriptions_near_vision']}")
			intermediate_glassesprescription["l_acceptance_typeoflens"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_acceptance_typeoflens']}")
			intermediate_glassesprescription["l_acceptance_ipd"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_acceptance_ipd']}")
			intermediate_glassesprescription["l_acceptance_lensmaterial"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_acceptance_lensmaterial']}")
			intermediate_glassesprescription["l_acceptance_lenstint"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_acceptance_lenstint']}")
			intermediate_glassesprescription["l_acceptance_framematerial"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_acceptance_framematerial']}")
			intermediate_glassesprescription["l_acceptance_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_acceptance_comments']}")
			intermediate_glassesprescription
		end

		def get_contactlens_hash(data)
			contactlens = {}
			contactlens["r_contactlens_bc"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_contactlens_bc']}")
			contactlens["r_contactlens_dia"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_contactlens_dia']}")
			contactlens["r_contactlens_sph"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_contactlens_sph']}")
			contactlens["r_contactlens_cyl"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_contactlens_cyl']}")
			contactlens["r_contactlens_axis"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_contactlens_axis']}")
			contactlens["r_contactlens_add"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_contactlens_add']}")
			contactlens["r_revisit_date"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_revisit_date']}")
			contactlens["r_contactlens_color"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_contactlens_color']}")
			contactlens["r_contactlens_types"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_contactlens_types']}")
			contactlens["r_contactlens_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['r_contactlens_comments']}")
			contactlens["l_contactlens_bc"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_contactlens_bc']}")
			contactlens["l_contactlens_dia"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_contactlens_dia']}")
			contactlens["l_contactlens_sph"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_contactlens_sph']}")
			contactlens["l_contactlens_cyl"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_contactlens_cyl']}")
			contactlens["l_contactlens_axis"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_contactlens_axis']}")
			contactlens["l_contactlens_add"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_contactlens_add']}")
			contactlens["l_revisit_date"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_revisit_date']}")
			contactlens["l_contactlens_color"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_contactlens_color']}")
			contactlens["l_contactlens_types"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_contactlens_types']}")
			contactlens["l_contactlens_comments"] = CommonHelper::RubyStrings.if_nil_return_empty("#{data['l_contactlens_comments']}")
			contactlens
		end

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

		def get_provisional_diagnosis(data)
			provisional_diagnosis = CommonHelper::RubyStrings.if_nil_return_empty("#{data['provisional_diagnosis']}")
			provisional_diagnosis
		end

		def get_ophthalinvestigationlist_array(data)
			ophthalinvestigationlist_array = []
			ophthalinvestigations = data['ophthalinvestigationlist']
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

		def get_radiology_investigations_list_array(data)
			radiology_investigations_list_array = []
			radiology_investigations = data['investigationlist']
			radiology_investigations&.each do |investigation|
				radiology_investigations_hash = {}
				if investigation['investigationside'] == '40638003'
					laterality = 'Bilateral'
				elsif investigation['investigationside'] == '18944008'
					laterality = 'Right'
				elsif investigation['investigationside'] == '8966001'
					laterality = 'Left'
				end
				radiology_investigations_hash['investigationname'] = CommonHelper::RubyStrings.if_nil_return_empty("#{investigation['investigationname']}").strip
				radiology_investigations_hash['entered_by'] = CommonHelper::RubyStrings.if_nil_return_empty("#{investigation['entered_by']}")
				radiology_investigations_hash['laterality'] = laterality
				radiology_investigations_hash['is_advised'] = CommonHelper::RubyStrings.if_nil_return_empty("#{investigation['is_advised']}")
				radiology_investigations_hash['is_performed'] = CommonHelper::RubyStrings.if_nil_return_empty("#{investigation['is_performed']}")
				radiology_investigations_list_array << radiology_investigations_hash
			end
			radiology_investigations_list_array
		end

		def get_laboratory_investigations_list_array(data)
			laboratory_investigations_list_array = []
			laboratoryinvestigations = data['addedlaboratoryinvestigationlist']
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
				procedure_array << procedure_hash
			end
			procedure_array
		end

		def get_medicine_array(data)
			medicines_array = []
			medicines = data['treatmentmedication']
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
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtOpdData :: send_order_request method :: client data :: #{client}")
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtOpdData :: send_order_request method :: url data :: #{url}")
			Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtOpdData :: send_order_request method :: payload data :: #{payload}")
			begin
				request = RestClient::Request.execute(method: :post, url: url, payload: payload.to_json, headers: { 'Content-Type' => 'application/json' })
				response = JSON.parse(request)
				Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtOpdData :: send_order_request method :: RestClient::Request :: response data :: #{response}")
			rescue StandardError => e
				Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtOpdData :: send_order_request method :: StandardError error :: INSIDE EXECPTION ::")
				Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtOpdData :: send_order_request method :: StandardError error :: e.inspect :: #{e.inspect}")
				Rails.logger.info("Inside External::Customer::DrAgarwals::ApiDrtOpdData :: send_order_request method :: StandardError error :: e.backtrace :: #{e.backtrace}")
			end
			response
		end

end # end of class
