class QueueManagement::AreasController < ApplicationController
  before_action :authorize
  before_action :set_area, only: [:update, :destroy]

  def index
    @facilities = current_user.facilities.pluck(:name, :id)
  end

  def view
    @areas = QueueManagement::Area.includes(:stations).where(facility_id: params[:facility_id])
  end

  def create
    @area = QueueManagement::Area.new(area_params)
    @area.save!
  end

  def update
    @area.update_attributes(area_params)

    head :ok
  end

  def destroy
    @area.destroy
  end

  private

  def area_params
    params.require(:area).permit(:organisation_id, :facility_id, :user_id, :name)
  end

  def set_area
    @area = QueueManagement::Area.find_by(id: params[:id])
  end
end
