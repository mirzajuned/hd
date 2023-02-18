class CashRegisterTemplatesController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def new
    @cash_register_template = CashRegisterTemplate.new
    @userid = current_user.id
    respond_to do |format|
      format.js {}
    end
  end

  def create
    params[:cash_register_template][:template_details] = params[:cash_register_template][:template_details].to_json
    @cash_register_template = CashRegisterTemplate.new(cash_register_template_params)

    respond_to do |format|
      if @cash_register_template.save
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
    @cash_register_templates_count = CashRegisterTemplate.where(:user_id => current_user.id, :name => %r[#{params[:sSearch]}]).count
    @cash_register_templates = CashRegisterTemplate.where(:user_id => current_user.id, :name => %r[#{params[:sSearch]}])
                                                   .limit(params[:iDisplayLength])
                                                   .offset(params[:iDisplayStart])
                                                   .order("name " + params[:sSortDir_0])
    @total_cash_register_template_count = CashRegisterTemplate.where(:user_id => current_user.id).count
    @sEcho = params[:sEcho]

    respond_to do |format|
      format.json {}
    end
  end

  def destroy
    @cash_register_template = CashRegisterTemplate.find(params[:id])
    respond_to do |format|
      if @cash_register_template.destroy
        format.js {}
      end
    end
  end

  def edit
    @cash_register_template = CashRegisterTemplate.find(params[:id])
    @template_cash_register_details = @cash_register_template[:template_details]
    @template_cash_register_details = JSON.parse(@template_cash_register_details)
    @userid = current_user.id
    respond_to do |format|
      format.js {}
    end
  end

  def update
    params[:cash_register_template][:template_details] = params[:cash_register_template][:template_details].to_json
    @cash_register_template = CashRegisterTemplate.find(params[:id])
    @cash_register_template.update_attributes(cash_register_template_params)
    respond_to do |format|
      format.js {}
    end
  end

  def delete
  end

  def cash_register_template_params
    params.require(:cash_register_template).permit(:user_id, :name, :template_details)
  end
end
