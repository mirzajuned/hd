class CustomOphthalInvestigationsController < ApplicationController
  before_action :find_investigation, only: [:edit, :update, :destroy, :enable_ophthal_investigation]

  def index
    @disabled_ophthals = CustomOphthalInvestigation.where(organisation_id: current_user.organisation_id, is_deleted: true)

    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def new
    @custom_ophthal_investigation = CustomOphthalInvestigation.new

    respond_to do |format|
      format.js {}
    end
  end

  def create
    params[:custom_ophthal_investigation][:investigation_id] = CommonHelper::get_custom_ophthal_investigation_identifier(current_user)
    params[:custom_ophthal_investigation][:has_laterality] = true
    @custom_oph_inv = CustomOphthalInvestigation.new(custom_oph_params(params))
    @custom_oph_inv.laterality = [{ side_name: 'Bilateral', side_id: '40638003' }, { side_name: 'Right', side_id: '18944008' }, { side_name: 'Left', side_id: '8966001' }]
    @custom_oph_inv.save
    respond_to do |format|
      format.js {}
    end
  end

  def edit
    respond_to do |format|
      format.js {}
    end
  end

  def update
    @custom_ophthal_inv = @investigation.update(custom_oph_params(params))

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
    new_name = params[:custom_ophthal_investigation][:investigation_name]
    saved_name = params[:saved_inv_name]

    if saved_name != new_name
      investigation_found = CustomOphthalInvestigation.find_by(investigation_name: new_name, is_deleted: false)
    end

    respond_to do |format|
      format.json { render :json => !investigation_found.present? }
    end
  end

  def investigations_data
    @total_investigations_count = CustomOphthalInvestigation.where(:investigation_name => /#{Regexp.escape(params[:sSearch])}/i, organisation_id: current_user.organisation_id, is_deleted: false).count
    @custom_investigations = CustomOphthalInvestigation.where(:investigation_name => /#{Regexp.escape(params[:sSearch])}/i, organisation_id: current_user.organisation_id, is_deleted: false)
                                                       .limit(params[:iDisplayLength])
                                                       .offset(params[:iDisplayStart])
                                                       .order(created_at: :desc)

    @total_records_count = CustomOphthalInvestigation.where(organisation_id: current_user.organisation_id, is_deleted: false).count
    @sEcho = params[:sEcho]

    respond_to do |format|
      format.json {}
    end
  end

  def enable_ophthal_investigation
    @investigation.update(is_deleted: false)
  end

  private

  def find_investigation
    @investigation = CustomOphthalInvestigation.find_by(id: params[:id])
  end

  def custom_oph_params(params)
    params.require(:custom_ophthal_investigation).permit(:investigation_name, :organisation_id, :specialty_id, :investigation_id, :facility_id, :has_laterality, :laterality => [], :region => [])
  end
end
