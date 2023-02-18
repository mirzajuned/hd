class NabhSettingsController < ApplicationController
  def setting_save
    @facility_ids = params[:facility_ids]
    @facility_ids.each do |facility_id|
      save_nabh_setting(facility_id)
    end
    render json: { "success": true }
  end

  def nabh_facility_change
    respond_to do |format|
      format.js { render '/nabh_settings/nabh_facility_change', layout: false }
    end
  end

  private

  def save_nabh_setting(facility_id)
    @nabh_setting = NabhSetting.find_by(facility_id: facility_id)
    if @nabh_setting.present?
      @nabh_setting.update(enabled: params[:enabled])
    else
      NabhSetting.create(enabled: params[:enabled], facility_id: facility_id, organisation_id: current_user.organisation_id)
    end
  end
end
