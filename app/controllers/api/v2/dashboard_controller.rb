class Api::V2::DashboardController < ApiApplicationController
  before_action :authorize_token
  before_action :current_user, :current_facility

  def facilities; end

  def roles
    @roles = Role.where(:id.in => [158965000, 28229004, 499992366])
  end

  def role_users
    role = params[:role] || 'doctor'
    @role_user = Role.where(name: role)[0].users.where(facility_ids: @current_facility.id, is_active: true)
  end
end
