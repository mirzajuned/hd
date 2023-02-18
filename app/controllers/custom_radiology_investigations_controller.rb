class CustomRadiologyInvestigationsController < ApplicationController
  before_action :authorize
  before_action :authorize_onboard
  before_action :find_investigation, only: [:edit, :update, :destroy, :enable_radiology_investigation]

  def index
    @disabled_radiology_investigations = CustomRadiologyInvestigation.where(organisation_id: current_user.organisation_id, is_deleted: true)

    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def new
    @available_specialties = Specialty.where(:id.in => current_organisation["specialty_ids"])
    @custom_radiology_investigation = CustomRadiologyInvestigation.new
    @org_id = current_user.organisation_id

    respond_to do |format|
      format.js {}
    end
  end

  def create
    params[:custom_radiology_investigation][:investigation_id] = CommonHelper::get_custom_radiology_investigation_identifier(current_user)
    @custom_radiology_investigation = CustomRadiologyInvestigation.new(custom_radiology_params(params))
    @custom_radiology_investigation.save

    respond_to do |format|
      format.js {}
    end
  end

  def edit
    @available_specialties = Specialty.where(:id.in => current_organisation["specialty_ids"])

    respond_to do |format|
      format.js {}
    end
  end

  def update
    @custom_radio_inv = @investigation.update(custom_radiology_params(params))

    respond_to do |format|
      format.js {}
    end
  end

  def destroy
    @investigation.update(is_deleted: true)

    respond_to do |format|
      format.js {}
    end
  end

  def inv_name_validation
    new_name = params[:custom_radiology_investigation][:investigation_name]
    saved_name = params[:saved_inv_name]
    if saved_name != new_name
      investigation_found = CustomRadiologyInvestigation.find_by(investigation_name: new_name)
    end

    respond_to do |format|
      format.json { render :json => !investigation_found.present? }
    end
  end

  def investigations_data
    @total_investigations_count = CustomRadiologyInvestigation.where(:investigation_name => /#{Regexp.escape(params[:sSearch])}/i, organisation_id: current_user.organisation_id, is_deleted: false).count
    @custom_investigations = CustomRadiologyInvestigation.where(:investigation_name => /#{Regexp.escape(params[:sSearch])}/i, organisation_id: current_user.organisation_id, is_deleted: false)
                                                         .limit(params[:iDisplayLength])
                                                         .offset(params[:iDisplayStart])
                                                         .order(created_at: :desc)

    @total_records_count = CustomRadiologyInvestigation.where(organisation_id: current_user.organisation_id, is_deleted: false).count
    @sEcho = params[:sEcho]

    respond_to do |format|
      format.json {}
    end
  end

  def enable_radiology_investigation
    @investigation.update(is_deleted: false)
  end

  private

  def find_investigation
    @investigation = CustomRadiologyInvestigation.find_by(id: params[:id])
  end

  def custom_radiology_params(params)
    params.require(:custom_radiology_investigation).permit(:investigation_name, :organisation_id, :facility_id, :specialty_id, :investigation_id)
  end
end
