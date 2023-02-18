class Mis::FinancialReportsController < ApplicationController
  layout 'loggedin'

  before_action :authorize
  before_action :authenticate_admin_user
  before_action :mis_params, only: [:reports_view, :reports_data, :download_data]
  before_action :facilities_hash, only: [:reports_view, :reports_data]
  before_action :currencies_hash, only: [:reports_view, :reports_data]
  before_action :get_filters

  def index
    @mis_lists = Global.mis_reports_list['revenue']
    @mis_lists.merge!(Global.mis_reports_list['financial'])
  end

  def reports_view
    redirect_to mis_financial_reports_path if @mis_params[:group].blank? || @mis_params[:title].blank?
  end

  def reports_data
    if @mis_params[:group].blank? || @mis_params[:title].blank?
      redirect_to mis_financial_reports_path
    else
      service = "Mis::FinancialReports::#{@mis_params[:title].to_s.camelize}Service"
      @data_array, @total_records = service.constantize.call(@mis_params)
      respond_to do |format|
        format.json { render 'mis/financial_reports/reports_data.json.jbuilder' }
      end
    end
  end

  def download_data
    service = "Mis::FinancialReports::#{@mis_params[:title].to_s.camelize}Service"
    @data_array, @total_records = service.constantize.call(@mis_params, 'xls')

    @filename = "#{params[:group]}_#{params[:title]}.xls"
    respond_to do |format|
      format.xls { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}\"" }
    end
  end

  private

  def authenticate_admin_user
    department_ids = current_user&.department_ids
    if department_ids.present?
      chk_cambodia_opto = (current_facility.country.id == 'KH_039' && current_user.role_ids.any?{|i| [28229004].include?i})
      if department_ids.include?("224608005") || chk_cambodia_opto
        # custom_check_for_lockup
      else
        redirect_to user_department_url(current_user)
      end
    else
      redirect_to '/'
    end
  end

  def custom_check_for_lockup
    multi_auth = OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id)).try(:multi_auth)
    return unless multi_auth
    return unless respond_to?(:lockup) && lockup_codeword
    return if cookies[:lockup].present? && cookies[:lockup] == lockup_codeword.to_s.downcase

    if request.xhr?
      respond_to do |format|
        format.js { render inline: "location.reload();" }
      end
    else
      redirect_to lockup.unlock_path(
        return_to: request.fullpath.split('?lockup_codeword')[0],
        lockup_codeword: params[:lockup_codeword],
      )
    end
  end

  def mis_params
    @mis_params = {}

    # Pushing all params to @mis_params Hash
    params.each { |key, value| @mis_params[key.to_sym] = value }

    date_today = Date.today.strftime('%d/%m/%Y')
    start_date = @mis_params[:start_date].present? ? @mis_params[:start_date] : date_today
    @mis_params[:start_date] = Date.parse(start_date)

    end_date = @mis_params[:end_date].present? ? @mis_params[:end_date] : date_today
    @mis_params[:end_date] = Date.parse(end_date)

    @mis_params[:url] = '/mis/financial_reports/reports_view?'

    default_params unless @mis_params[:has_params].present?
  end

  def default_params
    @mis_params[:time_period] = 'Today'
    @mis_params[:organisation_id] = current_facility.organisation_id.to_s
    @mis_params[:facility_id] = current_facility.id.to_s
    @mis_params[:facility_name] = current_facility.name.to_s
    @mis_params[:currency_id] = current_facility.currency_id.to_s
    @mis_params[:currency_symbol] = current_facility.currency_symbol.to_s
    @mis_params[:invoice_type] = 'all'
    @mis_params[:bill_type] = 'all'
    @mis_params[:doctor] = 'all'
  end

  def facilities_hash
    @current_user = current_user
    # @organisation_roles = @current_user.organisation.user_roles
    facilities = Facility.where(:id.in => @current_user.facilities.pluck(:id), is_active: true)
    @facilities = facilities.map do |f|
      { id: f.id.to_s,
        name: f.name.to_s,
        currency_id: f.currency_id.to_s,
        currency_symbol: f.currency_symbol.to_s,
        currency_ids: f.currency_ids }
    end
    @organisation = @current_user.organisation
  end

  def currencies_hash
    facility = @facilities.find { |f| f[:id] == @mis_params[:facility_id] }
    # currency_ids = facility.present? ? facility[:currency_ids] : @facilities.pluck(:currency_ids).flatten
    currency_ids = facility.present? ? facility[:currency_ids] : @organisation.currency_ids

    currencies = Currency.where(:id.in => currency_ids)
    @currencies = currencies.map { |c| { id: c.id.to_s, name: c.name.to_s, symbol: c.symbol.to_s } }
  end

  def get_filters
    @clinical_filter = Reports::Filter.where(:category.in => ['general', 'financial'], is_active: true)
  end
end
