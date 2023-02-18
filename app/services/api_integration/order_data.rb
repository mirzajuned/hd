class ApiIntegration::OrderData
  def self.create(visit_type, visit_id, client, current_facility_id)
    sleep 5

    @facility = ::Facility.find_by(id: current_facility_id)
    if visit_type == 'appointment'
      @case_sheet = ::CaseSheet.find_by(appointment_ids: visit_id)
      @appointment = ::Appointment.find_by(id: visit_id)
      @patient = @appointment.patient
    else
      @case_sheet = ::CaseSheet.find_by(admission_ids: visit_id)
    end

    @patient_mrn = @patient.patient_mrn

    puts '======================================================patient======================================>', @patient
    Rails.logger.info("======================================================request sent==for==patient==================================>#{@patient}")

    return if @case_sheet.blank?

    @appointment_integration_identifier_bson = @appointment.integration_identifier

    @appointment_data = ::ApiIntegration::Appointment::Data.find_by(appointment_integration_identifier_bson: @appointment_integration_identifier_bson)

    return if @appointment_data.blank?

    @appointment_integration_identifier = @appointment_data.appointment_integration_identifier

    @order_data = ::ApiIntegration::Order::Data.find_by(appointment_integration_identifier: @appointment_integration_identifier)

    current_order_data = if @order_data.present?
                           @order_data.data
                         else
                           {}
                         end

    payload = {}

    payload['MRN'] = @patient_mrn
    payload['visitId'] = @appointment_integration_identifier

    payload['diagnosis'] = get_diagnosis_array(@case_sheet, @appointment.id, current_order_data)

    payload['investigationOrders'] = get_investigation_array(@case_sheet, @appointment.id, current_order_data)

    # payload['procedureAdvices'] = []

    # payload['drugOrders'] = []

    payload['procedureAdvices'] = get_procedure_array(@case_sheet, @appointment.id, current_order_data)

    payload['drugOrders'] = get_medicine_array(@case_sheet, @appointment.id, current_order_data, @appointment.patient_id)

    puts '======================================================payload======================================>', payload
    Rails.logger.info("======================================================payload======================================>#{payload}")

    if @order_data.blank?
      order_data = {
        mr_no: @mr_no,
        appointment_date: @appointment_datetime,
        first_name: @appointment.patient.firstname,
        appointment_integration_identifier: @appointment_integration_identifier,
        appointment_integration_identifier_bson: @appointment.integration_identifier,
        data: payload,
        payload: payload,
        sent_date: Date.current,
        sent_time: Time.current,
        request_type: 'Sent',
        method_type: @method_type,
        status: @status,
        status_code: @status_code,
        message: @message,
        number_of_retries: 0
      }
      @order_data = ApiIntegration::Order::Data.new(order_data)
      @order_data.save
    else
      @order_data.update(payload: payload, data: payload)
    end

    puts '======================================================payload=withid=====================================>', payload
    Rails.logger.info("======================================================payload=withid=====================================>#{payload}")

    url = Global.send(client)[Rails.env]['order_data_url']
    token = Global.send(client)[Rails.env]['token']
    tokenlabel = Global.send(client)[Rails.env]['tokenlabel']

    begin
      response = send_order_request(client, url, token, tokenlabel, payload, current_facility_id)
      # @user_integration_identifier = response.try(:[], "response").try(:[], "data").try(:[], "externalId") || user.integration_identifier
      # @external_identifier = response.try(:[], "response").try(:[], "data").try(:[], "id") || user.try(:external_identifier)
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
    end
    puts '==========================================puts============response======================================>', @response
    Rails.logger.info("======================================================response======================================>#{@response}")

    @response_received = ::ApiIntegration::Order::ResponseReceived.new(visit_type: 'appointment', visit_integration_identifier: @appointment_integration_identifier, appointment_integration_identifier: @appointment_integration_identifier, mr_no: @patient_mrn, status: @status, status_code: @status_code, response: @response, response_code: @response_code, message: @message, data: @response_data)
    @response_received.save!

    puts '================================@response_code====,,,,======@status_code========', @response_code, @status_code

    if @response_code == '000' && @status_code == 200

      updated_diagnosis_order = @order_data.data['diagnosis'].each do |diagnosis|
        updated_diagnosis = @response_data['diagnosis'].find { |h| h['code'] == diagnosis['code'] }
        diagnosis['id'] = updated_diagnosis.try(:[], 'id').to_i
      end

      updated_investigation_order = @order_data.data['investigationOrders'].each do |investigation|
        updated_investigation = @response_data['investigationOrders'].find { |h| h['code'] == investigation['code'] }
        investigation['id'] = updated_investigation.try(:[], 'id').to_i
      end

      updated_procedure_order = @order_data.data['procedureAdvices'].each do |procedure|
        updated_procedure = @response_data['procedureAdvices'].find { |h| h['code'] == procedure['code'] }
        procedure['id'] = updated_procedure.try(:[], 'id').to_i
      end

      updated_medicine_order = @order_data.data['drugOrders'].each do |medicine|
        updated_medicine = @response_data['drugOrders'].find { |h| h['code'] == medicine['code'] }
        medicine['id'] = updated_medicine.try(:[], 'id').to_i
      end

      updated_response_data = @order_data.data

      # updated_response_data['diagnosis'] = updated_diagnosis_order
      updated_response_data['investigationOrders'] = updated_investigation_order
      updated_response_data['procedureAdvices'] = updated_procedure_order
      updated_response_data['drugOrders'] = updated_medicine_order

      puts '===========================updated_response_data===================', updated_response_data

      @order_data.update(data: updated_response_data)
    end

    begin
      @url = url
      @payload = payload
      create_data_request
      create_data_response
    rescue StandardError
    end
  end

  def self.update_investigation_performed(_visit_type, visit_id, client, current_facility_id, investigation)
    @appointment = ::Appointment.find_by(id: visit_id.to_s)
    @patient = @appointment.patient
    @patient_mrn = @patient.patient_mrn
    @facility = ::Facility.find_by(id: current_facility_id)

    investigation_code = investigation.try(:investigation_id)

    @appointment_integration_identifier_bson = @appointment.integration_identifier

    @appointment_data = ::ApiIntegration::Appointment::Data.find_by(appointment_integration_identifier_bson: @appointment_integration_identifier_bson)

    @appointment_integration_identifier = @appointment_data.appointment_integration_identifier

    @order_data = ::ApiIntegration::Order::Data.find_by(appointment_integration_identifier: @appointment_integration_identifier)

    current_order_data = if @order_data.present?
                           @order_data.data
                         else
                           {}
                         end

    updated_order_data = current_order_data
    updated_investigation_data = current_order_data['investigationOrders']

    payload = {}

    payload['MRN'] = @patient_mrn
    payload['visitId'] = @appointment_integration_identifier

    investigation_hash = {}

    if current_order_data.present?
      current_investigation = current_order_data['investigationOrders'].find { |h| h['code'] == investigation_code }
      current_investigation_id = current_investigation.try(:[], 'id')
      investigation_hash['id'] = current_investigation_id.to_i

      investigation_hash['code'] = current_investigation['code']
      investigation_hash['name'] = current_investigation['name']
      investigation_hash['quantity'] = current_investigation['quantity']
      investigation_hash['lateral'] = current_investigation['lateral']
      investigation_hash['externalDoctorId'] = current_investigation['externalDoctorId']
      investigation_hash['orderDate'] = current_investigation['orderDate']

      investigation_hash['status'] = 'PROCESSED'
      performed_by = investigation.try(:performed_by).to_s
      advised_by = investigation.try(:advised_by).to_s
      if performed_by.present?
        processed_by_id = User.find_by(id: performed_by, :role_ids.in => [158965000]).try(:integration_identifier).to_s
      end

      if processed_by_id.blank?
        if advised_by.present?
          processed_by_id = User.find_by(id: advised_by, :role_ids.in => [158965000]).try(:integration_identifier).to_s
        end
      end

      investigation_hash['processedBy'] = if processed_by_id.present?
                                            processed_by_id
                                          else
                                            ''
                                          end
    end

    Rails.logger.info("======================current_investigation==========================#{current_investigation}")
    Rails.logger.info("======================updated_investigation_data=0==========================#{updated_investigation_data}")

    updated_investigation_data -= [current_investigation]

    Rails.logger.info("======================updated_investigation_data=1==========================#{updated_investigation_data}")

    updated_investigation_data << investigation_hash

    Rails.logger.info("======================investigation_hash==========================#{investigation_hash}")
    Rails.logger.info("======================updated_investigation_data=2==========================#{updated_investigation_data}")

    investigationOrders = [investigation_hash]

    updated_order_data['investigationOrders'] = updated_investigation_data

    payload['investigationOrders'] = investigationOrders

    payload['procedureAdvices'] = []

    Rails.logger.info("=======================================sent for order status update==========payload===========================#{payload}")
    Rails.logger.info("=======================================sent for order status update==========updated_order_data===========================#{updated_order_data}")

    url = Global.send(client)[Rails.env]['update_order_status_url']
    token = Global.send(client)[Rails.env]['token']
    tokenlabel = Global.send(client)[Rails.env]['tokenlabel']

    begin
      response = send_order_request(client, url, token, tokenlabel, payload, current_facility_id)
      # @user_integration_identifier = response.try(:[], "response").try(:[], "data").try(:[], "externalId") || user.integration_identifier
      # @external_identifier = response.try(:[], "response").try(:[], "data").try(:[], "id") || user.try(:external_identifier)
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
    end
    puts '==========================================puts============response======================================>', @response

    Rails.logger.info("=======================================sent for order status update==========@response===========================#{@response}")

    @response_received = ::ApiIntegration::Order::ResponseReceived.new(visit_type: 'appointment', visit_integration_identifier: @appointment_integration_identifier, appointment_integration_identifier: @appointment_integration_identifier, mr_no: @patient_mrn, status: @status, status_code: @status_code, response: @response, response_code: @response_code, message: @message, data: @response_data)
    @response_received.save!

    begin
      @url = url
      @payload = payload
      create_data_request
      create_data_response
    rescue StandardError
    end

    Rails.logger.info("========================================@response_code====,,,,======@status_code=========================#{@response_code}, #{@status_code}")

    puts '================================@response_code====,,,,======@status_code========', @response_code, @status_code
  end

  def self.update(visit_type, visit_id, client, current_facility_id)
    sleep 5

    Rails.logger.info("=======================================entered for order status update==========params===========================#{visit_type}, #{visit_id}, #{client}, #{current_facility_id}")

    @facility = ::Facility.find_by(id: current_facility_id)
    if visit_type == 'appointment'
      Rails.logger.info('=======================================visittype is appointment==========')
      @case_sheet = ::CaseSheet.find_by(appointment_ids: visit_id.to_s)

      Rails.logger.info("==============================visittype is appointment==========@case sheet============visit_id===============#{@case_sheet}, #{visit_id}")
      @appointment = Appointment.find_by(id: visit_id.to_s)

      Rails.logger.info("=======================================visittype is appointment==========@appointment===========================#{@appointment}")

      @patient = @appointment.patient
    else
      @case_sheet = CaseSheet.find_by(admission_ids: visit_id)
    end

    @patient_mrn = @patient.patient_mrn

    Rails.logger.info("=======================================entered for order status update==========@case sheet===========================#{@case_sheet}")

    return if @case_sheet.blank?

    @appointment_integration_identifier_bson = @appointment.integration_identifier

    @appointment_data = ApiIntegration::Appointment::Data.find_by(appointment_integration_identifier_bson: @appointment_integration_identifier_bson)

    Rails.logger.info("=======================================entered for order status update==========@appointment_data===========================#{@appointment_data}")

    return if @appointment_data.blank?

    @appointment_integration_identifier = @appointment_data.appointment_integration_identifier

    @order_data = ApiIntegration::Order::Data.find_by(appointment_integration_identifier: @appointment_integration_identifier)

    Rails.logger.info("=======================================entered for order status update==========@order_data===========================#{@order_data.inspect}")

    current_order_data = if @order_data.present?
                           @order_data.data
                         else
                           {}
                         end

    updated_order_data = current_order_data

    payload = {}

    payload['MRN'] = @patient_mrn
    payload['visitId'] = @appointment_integration_identifier

    Rails.logger.info("=======================================entered for order status update==========current_order_data===========================#{current_order_data}")

    # investigationOrders = get_investigation_array(@case_sheet, @appointment.id, current_order_data)
    #
    # updated_order_data['investigationOrders'] = investigationOrders

    payload['investigationOrders'] = get_cancelled_investigation_array(@case_sheet, @appointment.id, current_order_data)
    payload['procedureAdvices'] = get_cancelled_procedure_array(@case_sheet, @appointment.id, current_order_data)

    payload['drugOrders'] = get_cancelled_medicine_array(@case_sheet, @appointment.id, current_order_data, @appointment.patient_id)

    puts '======================================================payload======================================>', payload
    Rails.logger.info("======================================================payload======================================>#{payload}")

    # if @order_data.present?
    #   @order_data.update(payload: payload, data: updated_order_data)
    # end

    url = Global.send(client)[Rails.env]['update_order_status_url']
    token = Global.send(client)[Rails.env]['token']
    tokenlabel = Global.send(client)[Rails.env]['tokenlabel']

    begin
      response = send_order_request(client, url, token, tokenlabel, payload, current_facility_id)
      # @user_integration_identifier = response.try(:[], "response").try(:[], "data").try(:[], "externalId") || user.integration_identifier
      # @external_identifier = response.try(:[], "response").try(:[], "data").try(:[], "id") || user.try(:external_identifier)
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
    end
    puts '==========================================puts============response======================================>', @response

    Rails.logger.info("=======================================sent for order status update==========@response===========================#{@response}")

    @response_received = ApiIntegration::Order::ResponseReceived.new(visit_type: 'appointment', visit_integration_identifier: @appointment_integration_identifier, appointment_integration_identifier: @appointment_integration_identifier, mr_no: @patient_mrn, status: @status, status_code: @status_code, response: @response, response_code: @response_code, message: @message, data: @response_data)
    @response_received.save!


    if @response_code == '000' && @status_code == 200

      if @order_data.present?
        # updated_diagnosis_order = @order_data.data['diagnosis'].each do |diagnosis|
        #   updated_diagnosis = @response_data['diagnosis'].find { |h| h['id'] == diagnosis['id'] }
        #   if updated_diagnosis.present?
        #     diagnosis['status'] = updated_diagnosis.try(:[], 'status')
        #   end
        # end

        updated_investigation_order = @order_data.data['investigationOrders'].each do |investigation|
          updated_investigation = @response_data['investigationOrders'].find { |h| h['id'] == investigation['id'] }
          if updated_investigation.present?
            investigation['status'] = updated_investigation.try(:[], 'status')
          end
        end

        updated_procedure_order = @order_data.data['procedureAdvices'].each do |procedure|
          updated_procedure = @response_data['procedureAdvices'].find { |h| h['id'] == procedure['id'] }
          if updated_procedure.present?
            procedure['status'] = updated_procedure.try(:[], 'status')
          end
        end

        updated_medicine_order = @order_data.data['drugOrders'].each do |medicine|
          updated_medicine = @response_data['drugOrders'].find { |h| h['id'] == medicine['id'] }
          if updated_medicine.present?
            medicine['status'] = updated_medicine.try(:[], 'status')
          end
        end

        updated_response_data = @order_data.data

        # updated_response_data['diagnosis'] = updated_diagnosis_order
        updated_response_data['investigationOrders'] = updated_investigation_order
        updated_response_data['procedureAdvices'] = updated_procedure_order
        updated_response_data['drugOrders'] = updated_medicine_order

        puts '===========================updated_response_data===================', updated_response_data

        @order_data.update(data: updated_response_data)
      end
    end


    begin
      @url = url
      @payload = payload
      create_data_request
      create_data_response
    rescue StandardError
    end

    Rails.logger.info("========================================@response_code====,,,,======@status_code=========================#{@response_code}, #{@status_code}")

    puts '================================@response_code====,,,,======@status_code========', @response_code, @status_code
  end

  private

  def self.create_data_request
    data_hash = @payload
    organisation_id = @facility.try(:organisation_id).to_s
    facility_id = @facility.id.to_s
    if @order_data.present?
      order_data_hash = @order_data.try(:data) || {}
    else
      order_data_hash = {}
    end
    ApiIntegration::DataRequests::CreateService.call(data_hash, @url, 'sent', organisation_id, facility_id, order_data_hash)
  rescue StandardError
  end

  def self.create_data_response
    data_hash = @response
    organisation_id = @facility.try(:organisation_id).to_s
    facility_id = @facility.id.to_s
    if @order_data.present?
      order_data_hash = @order_data.try(:data) || {}
    else
      order_data_hash = {}
    end
    ApiIntegration::DataResponses::CreateService.call(data_hash, @url, 'received', organisation_id, facility_id, order_data_hash)
  rescue StandardError
  end

  def self.get_diagnosis_array(case_sheet, appointment_id, current_order_data)
    diagnosis_array = []
    diagnoses = case_sheet.diagnoses.where(appointment_id: appointment_id.to_s)
    diagnoses.each do |diagnosis|
      diagnosis_hash = {}

      advised_by_id = diagnosis.advised_by_id.to_s
      external_id = ::User.find_by(id: advised_by_id).try(:integration_identifier).to_s if advised_by_id.present?

      if current_order_data.present?
        current_diagnosis = current_order_data['diagnosis'].find { |h| ((h['code'] == diagnosis.icddiagnosiscode.upcase.insert(3, '.')) && (h['status'] != "CANCELLED")) }
        current_diagnosis_id = current_diagnosis.try(:[], 'id')
        diagnosis_hash['id'] = current_diagnosis_id
      end

      if diagnosis_hash['id'].blank?
        diagnosis_hash['id'] = 0
      end

      diagnosis_hash['code'] = diagnosis.icddiagnosiscode.upcase.insert(3, '.')
      diagnosis_hash['description'] = diagnosis.diagnosisoriginalname
      diagnosis_hash['externalDoctorId'] = external_id
      diagnosis_hash['recordDate'] = diagnosis.created_at.strftime('%d/%m/%Y %R')

      diagnosis_array << diagnosis_hash
    end
    diagnosis_array
  end

  def self.get_cancelled_investigation_array(case_sheet, appointment_id, current_order_data)
    investigation_array = []

    ophthal_investigations = case_sheet.ophthal_investigations.where(appointment_id: appointment_id.to_s)
    laboratory_investigations = case_sheet.laboratory_investigations.where(appointment_id: appointment_id.to_s)
    radiology_investigations = case_sheet.radiology_investigations.where(appointment_id: appointment_id.to_s)

    Rails.logger.info(" =======canceltest=====================current_order_data['investigationOrders'] ========= #{current_order_data['investigationOrders']}")
    Rails.logger.info(" ============================case_sheet_data['ophthal_investigations'] ========= #{ophthal_investigations.to_a}")
    Rails.logger.info(" ============================case_sheet_data['laboratory_investigations'] ========= #{laboratory_investigations.to_a}")


    if current_order_data['investigationOrders'].present?
      current_order_data['investigationOrders'].each do |investigation|
        investigation_hash = {}
        # visit_record_investigation = ophthal_investigations.find { |h| h.try(:investigation_id).strip == investigation['code'].to_s }

        visit_record_investigation = ophthal_investigations.find_by(investigation_id: investigation['code'].to_s)

        if visit_record_investigation.blank?
          # visit_record_investigation = laboratory_investigations.find { |h| h.try(:investigation_id).strip == investigation['code'].to_s }
          visit_record_investigation = laboratory_investigations.find_by(investigation_id: investigation['code'].to_s)
        end

        if visit_record_investigation.blank?
          # visit_record_investigation = radiology_investigations.find { |h| h.try(:investigation_id).strip == investigation['code'].to_s }
          visit_record_investigation = radiology_investigations.find_by(investigation_id: investigation['code'].to_s)
        end

        if visit_record_investigation.blank?
          investigation_hash['id'] = investigation.try(:[], 'id')
          investigation_hash['processedBy'] = investigation.try(:[], 'externalDoctorId')
          investigation_hash['status'] = 'CANCELLED'
          investigation_array << investigation_hash
        end
      end
    end

    investigation_array
  end

  def self.get_investigation_array(case_sheet, appointment_id, current_order_data)
    investigation_array = []

    ophthal_investigations = case_sheet.ophthal_investigations.where(appointment_id: appointment_id.to_s)
    ophthal_investigations.each do |investigation|
      investigation_hash = {}

      if investigation.investigationside == '40638003'
        laterality = 'Bilateral'
        quantity = 2
      elsif investigation.investigationside == '18944008'
        laterality = 'Right'
        quantity = 1
      elsif investigation.investigationside == '8966001'
        laterality = 'Left'
        quantity = 1
      end
      advised_by_id = investigation.advised_by_id.to_s
      external_id = ::User.find_by(id: advised_by_id).try(:integration_identifier).to_s if advised_by_id.present?

      if current_order_data.present?
        if current_order_data['investigationOrders'].present?
          current_investigation = current_order_data['investigationOrders'].find { |h| ((h['code'] == investigation.investigation_id.strip) && (h['status'] != "CANCELLED") ) }
          current_investigation_id = current_investigation.try(:[], 'id')
          investigation_hash['id'] = current_investigation_id.to_i
        end
      end

      if investigation_hash['id'].blank?
        investigation_hash['id'] = 0
      end

      if investigation.is_performed.present?
        investigation_hash['status'] = 'PROCESSED'
        processed_by_id = investigation.reviewed_by_id.to_s
        consultant_id = investigation.consultant_id.to_s
        if processed_by_id.present?
          processed_by_id = ::User.find_by(id: processed_by_id).try(:integration_identifier).to_s
        elsif consultant_id.present?
          processed_by_id = ::User.find_by(id: consultant_id).try(:integration_identifier).to_s
        end
        investigation_hash['processedBy'] = processed_by_id
      end

      investigation_hash['code'] = investigation.investigation_id.strip
      investigation_hash['name'] = investigation.investigationname.strip
      investigation_hash['quantity'] = quantity
      investigation_hash['lateral'] = laterality
      investigation_hash['investigation_side'] = investigation.investigationside
      investigation_hash['externalDoctorId'] = external_id
      investigation_hash['orderDate'] = investigation.created_at.strftime('%d/%m/%Y %R')
      investigation_array << investigation_hash
    end

    laboratory_investigations = case_sheet.laboratory_investigations.where(appointment_id: appointment_id.to_s)

    laboratory_investigations.each do |investigation|
      investigation_hash = {}

      Rails.logger.info(" ============================investigation_hash laboratory ========= #{investigation_hash}")

      advised_by_id = investigation.advised_by_id.to_s
      external_id = ::User.find_by(id: advised_by_id).try(:integration_identifier).to_s if advised_by_id.present?

      if current_order_data.present?
        if current_order_data['investigationOrders'].present?
          current_investigation = current_order_data['investigationOrders'].find { |h| ((h['code'] == investigation.investigation_id.strip) && (h['status'] != "CANCELLED")) }
          current_investigation_id = current_investigation.try(:[], 'id')
          investigation_hash['id'] = current_investigation_id.to_i
        end
      end

      if investigation_hash['id'].blank?
        investigation_hash['id'] = 0
      end

      if investigation.is_performed.present?

        Rails.logger.info(" ============================investigation.is_performed ==inside======= #{investigation.is_performed}")

        investigation_hash['status'] = 'PROCESSED'
        processed_by_id = investigation.reviewed_by_id.to_s
        consultant_id = investigation.consultant_id.to_s
        if processed_by_id.present?
          processed_by_id = ::User.find_by(id: processed_by_id).try(:integration_identifier).to_s
        elsif consultant_id.present?
          processed_by_id = ::User.find_by(id: consultant_id).try(:integration_identifier).to_s
        end
        investigation_hash['processedBy'] = processed_by_id

        Rails.logger.info(" ============================investigation_hash laboratory 1===inside====== #{investigation_hash}")

      end

      Rails.logger.info(" ============================investigation_hash laboratory 2========= #{investigation_hash}")

      investigation_hash['code'] = investigation.investigation_id.strip
      investigation_hash['name'] = investigation.investigationname.strip
      investigation_hash['quantity'] = 1
      investigation_hash['lateral'] = ''
      investigation_hash['investigation_side'] = ''
      investigation_hash['externalDoctorId'] = external_id
      investigation_hash['orderDate'] = investigation.created_at.strftime('%d/%m/%Y %R')
      Rails.logger.info(" ============================investigation_hash laboratory 3========= #{investigation_hash}")

      investigation_array << investigation_hash

      Rails.logger.info(" ============================investigation_array laboratory 0========= #{investigation_array}")
    end

    radiology_investigations = case_sheet.radiology_investigations.where(appointment_id: appointment_id.to_s)

    radiology_investigations.each do |investigation|
      investigation_hash = {}

      advised_by_id = investigation.advised_by_id.to_s
      external_id = ::User.find_by(id: advised_by_id).try(:integration_identifier).to_s if advised_by_id.present?

      if current_order_data.present?
        if current_order_data['investigationOrders'].present?
          current_investigation = current_order_data['investigationOrders'].find { |h| ((h['code'] == investigation.investigation_id.strip) && (h['status'] != "CANCELLED")) }
          current_investigation_id = current_investigation.try(:[], 'id')
          investigation_hash['id'] = current_investigation_id.to_i
        end
      end

      if investigation_hash['id'].blank?
        investigation_hash['id'] = 0
      end

      if investigation.is_performed.present?
        investigation_hash['status'] = 'PROCESSED'
        processed_by_id = investigation.reviewed_by_id.to_s
        consultant_id = investigation.consultant_id.to_s
        if processed_by_id.present?
          processed_by_id = ::User.find_by(id: processed_by_id).try(:integration_identifier).to_s
        elsif consultant_id.present?
          processed_by_id = ::User.find_by(id: consultant_id).try(:integration_identifier).to_s
        end
        investigation_hash['processedBy'] = processed_by_id
      end

      investigation_hash['code'] = investigation.investigation_id.strip
      investigation_hash['name'] = investigation.investigationname.strip
      investigation_hash['quantity'] = 1
      investigation_hash['lateral'] = ''
      investigation_hash['investigation_side'] = ''
      investigation_hash['externalDoctorId'] = external_id
      investigation_hash['orderDate'] = investigation.created_at.strftime('%d/%m/%Y %R')
      investigation_array << investigation_hash
    end

    Rails.logger.info(" ============================investigation_array ========= #{investigation_array}")

    investigation_array
  end

  def self.get_cancelled_procedure_array(case_sheet, appointment_id, current_order_data)
    procedure_array = []
    procedures = case_sheet.procedures.where(appointment_id: appointment_id.to_s)


    Rails.logger.info(" =======canceltest=====================current_order_data['procedureAdvices'] ========= #{current_order_data['procedureAdvices']}")

    if current_order_data['procedureAdvices'].present?
      current_order_data['procedureAdvices'].each do |procedure|
        procedure_hash = {}

        # visit_record_procedure = procedures.find { |h| h.try(:procedure_id).strip == procedure['code'].to_s }
        visit_record_procedure = procedures.find_by(procedure_id: procedure['code'].to_s)

        Rails.logger.info(" ============================visit_record_procedure ========= #{visit_record_procedure}")


        if visit_record_procedure.blank?
          procedure_hash['id'] = procedure.try(:[], 'id')
          procedure_hash['processedBy'] = procedure.try(:[], 'externalDoctorId')
          procedure_hash['status'] = 'CANCELLED'
          procedure_array << procedure_hash
        end
      end
    end
    procedure_array
  end

  def self.get_procedure_array(case_sheet, appointment_id, current_order_data)
    procedure_array = []
    procedures = case_sheet.procedures.where(appointment_id: appointment_id.to_s)
    procedures.each do |procedure|
      procedure_hash = {}

      if procedure.procedureside == '40638003'
        laterality = 'Bilateral'
        quantity = 2
      elsif procedure.procedureside == '18944008'
        laterality = 'Right'
        quantity = 1
      elsif procedure.procedureside == '8966001'
        laterality = 'Left'
        quantity = 1
      end

      custom_common_procedure = ::CustomCommonProcedure.find_by(code: procedure.procedure_id, organisation_id: @facility.try(:organisation_id).to_s)
      puts 'custom_common_procedure=====================>', custom_common_procedure
      next if custom_common_procedure.blank?

      puts 'custom_common_procedure===========found==========>', custom_common_procedure
      region = custom_common_procedure.region[0] if custom_common_procedure.present?

      if region.present?
        eye_region = if region == 'cataract'
                       'Cataract'
                     elsif region == 'cornea'
                       'Cornea'
                     elsif region == 'glaucoma'
                       'Glaucoma'
                     elsif region == 'plasty'
                       'Orbit & Occuloplasty'
                     elsif region == 'squint'
                       'Paediatric & Strabismus'
                     else
                       'Vitreo - Retina'
                     end
      end

      advised_by_id = procedure.advised_by_id.to_s
      external_id = User.find_by(id: advised_by_id).try(:integration_identifier).to_s if advised_by_id.present?

      if current_order_data.present?
        current_procedure = current_order_data['procedureAdvices'].find { |h| ((h['code'] == procedure.procedure_id.strip) && (h['status'] != "CANCELLED")) }
        current_procedure_id = current_procedure.try(:[], 'id')
        procedure_hash['id'] = current_procedure_id.to_i
      end

      if procedure_hash['id'].blank?
        procedure_hash['id'] = 0
      end

      procedure_hash['code'] = procedure.procedure_id.strip
      procedure_hash['name'] = procedure.procedurename.strip
      procedure_hash['region'] = eye_region
      procedure_hash['externalDoctorId'] = external_id.to_s
      procedure_hash['lateral'] = laterality
      procedure_hash['quantity'] = quantity
      procedure_hash['orderDate'] = procedure.created_at.strftime('%d/%m/%Y %R')
      procedure_array << procedure_hash
    end
    procedure_array
  end

  def self.get_cancelled_medicine_array(_case_sheet, appointment_id, current_order_data, patient_id)
    drugs_array = []

    prescriptions = PatientPrescription.where(appointment_id: appointment_id.to_s, patient_id: patient_id.to_s)[0]

    medicines = prescriptions.medications if prescriptions.present?


    if current_order_data['drugOrders'].present?
      current_order_data['drugOrders'].each do |medicine|
        medicine_hash = {}

        if medicines.present?
          visit_record_medicines = medicines.find { |h| h.try(:pharmacy_item_id) == medicine['code'].to_s }
          # visit_record_medicines = medicines.find_by(pharmacy_item_id: medicine['code'].to_s)
        end

        if visit_record_medicines.blank?
          medicine_hash['id'] = medicine.try(:[], 'id')
          medicine_hash['processedBy'] = medicine.try(:[], 'externalDoctorId')
          medicine_hash['status'] = 'CANCELLED'
          drugs_array << medicine_hash
        end
      end
    end
    drugs_array
  end

  def self.get_medicine_array(_case_sheet, appointment_id, current_order_data, patient_id)
    drugs_array = []

    prescriptions = PatientPrescription.where(appointment_id: appointment_id.to_s, patient_id: patient_id.to_s)
    prescriptions.each do |prescription|
      medicines = prescription.medications
      medicines.each do |medicine|
        medicine_hash = {}

        if medicine['taper_id'].present? && medicine['taper_id'] != '0'
          tapering_set = TaperingKit.find_by(id: medicine['taper_id'].to_s).tapering_set

          total_doses = 0
          tapering_set.each do |set|
            number_of_days = set.try(:number_of_days).to_i
            frequency = set.try(:frequency).to_i

            set_total_doses = (number_of_days * frequency)

            # set_duration_days = set.number_of_days.to_i
            total_doses = total_doses.to_i + set_total_doses.to_i
          end

          quantity_per_dose = medicine['medicinequantity'].to_i
          quantity = (quantity_per_dose.to_i * total_doses.to_i).to_i

        else
          duration_multiplier = if medicine['medicinedurationoption'] == 'D'
                                  1
                                elsif medicine['medicinedurationoption'] == 'W'
                                  7
                                elsif medicine['medicinedurationoption'] == 'M'
                                  30
                                else
                                  1
                                end

          duration = medicine['medicineduration'].to_i
          duration_days = duration * duration_multiplier
          frequency = medicine['medicinefrequency'].to_i
          quantity_per_time = medicine['medicinequantity'].to_r.to_f

          quantity = (duration_days * quantity_per_time * frequency).to_i
        end

        advised_by_id = prescription.consultant_id.to_s
        external_id = User.find_by(id: advised_by_id).try(:integration_identifier).to_s if advised_by_id.present?

        if current_order_data.present?
          current_medicine = current_order_data['drugOrders'].find { |h| ((h['code'] == medicine['pharmacy_item_id']) && (h['status'] != "CANCELLED")) }

          puts '=======================================current_medicine================================', current_medicine
          puts '=======================================space================================'

          current_medicine_id = current_medicine.try(:[], 'id')
          medicine_hash['id'] = current_medicine_id.to_i
        end

        if medicine_hash['id'].blank?
          medicine_hash['id'] = 0
        end

        medicine_hash['externalDoctorId'] = external_id.to_s

        medicine_hash['code'] = medicine['pharmacy_item_id']
        medicine_hash['name'] = medicine['medicinename']
        quantity = 1 if quantity == 0
        medicine_hash['quantity'] = quantity
        medicine_hash['orderDate'] = prescription.created_at.strftime('%d/%m/%Y %R')
        if medicine_hash['code'].present?
          drugs_array << medicine_hash
        end
      end
    end

    drugs_array
  end

  def self.send_order_request(client, url, token, tokenlabel, payload, current_facility_id)
    request = RestClient::Request.execute(method: :post, url: url, payload: payload.to_json, headers: { tokenlabel => token, 'Content-Type' => 'application/json' })

    response = JSON.parse(request)
    Rails.logger.info("=======================firsttry==============================================#{response}")

    if response['status'] == '401' || response['responseCode'] == '005' # handling token expiry
      token = ::Api::V1::Integration::GenerateTokensController.create_session(client, current_facility_id)

      Rails.logger.info("=======================new token==============================================#{token}")

      if token.present?
        request = RestClient::Request.execute(method: :post, url: url, payload: payload.to_json, headers: { tokenlabel => token, 'Content-Type' => 'application/json' })
        response = JSON.parse(request)
        Rails.logger.info("=======================secondtry==============================================#{response}")
      end
    end

    response
  end
end
