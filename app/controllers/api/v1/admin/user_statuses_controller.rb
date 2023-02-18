class Api::V1::Admin::UserStatusesController < ApiApplicationController
  before_action :doorkeeper_authorize!

  def index
    raise ActionController::ParameterMissing if params[:user_id].nil?

    @user = User.includes(:user_statuses).find_by(id: params[:user_id])
    @user_statuses = @user.user_statuses.order(start_time: :desc)

    render status: :ok
  rescue ActionController::ParameterMissing
    render status: :bad_request
  end
end
