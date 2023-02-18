class OphthalLaboratorySetsController < ApplicationController
  before_action :ophthal_laboratory_set, only: [:edit, :update, :destroy]

  def index
  end

  def new
    organisations_setting = OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id))
    @disable_default_investigation =  organisations_setting.try(:disable_default_investigation)
    @ophthal_laboratory_set = OphthalLaboratorySet.new
    @path = "New"
    respond_to do |format|
      format.js {}
    end
  end

  def create
    # if params[:ophthal_laboratory_set][:data].nil?
    #   params[:ophthal_laboratory_set] = {treatmentmedication_attributes: {}}
    # end
    if params[:ophthal_laboratory_set][:data].nil?
      params[:ophthal_laboratory_set][:data] = {}.to_json
    else
      params[:ophthal_laboratory_set][:data] = params[:ophthal_laboratory_set][:data].to_json
    end

    @ophthal_laboratory_set = OphthalLaboratorySet.new(ophthal_set_params)
    if @ophthal_laboratory_set.save
      respond_to do |format|
        format.js { render "close" }
      end
    else
      @path = "New"
      respond_to do |format|
        format.js { render :new }
        format.json { render json: @ophthal_laboratory_set.errors }
      end
    end
  end

  def edit
    organisations_setting = OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id))
    @disable_default_investigation =  organisations_setting.try(:disable_default_investigation)
    @path = "Edit"
    respond_to do |format|
      format.js {}
    end
  end

  def update
    if params[:ophthal_laboratory_set][:data].nil?
      params[:ophthal_laboratory_set][:data] = {}.to_json
    else
      params[:ophthal_laboratory_set][:data] = params[:ophthal_laboratory_set][:data].to_json
    end

    if @ophthal_laboratory_set.update_attributes(ophthal_set_params)
      respond_to do |format|
        format.js { render "close" }
      end
    else
      @path = "Edit"
      respond_to do |format|
        format.js { render :edit }
        format.json { render json: @ophthal_laboratory_set.errors }
      end
    end
  end

  def destroy
    @ophthal_laboratory_set.update_attributes(is_active: false)
    respond_to do |format|
      format.js { render "close" }
    end
  end

  def data
    if current_user.has_role?(:doctor)
      @ophthal_laboratory_set = OphthalLaboratorySet.where(doctor_id: current_user.id.to_s, is_active: true)
    else
      @ophthal_laboratory_set = OphthalLaboratorySet.where(facility_id: current_facility.id.to_s, doctor_id: nil, is_active: true)
    end

    @ophthal_sets_count = @ophthal_laboratory_set.where(:name => %r[#{params[:sSearch]}]).count
    @ophthal_sets = @ophthal_laboratory_set.where(:name => %r[#{params[:sSearch]}])
                                           .limit(params[:iDisplayLength])
                                           .offset(params[:iDisplayStart])
                                           .order(created_at: :desc)
    @total_ophthal_set_count = @ophthal_laboratory_set.count
    @sEcho = params[:sEcho]

    respond_to do |format|
      format.json {}
    end
  end

  private

  def ophthal_set_params
    params.require(:ophthal_laboratory_set).permit(:name, :data, :doctor_id, :user_id, :facility_id, :organisation_id)
  end

  def ophthal_laboratory_set
    @ophthal_laboratory_set = OphthalLaboratorySet.find(params[:id])
  end
end
