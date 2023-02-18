class UserNotesTemplatesController < ApplicationController
  before_action :authorize
  before_action :find_specialties, only: [:new, :edit]

  respond_to :js, :json, :html
  layout 'loggedin'

  def new
    @user_notes_template = UserNotesTemplate.new
    @userid = current_user.id
    @level  = params[:level]
    @type = params[:type] || '1000001'
    respond_to do |format|
      format.js {}
    end
  end

  def create
    params[:user_notes_template][:template_details] = params[:user_notes_template][:template_details].to_json
    # render :text => params[:certificate_template]
    @user_notes_template = UserNotesTemplate.new(user_notes_template_params)
    respond_to do |format|
      if @user_notes_template.save
        format.js {}
      else
        format.js { render :new }
      end
    end
  end

  def index
    @level = 'user'

    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def data
    @level = params[:level]
    @type = params[:type]

    if @level == 'organisation'
      certificate_data_organisation
    elsif @level == 'facility'
      certificate_data_facility
    else
      certificate_data_user
    end

    @sEcho = params[:sEcho]
    respond_to do |format|
      format.json {}
    end
  end

  def destroy
    @user_notes_template = UserNotesTemplate.find_by(id: params[:id])
    @level = params[:level]

    respond_to do |format|
      format.js {} if @user_notes_template.update_attributes(is_deleted: true)
    end
  end

  def edit
    @user_notes_template = UserNotesTemplate.find_by(id: params[:id])
    @template_details = @user_notes_template[:template_details]
    @template_details = JSON.parse(@template_details)
    @userid = current_user.id
    @level  = params[:level]
    @type = @user_notes_template.try(:type)
    respond_to do |format|
      format.js {}
    end
  end

  def update
    params[:user_notes_template][:template_details] = params[:user_notes_template][:template_details].to_json
    @user_notes_template = UserNotesTemplate.find_by(id: params[:id])
    @user_notes_template.update_attributes(user_notes_template_params)
    @level = params[:user_notes_template][:level]

    respond_to do |format|
      format.js {}
    end
  end

  def get_organisation_certificates
    @type = params[:type] || '1000001'
    @level = 'organisation'
  end

  def get_facility_certificates
    @type = params[:type] || '1000001'
    @level = 'facility'
  end

  def get_user_certificates
    @type = params[:type] || '1000001'
    @level = 'user'
  end

  private

  def find_specialties
    if params[:level] == 'user'
      @available_specialties = Specialty.where(:id.in => current_user.specialty_ids)
      @level_name = current_user.fullname

    elsif params[:level] == 'organisation'
      @available_specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])
      @level_name = current_organisation['name']

    elsif params[:level] == 'facility'
      @available_specialties = Specialty.where(:id.in => current_facility.specialty_ids)
      @level_name = current_facility.name
    end
  end

  def user_notes_template_params
    params.require(:user_notes_template).permit(:user_id, :name, :template_details, :level, :organisation_id, :facility_id, :specialty_id, :type)
  end

  def certificate_data_user
    @user_notes_template_count = UserNotesTemplate.where(user_id: current_user.id, name: /#{params[:sSearch]}/, level: @level, type: @type, is_deleted: false).count
    @user_notes_template = UserNotesTemplate.where(user_id: current_user.id, name: /#{params[:sSearch]}/, level: @level, type: @type, is_deleted: false)
                                            .limit(params[:iDisplayLength])
                                            .offset(params[:iDisplayStart])
                                            .order('name ' + params[:sSortDir_0])
    @total_certificate_template_count = UserNotesTemplate.where(user_id: current_user.id, level: @level, type: @type, is_deleted: false).count
  end

  def certificate_data_organisation
    @user_notes_template_count = UserNotesTemplate.where(organisation_id: current_user.organisation_id, name: /#{params[:sSearch]}/, level: @level, type: @type, is_deleted: false).count
    @user_notes_template = UserNotesTemplate.where(organisation_id: current_user.organisation_id, name: /#{params[:sSearch]}/, level: @level, type: @type, is_deleted: false)
                                            .limit(params[:iDisplayLength])
                                            .offset(params[:iDisplayStart])
                                            .order('name ' + params[:sSortDir_0])
    @total_certificate_template_count = UserNotesTemplate.where(organisation_id: current_user.organisation_id, level: @level, type: @type, is_deleted: false).count
  end

  def certificate_data_facility
    @user_notes_template_count = UserNotesTemplate.where(facility_id: current_facility.id, name: /#{params[:sSearch]}/, level: @level, type: @type, is_deleted: false).count
    @user_notes_template = UserNotesTemplate.where(facility_id: current_facility.id, name: /#{params[:sSearch]}/, level: @level, type: @type, is_deleted: false)
                                            .limit(params[:iDisplayLength])
                                            .offset(params[:iDisplayStart])
                                            .order('name ' + params[:sSortDir_0])
    @total_certificate_template_count = UserNotesTemplate.where(facility_id: current_facility.id, level: @level, type: @type, is_deleted: false).count
  end
end
