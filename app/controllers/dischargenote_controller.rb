class DischargenoteController < ApplicationController
  # *******************************************************************
  # create update is working
  # *******************************************************************

  before_action :set_dischargenote, only: [:show, :edit, :update, :destroy]

  def index
    @notes = DischargeNote.all
  end

  # GET /beds/1
  # GET /beds/1.json
  def show
  end

  # GET /beds/new
  def new
    @note = DischargeNote.new
  end

  # GET /beds/1/edit
  def edit
  end

  # POST /beds
  # POST /beds.json
  def create
    @note = DischargeNote.new(note_params)

    respond_to do |format|
      if @note.save
        format.js { render "ipd_patients/dischargenotesave", :layout => false }
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
        format.js { render "ipd_patients/dischargenotesave", :layout => false }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @note.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /beds/1
  # DELETE /beds/1.json
  def destroy
    @note.destroy
    respond_to do |format|
      format.html { redirect_to home }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_dischargenote
    @note = DischargeNote.find(params[:_id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def note_params
    params.require(:discharge_note).permit!
  end
end
