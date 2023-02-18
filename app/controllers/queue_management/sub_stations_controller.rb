class QueueManagement::SubStationsController < ApplicationController
  before_action :authorize
  before_action :validate_setting_enabled, :validate_active_appointments, only: [:link_user]

  # User Selection Navbar
  def link_user
    @areas = QueueManagement::Area.where(facility_id: current_facility.id.to_s)
  end

  def update_link_user
    # Call this before update as it will change once update takes place
    @existing_sub_station = current_sub_station

    # Find SubStation
    sub_station = QueueManagement::SubStation.find_by(id: params[:sub_station_id])
    return if sub_station.nil?

    old_active_user_id = sub_station.active_user_id

    sub_station.update_attributes!(active_user_id: current_user.id, last_active_user_id: old_active_user_id)

    # Update Dropdown with new SubStation & Remove Previous User
    dropdown_sub_station(sub_station.id, current_user.id.to_s, 'update')
    dropdown_sub_station(sub_station.id, old_active_user_id.to_s, 'remove') if old_active_user_id

    # Update Station Dropdown with New SubStation Info
    QueueManagementJobs::StationJob.perform_later(sub_station.station_id.to_s)

    update_existing_station if @existing_sub_station.present?
  end

  def link_users
    @facilities = current_user.facilities.pluck(:name, :id)
  end

  def update_link_users
    return unless params[:sub_stations].present?

    facility_setting = FacilitySetting.find_by(facility_id: params[:facility_id])

    params[:sub_stations].each do |_k, sub_station_params|
      next unless sub_station_params[:is_updated] == 'true'

      sub_station = QueueManagement::SubStation.find_by(id: sub_station_params[:id])
      old_sub_station_id = sub_station.id
      old_sub_station_user_id = sub_station.user_id

      sub_station.update_attributes!(user_id: sub_station_params[:user_id])

      # If user can set station, then no need to update dropdown with permanent user values
      next if facility_setting&.user_set_station

      # SubStation Workflow Dropdown
      dropdown_sub_station(old_sub_station_id, old_sub_station_user_id, 'remove') if old_sub_station_user_id.present?
      dropdown_sub_station(sub_station.id, sub_station.user_id, 'update') if sub_station.user_id.present?

      # Station Workflow Dropdown
      QueueManagementJobs::StationJob.perform_later(sub_station.station_id.to_s)
    end
  end

  def set_stations
    stations = QueueManagement::Station.where(area_id: params[:area_id])

    render json: stations.to_json
  end

  def set_sub_stations
    if params[:station_id].present?
      link_user_sub_stations
    else
      @sub_stations = QueueManagement::SubStation.includes(:station, :area).where(facility_id: params[:facility_id])
                                                 .order(area_id: :asc, station_id: :asc).to_a

      @users = User.where(facility_ids: params[:facility_id], is_active: true).to_a
      @facility_setting = FacilitySetting.find_by(facility_id: params[:facility_id])
    end
  end

  private

  def dropdown_sub_station(sub_station_id, user_id, task)
    QueueManagementJobs::SubStationJob.perform_later(sub_station_id.to_s, user_id.to_s, task)
  end

  def validate_setting_enabled
    @user_set_station_enabled = current_facility_setting&.queue_management && current_facility_setting&.user_set_station

    return unless @user_set_station_enabled
  end

  def validate_active_appointments
    opd_clinical_workflows = OpdClinicalWorkflow.where(
      appointmentdate: Date.current, user_id: current_user.id, :state.in => ['call', current_user.primary_role],
      facility_id: current_facility.id
    )
    @opd_clinical_workflows_empty = opd_clinical_workflows.empty?
    return if @opd_clinical_workflows_empty
  end

  def link_user_sub_stations
    sub_stations = QueueManagement::SubStation.includes(:active_user).where(station_id: params[:station_id])
    active_user_ids = sub_stations.pluck(:active_user_id).uniq.compact
    opd_clinical_workflows = OpdClinicalWorkflow.where(appointmentdate: Date.current, facility_id: current_facility.id,
                                                       :user_id.in => active_user_ids)
    user_state_array = opd_clinical_workflows.pluck(:user_id, :state).uniq

    occupied = []
    unoccupied = []
    sub_stations.each do |sub_station|
      set = [sub_station.id, sub_station.display_code, sub_station.active_user&.fullname]
      occupied_station?(sub_station, user_state_array) ? occupied << set : unoccupied << set
    end

    render json: { unoccupied: unoccupied, occupied: occupied }.to_json
  end

  def occupied_station?(sub_station, user_state_array)
    # 1. Permanent Sub-Station of other user (Never Available)
    # 2. Active Sub-Station of current user (Already Selected)
    # 3. Engaged Apppointment(s) in other users Sub-Station (Cant Snatch)
    [current_user.id, nil].exclude?(sub_station.user_id) ||
      sub_station.active_user_id == current_user.id ||
      (sub_station.active_user_id && engaged_appointments?(sub_station.active_user, user_state_array))
  end

  def engaged_appointments?(active_user, user_state_array)
    engaged_states = ['call', active_user&.primary_role, 'engaged']
    user_state_array.find { |ws| ws[0] == active_user&.id.to_s && engaged_states.include?(ws[1]) }
  end

  def update_existing_station
    @existing_sub_station.update_attributes!(active_user_id: nil)

    # Update Dropdown for previous SubStation
    dropdown_sub_station(@existing_sub_station.id.to_s, current_user.id.to_s, 'remove')

    # Update Station Dropdown with Old SubStation Info
    QueueManagementJobs::StationJob.perform_later(@existing_sub_station.station_id.to_s)
  end
end
