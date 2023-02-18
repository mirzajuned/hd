class ReferringDoctorsController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def new
    @referring_doctor = ReferringDoctor.new
    @call_type = "Create"
    @user_id = current_user.id
    respond_to do |format|
      format.js {}
    end
  end

  def create
    @referring_doctor = ReferringDoctor.new(referring_doc_params)
    respond_to do |format|
      if @referring_doctor.save
        format.js {}
      else
        format.js { render :new }
      end
    end
  end

  def index
    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def data
    @total_referring_docs_count = ReferringDoctor.where(:user_id => current_user.id, :is_active => true).count
    @referring_docs_count = ReferringDoctor.where(:user_id => current_user.id, :is_active => true, :name => %r[#{params[:sSearch]}]).count
    @referring_doctors = ReferringDoctor.where(:user_id => current_user.id, :is_active => true, :name => %r[#{params[:sSearch]}])
                                        .limit(params[:iDisplayLength])
                                        .offset(params[:iDisplayStart])
                                        .order("name " + params[:sSortDir_0])
    @sEcho = params[:sEcho]
    respond_to do |format|
      format.json {}
    end
  end

  def edit
    @referring_doctor = ReferringDoctor.find(params[:id])
    @call_type = "Update"
    @user_id = current_user.id
    respond_to do |format|
      format.js {}
    end
  end

  def update
    @referring_doctor = ReferringDoctor.find(params[:id])
    @referring_doctor.update(doc_update_params)
    respond_to do |format|
      format.js {}
    end
  end

  def find_matching
    @referring_doc_list = ReferringDoctor.where(:name => /#{Regexp.escape(params[:q])}/i, :user_id => current_user.id, :is_active => true)
  end

  def populate
    @referring_doctor = ReferringDoctor.find("#{params[:populate_doc_details][:id]}")
    @target_id = params[:target_id]
    @prefix = params[:populate_doc_details][:prefix]
    respond_to do |format|
      format.js {}
    end
  end

  def destroy
    @referring_doctor = ReferringDoctor.find(params[:id])
    respond_to do |format|
      if @referring_doctor.update(is_active: false)
        format.js {}
      end
    end
  end

  private

  def referring_doc_params
    params.require(:referring_doctor).permit(:user_id, :place, :name, :speciality, :hospital_name, :mobile_number, :email, :city)
  end

  def doc_update_params
    params.require(:referring_doctor).permit(:user_id, :place, :name, :id, :speciality, :hospital_name, :mobile_number, :email, :city)
  end
end
