class ApiIntegration::AdmissionStatusData
  def self.update(admission_id, client, current_facility_id, status, date)
    sleep 5
    @facility = ::Facility.find_by(id: current_facility_id)
    @admission = ::Admission.find_by(id: admission_id)

    return if @admission.blank?

    @patient_mrn = @admission.try(:patient).try(:patient_mrn)

    @admission_integration_identifier_bson = @admission.integration_identifier

    @admission_data = ::ApiIntegration::Admission::Data.find_by(admission_integration_identifier_bson: @admission_integration_identifier_bson)

    return if @admission_data.blank?

    @admission_integration_identifier = @admission_data.admission_integration_identifier

    LoggerService.new.integration(@admission_data.to_json, 'integration', 'admission_data')

    payload = {}

    date = Time.now.strftime('%d/%m/%Y %R') if date.blank?

    if status == 'markedForDischarge'
      begin
        procedure_array = get_procedures_array
        payload['procedureAdvices'] = procedure_array
        payload['payloadDeliveryTime'] = Time.now
      rescue StandardError => e
        payload['procedureAdvices'] = []
      end
      LoggerService.new.integration(@admission_data.to_json, 'integration', 'admission_data')

      url = Global.send(client)[Rails.env]['admission_marked_discharge_url']
    elsif status == 'discharged'
      url = Global.send(client)[Rails.env]['admission_discharged_url']
    end

    payload['visitId'] = @admission_integration_identifier
    payload['status'] = status
    payload['date'] = date

    return if url.blank?

    token = ::ApiIntegration::ClientIntegrationToken.find_by(client: client, facility_id: current_facility_id).try(:token).to_s
    tokenlabel = Global.send(client)[Rails.env]['tokenlabel']

    puts '==========================================payload======================================>', payload
    LoggerService.new.integration(payload, 'integration', 'payload')

    begin
      response = send_admission_status_request(client, url, token, tokenlabel, payload, current_facility_id)
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
      @status_code = 400
      @response_code = 400
      @message = 'No Response Received'
      @response = {}
      @response_data = {}
    end
    LoggerService.new.integration(@response, 'integration', '@response')

    @response_received = ::ApiIntegration::Admission::ResponseReceived.new(admission_integration_identifier: @admission_integration_identifier, mr_no: @patient_mrn, status: @status, status_code: @status_code, response: @response, response_code: @response_code, message: @message, data: @response_data)
    @response_received.save!

    puts '================================@response_code====,,,,======@status_code========', @response_code, @status_code

    begin
      @url = url
      @payload = payload
      create_data_request
      create_data_response
    rescue StandardError
    end
  end

  private

  def self.create_data_request
    data_hash = @payload
    organisation_id = @facility.try(:organisation_id).to_s
    facility_id = @facility.id.to_s
    ApiIntegration::DataRequests::CreateService.call(data_hash, @url, 'sent', organisation_id, facility_id, {})
  rescue StandardError
  end

  def self.create_data_response
    data_hash = @response
    organisation_id = @facility.try(:organisation_id).to_s
    facility_id = @facility.id.to_s
    ApiIntegration::DataResponses::CreateService.call(data_hash, @url, 'received', organisation_id, facility_id, {})
  rescue StandardError
  end

  def self.send_admission_status_request(client, url, token, tokenlabel, payload, current_facility_id)
    LoggerService.new.integration(payload, 'integration', "token============#{token}")

    request = RestClient::Request.execute(method: :post, url: url, payload: payload.to_json, headers: { tokenlabel => token, 'Content-Type' => 'application/json' })
    response = JSON.parse(request)
    if response['status'] == '401' || response['responseCode'] == '005' # handling token expiry
      token = Api::V1::Integration::GenerateTokensController.create_session(client, current_facility_id)
      if token.present?
        request = RestClient::Request.execute(method: :post, url: url, payload: payload.to_json, headers: { tokenlabel => token, 'Content-Type' => 'application/json' })
        response = JSON.parse(request)
      end
    end

    response
  end

  def self.get_procedures_array
    procedure_array = []

    @ipd_record = ::Inpatient::IpdRecord.find_by(admission_id: @admission.id.to_s)

    return if @ipd_record.blank?

    case_sheet_id = @ipd_record.case_sheet_id

    casesheet = ::CaseSheet.find_by(id: case_sheet_id)

    return if @ipd_record.blank?

    # @ipd_record_procedures = casesheet.procedures.where(admission_id: @admission.id.to_s, :performed_datetime.ne => nil)
    @ipd_record_procedures = casesheet.procedures.or({ admission_id: @admission.id.to_s }, { admission_id: @admission.id }).where(:performed_datetime.ne => nil)

    # @ipd_record_procedures = @ipd_record.procedure

    @admission_data_procedures = @admission_data.procedures_received
    @admission_data_procedures.each do |procedure_received|
      procedure_hash = {}

      laterality_received = if procedure_received['lateral'].try(:downcase) == 'right'
                              '18944008'
                            elsif procedure_received['lateral'].try(:downcase) == 'left'
                              '8966001'
                            else
                              ''
                            end

      ipd_record_procedure = @ipd_record_procedures.find_by(procedurefullcode: procedure_received['code'], procedureside: laterality_received)

      custom_common_procedure = ::CustomCommonProcedure.find_by(code: procedure_received['code'], organisation_id: @facility.try(:organisation_id).to_s)
      next if custom_common_procedure.blank?

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

      advised_by_id = ipd_record_procedure.try(:advised_by_id).try(:to_s)
      external_id = if advised_by_id.present?
                      ::User.find_by(id: advised_by_id).try(:integration_identifier).to_s
                    else
                      @admission_data.try(:doctor_integration_identifier)
                    end

      if ipd_record_procedure.present?

        if ipd_record_procedure.is_performed == true
          procedure_status = 'performed'
          performed_datetime = ipd_record_procedure.try(:performed_datetime)
          processedDateTime = performed_datetime.strftime('%d/%m/%Y %R') if performed_datetime.present?
        else
          procedure_status = 'notPerformed'
          processedDateTime = ''
        end

        procedure_hash['id'] = procedure_received['id']
        procedure_hash['code'] = procedure_received['code']
        procedure_hash['name'] = procedure_received['name']
        procedure_hash['procedureStatus'] = procedure_status
        procedure_hash['processedDateTime'] = processedDateTime
        procedure_hash['region'] = eye_region || 'others'
        procedure_hash['quantity'] = 1
        procedure_hash['orderDate'] = ipd_record_procedure.created_at.strftime('%d/%m/%Y %R')
        procedure_hash['lateral'] = procedure_received['lateral']
        procedure_hash['externalDoctorId'] = external_id
      else
        procedure_hash['id'] = procedure_received['id']
        procedure_hash['code'] = procedure_received['code']
        procedure_hash['name'] = procedure_received['name']
        procedure_hash['procedureStatus'] = 'notPerformed'
        procedure_hash['processedDateTime'] = processedDateTime
        procedure_hash['region'] = eye_region || 'others'
        procedure_hash['quantity'] = 1
        procedure_hash['orderDate'] = @admission_data.created_at.strftime('%d/%m/%Y %R')
        procedure_hash['lateral'] = procedure_received['lateral']
        procedure_hash['externalDoctorId'] = external_id
      end
      procedure_array << procedure_hash
    end

    LoggerService.new.integration(@ipd_record_procedures.to_json, 'integration', '@@ipd_record_procedures')

    @ipd_record_procedures.where(is_performed: true).each do |ipd_record_procedure|
      procedure_hash = {}

      if ipd_record_procedure.procedureside == '40638003'
        laterality = 'Bilateral'
        quantity = 2
      elsif ipd_record_procedure.procedureside == '18944008'
        laterality = 'Right'
        quantity = 1
      elsif ipd_record_procedure.procedureside == '8966001'
        laterality = 'Left'
        quantity = 1
      end

      custom_common_procedure = ::CustomCommonProcedure.find_by(code: ipd_record_procedure.procedure_id, organisation_id: @facility.try(:organisation_id).to_s)
      next if custom_common_procedure.blank?

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

      advised_by_id = ipd_record_procedure.try(:advised_by_id).try(:to_s)
      external_id = ::User.find_by(id: advised_by_id).try(:integration_identifier).to_s if advised_by_id.present?

      performed_datetime = ipd_record_procedure.try(:performed_datetime)
      processedDateTime = performed_datetime.strftime('%d/%m/%Y %R') if performed_datetime.present?

      procedure_hash['id'] = 0
      procedure_hash['code'] = ipd_record_procedure.procedure_id.strip
      procedure_hash['name'] = ipd_record_procedure.procedurename.strip
      procedure_hash['procedureStatus'] = 'performed'
      procedure_hash['processedDateTime'] = processedDateTime
      procedure_hash['region'] = eye_region || 'others'
      procedure_hash['quantity'] = quantity
      procedure_hash['orderDate'] = ipd_record_procedure.created_at.strftime('%d/%m/%Y %R')
      procedure_hash['lateral'] = laterality
      procedure_hash['externalDoctorId'] = external_id

      duplicate_procedure = procedure_array.find { |procedure| (procedure['code'] == procedure_hash['code'] && procedure['lateral'] == procedure_hash['lateral']) }
      procedure_array << procedure_hash if duplicate_procedure.blank?
    end
    LoggerService.new.integration(procedure_array, 'integration', 'procedure_array')

    procedure_array
  end
end
