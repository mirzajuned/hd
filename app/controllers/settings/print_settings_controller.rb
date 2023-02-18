class Settings::PrintSettingsController < ApplicationController
  layout 'loggedin'

  before_action :authorize
  before_action :authenticate_admin_user, only: [:index]
  before_action :set_print_setting, only: [:edit, :update, :destroy, :preview_print]
  before_action :facilities_array, only: [:new, :edit]
  before_action :departments_array, only: [:new, :edit]

  def index
    @print_settings = PrintSetting.where(organisation_id: current_user.organisation_id.to_s, is_deleted: false)
  end

  def new
    @print_setting = PrintSetting.new
  end

  def create
    @print_setting = PrintSetting.new(print_setting_params)
    @print_setting.save!
  end

  def edit; end

  def update
    @print_setting.update_attributes(print_setting_params)
  end

  def destroy
    @print_setting.update_attributes(is_deleted: true)
  end

  def preview_print
    @organisation = current_user.organisation
    respond_to do |format|
      print_attributes(format, 'settings/print_settings/print_preview', 'Dummy-Print', @print_setting)
    end
  end

  private

  def authenticate_admin_user
    department_ids = current_user.department_ids
    if department_ids.present?
      if department_ids.include?("224608005")
        custom_check_for_lockup
      else
        redirect_to user_department_url(current_user)
      end
    else
      redirect_to '/'
    end
  end

  def custom_check_for_lockup
    multi_auth = OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id)).try(:multi_auth)
    return unless multi_auth
    return unless respond_to?(:lockup) && lockup_codeword
    return if cookies[:lockup].present? && cookies[:lockup] == lockup_codeword.to_s.downcase

    if request.xhr?
      respond_to do |format|
        format.js { render inline: "location.reload();" }
      end
    else
      redirect_to lockup.unlock_path(
        return_to: request.fullpath.split('?lockup_codeword')[0],
        lockup_codeword: params[:lockup_codeword],
      )
    end
  end

  def print_setting_params
    params.require(:print_setting).permit(:organisation_id, :type, :is_editable, :name, :header_height, :footer_height,
                                          :left_margin, :right_margin, :customised_letter_head, :header_location,
                                          :header, :header_logo_location, :logo, :left, :right, :customised_footer,
                                          :footer_text, facility_ids: [], department_ids: [])
  end

  def set_print_setting
    @print_setting = PrintSetting.find_by(id: params[:id])
  end

  def facilities_array
    facilities = Facility.where(organisation_id: current_user.organisation_id, is_active: true)

    @facilities_array = facilities.pluck(:name, :id)
  end

  def departments_array
    departments = Department.all

    @departments_array = departments.pluck(:name, :id)
  end
end
