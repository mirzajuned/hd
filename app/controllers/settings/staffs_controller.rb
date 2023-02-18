class Settings::StaffsController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def account_settings
    respond_to do |format|
      format.js { render "settings/staffs/account_settings", layout: false }
      format.html {}
    end
  end

  def staff_settings
    @user = current_user
    @user_departments = Department.where(:id.in => @user.department_ids).map { |dept| { id: dept.id, name: dept.name } }
    respond_to do |format|
      format.js { render "settings/staffs/staff_settings", layout: false }
      format.html {}
    end
  end

  def practice_setting
    @user_set_type = UsersLaboratoryList.where(user_id: current_user.id, set_type: 440655000, is_deleted: false).pluck(:name, :id)
    @facility_set_type = FacilityLaboratoryList.where(facility_id: current_facility.id, set_type: 440655000, is_deleted: false).pluck(:name, :id)
    @set_type = @user_set_type + @facility_set_type
    respond_to do |format|
      format.js { render "settings/staffs/practice_setting", layout: false }
      format.html {}
    end
  end
end
