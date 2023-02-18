class RoomTypesController < ApplicationController
  # before_action :set_room_type, only: [:show, :edit, :update, :destroy]
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  # GET /roomtypes
  # GET /roomtypes.json
  def index
    @roomtypes = RoomType.all
  end

  # POST /roomtypes
  # POST /roomtypes.json
  def create
    @room_type_name_counter = params[:room_type][:room_type_name_counter]
    @ward_room_type_id = params[:room_type][:ward_room_type_id]
    @room_type = RoomType.new(new_room_type_params)
    respond_to do |format|
      if @room_type.save
        format.js { render "room_types/js/create" }
      else
        format.html { render action: 'new' }
        format.json { render json: @room_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /roomtypes/1
  # GET /roomtypes/1.json
  def show
  end

  # GET /roomtypes/new
  def new
    respond_to do |format|
      format.js {}
    end
  end

  # GET /roomtypes/1/edit
  def edit
  end

  # PATCH/PUT /roomtypes/1
  # PATCH/PUT /roomtypes/1.json
  def update
    respond_to do |format|
      if @bed.update(bed_params)
        format.html { redirect_to @bed, notice: 'Bed was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @bed.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /roomtypes/1
  # DELETE /roomtypes/1.json
  def destroy
    @bed.destroy
    respond_to do |format|
      format.html { redirect_to roomtypes_url }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_bed
    @bed = Bed.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def new_room_type_params
    params.require(:room_type).permit(:name, :code, :facility_id, :organisation_id)
  end
end
