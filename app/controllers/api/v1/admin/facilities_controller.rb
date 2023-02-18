class Api::V1::Admin::FacilitiesController < ApiApplicationController
  before_action :doorkeeper_authorize!

  def index
    params.fetch(:organisation_id)

    options = { organisation_id: params[:organisation_id] }
    options = options.merge(is_active: params[:status]) if params[:status].present?

    @organisation = Organisation.find_by(id: params[:organisation_id])
    @facilities = Facility.where(options).to_a
    @users = User.where(:facility_ids.in => @facilities.pluck(:id)).to_a

    render status: :ok
  rescue ActionController::ParameterMissing
    render status: :bad_request
  end
end
