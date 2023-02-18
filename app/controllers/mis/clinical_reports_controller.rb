class Mis::ClinicalReportsController < ApplicationController
  layout 'loggedin'

  before_action :authorize
  before_action :authenticate_admin_user
  before_action :get_filters
  before_action :mis_params, only: [:reports_view, :reports_data, :download_data]
  before_action :facilities_hash, only: [:reports_view, :reports_data]

  def index
    # if Rails.env == 'development' || ['cicd1', 'cicd2', 'cicd3'].include?(Rails.env)
    #   organisation_ids = Organisation.pluck(:id).map(&:to_s)
    # else
    #   organisation_ids = Global.mis_organisations[Rails.env]
    # end
    # @show_new_url = false
    # @show_new_url = true if current_user.organisation_id.to_s.in?(organisation_ids)
    @show_new_url = true
    @mis_lists = Global.mis_reports_list['clinical'] # Dropdown
  end

  def reports_view
    redirect_to mis_clinical_reports_path if @mis_params[:group].blank? || @mis_params[:title].blank?
  end

  def reports_data
    service = "Mis::ClinicalReports::#{@mis_params[:title].to_s.camelize}Service".constantize
    @data_array, @total_records = service.call(@mis_params, 'json')

    respond_to do |format|
      format.json { render 'mis/clinical_reports/reports_data.json.jbuilder' }
    end
  end

  def download_data
    @data_array, @total_records = if @mis_params[:title] == 'patient_time_spent_wise'
            Mis::ClinicalReports::PatientDetailService.call(@mis_params, request.format.symbol.to_s, @mis_params[:title].to_s)
          else
            "Mis::ClinicalReports::#{@mis_params[:title].to_s.camelize}Service".constantize.call(@mis_params, request.format.symbol.to_s)
          end
    @filename = "#{params[:group]}_#{params[:title]}.#{request.format.symbol}"
    respond_to do |format|
      format.xls { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}\"" }
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}\"" }
    end
  end

  private

  def authenticate_admin_user
    department_ids = current_user.department_ids
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

  def get_filters
    @clinical_filter = Reports::Filter.where(organisation_id: current_organisation['_id'])
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

    @mis_params[:url] = '/mis/clinical_reports/reports_view?'
    @mis_params[:organisation_id] = current_facility.organisation_id.to_s
    default_params unless @mis_params[:has_params].present?
    store_params if params[:title] == 'pharmacy_list_wise' || params[:title] == 'pharmacy_list_state_wise' ||
                    params[:title] == 'optical_list_wise' || params[:title] == 'optical_list_state_wise'
  end

  def default_params
    @mis_params[:time_period] = 'Today'
    @mis_params[:facility_id] = current_facility.id.to_s
    @mis_params[:facility_name] = current_facility.name.to_s
  end

  def facilities_hash
    @current_user = current_user
    facilities = Facility.where(:id.in => @current_user.facilities.pluck(:id), is_active: true)
    @facilities = facilities.map do |f|
      { id: f.id.to_s,
        name: f.name.to_s,
        currency_id: f.currency_id.to_s,
        currency_symbol: f.currency_symbol.to_s,
        currency_ids: f.currency_ids }
    end
  end

  def store_params
    if params[:title] == 'pharmacy_list_wise' || params[:title] == 'pharmacy_list_state_wise'
      @stores = if @mis_params[:facility_id].present?
                  Inventory::Store.where(facility_id: @mis_params[:facility_id], :user_ids.in => [current_user.id],
                                         is_active: true, department_id: '284748001')
                else
                  Inventory::Store.where(:user_ids.in => [current_user.id], is_active: true, department_id: '284748001')
                end
    else
      @stores = if @mis_params[:facility_id].present?
                  Inventory::Store.where(facility_id: @mis_params[:facility_id], :user_ids.in => [current_user.id],
                                         is_active: true, department_id: '50121007')
                else
                  Inventory::Store.where(:user_ids.in => [current_user.id], is_active: true, department_id: '50121007')
                end
    end
    @store_ids = @stores&.pluck(:id)
    if params[:store_id].present?
      if @store_ids.include? BSON::ObjectId(params[:store_id])
        @mis_params[:store_id] = params[:store_id]
        @mis_params[:store_name] = params[:store_name]
      else
        @mis_params[:store_id] = @stores[0]&.id.to_s
        @mis_params[:store_name] = @stores[0]&.name
      end
    else
      @mis_params[:store_id] = @stores[0]&.id.to_s
      @mis_params[:store_name] = @stores[0]&.name
    end
  end
end
