class Mis::NewClinicalReportsController < ApplicationController
  layout 'loggedin'

  before_action :authorize
  before_action :authenticate_admin_user
  before_action :mis_params, only: [:reports_view, :reports_data, :download_data]
  before_action :filters
  before_action :facilities_hash, only: [:reports_view, :reports_data]

  def index
    @mis_lists = Global.mis_reports_list['new_clinical']
    @grouped_options = @mis_lists.map do |report_list|
      group = (report_list[0] == 'ot') ? 'OT' : report_list[0].titleize
      [group,
       report_list[1].map do |report_name|
         [Mis::Constants::Badge.link_name(report_name), report_name]
       end]
    end
  end

  def reports_view
    redirect_to mis_new_clinical_reports_path if @mis_params[:group].blank? || @mis_params[:title].blank?
    if @mis_params[:role_filter]&.present? || @mis_params[:title] == 'user_wise_tat'
      @roles = Role.all
    end
  end

  def reports_data
    if @mis_params[:group].blank? || @mis_params[:title].blank?
      redirect_to mis_new_clinical_reports_path
    else
    @data_array, @total_records = "Mis::ClinicalReports::#{@mis_params[:title].to_s.camelize}Service"
                                      .constantize.call(@mis_params, 'json')
      respond_to do |format|
        format.json { render 'mis/new_clinical_reports/reports_data.json.jbuilder' }
      end
    end
  end

  def download_data
    @data_array, @total_records = "Mis::ClinicalReports::#{@mis_params[:title].to_s.camelize}Service"
                                      .constantize.call(@mis_params, request.format.symbol.to_s)
    @sheet_header = YAML.load_file("#{Rails.root}/config/mis/clinical_headers.yml")[@mis_params[:title]]
    if @mis_params[:title].in?(['inpatient_detail', 'procedure_detail', 'patient_referred_to_summary', 'investigation_detail'])
      country_id = Facility.find_by(id: @mis_params[:facility_id]).country_id if @mis_params[:facility_id].present?
      if country_id.present? && country_id == 'VN_254'
        @sheet_header[0][@sheet_header[0].index('STATE')].replace('COMMUNE')
        @sheet_header[0][@sheet_header[0].index('PINCODE')].replace('DISTRICT')
      end
    elsif @mis_params[:group] == 'diagnosis' && @mis_params[:organisation_id] != '5d1acd4dcd29ba3243ea6d41'
      @sheet_header[0].insert(0, 'DIAGNOSIS DATE')
    end
    @filter_data = @data_array.shift(1).flatten[0].to_a
    @filename = "#{params[:group]}_#{params[:title]}.xlsx"
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}\"" }
    end
  end

  private

  def authenticate_admin_user
    department_ids = current_user&.department_ids || []
    if department_ids.present?
      chk_cambodia_opto = (current_facility.country.id == 'KH_039' && current_user.role_ids.any?{|i| [28229004].include?i})
      if department_ids.include?('224608005') || chk_cambodia_opto || params[:title] == "patient_adverse_event"
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
        format.js { render inline: 'location.reload();' }
      end
    else
      redirect_to lockup.unlock_path(
        return_to: request.fullpath.split('?lockup_codeword')[0],
        lockup_codeword: params[:lockup_codeword]
      )
    end
  end

  def filters
    filter_query = Reports::Filter.where(is_active: true)
    @adverse_filter = filter_query.where(filter_group: 'clinical', category: 'clinical', type: 'adverse_event')
    @clinical_filter = if params[:group] == 'inpatient'
                         filter_query.where(filter_group: 'clinical', category: 'clinical', type: 'ipd')
                       elsif params[:group] == 'procedure'
                         filter_query.where(filter_group: 'clinical', category: 'clinical', type: 'procedure')
                       elsif params[:group] == 'investigation'
                         filter_query.where(filter_group: 'clinical', category: 'clinical', type: 'investigation')
                       elsif params[:group] == 'referral'
                         filter_query.where(filter_group: 'clinical', category: 'clinical', type: 'referral')
                       elsif params[:title] == 'user_wise_tat'
                         filter_query.where(filter_group: 'outpatient', category: 'outpatient', type: 'user_wise_tat')
                       elsif params[:title] == 'role_wise_tat'
                         filter_query.where(filter_group: 'outpatient', category: 'outpatient', type: 'role_wise_tat')                         
                       elsif params[:group] != 'conversion'
                         filter_query.where(filter_group: 'clinical', category: 'clinical', type: 'opd')
                       end
    
    @default_filter = filter_query.where(
      organisation_id: current_organisation['_id'], filter_group: 'default',
      :filter_value_name.nin => ['pharmacy_store_id', 'optical_store_id']
    )
    if @mis_params && @mis_params[:title] == 'vision_improvement'
      @general_filter = filter_query.where(filter_group: 'clinical', :organisation_id.in => [nil, current_organisation['_id']], :category.in => ['general', 'vision_improvement'])
    elsif @mis_params && params[:title] == 'patient_referred_to_summary'
      @general_filter = filter_query.where(filter_group: 'clinical', category: 'clinical', type: 'referral')
    elsif @mis_params && params[:title].in?(['cumulative_investigation_advised', 'advised_investigation_conversion', 'daily_investigation_conversion', 'advised_performed_investigation', 'investigation_performed', 'investigation_detail', 'procedure_detail', 'procedure_performed', 'advised_performed_procedure', 'advised_procedure_conversion'])
      @general_filter = filter_query.where(filter_group: 'clinical', organisation_id: current_organisation['_id'], category: 'general', :filter_name.ne => 'doctor')
    elsif @mis_params && params[:group] != 'conversion' && ['referral_statistics', 'diagnosis_stats', 'diagnosis_aggregated', 'patient_referred_to_stats', 'daily_procedure_conversion', 'cumulative_procedure_advised', 'role_wise_tat', 'user_wise_tat', 'patient_time_spent_wise'].exclude?(@mis_params[:title])
      @general_filter = filter_query.where(filter_group: 'clinical', organisation_id: current_organisation['_id'], category: 'general')
    elsif params[:group] == 'conversion'
      if params[:title] == 'pharmacy_conversion_summary' || params[:title] == 'pharmacy_conversion_stats'
        @general_filter = filter_query.where(
          :organisation_id.in => [nil, current_organisation['_id']], 
          :facility_id.in => [nil, current_facility['id']], filter_group: 'default', 
          :filter_value_name.nin => ['optical_store_id', 'facility_id']
        )
      elsif params[:title] == 'optical_conversion_summary' || params[:title] == 'optical_conversion_stats'
        @general_filter = filter_query.where(
          :organisation_id.in => [nil, current_organisation['_id']], 
          :facility_id.in => [nil, current_facility['id']], filter_group: 'default', 
          :filter_value_name.nin => ['pharmacy_store_id', 'facility_id', 'doctor']
        )
      end
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
    @mis_params[:url] = '/mis/new_clinical_reports/reports_view?'
    @mis_params[:organisation_id] = current_facility.organisation_id.to_s
    @mis_params[:country_id] = current_facility.country_id
    default_params unless @mis_params[:has_params].present?
  end

  def default_params
    @mis_params[:time_period] = 'Today'
    @mis_params[:organisation_id] = current_facility.organisation_id.to_s
    @mis_params[:facility_id] = current_facility.id.to_s
    @mis_params[:facility_name] = current_facility.name.to_s
    default_pharmacy_store if @mis_params[:title] == 'pharmacy_conversion_summary' || @mis_params[:title] == 'pharmacy_conversion_stats'
    default_optical_store if @mis_params[:title] == 'optical_conversion_summary' || @mis_params[:title] == 'optical_conversion_stats'
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

  def default_pharmacy_store
    return unless @mis_params[:facility_id].present?
    store = Inventory::Store.find_by(
      department_id: '284748001', facility_id: @mis_params[:facility_id]
    )
    @mis_params[:pharmacy_store_id] = store.try(:id)
    @mis_params[:pharmacy_store_name] = store.try(:name)
  end
  # end default_pharmacy_store

  def default_optical_store
    return unless @mis_params[:facility_id].present?
    store = Inventory::Store.find_by(
      department_id: '50121007', facility_id: @mis_params[:facility_id]
    )
    @mis_params[:optical_store_id] = store.try(:id)
    @mis_params[:optical_store_name] = store.try(:name)
  end
  # end default_optical_store
end
