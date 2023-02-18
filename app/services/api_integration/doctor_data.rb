class ApiIntegration::DoctorData
  def self.create(user_id, client, current_facility_id)
    sleep 5
    user = User.find_by(id: user_id)

    @facility = ::Facility.find_by(id: current_facility_id)
    return if user.blank?

    payload = {}


    user_integration_identifier = user.integration_identifier.to_s

    user_data = ::ApiIntegration::User::Data.find_by(user_integration_identifier: user_integration_identifier)

    doctor_payload_attributes = Global.send(client)[Rails.env]['doctor_payload_attributes']
    doctor_payload_attributes.each do |key, value|
      if key == 'is_active'
        payload[value] = user.try(:send, key)
      else
        payload[value] = user.try(:send, key).try(:to_s)
      end
    end

    payload['code'] = payload['externalId'][-8..-1]
    payload['id'] = user_data.try(:user_external_id)

    sub_speciality_ids = user.try(:send, 'sub_specialty_ids')
    primary_sub_speciality = if sub_speciality_ids.length == 1
                               sub_speciality_ids[0]
                             else
                               (sub_speciality_ids - ['422234006'])[0]
                             end

    primary_sub_speciality_text = Global.send(client)['doctor_speciality'][primary_sub_speciality]

    payload['speciality'] = primary_sub_speciality_text.to_s

    if user_data.blank?
      user_data_params = {
          user_integration_identifier: user_integration_identifier,
          user_external_id: 0,
          user_integration_identifier_bson: user.try(:integration_identifier),
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
      user_data = ApiIntegration::User::Data.new(user_data_params)
      user_data.save
    else
      user_data.update(payload: payload, data: payload)
    end

    url = Global.send(client)[Rails.env]['doctor_data_url']
    token = Global.send(client)[Rails.env]['token']
    tokenlabel = Global.send(client)[Rails.env]['tokenlabel']

    LoggerService.new.integration(payload, 'integration', 'doctor data payload')

    begin
      response = send_user_request(client, url, token, tokenlabel, payload, current_facility_id)
      @user_integration_identifier = response.try(:[], 'data').try(:[], 'externalId') || user.integration_identifier
      @external_identifier = response.try(:[], 'data').try(:[], 'id') || 0
      @status = response.try(:[], 'status')
      @status_code = 200
      @response_code = response.try(:[], 'responseCode')
      @message = response.try(:[], 'errorMessage') || 'Success'
      @response = response
    rescue StandardError
      @user_integration_identifier = user.integration_identifier
      @external_identifier = 0
      @status = 'Failed'
      @status_code = 500
      @response_code = 500
      @message = 'No Response Received'
      @response = {}
    end


    @response_received = ApiIntegration::User::ResponseReceived.new(status: @status, status_code: @status_code, response: @response, response_code: @response_code, message: @message, user_integration_identifier: @user_integration_identifier, role_ids: user.role_ids, role: 'doctor', user_id: user.id, user_external_id: @external_identifier)
    @response_received.save!

    if @response_code == '000' && @status_code == 200
      updated_response_data = user_data.data
      updated_response_data['id'] = @external_identifier
      user_data.user_external_id = @external_identifier
      user_data.data = updated_response_data
      user_data.save
    end

    begin
      @current_facility = Facility.find_by(id: current_facility_id)
      @url = url
      @payload = payload
      create_data_request
      create_data_response
    rescue StandardError
    end
    LoggerService.new.integration(response, 'integration', 'response')
  end

  def self.update(user_id, client, current_facility_id)
    sleep 5
    user = User.find_by(id: user_id)

    return if user.blank?

    payload = {}

    user_integration_identifier = user.integration_identifier.to_s

    user_data = ::ApiIntegration::User::Data.find_by(user_integration_identifier: user_integration_identifier)


    doctor_payload_attributes = Global.send(client)[Rails.env]['doctor_payload_attributes']
    doctor_payload_attributes.each do |key, value|
      if key == 'is_active'
        payload[value] = user.try(:send, key)
      else
        payload[value] = user.try(:send, key).try(:to_s)
      end
    end

    payload['code'] = payload['externalId'][-8..-1]

    payload['id'] = user_data.try(:user_external_id) || 0

    sub_speciality_ids = user.try(:send, 'sub_specialty_ids')
    primary_sub_speciality = if sub_speciality_ids.length == 1
                               sub_speciality_ids[0]
                             else
                               (sub_speciality_ids - ['422234006'])[0]
                             end

    primary_sub_speciality_text = Global.send(client)['doctor_speciality'][primary_sub_speciality]

    payload['speciality'] = primary_sub_speciality_text.to_s

    if user_data.blank?
      user_data_params = {
          user_integration_identifier: user_integration_identifier,
          user_external_id: 0,
          user_integration_identifier_bson: user.try(:integration_identifier),
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
      user_data = ApiIntegration::User::Data.new(user_data_params)
      user_data.save
    else
      user_data.update(payload: payload, data: payload)
    end


    url = Global.send(client)[Rails.env]['doctor_data_url']
    token = Global.send(client)[Rails.env]['token']
    tokenlabel = Global.send(client)[Rails.env]['tokenlabel']

    LoggerService.new.integration(payload, 'integration', 'doctor data payload')

    begin
      response = send_user_request(client, url, token, tokenlabel, payload, current_facility_id)
      @user_integration_identifier = response.try(:[], 'data').try(:[], 'externalId') || user.integration_identifier
      @external_identifier = response.try(:[], 'data').try(:[], 'id') || 0
      @status = response.try(:[], 'status')
      @status_code = 200
      @response_code = response.try(:[], 'responseCode')
      @message = response.try(:[], 'errorMessage') || 'Success'
      @response = response
    rescue StandardError
      @user_integration_identifier = user.integration_identifier
      @external_identifier = 0
      @status = 'Failed'
      @status_code = 500
      @response_code = 500
      @message = 'No Response Received'
      @response = {}
    end

    @response_received = ApiIntegration::User::ResponseReceived.new(status: @status, status_code: @status_code, response: @response, response_code: @response_code, message: @message, user_integration_identifier: @user_integration_identifier, role_ids: user.role_ids, role: 'doctor', user_external_id: @external_identifier)
    @response_received.save!

    if @response_code == '000' && @status_code == 200
      updated_response_data = user_data.data
      updated_response_data['id'] = @external_identifier
      user_data.user_external_id = @external_identifier
      user_data.data = updated_response_data
      user_data.save
    end

    begin
      @current_facility = Facility.find_by(id: current_facility_id)
      @url = url
      @payload = payload
      create_data_request
      create_data_response
    rescue StandardError
    end

    LoggerService.new.integration(response, 'integration', 'response')
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

  def self.send_user_request(client, url, token, tokenlabel, payload, current_facility_id)
    request = RestClient::Request.execute(method: :post, url: url, payload: payload.to_json, headers: { tokenlabel => token, 'Content-Type' => 'application/json' })

    response = JSON.parse(request)
    LoggerService.new.integration(response, 'integration', 'response')

    if response['status'] == '401' || response['responseCode'] == '005' # handling token expiry
      # user =  User.find_by(id: user_id)
      token = Api::V1::Integration::GenerateTokensController.create_session(client, current_facility_id)

      if token.present?
        request = RestClient::Request.execute(method: :post, url: url, payload: payload.to_json, headers: { tokenlabel => token, 'Content-Type' => 'application/json' })
        response = JSON.parse(request)
      end
    end

    response
  end
end
