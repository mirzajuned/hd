# rubocop:disable all
class ApiApplicationController < ActionController::Base
  # *******************************************
  # NOT WORKING
  # *******************************************
  around_action :api_time_zone, if: :current_facility
  skip_before_action :check_for_lockup, raise: false
  # skip_before_action :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }

  private

  def current_user
    @current_user ||= User.find(session[:api_user_id]) if session[:api_user_id]
  end
  helper_method :current_user

  def current_facility
    @current_facility ||= Facility.find_by(id: params[:current_facility_id]) if params[:current_facility_id]
  end
  helper_method :current_facility


  def authorize_token
    @api_key = ApiKey.find_by(access_token: request.headers['Token'], expiry_time: { '$gt' => Time.current })
    if @api_key.present?
      session[:api_user_id] = @api_key.user_id
    else
      render json: { error: 'HTTP Token: Access denied.' }, status: :forbidden
    end
  end

  def api_time_zone(&block)
    Time.use_zone(current_facility.time_zone, &block)
  end

  def to_boolean(value)
    !['false', false, 0].include?(value)
  end

  protected

  def request_http_token_authentication(realm = 'Application')
    headers['WWW-Authenticate'] = %(Token realm="#{realm.delete('"')}")
    render json: { error: 'HTTP Token: Access denied.' }, status: :forbidden
  end
end
