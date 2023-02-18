class OtnoteController < ApplicationController
  before_action :set_otnote, only: [:show, :edit, :update, :destroy]

  # def index
  #   @notes = OtNote.all
  # end

  # GET /beds/1
  # GET /beds/1.json
  # def show
  # end

  # GET /beds/new
  def new
    @note = OtNote.new
  end

  # GET /beds/1/edit
  # def edit
  # end

  # POST /beds
  # POST /beds.json
  def create
    @note = OtNote.new(note_params)

    respond_to do |format|
      if @note.save
        format.js { render "ipd_patients/otnotesave", :layout => false }
        format.json { redirect_to ipd_patients_home_path, status: :created, location: @note }
      else
        format.html { render action: 'new' }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /beds/1
  # PATCH/PUT /beds/1.json
  def update
    respond_to do |format|
      if @note.update(note_params)
        format.js { render "ipd_patients/otnotesave", :layout => false }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /beds/1
  # DELETE /beds/1.json
  # def destroy
  #   @note.destroy
  #   respond_to do |format|
  #     format.html { redirect_to home }
  #     format.json { head :no_content }
  #   end
  # end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_otnote
    @note = OtNote.find(params[:_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def note_params
    params.require(:ot_note).permit!
  end
end
