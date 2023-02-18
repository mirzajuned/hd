class BedTypesController < ApplicationController
  # before_action :set_bed_type, only: [:show, :edit, :update, :destroy]
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  # GET /bedtypes
  # GET /bedtypes.json
  def index
    @bedtypes = BedType.all
  end

  # POST /bedtypes
  # POST /bedtypes.json
  def create
    @room_type_name_counter = params[:bed_type][:room_type_name_counter]
    @bed_type_name_counter = params[:bed_type][:bed_type_name_counter]
    @ward_room_bed_type_id = params[:bed_type][:ward_room_bed_type_id]
    @bed_type = BedType.new(new_bed_type_params)
    respond_to do |format|
      if @bed_type.save
        format.js { render "bed_types/js/create" }
      else
        format.html { render action: 'new' }
        format.json { render json: @bed_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /bedtypes/1
  # GET /bedtypes/1.json
  def show
  end

  # GET /bedtypes/new
  def new
    respond_to do |format|
      format.js {}
    end
  end

  # GET /bedtypes/1/edit
  def edit
  end

  # PATCH/PUT /bedtypes/1
  # PATCH/PUT /bedtypes/1.json
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

  # DELETE /bedtypes/1
  # DELETE /bedtypes/1.json
  def destroy
    @bed.destroy
    respond_to do |format|
      format.html { redirect_to bedtypes_url }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_bed
    @bed = Bed.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def new_bed_type_params
    params.require(:bed_type).permit(:name, :code, :facility_id, :organisation_id)
  end
end
