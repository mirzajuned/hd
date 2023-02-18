class Mis::RevenueReportsController < ApplicationController
  layout 'loggedin'

  before_action :authorize
  before_action :authenticate_admin_user
  before_action :mis_params, only: [:reports_view, :reports_data, :download_data]
  # before_action :facilities_hash, only: [:reports_view, :reports_data]
  # before_action :currencies_hash, only: [:reports_view, :reports_data]
  before_action :load_filters

  def index
    @mis_lists = Global.mis_reports_list['revenue'] # Dropdown
    @grouped_options = @mis_lists.map do |report_list|
      [report_list[0].titleize,
       report_list[1].map do |report_name|
         [report_name.titleize, report_name]
       end]
    end
  end

  def reports_view
    redirect_to mis_revenue_reports_path if @mis_params[:group].blank? || @mis_params[:title].blank?
  end

  def reports_data
    if @mis_params[:group].blank? || @mis_params[:title].blank?
      redirect_to mis_revenue_reports_path
    else
      service = "Mis::RevenueReports::#{@mis_params[:title].to_s.camelize}Service"
      @data_array, @total_records = service.constantize.call(@mis_params)

      respond_to do |format|
        format.json { render 'mis/revenue_reports/reports_data.json.jbuilder' }
      end
    end
  end

  def download_data
    service = "Mis::RevenueReports::#{@mis_params[:title].to_s.camelize}Service"
    if @mis_params[:title] == 'collection_by_user' && @country_id.present?
      @sheet_header = YAML.load_file("#{Rails.root}/config/mis/revenue_headers.yml")["#{@mis_params[:title]}_#{@country_id}"]
    else
      @sheet_header = YAML.load_file("#{Rails.root}/config/mis/revenue_headers.yml")[@mis_params[:title]]
      @sheet_header[0] << 'Assigned/Consultant' if @mis_params[:organisation_id] == '5fca3a6b6ab05d1cbb8c75c4' && @mis_params[:title] == 'billing_summary'
    end

    if @mis_params[:title].in?(['package_summary', 'service_summary'])
      country_id = Facility.find_by(id: @mis_params[:facility_id]).country_id if @mis_params[:facility_id].present?
      if country_id.present? && country_id == 'VN_254'
        @sheet_header[0][@sheet_header[0].index('State')].replace('Commune')
        @sheet_header[0][@sheet_header[0].index('Pincode')].replace('District')
      end
    end

    @data_array, @total_records = service.constantize.call(@mis_params, 'xls')
    @filter_data = @data_array.shift(1).flatten[0].to_a
    @filename = "#{params[:title]}_#{Date.current}_by_#{current_user.fullname.titleize}.xlsx"
    render xlsx: 'download_data.xlsx.axlsx', filename: @filename.to_s, xlsx_author: 'HealthGraph'
  end

  def chceck_specialty_count
    return unless params[:ajax]['facility_id'].present? || params[:ajax]['report_name'].present?
    report_for = params[:ajax]['report_name']
    facility_id = params[:ajax]['facility_id']

    has_specialties = has_sub_specialties = false

    if report_for == 'services'
      has_specialties = Finance::StatisticService.where(
                          facility_id: facility_id, :specialty_id.nin => [nil, '']
                        ).pluck(:specialty_id).uniq.count > 1
      has_sub_specialties = Finance::StatisticService.where(
                          facility_id: facility_id, :sub_specialty_id.nin => [nil, '']
                        ).pluck(:sub_specialty_id).uniq.count > 0
    elsif report_for == 'package'
      has_specialties = Finance::StatisticPackage.where(
                          facility_id: facility_id, :specialty_id.nin => [nil, '']
                        ).pluck(:specialty_id).uniq.count > 1
      has_sub_specialties = Finance::StatisticPackage.where(
                          facility_id: facility_id, :sub_specialty_id.nin => [nil, '']
                        ).pluck(:sub_specialty_id).uniq.count > 0
          
    end
    respond_to do |format|
      format.json { render :json => { 
        "has_specialties" => has_specialties, 
        "has_sub_specialties" => has_sub_specialties 
      } }
    end
  end

  private

  def authenticate_admin_user
    if current_user.present?
      department_ids = current_user.department_ids
      if department_ids.present?
        chk_cambodia_opto = (current_facility.country.id == 'KH_039' && current_user.role_ids.any?{|i| [28229004].include?i})
        if department_ids.include?('224608005') || chk_cambodia_opto
          # custom_check_for_lockup
        else
          redirect_to user_department_url(current_user)
        end
      else
        redirect_to '/'
      end
    else
      redirect_to '/'
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
    @mis_params[:url] = '/mis/revenue_reports/reports_view?'
    @back_url = "/mis/financial_reports"
    if @mis_params[:back_group].present? && @mis_params[:back_title].present?
      @back_url = "#{@mis_params[:url]}#{back_params}"
    end

    @country_id = current_facility.country_id rescue 'IN_108'

    default_params unless @mis_params[:has_params].present?
  end

  def default_params
    @country_id = current_facility.country_id rescue 'IN_108'
    @mis_params[:time_period] = 'Today'
    @mis_params[:organisation_id] = current_facility.organisation_id.to_s
    @mis_params[:facility_id] = current_facility.id.to_s
    @mis_params[:facility_name] = current_facility.name.to_s.gsub(/\'/,'`')
    @mis_params[:country_id] = @country_id
    @mis_params[:is_advance] = @mis_params[:is_bill] = @mis_params[:is_refund] = true

    @mis_params[:bill_type] = @mis_params[:user_id] = @mis_params[:user_name] = ''
    @mis_params[:department_id] = @mis_params[:department_name] = ''
    @mis_params[:payer_name] = @mis_params[:bill_status] = ''
    @mis_params[:conversion_status] = @mis_params[:discount_type] = @mis_params[:bill_entry_type_id] = ''
    @mis_params[:sub_specialty_id] = ''

    default_pharmacy_store if @mis_params[:title] == 'pharmacy_conversion_summary' || @mis_params[:title] == 'pharmacy_conversion_stats'
    default_optical_store if @mis_params[:title] == 'optical_conversion_summary' || @mis_params[:title] == 'optical_conversion_stats'
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
        currency_ids: f.currency_ids,
        country_id: f.country_id }
    end
    @organisation = @current_user.organisation
  end

  def currencies_hash
    facility = @facilities.find { |f| f[:id] == @mis_params[:facility_id] }
    currency_ids = facility.present? ? facility[:currency_ids] : @organisation.currency_ids

    currencies = Currency.where(:id.in => currency_ids)
    @currencies = currencies.map { |c| { id: c.id.to_s, name: c.name.to_s, symbol: c.symbol.to_s } }

    @country_id = facility[:country_id]
  end

  def load_filters
    @current_date = Date.current
    return unless @mis_params.present?

    filter_file = YAML.load_file("#{Rails.root}/config/mis/filters_config.yml")[@mis_params[:title]]
    filter_query = Reports::Filter.where(is_active: true)

    @facility_filter = filter_query.find_by(
      organisation_id: current_organisation['_id'], filter_group: 'default',
      filter_value_name: 'facility_id'
    )
    @default_filter = filter_query.where(
      :organisation_id.in => [nil, current_organisation['_id']], :facility_id.in => [nil, current_facility['_id']],
      :filter_group.in => ['default', 'financial'], :filter_value_name.in => filter_file['default_filters']
    ) if filter_file['default_filters'].present?
    @financial_filter = filter_query.where(
      :filter_group.in => ['default', 'financial'], category: 'financial',
      :filter_value_name.in => filter_file['more_filters']
    ) if filter_file['more_filters'].present?

    total_record_count = @default_filter.count || 0 rescue 0
    total_record_count += @financial_filter.count if @financial_filter.present? #&& @financial_filter.count > 0
    @row_count = (12 / total_record_count) rescue 12
    @row_count = 6 if @row_count == 12
  end

  def back_params
    back_params_str = "group=#{@mis_params[:back_group]}"
    back_params_str += "&title=#{@mis_params[:back_title]}"
    back_params_str += "&start_date=#{@mis_params[:back_start_date]}"
    back_params_str += "&end_date=#{@mis_params[:back_end_date]}"
    back_params_str += "&facility_id=#{@mis_params[:facility_id]}"
    back_params_str += "&time_period=#{@mis_params[:back_time_period]}"
    back_params_str += "&bill_type=#{@mis_params[:bill_type]}"
    back_params_str += "&organisation_id=#{@mis_params[:organisation_id]}"
    back_params_str += "&facility_name=#{@mis_params[:facility_name].gsub(/\'/,'`')}"
    back_params_str += "&has_params=#{@mis_params[:has_params]}"

    if @mis_params[:title] == 'pharmacy_conversion_summary' || @mis_params[:title] == 'pharmacy_conversion_stats'
      back_params_str += "&pharmacy_store_id=#{@mis_params[:pharmacy_store_id]}" 
      back_params_str += "&pharmacy_store_name=#{@mis_params[:pharmacy_store_name]}" 
    elsif @mis_params[:title] == 'optical_conversion_summary' || @mis_params[:title] == 'optical_conversion_stats'
      back_params_str += "&optical_store_id=#{@mis_params[:optical_store_id]}" 
      back_params_str += "&optical_store_name=#{@mis_params[:optical_store_name]}" 
    end

    back_params_str
  end
  # EOF back_params

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
