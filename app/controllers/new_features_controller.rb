class NewFeaturesController < ApplicationController
  before_action :authorize

  def index
    @current_user = current_user
    # @department = @current_user.department
  end

  def seen
    @user = User.find_by(id: params[:user_id])
    @user.update(new_feature_seen: true)
  end
end
