class Api::V1::Admin::UsersController < ApiApplicationController
  before_action :doorkeeper_authorize!

  def index
    if params[:organisation_id].present?
      options = { organisation_id: params[:organisation_id] }
    elsif params[:facility_id].present?
      options = { facilty_ids: params[:facility_id] }
    else
      raise ActionController::ParameterMissing
    end

    options = options.merge(is_active: to_boolean(params[:status])) if params[:status].present?

    @users = User.where(options).to_a
    @facility = Facility.find_by(id: params[:facility_id])
    @organisation = Organisation.find_by(id: params[:organisation_id] || @facility.id.to_s)

    render status: :ok
  rescue ActionController::ParameterMissing
    render status: :bad_request
  end
end
