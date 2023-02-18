class RadiologyLaboratorySetsController < ApplicationController
  before_action :radiology_laboratory_set, only: [:edit, :update, :destroy]
  before_action :radiology_investigations, only: [:new, :create, :edit, :update]

  def index
  end

  def new
    organisations_setting = OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id))
    @disable_default_investigation =  organisations_setting.try(:disable_default_investigation)
    @radiology_laboratory_set = RadiologyLaboratorySet.new
    @path = "New"
    respond_to do |format|
      format.js {}
    end
  end

  def create
    # if params[:radiology_laboratory_set][:data].nil?
    #   params[:radiology_laboratory_set] = {treatmentmedication_attributes: {}}
    # end
    if params[:radiology_laboratory_set][:data].nil?
      params[:radiology_laboratory_set][:data] = {}.to_json
    else
      params[:radiology_laboratory_set][:data] = params[:radiology_laboratory_set][:data].to_json
    end

    @radiology_laboratory_set = RadiologyLaboratorySet.new(radiology_set_params)
    if @radiology_laboratory_set.save
      respond_to do |format|
        format.js { render "close" }
      end
    else
      @path = "New"
      respond_to do |format|
        format.js { render :new }
        format.json { render json: @radiology_laboratory_set.errors }
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
    if params[:radiology_laboratory_set][:data].nil?
      params[:radiology_laboratory_set][:data] = {}.to_json
    else
      params[:radiology_laboratory_set][:data] = params[:radiology_laboratory_set][:data].to_json
    end

    if @radiology_laboratory_set.update_attributes(radiology_set_params)
      respond_to do |format|
        format.js { render "close" }
      end
    else
      @path = "Edit"
      respond_to do |format|
        format.js { render :edit }
        format.json { render json: @radiology_laboratory_set.errors }
      end
    end
  end

  def destroy
    @radiology_laboratory_set.update_attributes(is_active: false)
    respond_to do |format|
      format.js { render "close" }
    end
  end

  def data
    if current_user.role_ids.include?(158965000)
      @radiology_laboratory_set = RadiologyLaboratorySet.where(doctor_id: current_user.id.to_s, :specialty_id.in => current_user.specialty_ids, is_active: true)
    else
      @radiology_laboratory_set = RadiologyLaboratorySet.where(facility_id: current_facility.id.to_s, doctor_id: nil, :specialty_id.in => current_user.specialty_ids, is_active: true)
    end

    @radiology_sets_count = @radiology_laboratory_set.where(:name => %r[#{params[:sSearch]}]).count
    @radiology_sets = @radiology_laboratory_set.where(:name => %r[#{params[:sSearch]}])
                                               .limit(params[:iDisplayLength])
                                               .offset(params[:iDisplayStart])
                                               .order(created_at: :desc)
    @total_radiology_set_count = @radiology_laboratory_set.count
    @sEcho = params[:sEcho]

    respond_to do |format|
      format.json {}
    end
  end

  def get_specialty_investigations
    radiology_investigations

    render json: { custom_invest: @custom_radiology_investigations.pluck(:investigation_name, :investigation_id),
                   x_ray_invest: @radiology_investigation_xray.pluck(:investigation_type, :investigation_name, :investigation_id),
                   mri_invest: @radiology_investigation_mri.pluck(:investigation_type, :investigation_name, :investigation_id) }
  end

  private

  def radiology_set_params
    params.require(:radiology_laboratory_set).permit(:name, :data, :doctor_id, :user_id, :specialty_id, :facility_id, :organisation_id)
  end

  def radiology_laboratory_set
    @radiology_laboratory_set = RadiologyLaboratorySet.find_by(id: params[:id])
  end

  def radiology_investigations
    @available_specialties = Specialty.where(:id.in => current_user.specialty_ids)
    @selected_specialty =  params[:specialty_id] || @radiology_laboratory_set.try(:specialty_id) || @available_specialties.first.try(:id)
    selected_specialty = (@selected_specialty == "309988001") ? "309988001" : "309989009" # Remove once Investigation has own Speciality
    @radiology_investigations = RadiologyInvestigationData.where(specialty_id: selected_specialty.to_i)
    @custom_radiology_investigations = CustomRadiologyInvestigation.where(organisation_id: current_user.organisation_id, specialty_id: @selected_specialty.to_i, is_deleted: false)
    @radiology_investigation_xray = @radiology_investigations.where(investigation_type_id: 363680008)
    @radiology_investigation_mri = @radiology_investigations.not.where(investigation_type_id: 363680008)
  end
end
