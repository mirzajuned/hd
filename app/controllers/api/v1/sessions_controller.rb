require 'rest-client'
require 'json'
module Api
  module V1
    class SessionsController < ApplicationController
      def create_session
        client_id = Rails.application.secrets.client_id
        client_secret = Rails.application.secrets.client_secret

        if Rails.env.development?
          url = 'http://localhost:8080/oauth/token?'
        elsif Rails.env.preproduction?
          url = 'https://pppsr.healthgraph.in/oauth/token?'
        elsif Rails.env.stage?
          url = 'https://stagepsr.healthgraph.in/oauth/token?'
        else
          url = 'https://psr.healthgraph.in/oauth/token?'
        end

        response = RestClient.post url, { grant_type: 'client_credentials', client_id: client_id,
                                          client_secret: client_secret }
        token = JSON.parse(response)["access_token"]

        TokenSession.last.update(session_id: token.to_s)

        eval("redirect_to #{params[:url]}(:params=> params.permit!)")
      end
    end
  end
end
