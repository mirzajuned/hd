class Settings::OpticiansController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def account_settings
    respond_to do |format|
      format.js { render "settings/opticians/account_settings", layout: false }
      format.html {}
    end
  end
end
