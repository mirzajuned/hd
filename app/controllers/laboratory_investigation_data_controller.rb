class LaboratoryInvestigationDataController < ApplicationController
  before_action :authorize
  before_action :authorize_onboard
  before_action :find_investigation, only: [:edit, :update, :destroy, :enable_laboratory_investigation]

  def index
    @disabled_laboratory_investigations = LaboratoryInvestigationData.where(facility_id: current_facility.id, is_deleted: true)

    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def new
    laboratory_array('new')
    @available_specialties = Specialty.where(:id.in => current_organisation["specialty_ids"])
    @laboratory_investigation_data = LaboratoryInvestigationData.new

    respond_to do |format|
      format.js {}
    end
  end

  def create
    @custom_laboratory_inv = LaboratoryInvestigationsData::CreateLaboratoryInvService.call(params[:laboratory_investigation_data], current_user)

    respond_to do |format|
      format.js {}
    end
  end

  def edit
    laboratory_array('edit')
    @available_specialties = Specialty.where(:id.in => current_organisation["specialty_ids"])

    respond_to do |format|
      format.js {}
    end
  end

  def update
    @custom_laboratory_inv = LaboratoryInvestigationsData::UpdateLaboratoryInvService.call(params[:id], params[:laboratory_investigation_data], current_user)

    respond_to do |format|
      format.js {}
    end
  end

  def destroy
    facilities = Facility.where(organisation_id: current_organisation["_id"]).pluck(:id)
    @laboratory_investigations = LaboratoryInvestigationData.where(:facility_id.in => facilities, loinc_code: @investigation.loinc_code)
    @laboratory_investigations.each do |investigation|
      investigation.update(is_deleted: true)
    end

    respond_to do |format|
      format.js {}
    end
  end

  def inv_name_validation
    new_name = params[:laboratory_investigation_data][:investigation_name]
    saved_name = params[:saved_inv_name]
    if saved_name != new_name
      investigation_found = LaboratoryInvestigationData.find_by(investigation_name: new_name, is_deleted: false, facility_id: current_facility.id)
    end

    respond_to do |format|
      format.json { render :json => !investigation_found.present? }
    end
  end

  def investigations_data
    all_investigations = LaboratoryInvestigationData.where(facility_id: current_facility.id, is_deleted: false)
    @total_investigations_count = all_investigations.where(:investigation_name => /#{params[:sSearch]}/i).count
    @custom_investigations = all_investigations.where(:investigation_name => /#{params[:sSearch]}/i).limit(params[:iDisplayLength]).offset(params[:iDisplayStart]).order(created_at: :desc)
    @total_records_count = all_investigations.count
    @sEcho = params[:sEcho]

    respond_to do |format|
      format.json {}
    end
  end

  def enable_laboratory_investigation
    facilities = Facility.where(organisation_id: current_organisation["_id"])
    investigations_array = []
    facilities.each do |facility|
      @laboratory_investigation = LaboratoryInvestigationData.find_by(facility_id: facility.id, loinc_code: @investigation.loinc_code)
      if @laboratory_investigation.present?
        investigations_array << @laboratory_investigation
      end
    end

    investigations_array.each do |investigation|
      investigation.update(is_deleted: false)
    end
  end

  def search
    # specality_id: params[:specality_id],
    @investigations_array = []

    if OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id)).try(:disable_default_investigation)

      @laboratory_investigations = LaboratoryInvestigationData.where(facility_id: current_facility.id, investigation_name: /#{Regexp.escape(params[:search])}/i, is_custom: true, is_deleted: false).limit(50)

    else
      @laboratory_investigations = LaboratoryInvestigationData.where(facility_id: current_facility.id, investigation_name: /#{Regexp.escape(params[:search])}/i, is_deleted: false).limit(50)
    end
    @laboratory_investigations.each do |investigation|
      investigation_struc = Struct.new(:id, :name, :investigation_id, :investigation_type, :investigation_type_label, :loinc_code).new
      investigation_struc.id = investigation._id
      investigation_struc.loinc_code = investigation.loinc_code
      investigation_struc.name = investigation.investigation_name
      investigation_struc.investigation_id = investigation.investigation_id
      investigation_struc.investigation_type = "LaboratoryInvestigationData"
      investigation_struc.investigation_type_label = ("CC" if investigation.is_custom) || "C"
      @investigations_array << investigation_struc
    end
  end

  private

  def find_investigation
    @investigation = LaboratoryInvestigationData.find_by(id: params[:id])
  end

  def laboratory_array(flag)
    if flag == 'new'
      all_investigations = LaboratoryInvestigationData.where(facility_id: current_facility.id, is_deleted: false)
    elsif flag == 'edit'
      all_investigations = LaboratoryInvestigationData.where(facility_id: current_facility.id, is_deleted: false).not_in(_id: @investigation.id)
    end

    @laboratory_investigations = all_investigations.sort_by! { |investigation| investigation.investigation_name.downcase }
  end
end
