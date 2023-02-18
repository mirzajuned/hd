class DepartmentsController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def new
    @facility = Facility.find(params[:parent_id])
    @departments = Department.where(:id.nin => @facility.department_ids)
    respond_to do |format|
      format.js {}
    end
  end

  def create
    @facility = Facility.find(params[:facility_id])
    @facility.push(department_ids: [params[:department_id]])
    respond_to do |format|
      format.js {}
    end
  end

  def fetch
    @facility = Facility.find(params[:parent_id])
    @departments_count = @facility.departments.where(:name => %r[#{params[:sSearch]}]).count
    @departments = @facility.departments.where(:name => %r[#{params[:sSearch]}])
                            .limit(params[:iDisplayLength])
                            .offset(params[:iDisplayStart])
                            .order("name " + params[:sSortDir_0])

    @total_departments_count = @facility.departments.count
    @sEcho = params[:sEcho]
    respond_to do |format|
      format.json {}
    end
  end

  def get_departments_for_facility
    @departments = Facility.find(params[:facility_id]).departments
    respond_to do |format|
      format.html { render partial: "opd_appointments/departments_dropdown", :layout => false } # for future use if nurse can access all the departments
    end
  end
end
