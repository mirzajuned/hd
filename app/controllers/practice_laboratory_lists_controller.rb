class PracticeLaboratoryListsController < ApplicationController
  before_action :authorize
  before_action :user_laboratory_lists

  respond_to :js, :json, :html
  layout 'loggedin'

  def index
    @medication_kits = MedicationKit.where(user_id: current_user.id)
    @medication_lists = MyPracticeMedicationList.where(user_id: current_user.id, is_deleted: false)
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def new
    @user = User.find_by(id: current_user.id)
    @userlaboratorylist = UsersLaboratoryList.new
    # get_specialties
    @lab_investigations = LaboratoryInvestigationData.where(only_sub_test: false, facility_id: current_facility.id, is_deleted: false)

    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def create
    params[:opdrecord] = { addedlaboratoryinvestigationlist_attributes: {} } if params[:opdrecord].nil?
    params[:users_laboratory_list][:organisation_id] = current_user.organisation_id.to_s
    params[:users_laboratory_list][:data] = params[:opdrecord][:addedlaboratoryinvestigationlist_attributes].to_json
    @userlaboratorylist = UsersLaboratoryList.new(laboratory_list_params)
    respond_to do |format|
      if @userlaboratorylist.save

        format.js { render 'create', layout: false }
      else
        format.html { render :new }
      end
    end
  end

  def edit
    @userlaboratorylist = UsersLaboratoryList.find(params[:id])
    @userlaboratorylist_details = @userlaboratorylist[:data]
    @userlaboratorylist_details = JSON.parse(@userlaboratorylist_details)
    @userid = current_user.id

    # get_specialties
    @lab_investigations = LaboratoryInvestigationData.where(only_sub_test: false, facility_id: current_facility.id, is_deleted: false)

    respond_to do |format|
      format.js {}
      format.html {}
    end
  end

  def update
    params[:opdrecord] = { addedlaboratoryinvestigationlist_attributes: {} } if params[:opdrecord].nil?
    params[:users_laboratory_list][:data] = params[:opdrecord][:addedlaboratoryinvestigationlist_attributes].to_json
    # params[:medication_kit][:kit_details].to_json
    @userlaboratorylist = UsersLaboratoryList.find(params[:users_laboratory_list][:id])
    # @userlaboratorylist.update(laboratory_kit_update_params)
    respond_to do |format|
      format.js {} if @userlaboratorylist.update(laboratory_kit_update_params)
    end
  end

  def destroy
    @facilitylaboratorylist = UsersLaboratoryList.find(params[:id])
    @facilitylaboratorylist.update(is_deleted: true)

    respond_to do |format|
      format.js {}
    end
  end

  def get_specialty_investigations
    lab_investigations = LaboratoryInvestigationData.where(only_sub_test: false, facility_id: current_facility.id, specialty_id: params[:specialty_id], is_deleted: false)

    render json: {
      standard_invest: lab_investigations.where(is_custom: false).pluck(:investigation_name, :loinc_code),
      custom_invest: lab_investigations.where(is_custom: true).pluck(:investigation_name, :loinc_code)
    }
  end

  private

  def user_laboratory_lists
    @userlaboratorylists = UsersLaboratoryList.where(user_id: current_user.id, is_deleted: false)
  end

  def laboratory_kit_update_params
    params.require(:users_laboratory_list).permit(:id, :user_id, :specialty_id, :organisation_id, :doctor, :name, :set_type, :data)
  end

  def laboratory_list_params
    params.require(:users_laboratory_list).permit(:user_id, :specialty_id, :organisation_id, :doctor, :name, :set_type, :data)
  end

  def get_specialties
    @available_specialties = Specialty.where(:id.in => current_user.specialty_ids)
    @selected_specialty =  @userlaboratorylist.specialty_id || @available_specialties.first.id.to_s
  end
end
