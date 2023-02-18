require 'rest-client'
require 'json'
module Api
  module V1
    class OutreachSessionsController < ApplicationController
      def create_session
        # client_id = '67819ab004aa639f546fab2b7d9cfc347871077c279135ab534cf55f6117c027'
        client_id = Rails.application.secrets.outreach_client_id
        # client_secret = '93620ef6f32a64e5c8211411cb89dd89a1f382c0c0f3276df6a12719680893ed'
        client_secret = Rails.application.secrets.outreach_client_secret

        if Rails.env.development?
          url = 'http://localhost:8080/oauth/token?'
        elsif Rails.env.preproduction?
          url = 'https://ppoutreach.healthgraph.in/oauth/token?'
        elsif Rails.env.cicd1?
          url = 'http://cicd1outreach.healthgraph.in/oauth/token?'
        elsif Rails.env.cicd2?
          url = 'http://cicd2outreach.healthgraph.in/oauth/token?'
        elsif Rails.env.cicd3?
          url = 'http://cicd3outreach.healthgraph.in/oauth/token?'
        elsif Rails.env.stage?
          url = 'https://stageoutreach.healthgraph.in/oauth/token?'
        elsif Rails.env.qa1?
          url = 'https://qa1outreach.healthgraph.in/oauth/token?'
        elsif Rails.env.qa2?
          url = 'https://q2outreach.healthgraph.in/oauth/token?'
        elsif Rails.env.qa3?
          url = 'https://qa3outreach.healthgraph.in/oauth/token?'
        elsif Rails.env.qa4?
          url = 'https://qa4outreach.healthgraph.in/oauth/token?'
        elsif Rails.env.qa5?
          url = 'https://qa5outreach.healthgraph.in/oauth/token?'
        elsif Rails.env.qa6?
          url = 'https://qa6outreach.healthgraph.in/oauth/token?'
        elsif Rails.env.qa7?
          url = 'https://qa7outreach.healthgraph.in/oauth/token?'
        elsif Rails.env.qa8?
          url = 'https://qa8outreach.healthgraph.in/oauth/token?'
        elsif Rails.env.qa9?
          url = 'https://qa9outreach.healthgraph.in/oauth/token?'
        elsif Rails.env.qa10?
          url = 'https://qa10outreach.healthgraph.in/oauth/token?'
        elsif Rails.env.uat?
          url = 'https://uatoutreach.healthgraph.in/oauth/token?'
        else
          url = 'https://outreach.healthgraph.in/oauth/token?'
        end

        response = RestClient.post url, { grant_type: 'client_credentials', client_id: client_id, client_secret: client_secret }
        token = JSON.parse(response)["access_token"]

        OutreachSession.last.update(session_id: token.to_s)

        eval("redirect_to #{params[:url]}(:params=> params.permit!)")
      end
    end
  end
end
