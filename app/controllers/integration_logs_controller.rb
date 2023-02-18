class IntegrationLogsController < ApplicationController
  before_action :authorize
  layout "loggedin"

  def index
    if params[:password] == "5how!ntegrati0n"
      # Date
      if params[:date].present?
        @date = Date.parse(params[:date])
      else
        @date = Date.current
      end

      # Data
      if current_user.try(:organisation_id).to_s == "57f1c8b7666d676c0c000002"
        @data = ApiIntegration::DrAgarwal::Appointment::Data.where(:updated_at.gte => @date, :updated_at.lt => @date + 1).order(updated_at: :desc)
        @data_received = @data.where(request_type: "Received")
        @data_sent = @data.where(request_type: "Sent")

        # Response
        @response_received = ApiIntegration::DrAgarwal::Appointment::ResponseReceived.where(:updated_at.gte => @date, :updated_at.lte => @date + 1).order(updated_at: :desc)
        @response_sent = ApiIntegration::DrAgarwal::Appointment::ResponseSent.where(:updated_at.gte => @date, :updated_at.lte => @date + 1).order(updated_at: :desc)
      else
        date_count = params[:date_count].try(:to_i) || 0

        @data = ApiIntegration::Appointment::Data.where(:updated_at.gte => @date + date_count, :updated_at.lt => @date + 1 + date_count).order(updated_at: :desc)
        @data_received = @data.where(request_type: "Received")
        @data_sent = @data.where(request_type: "Sent")

        # Response
        @response_received = ApiIntegration::Appointment::ResponseReceived.where(:updated_at.gte => @date + date_count, :updated_at.lte => @date + 1 + date_count).order(updated_at: :desc)
        @response_sent = ApiIntegration::Appointment::ResponseSent.where(:updated_at.gte => @date + date_count, :updated_at.lte => @date + 1 + date_count).order(updated_at: :desc)
      end

    else
      redirect_to '/'
    end
  end

  def advance_index
    if params[:password] == "5how!ntegrati0n"
      # Date
      if params[:date].present?
        @date = Date.parse(params[:date])
      else
        @date = Date.current
      end

      # Data
      date_count = params[:date_count].try(:to_i) || 0
      @data = ApiIntegration::DataRequest.where(:updated_at.gte => @date + date_count, :updated_at.lt => @date + 1 + date_count, organisation_id: current_user.try(:organisation_id)).order(updated_at: :desc)
      @data_received = @data.where(request_type: "received")
      @data_sent = @data.where(request_type: "sent")

      # Response
      @response = ApiIntegration::DataResponse.where(:updated_at.gte => @date + date_count, :updated_at.lte => @date + 1 + date_count, organisation_id: current_user.try(:organisation_id)).order(updated_at: :desc)

      @response_received = @response.where(response_type: "received")
      @response_sent = @response.where(response_type: "sent")
    end
  end
end
