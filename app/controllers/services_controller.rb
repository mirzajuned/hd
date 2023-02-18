class ServicesController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def index
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def new
    @organisationid = current_user.organisation.id
    @service_type = (params[:service_type])
    @service_type_id = (params[:service_type_id]).to_i
    @service = Service.new
    @call_type = "Add"
    respond_to do |format|
      format.js {}
    end
  end

  def create
    @service = Service.new(service_params)
    respond_to do |format|
      if @service.save
        format.js {}
      else
        format.js { render :new }
      end
    end
  end

  def edit
    @organisationid = current_user.organisation.id
    @service_type = (params[:service_type])
    @service_type_id = (params[:service_type_id]).to_i
    @service = Service.find(params[:id])
    @call_type = "Edit"
    respond_to do |format|
      format.js {}
    end
  end

  def update
    @service = Service.find(params[:id])
    @service.update(service_update_params)
    respond_to do |format|
      format.js {}
    end
  end

  def destroy
    @service = Service.find(params[:id])
    respond_to do |format|
      if @service.destroy
        format.js {}
      end
    end
  end

  def findmatchingservice
    @servicelist = Service.where(:name => /#{Regexp.escape(params[:q])}/i, :organisation_id => current_user.organisation.id, :service_type => params[:patient_service_type])
  end

  def populateservicedetails
    @service = Service.find("#{params[:populateservicedetails][:id]}")
    @target_id = params[:target_id]
    @prefix = params[:prefix]
    respond_to do |format|
      format.js {}
    end
  end

  def data
    @total_services_count = Service.where(:organisation_id => current_user.organisation.id, :service_type_id => 440655000).count
    @services_count = Service.where(:organisation_id => current_user.organisation.id, :service_type_id => 440655000, :name => %r[#{params[:sSearch]}]).count
    @services = Service.where(:organisation_id => current_user.organisation.id, :service_type_id => 440655000, :name => %r[#{params[:sSearch]}])
                       .limit(params[:iDisplayLength])
                       .offset(params[:iDisplayStart])
                       .order("name " + params[:sSortDir_0])
    @sEcho = params[:sEcho]
    respond_to do |format|
      format.json {}
    end
  end

  def ipddata
    @total_services_count = Service.where(:organisation_id => current_user.organisation.id, :service_type_id => 440654001).count
    @services_count = Service.where(:organisation_id => current_user.organisation.id, :service_type_id => 440654001, :name => %r[#{params[:sSearch]}]).count
    @services = Service.where(:organisation_id => current_user.organisation.id, :service_type_id => 440654001, :name => %r[#{params[:sSearch]}])
                       .limit(params[:iDisplayLength])
                       .offset(params[:iDisplayStart])
                       .order("name " + params[:sSortDir_0])
    @sEcho = params[:sEcho]
    respond_to do |format|
      format.json {}
    end
  end

  def otdata
    @total_services_count = Service.where(:organisation_id => current_user.organisation.id, :service_type_id => 387713003).count
    @services_count = Service.where(:organisation_id => current_user.organisation.id, :service_type_id => 387713003, :name => %r[#{params[:sSearch]}]).count
    @services = Service.where(:organisation_id => current_user.organisation.id, :service_type_id => 387713003, :name => %r[#{params[:sSearch]}])
                       .limit(params[:iDisplayLength])
                       .offset(params[:iDisplayStart])
                       .order("name " + params[:sSortDir_0])
    @sEcho = params[:sEcho]
    respond_to do |format|
      format.json {}
    end
  end

  def admindata
    @total_services_count = Service.where(:organisation_id => current_user.organisation.id, :service_type_id => 413454004).count
    @services_count = Service.where(:organisation_id => current_user.organisation.id, :service_type_id => 413454004, :name => %r[#{params[:sSearch]}]).count
    @services = Service.where(:organisation_id => current_user.organisation.id, :service_type_id => 413454004, :name => %r[#{params[:sSearch]}])
                       .limit(params[:iDisplayLength])
                       .offset(params[:iDisplayStart])
                       .order("name " + params[:sSortDir_0])
    @sEcho = params[:sEcho]
    respond_to do |format|
      format.json {}
    end
  end

  def assessmentdata
    @total_services_count = Service.where(:organisation_id => current_user.organisation.id, :service_type_id => 9999999999).count
    @services_count = Service.where(:organisation_id => current_user.organisation.id, :service_type_id => 9999999999, :name => %r[#{params[:sSearch]}]).count
    @services = Service.where(:organisation_id => current_user.organisation.id, :service_type_id => 9999999999, :name => %r[#{params[:sSearch]}])
                       .limit(params[:iDisplayLength])
                       .offset(params[:iDisplayStart])
                       .order("name " + params[:sSortDir_0])
    @sEcho = params[:sEcho]
    respond_to do |format|
      format.json {}
    end
  end

  def add_excel
    @service_type = (params[:service_type])
    @service_type_id = params[:service_type_id].to_i
    respond_to do |format|
      format.js {}
    end
  end

  def import_excel
    @service_type = (params[:service_type])
    @service_type_id = params[:service_type_id].to_i
    bulk_file_details = params[:bulk_file].tempfile
    Spreadsheet.client_encoding = 'UTF-8'
    bulk_file = Spreadsheet.open bulk_file_details.path
    uploaded_data = bulk_file.worksheet 0
    uploaded_data.each_with_index do |row, index|
      service = Service.new(:name => row[0], :default_units => row[1], :unit_cost => row[2], :service_type => @service_type, :service_type_id => @service_type_id, :organisation_id => current_user.organisation_id.to_s, :is_custom => "Y")
      if service.save
      end
    end
    FileUtils.rm bulk_file_details.path
    respond_to do |format|
      format.js {}
    end
  end

  private

  def service_params
    params.require(:service).permit(:organisation_id, :unit_cost, :default_units, :name, :id, :service_type, :service_type_id).merge(:is_custom => "Y")
  end

  def service_update_params
    params.require(:service).permit(:organisation_id, :unit_cost, :default_units, :name, :id, :service_type, :service_type_id).merge(:is_custom => "Y")
  end
end
