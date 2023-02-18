require 'rest-client'
require 'json'
class Api::V1::Integration::GenerateTokensController < ApiApplicationController
  def self.create_session(client, facility_id)
    client_integration_token = ApiIntegration::ClientIntegrationToken.find_by(client: client, facility_id: facility_id)

    # if client_integration_token.blank?
    #   facility = Facility.find_by(id: facility_id)
    #   facility_integration_identifier = facility.integration_identifier
    #
    #   organisation = Organisation.find_by(id: facility.organisation_id)
    #   organisation_id = organisation.id.try(:to_s)
    #   organisation_integration_identifier = organisation.integration_identifier
    #
    #   client_integration_token = ApiIntegration::ClientIntegrationToken.create(client: client, facility_id: facility_id, facility_integration_identifier: facility_integration_identifier, organisation_integration_identifier: organisation_integration_identifier, organisation_id: organisation_id )
    # end

    if client_integration_token.present?
      url = client_integration_token.url
      payload = client_integration_token.credential_payload

      LoggerService.new.integration(payload, 'integration', "generate tokens#{url}")

      request = RestClient::Request.execute(method: :post, url: url,
                                            payload: payload.to_json,
                                            headers: { 'Content-Type' => 'application/json' })

      response = JSON.parse(request)

      LoggerService.new.integration(response, 'integration', 'generate tokens response')

      if response['responseCode'] == '000'
        token = response['response']['uToken']
        client_integration_token.update(token: token)
      else
        token = nil
      end

      token
    end

    # client_id = Rails.application.secrets.client_id
    # client_secret = Rails.application.secrets.client_secret
    #
    #
    # url = if Rails.env.development?
    #         'http://localhost:8080/oauth/token?'
    #       elsif Rails.env.preproduction?
    #         'https://ppehr.healthgraph.in/oauth/token?'
    #       else
    #         'https://ehr.healthgraph.in/oauth/token?'
    #       end
    #
    # response = RestClient.post url,
    #                            grant_type: 'client_credentials',
    #                            client_id: client_id,
    #                            client_secret: client_secret
    # token = JSON.parse(response)['access_token']
    #
    # Session.last.update(session_id: token.to_s)

    # eval('redirect_to ' + params[:url] + '(:params=> params.permit!)')
  end
end
