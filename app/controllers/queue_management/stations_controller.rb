class QueueManagement::StationsController < ApplicationController
  before_action :authorize
  before_action :find_facility_setting, only: [:index, :set_stations]

  def index
    @facilities = current_user.facilities.pluck(:name, :id)
    @area_stations = QueueManagement::Station.includes(:area, :sub_stations).where(facility_id: params[:facility_id])
                                             .group_by(&:area)
  end

  def new
    @facilities = current_user.facilities.pluck(:name, :id)

    @areas = QueueManagement::Area.where(facility_id: params[:facility_id])
    @station_types = ['room', 'area']
  end

  def create
    params[:stations]&.each do |_k, station|
      next if station[:sub_stations_attributes].nil?

      @station_params = true
      if station[:id].nil?
        @station = QueueManagement::Station.new(station_params(station))
        @station.save!
      else
        @station = QueueManagement::Station.find_by(id: station[:id])
        @station.update_attributes(station_params(station))
      end

      # Station Workflow Dropdown
      QueueManagementJobs::StationJob.perform_later(@station.id.to_s)

      # Sub Station Workflow Dropdown
      dropdown_sub_stations(@station.sub_stations.where(:user_id.ne => nil))
    end
  end

  def set_areas
    areas = QueueManagement::Area.where(facility_id: params[:facility_id])

    render json: { areas: areas.pluck(:name, :id) }
  end

  def set_users
    @users = User.where(facility_ids: params[:facility_id], department_ids: '485396012', is_active: true)

    render json: { users: @users.pluck(:fullname, :id) }
  end

  def set_stations
    @stations = QueueManagement::Station.includes(:sub_stations).where(area_id: params[:area_id]).to_a
    @station_types = ['room', 'area']
  end

  private

  def station_params(station)
    station.permit(:name, :type, :display_code, :area_id, :user_id, :facility_id, :organisation_id, :is_deleted,
                   sub_stations_attributes: [:id, :display_code, :created_by_id, :facility_id, :organisation_id,
                                             :area_id, :is_deleted])
  end

  def dropdown_sub_stations(sub_stations)
    sub_stations.each do |sub_station|
      QueueManagementJobs::SubStationJob.perform_later(sub_station.id.to_s, sub_station.user_id.to_s, 'update')
    end
  end

  def find_facility_setting
    @facility_setting = FacilitySetting.find_by(facility_id: params[:facility_id])
  end
end
