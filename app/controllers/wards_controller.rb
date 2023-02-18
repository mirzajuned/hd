class WardsController < ApplicationController
  before_action :authorize
  before_action :set_ward, only: [:edit, :update, :destroy]
  before_action :set_room_types, only: [:index, :new, :edit]

  def index
    @wards = Ward.includes(:rooms).where(facility_id: current_facility.id)
  end

  def new
    @ward = Ward.new
  end

  def create
    ward = Ward.new(ward_params)
    ward.save!
  end

  def edit; end

  def update
    @ward.update(ward_params)
  end

  def destroy
    @ward&.update_attributes(is_deleted: true)
    rooms = @ward&.rooms
    rooms&.update_all(is_deleted: true)
    rooms&.map { |room| room.beds.update_all(is_deleted: true) }
  end

  private

  def ward_params
    params.require(:ward).permit(
      :name, :code, :total_rooms, :organisation_id, :facility_id,
      rooms_attributes: [
        :id, :is_deleted, :name, :type, :code, :total_beds, :organisation_id, :facility_id,
        beds_attributes: [
          :id, :is_deleted, :name, :code, :price, :group_id, :organisation_id, :facility_id
        ]
      ]
    )
  end

  def set_ward
    @ward = Ward.find_by(id: params[:id])
  end

  def set_room_types
    @room_types = Global.room_master.types
  end
end
