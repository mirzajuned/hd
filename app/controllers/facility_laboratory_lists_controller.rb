class FacilityLaboratoryListsController < ApplicationController
  before_action :authorize
  before_action :set_init_params

  respond_to :js, :json, :html
  layout 'loggedin'

  def index
    @medication_kits = MedicationKit.where(user_id: @current_user.id)
    @medication_lists = MyPracticeMedicationList.where(user_id: @current_user.id, is_deleted: false)
    @facilitylaboratorylists = FacilityLaboratoryList.where(facility_id: @current_facility.id, is_deleted: false)

    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def new
    @facilitylaboratorylist = FacilityLaboratoryList.new
    # get_specialties
    @lab_investigations = LaboratoryInvestigationData.where(only_sub_test: false, facility_id: @current_facility.id, is_deleted: false)

    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def create
    params[:opdrecord] = { addedlaboratoryinvestigationlist_attributes: {} } if params[:opdrecord].nil?
    params[:facility_laboratory_list][:organisation_id] = @current_user.organisation_id.to_s
    params[:facility_laboratory_list][:data] = params[:opdrecord][:addedlaboratoryinvestigationlist_attributes].to_json
    @facilitylaboratorylist = FacilityLaboratoryList.new(laboratory_list_params)
    respond_to do |format|
      if @facilitylaboratorylist.save
        @facilitylaboratorylists = FacilityLaboratoryList.where(facility_id: @current_facility.id, is_deleted: false)
        format.js { render 'create', layout: false }
      else
        format.html { render :new }
      end
    end
  end

  def edit
    @facilitylaboratorylist = FacilityLaboratoryList.find_by(id: params[:id])
    @facilitylaboratorylist_details = @facilitylaboratorylist[:data]
    @facilitylaboratorylist_details = JSON.parse(@facilitylaboratorylist_details)
    # get_specialties

    @lab_investigations = LaboratoryInvestigationData.where(only_sub_test: false, facility_id: @current_facility.id, is_deleted: false)

    respond_to do |format|
      format.js {}
      format.html {}
    end
  end

  def update
    params[:opdrecord] = { addedlaboratoryinvestigationlist_attributes: {} } if params[:opdrecord].nil?
    params[:facility_laboratory_list][:data] = params[:opdrecord][:addedlaboratoryinvestigationlist_attributes].to_json
    # params[:medication_kit][:kit_details].to_json
    @facilitylaboratorylist = FacilityLaboratoryList.find(params[:facility_laboratory_list][:id])
    # @facilitylaboratorylist.update(laboratory_kit_update_params)
    # @facilitylaboratorylists = FacilityLaboratoryList.where(:user_id => @current_user.id)
    respond_to do |format|
      if @facilitylaboratorylist.update(laboratory_kit_update_params)
        @facilitylaboratorylists = FacilityLaboratoryList.where(facility_id: @current_facility.id, is_deleted: false)
        format.js {}
      end
    end
  end

  def destroy
    @facilitylaboratorylist = FacilityLaboratoryList.find(params[:id])
    @facilitylaboratorylist.update(is_deleted: true)

    respond_to do |format|
      format.js {}
    end
  end

  def get_specialty_investigations
    lab_investigations = LaboratoryInvestigationData.where(only_sub_test: false, facility_id: @current_facility.id, specialty_id: params[:specialty_id], is_deleted: false)

    render json: {
      standard_invest: lab_investigations.where(is_custom: false).pluck(:investigation_name, :loinc_code),
      custom_invest: lab_investigations.where(is_custom: true).pluck(:investigation_name, :loinc_code)
    }
  end

  private

  def laboratory_kit_update_params
    params.require(:facility_laboratory_list).permit(:id, :user_id, :facility_id, :specialty_id, :organisation_id, :doctor, :name, :set_type, :data)
  end

  def laboratory_list_params
    params.require(:facility_laboratory_list).permit(:user_id, :facility_id, :specialty_id, :organisation_id, :doctor, :name, :set_type, :data)
  end

  def set_init_params
    @current_user = current_user
    @current_facility = current_facility
  end

  def get_specialties
    @available_specialties = Specialty.where(:id.in => current_user.specialty_ids)
    @selected_specialty =  @facilitylaboratorylist.specialty_id || @available_specialties.first.id.to_s
  end
end
