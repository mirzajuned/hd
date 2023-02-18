class QueueManagement::ScreensController < ApplicationController
  before_action :authorize

  def index
    @facilities = current_user.facilities.pluck(:name, :id)

    @facility_setting = FacilitySetting.find_by(facility_id: params[:facility_id])
    @screens = QueueManagement::Screen.where(facility_id: params[:facility_id]).to_a
  end

  def new
    @facilities = current_user.facilities.pluck(:name, :id)
  end

  def create
    params[:screens]&.each do |_k, screen|
      @screen_params = true
      @screen = QueueManagement::Screen.new(screen_params(screen))
      @screen.save
    end
  end

  def edit
    @screen = QueueManagement::Screen.find_by(id: params[:id])

    @facility = Facility.find_by(id: @screen.facility_id)
  end

  def update
    @screen = QueueManagement::Screen.find_by(id: params[:id])

    @screen.update_attributes!(screen_params(params[:queue_management_screen]))
  rescue StandardError
    @facility = Facility.find_by(id: @screen.facility_id)

    render 'edit'
  end

  private

  def screen_params(screen)
    screen.permit(:name, :username, :passcode, :expiry_date, :user_id, :facility_id, :organisation_id)
  end
end
