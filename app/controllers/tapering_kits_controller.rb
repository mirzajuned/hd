class TaperingKitsController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def new
    @user = current_user.id
    @tapering = TaperingKit.new()
    @med_id = params[:med_id]
    @medicinename = params[:medicinename]
    @medicineduration = params[:medicineduration]
    @medicinedurationoption = params[:medicinedurationoption]
    if params[:medicinefrequency] != "" || params[:medicinefrequency] != "SOS"
      @medicinefrequency = (params[:medicinefrequency]).to_i
    else
      @medicinefrequency = 0
    end
    @source = params[:source]

    respond_to do |format|
      format.js {}
    end
  end

  def index
    @tapering_sets = TaperingKit.where(user_id: current_user.id)
    respond_to do |format|
      format.js {}
    end
  end

  def create
    # params[:tapering_kit][:tapering_set] = params[:tapering_kit][:tapering_set].to_json
    @tapering = TaperingKit.new(tapering_kit_params)
    @med_id = params[:med_id]
    if @tapering.save
      respond_to do |format|
        format.js { render 'tapering_kits/close', layout: false }
      end
    end
  end

  def edit
    @user = current_user.id
    @tapering = TaperingKit.find(params[:id])
    @med_id = params[:med_id]
    @medicinename = params[:medicinename]
    @medicineduration = params[:medicineduration]
    @medicinedurationoption = params[:medicinedurationoption]
    if params[:medicinefrequency] != "" || params[:medicinefrequency] != "SOS"
      @medicinefrequency = (params[:medicinefrequency]).to_i
    else
      @medicinefrequency = 0
    end
    @source = params[:source]

    @tapering_set = @tapering.tapering_set
    # @tapering_set = JSON.parse(@tapering_set)

    respond_to do |format|
      format.js {}
    end
  end

  def update
    # params[:tapering_kit][:id] = params[:tapering_kit][:id]
    @tapering = TaperingKit.find(params[:id])
    @med_id = params[:med_id]
    if @tapering.update_attributes(tapering_kit_update_params)
      respond_to do |format|
        format.js { render 'tapering_kits/close', layout: false }
      end
    end
  end

  def add_tapering_field
    @counter = params[:ajax][:counter]
    @durationtype = params[:ajax][:durationtype]
    @last_row_date = params[:ajax][:last_row_date]
    respond_to do |format|
      format.js { render 'opd_records/add_tapering_kit_row', layout: false }
    end
  end

  def destroy
  end

  private

  def tapering_kit_params
    params.require(:tapering_kit).permit(:taperingtype, :taper_by, :medicine_name, :keyword, :user_id, :facility_id, tapering_set_attributes: [:number_of_days, :start_date, :end_date, :start_time, :end_time, :frequency, :dosage, :interval])
  end

  def tapering_kit_update_params
    params.require(:tapering_kit).permit(:taperingtype, :taper_by, :medicine_name, :keyword, :user_id, :facility_id, tapering_set_attributes: [:id, :number_of_days, :start_date, :end_date, :start_time, :end_time, :frequency, :dosage, :interval, :_destroy])
  end
end
