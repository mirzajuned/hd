class OtRoomsController < ApplicationController
  before_action :authorize
  before_action :set_ot_room, only: [:edit, :update, :destroy]
  before_action :set_facilities, only: [:index, :new, :edit, :facility_dropdown]
  before_action :set_specialties, only: [:index, :facility_dropdown]

  def index
    @ot_rooms = OtRoom.where(facility_id: current_facility.id, is_deleted: false)
  end

  def facility_dropdown
    @facility_filter = OtRoom.where(facility_id: params[:facility_dropdown_id], is_deleted: false)
    @ot_rooms = OtRoom.where(facility_id: params[:facility_dropdown_id], is_deleted: false)
  end

  def new
    @ot_room = OtRoom.new
  end

  def create
    params[:ot_rooms].each do |_k, ot_room|
      ot = OtRoom.new(ot_params(ot_room))
      ot.save!
    end
  end

  def edit
    facility = Facility.find_by(id: @ot_room.facility_id)
    @specialties = Specialty.where(:id.in => facility.specialty_ids).pluck(:name, :id)
  end

  def update
    @ot_room.update(ot_params(params[:ot_room]))
  end

  def destroy
    @ot_room.update_attributes(is_deleted: true)
  end

  def search_specialty
    facility = Facility.find_by(id: params[:facility_id])
    specialties = Specialty.where(:id.in => facility.specialty_ids).pluck(:name, :id)
    render json: specialties.to_json
  end

  private

  def ot_params(ot_room)
    ot_room.permit(:name, :specialty_id, :capacity, :organisation_id, :facility_id)
  end

  def set_ot_room
    @ot_room = OtRoom.find_by(id: params[:id])
  end

  def set_facilities
    @current_user = current_user
    @facilities = @current_user.facilities.pluck(:name, :id)
    # @facilities = Facility.where(organisation_id: current_organisation['_id'])
  end

  def set_specialties
    @specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])
    @specialties_hash = @specialties.map { |specialty| { id: specialty.id.to_s, name: specialty.name } }
  end
end
